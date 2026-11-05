# ADR (Architecture Decision Records)

設計上の判断を「なぜそうしたか」とともに残す。コードを読めば **何を** したかは分かるが、
**なぜ** 他の選択肢ではないのかはコードに残らないため。

- 1判断1ファイル。番号は連番で、一度採番したら変えない
- 判断を覆すときは、元の ADR を書き換えずに新しい ADR を作り、元の ADR の状態を「置き換え済み (ADR-XXXX)」にする
- 新しく書くときは [template.md](template.md) をコピーする

| No. | タイトル | 状態 |
| --- | --- | --- |
| [0001](0001-docker-only-development.md) | 開発環境は Docker Compose で完結させる | 採用 |
| [0002](0002-postgresql-and-solid-stack.md) | DB は PostgreSQL、キュー/キャッシュも DB に置く (Redis なし) | 採用 |
| [0003](0003-hotwire-and-importmap.md) | フロントエンドは Hotwire + importmap (Node.js なし) | 採用 |
| [0004](0004-rspec-and-factorybot.md) | テストは RSpec + FactoryBot | 採用 |
| [0005](0005-single-json-schema-for-import.md) | LLM 連携は JSON Schema 1ファイルを唯一の定義にする | 採用 |
| [0006](0006-production-container-design.md) | 本番コンテナは非 root・8080・マイグレーション分離 | 採用 |
| [0007](0007-export-as-download.md) | エクスポートはメール送信ではなく直接ダウンロード | 採用 |
| [0008](0008-rate-limiting-with-rails-cache.md) | レート制限は Rails.cache で数え、メールは実送信数で数える | 採用 |
