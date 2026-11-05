# CLAUDE.md

このリポジトリで作業する AI エージェント向けのガイド。人間向けの規約は [CONTRIBUTING.md](CONTRIBUTING.md)、セットアップは [README.md](README.md) を参照。

## プロジェクト概要

カンファレンスの聴講メモアプリ (Rails 8.1 / Ruby 4.0 / PostgreSQL)。学習用だが実務相当の構成を維持する。
将来 ECS (Fargate, ARM64) にデプロイする前提で、本番イメージは `Dockerfile`、開発は `compose.yaml`。

## コマンド (すべて Docker 経由。ホストに Ruby は無い)

```sh
docker compose run --rm -e RAILS_ENV=test web bundle exec rspec [path]   # テスト
docker compose run --rm --no-deps web bin/rubocop -A                      # Ruby lint + 自動修正
docker compose run --rm --no-deps web bundle exec erb_lint --lint-all -a  # ERB lint + 自動修正
docker compose run --rm --no-deps web bin/brakeman --no-pager -q          # セキュリティ
docker compose run --rm --no-deps web bin/rails tailwindcss:build         # CSS ビルド確認
docker compose run --rm web bin/rails g ...                               # ジェネレータ
docker compose run --rm web bundle exec annotaterb models                 # マイグレーション後
```

`docker compose up` 中なら `run --rm` の代わりに `exec web` でもよい。

## 作業完了の条件

変更後は以下がすべて通ること。通らないまま完了報告しない。

1. `bundle exec rspec` (0 failures)
2. `bin/rubocop` (no offenses)
3. `bundle exec erb_lint --lint-all` (no errors)
4. `bin/brakeman` (no warnings)
5. CSS を触ったら `bin/rails tailwindcss:build` がエラーなく通る

## アーキテクチャと規約

- **配置**
  - ActiveRecord モデル: `app/models`
  - フォームオブジェクト (ActiveModel): `app/models` (例: `ConferenceImport`)
  - 複数モデルにまたがる手続き・変換: `app/services` (`XxxExporter#call` のように1公開メソッド)
  - 非同期処理: `app/jobs` (Solid Queue)。引数には AR オブジェクトを渡してよい (GlobalID)
- **コントローラ**: REST の7アクションのみ。それ以外の操作はリソースを切り出す
  (例: お気に入り切替 → `Talks::FavoritesController#update`、エクスポート → `Conferences::ExportsController#show`、スキーマ取得 → `ConferenceImports::SchemasController#show`)
- **認可**: 必ず `current_user` 起点でスコープする (`current_user.conferences.find`, `Talk.owned_by(current_user)`)。
  `Conference.find(params[:id])` のような素の find は書かない
- **Strong Parameters**: `params.expect(...)` を使う (Rails 8 流)
- **UI 文言**: すべて `config/locales/ja.yml`。ビューへの直書き禁止 (テスト/開発で `raise_on_missing_translations` 有効)
- **N+1**: テスト環境で Bullet が例外を投げる。一覧では `includes` / `counter_cache` を使う
- **マイグレーション**: strong_migrations が危険な操作を止める。NOT NULL / FK / index / check 制約を DB 側にも張る
- **スタイル**: ダブルクォート、Ruby 3.4+ 構文 (`it`、ハッシュ省略記法 `name:`) OK

## ハマりどころ (過去に実際に踏んだもの)

- **Tailwind v4**: 独自クラスは `@layer components` ではなく `@utility` で定義する。
  `@layer components` 内のクラスは `@apply` できずビルドが失敗し、CSS が丸ごと当たらなくなる
- **`includes` + `joins(...).where(関連テーブル)`**: eager_load になり関連が絞り込まれてしまう。
  関連で絞り込むときはサブクエリ (`where(id: ...select(:talk_id))`) を使う (`Talk.tagged_with` 参照)
- **`errors.add` のオプション名**: `message:` は予約語。補間変数には別名 (`detail:` 等) を使う
- **`association.build(attrs)`**: 属性代入時点では親がまだセットされていない。親に依存する処理は `before_save` 等に遅延する
  (`Talk#tag_list=` 参照)
- **per-form CSRF**: ページ内の各フォームのトークンは別物。curl 等で検証するときは `<meta name="csrf-token">` を使う
- **本番 `force_ssl`**: ALB のヘルスチェック用に `/up` はリダイレクト除外済み。消さないこと
- **本番コンテナのポートは 8080**: 非 root で動かすため :80 は使わない (Fargate では bind できないことがある)。
  ALB のターゲットグループ / ヘルスチェックも 8080 に合わせる
- **本番の必須環境変数**: `APP_HOST` と `MAILER_FROM` は既定値なし (未設定なら起動時に KeyError)。
  起動時のマイグレーションは `RUN_DB_PREPARE=true` のときだけ (ECS では単発タスクで流す)
- **レート制限のカウンタは `Rails.cache`**: `rate_limit` と `PasswordResetThrottle` は Rails.cache に依存する
  (本番 Solid Cache、開発/テスト memory_store)。`:null_store` にすると制限が効かなくなる。
  テストでは `spec/support/cache.rb` が example ごとにクリアする
- **JSON インポートのスキーマ**: `app/schemas/conference_import.schema.json` が唯一の定義。
  `Talk` の enum を変えたらスキーマも更新する (spec で不一致を検知する)
- **credentials**: `config/master.key` はコミットしない。本番は `SECRET_KEY_BASE` 等を環境変数で渡す設計で、credentials は未使用

## Git / GitHub

- `main` はブランチ保護されており直接 push できない (管理者も不可)。必ずブランチを切って PR を出す
  ```sh
  git switch -c <type>/<説明>   # 例: feat/talk-search
  git push -u origin HEAD && gh pr create --fill
  ```
- マージは Squash のみ。**PR タイトルがそのまま main のコミットメッセージになる**ため、PR タイトルも Conventional Commits 形式にする (CI の `pr_title` で検査)
- マージ必須チェック: `scan_ruby` `scan_js` `lint` `test` `docker_build` `pr_title`
- コミットメッセージは Conventional Commits (`feat: ...`, `fix(import): ...`)。詳細は CONTRIBUTING.md
- 1コミット1論理変更。lint の自動修正だけの差分は `style:` で分ける
- コミット・プッシュ・PR 作成はユーザーに頼まれたときのみ
- GitHub は Free プラン (公開リポジトリ)。有料機能前提の設定は入れない

## Ruby のバージョンを上げるとき

次の3箇所を揃えて更新する (Dependabot の対象外にしている)。

- `.ruby-version`
- `Dockerfile` の `ARG RUBY_VERSION`
- `Dockerfile.dev` の `ARG RUBY_VERSION`

更新後は `docker compose build` し直し、`TargetRubyVersion` (`.rubocop.yml`) もメジャー/マイナーが変わる場合は合わせる。
