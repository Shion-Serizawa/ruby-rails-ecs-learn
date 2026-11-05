# 用語集

このリポジトリとドキュメントに出てくる用語。

## Ruby

| 用語 | 説明 |
| --- | --- |
| gem | Ruby のライブラリ。`Gemfile` に書き、`bundle install` で入れる |
| Bundler | gem の依存関係を管理するツール。`Gemfile.lock` でバージョンを固定する |
| ブロック | `{ ... }` / `do ... end` でメソッドに渡す処理のかたまり |
| シンボル | `:name` のような識別子。不変で軽い |
| mixin | `include` でモジュールのメソッドをクラスに取り込むこと |
| `it` | Ruby 3.4+ でブロックの引数を名前なしで参照する書き方 |
| irb | Ruby の対話環境。`bin/rails console` は Rails を読み込んだ irb |
| RuboCop | Ruby のリンター兼フォーマッター |

## Rails

| 用語 | 説明 |
| --- | --- |
| MVC | Model (データ) / View (表示) / Controller (受付) の分担 |
| ActiveRecord | モデルと DB テーブルを対応づける仕組み (ORM) |
| ActiveModel | DB を持たないモデル (フォームオブジェクト等) に検証などの機能を与える |
| ActiveSupport | Rails が Ruby に足した便利メソッド群 (`present?`, `3.days` 等) |
| マイグレーション | DB スキーマの変更を Ruby で書いたファイル。履歴として残る |
| スコープ | よく使う検索条件に名前を付けたもの (`Talk.favorites`) |
| コールバック | 保存前後などに自動で呼ばれる処理 (`before_save`) |
| concern | 複数のクラスで共有するモジュール (`Authentication`) |
| Strong Parameters | 受け取るパラメータを許可リストで絞る仕組み (`params.expect`) |
| パーシャル | `_` で始まる部品テンプレート (`_talk.html.erb`) |
| ヘルパー | ビューで使うメソッド (`link_to`, `conference_path` 等) |
| i18n | 国際化。文言を `config/locales/*.yml` に分離する |
| Zeitwerk | クラス名とファイル名の規約に従って自動で読み込む仕組み |
| N+1 問題 | 一覧の1件ごとに SQL が発行されて遅くなる問題。`includes` で解決 |
| counter_cache | 関連の件数を親テーブルのカラムに保持する仕組み |
| Hotwire | Turbo と Stimulus の総称。HTML 中心で SPA 風の体験を作る |
| Turbo Drive | リンク・フォームを fetch に置き換えて画面遷移を高速化 |
| Turbo Stream | サーバから「DOM のどこをどう変えるか」を送る仕組み |
| Turbo Frame | ページの一部だけを独立して遷移させる枠 |
| Stimulus | HTML の `data-*` 属性で JS を結びつける小さなフレームワーク |
| importmap | JS をバンドルせず、ブラウザの import map で読み込む仕組み |
| Active Job | 非同期ジョブの共通インターフェース |
| Solid Queue / Solid Cache | Rails 8 標準の、DB を使うジョブキュー / キャッシュ |
| Action Mailer | メール送信の仕組み。`deliver_later` で非同期送信 |
| credentials | 暗号化された秘密情報ファイル。このリポジトリでは使わず環境変数にしている |

## テスト

| 用語 | 説明 |
| --- | --- |
| RSpec | テストフレームワーク。`describe` / `context` / `it` で仕様を書く |
| FactoryBot | テストデータを作るライブラリ (`create(:talk)`) |
| request spec | HTTP リクエストを送ってレスポンスを検証するテスト |
| system spec | ブラウザを操作する E2E テスト (Capybara) |
| shoulda-matchers | 検証や関連を1行でテストするマッチャ集 |
| Bullet | N+1 クエリを検出する gem |

## インフラ・運用

| 用語 | 説明 |
| --- | --- |
| Docker Compose | 複数コンテナをまとめて起動するツール (`compose.yaml`) |
| ECS / Fargate | AWS のコンテナ実行サービス / そのサーバレスな実行基盤 |
| タスク / サービス | ECS で動くコンテナのまとまり / タスクを指定数動かし続ける単位 |
| ALB | AWS のロードバランサー。TLS 終端とヘルスチェックを行う |
| RDS | AWS のマネージド DB (ここでは PostgreSQL) |
| SES | AWS のメール送信サービス |
| CDK | AWS のインフラを TypeScript 等のコードで定義するツール |
| Thruster | Rails 用の軽量 HTTP プロキシ。Puma の前で静的配信・圧縮を行う |
| Puma | Rails を動かすアプリケーションサーバ |
| ヘルスチェック | ALB が `/up` を叩いてタスクの生死を確認すること |
| 12-factor | クラウド向けアプリの設計原則。設定を環境変数で渡す等 |
| レート制限 | 一定時間内のリクエスト数を制限すること (`rate_limit`) |
| CSP | Content Security Policy。読み込めるスクリプト等の出どころを制限するヘッダ |

## 開発プロセス

| 用語 | 説明 |
| --- | --- |
| GitHub Flow | main からブランチを切り、PR でマージする運用 |
| Conventional Commits | `feat:` `fix:` などの接頭辞でコミットの種類を示す規約 |
| Squash and merge | PR のコミットを1つにまとめてマージする方式 |
| ADR | 設計判断の記録 ([adr/](adr/README.md)) |
| Lefthook | Git のフック (コミット前のチェック等) を管理するツール |
| Dependabot | 依存関係の更新 PR を自動で作る GitHub の機能 |

## RubyKaigi などでよく聞くキーワード

カンファレンスのトークで出てくるが、このアプリでは直接は扱っていないもの。聞いたときの手がかりに。

| 用語 | ざっくり言うと |
| --- | --- |
| YJIT / ZJIT | Ruby に組み込まれた JIT コンパイラ (実行時に機械語へ変換して高速化) |
| Prism | Ruby の新しいパーサー (ソースコードを構文木にする部品)。RuboCop 等のツールも使い始めている |
| Ractor | 並列実行のための仕組み。スレッドと違い、オブジェクトを共有しない |
| Fiber / Fiber Scheduler | 軽量な実行単位。ノンブロッキング I/O に使われる |
| GVL | Global VM Lock。同時に Ruby コードを実行できるスレッドを1つに制限するロック |
| GC | ガベージコレクション。使われなくなったメモリの回収 |
| RBS / Steep / TypeProf | Ruby の型定義言語と、型チェック・型推論のツール |
| CRuby (MRI) | 公式の Ruby 処理系。JRuby / TruffleRuby など他の実装もある |
| debug.gem / irb | 標準のデバッガと対話環境。このリポジトリの `debugger` も debug.gem |

正確な最新状況は Ruby のリリースノート (NEWS) で確認すること。
