# Conf Notes

カンファレンスで聴いたセッションを記録する Rails アプリ。Ruby / Rails 学習用。

- カンファレンス・セッションの CRUD、タグ、お気に入り(Turbo Stream)、評価
- **LLM で整形した JSON からの一括インポート**(JSON Schema をワンクリックでコピー)
- 聴講メモを Markdown ファイルとしてダウンロード(ユーザー単位でレート制限)
- パスワードリセット(メール送信は Solid Queue で非同期。IP / 宛先 / 全体の3段階で送信数を制限)

## 技術スタック

| 分類 | 採用 |
| --- | --- |
| 言語 / FW | Ruby 4.0 / Rails 8.1 |
| DB | PostgreSQL 18 (Solid Queue / Cache / Cable も PostgreSQL) |
| フロント | Hotwire (Turbo + Stimulus), importmap, Tailwind CSS v4 |
| 認証 | Rails 8 組み込みの authentication ジェネレータ + 新規登録 |
| テスト | RSpec, FactoryBot, Capybara (headless Chromium), shoulda-matchers, SimpleCov |
| 静的解析 | RuboCop (+ rails / rspec / performance / factory_bot / capybara), erb_lint |
| セキュリティ | Brakeman, bundler-audit, importmap audit |
| 開発支援 | Bullet (N+1検出), strong_migrations, annotaterb, letter_opener_web, Lefthook |
| その他 | pagy (ページネーション), rails-i18n (日本語), json_schemer |

## 開発環境 (Docker Compose)

ホストに Ruby は不要。

```sh
docker compose up --build        # web / css(Tailwind watch) / worker(Solid Queue) / db
docker compose exec web bin/rails db:seed   # demo@example.com / password123
```

- アプリ: http://localhost:3000
- 送信メール確認: http://localhost:3000/letter_opener

### よく使うコマンド

```sh
# Rails コンソール / ジェネレータ
docker compose exec web bin/rails console
docker compose exec web bin/rails g migration AddFooToTalks foo:string

# テスト
docker compose run --rm -e RAILS_ENV=test web bundle exec rspec

# Lint / フォーマット (-A で自動修正)
docker compose run --rm --no-deps web bin/rubocop -A
docker compose run --rm --no-deps web bundle exec erb_lint --lint-all -a

# セキュリティスキャン
docker compose run --rm --no-deps web bin/brakeman
docker compose run --rm --no-deps web bin/bundler-audit

# モデルのスキーマ注釈を更新
docker compose run --rm web bundle exec annotaterb models
```

### Git hooks (任意)

```sh
mise install && lefthook install
```

コミット時に RuboCop / erb_lint、プッシュ時に Brakeman / RSpec が走る(`lefthook.yml`)。

## JSON インポート (LLM 連携)

1. 「JSONからインポート」画面で **LLM用プロンプトをコピー** を押す(指示 + JSON Schema)
2. LLM に貼り付け、続けて公式サイトのタイムテーブル等を貼って送信
3. 返ってきた JSON を貼り付けて「インポートする」

- スキーマ定義: [app/schemas/conference_import.schema.json](app/schemas/conference_import.schema.json)
  - `GET /conference_import/schema.json` でも取得可能
- スキーマ検証 → モデル検証の2段階で、エラーは JSON Pointer (`/talks/3/title` など) 付きで表示
- 全件成功 or 全件ロールバック。```json のコードフェンスは自動除去

## 本番イメージ (ECS 想定)

`Dockerfile` はマルチステージの本番用(非 root、jemalloc、Thruster)。ローカルで本番相当の構成を確認できる。

```sh
docker compose -f compose.production.yaml up --build
# http://localhost:8080 / メール: http://localhost:8025 (Mailpit)
```

ECS に載せる際の想定:

| コンテナ | command | 備考 |
| --- | --- | --- |
| web | (デフォルト) `./bin/thrust ./bin/rails server` | :8080 (非 root のため非特権ポート)。ALB のヘルスチェックは `/up` |
| worker | `./bin/jobs` | Solid Queue。別 ECS Service として |
| migrate | `./bin/rails db:prepare` | デプロイ前の単発タスク。web/worker は起動時にマイグレーションしない |

主な環境変数:

| 変数 | 用途 |
| --- | --- |
| `DB_HOST` / `DB_USERNAME` / `DB_PASSWORD` / `DB_NAME` | RDS 接続 (`_cache` `_queue` `_cable` のDBも使用) |
| `SECRET_KEY_BASE` または `RAILS_MASTER_KEY` | Secrets Manager から注入 |
| `APP_HOST` | **必須**。メール内リンクのホスト (未設定なら起動時に失敗) |
| `MAILER_FROM` | **必須**。差出人 (SES で検証済みのアドレス。例: `Conf Notes <no-reply@example.com>`) |
| `SMTP_ADDRESS` / `SMTP_PORT` / `SMTP_USERNAME` / `SMTP_PASSWORD` | SES 等 |
| `RAILS_FORCE_SSL` / `RAILS_ASSUME_SSL` | ALB で TLS 終端する前提で既定 `true` |
| `RUN_DB_PREPARE` | `true` のときだけ web 起動時に `db:prepare` を流す (既定は流さない。ECS では使わない) |

開発機 (Raspberry Pi, arm64) でビルドしたイメージは Fargate の ARM64 (Graviton) でそのまま動く。
