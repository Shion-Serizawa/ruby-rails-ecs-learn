# 開発ガイドライン

## ブランチ戦略 (GitHub Flow)

- `main` は常にデプロイ可能な状態に保つ。直接 push しない
- 作業は `main` からブランチを切り、PR でマージする
- ブランチ名: `<type>/<短い説明>`
  - 例: `feat/talk-search`, `fix/tag-filter`, `chore/bump-rails`
- マージは **Squash and merge** を基本とする (PR タイトルがそのままコミットメッセージになる)
- CI (lint / security / test) がグリーンになってからマージする

## コミットメッセージ ([Conventional Commits](https://www.conventionalcommits.org/ja/v1.0.0/))

```
<type>(<scope>): <要約>

<本文: なぜ変更したか。何をしたかはコードを見れば分かる>
```

| type | 用途 |
| --- | --- |
| `feat` | 機能追加 |
| `fix` | バグ修正 |
| `refactor` | 振る舞いを変えない内部改善 |
| `perf` | パフォーマンス改善 |
| `test` | テストのみの追加・修正 |
| `docs` | ドキュメント |
| `style` | フォーマット・lint の自動修正のみ |
| `build` | Docker / Gemfile / 依存関係 |
| `ci` | GitHub Actions |
| `chore` | その他雑務 |

- `scope` は任意。例: `import`, `auth`, `talks`, `docker`
- 要約は日本語可。末尾に句点を付けない。50文字程度まで
- 破壊的変更は `feat!:` とし、本文に `BREAKING CHANGE:` を書く
- `lefthook install` 済みなら形式違反のコミットは弾かれる

例:

```
feat(import): JSON Schema によるカンファレンス一括インポートを追加
fix(talks): タグ絞り込み時に他のタグが表示されない問題を修正
build(docker): 本番イメージから test グループの gem を除外
```

## プルリクエスト

- テンプレート (`.github/pull_request_template.md`) に沿って書く
- 1 PR は 1 つの目的に絞る。目安として差分 400 行以内
- UI 変更はスクリーンショットを添付する
- レビューで指摘された修正は追加コミットで行い、Squash で1つにまとめる

## コーディングガイドライン

### 全般

- **Rails の規約に従う** (Convention over Configuration)。独自の仕組みを作る前に Rails 標準を探す
- 自動で直せるスタイルは議論しない。RuboCop / erb_lint の結果を正とする
- 例外的にルールを無効化する場合は、理由をコメントで残す (`# rubocop:disable Xxx -- 理由`)

### モデル / ロジックの置き場所

| 置き場所 | 用途 |
| --- | --- |
| モデル | バリデーション、関連、スコープ、そのモデルで完結するロジック |
| `app/models` のフォームオブジェクト | DB テーブルに対応しない入力 (例: `ConferenceImport`) |
| `app/services` | 複数モデルにまたがる手続き・変換。公開メソッドは `#call` 1つ |
| `app/jobs` | 時間のかかる処理・外部への送信 |
| コントローラ | パラメータ受け取り → モデル/サービス呼び出し → レスポンス。ロジックを書かない |

- コントローラは REST の 7 アクションのみ。それ以外はリソースを切り出す (`Talks::FavoritesController` 等)
- データは必ずログインユーザー起点で取得する (`current_user.conferences.find(...)`)

### データベース

- 制約は DB にも張る (NOT NULL / 外部キー / ユニークインデックス / CHECK)
- マイグレーション後は `annotaterb models` でモデル先頭のスキーマコメントを更新する
- strong_migrations の警告は無視せず、案内に従って安全な手順に分割する

### ビュー / フロントエンド

- 文言はすべて `config/locales/ja.yml` に置く
- 共通 UI は Tailwind の `@utility` (`btn-primary`, `card` など) を使う
- JavaScript は Stimulus コントローラとして書き、インラインスクリプトは書かない
- 画面の部分更新は Turbo Stream / Turbo Frame を優先する

### テスト

- 新機能・バグ修正には spec を付ける (バグ修正は再現テストを先に書く)
- 種類の使い分け:
  - `spec/models`, `spec/services`: ロジックの網羅
  - `spec/requests`: HTTP ステータス、認可、リダイレクト
  - `spec/system`: 主要なユーザーフロー。JS が必要なものだけ `:js` を付ける
- データは FactoryBot で作る。fixtures は使わない
- example 名は日本語で「何がどうなるか」を書く

## マージ前チェック

CI と同じものをローカルで実行できる (pre-push フックでも一部実行される)。

```sh
docker compose run --rm --no-deps web bin/rubocop
docker compose run --rm --no-deps web bundle exec erb_lint --lint-all
docker compose run --rm --no-deps web bin/brakeman --no-pager
docker compose run --rm -e RAILS_ENV=test web bundle exec rspec
```
