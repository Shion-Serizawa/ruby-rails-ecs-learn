# アーキテクチャ

Conf Notes の全体構成と、主要な処理の流れをまとめる。データ構造は [domain-model.md](domain-model.md)、
なぜその構成にしたかは [adr/](adr/) を参照。

## 1. システム全体像

```mermaid
flowchart LR
  user([利用者<br/>ブラウザ])
  llm([LLM<br/>ChatGPT / Claude 等])
  subgraph app[Conf Notes]
    web[Web<br/>Rails + Puma + Thruster]
    worker[Worker<br/>Solid Queue]
  end
  db[(PostgreSQL)]
  smtp[[SMTP<br/>本番: Amazon SES]]

  user -- HTTPS --> web
  user -. プロンプト + JSON Schema をコピー .-> llm
  llm -. 整形した JSON を貼り付け .-> user
  web -- 読み書き / ジョブ投入 --> db
  worker -- ジョブ取得 --> db
  worker -- パスワードリセットメール --> smtp
```

- **Web** は画面とフォームを返す普通の Rails アプリ (SPA ではない)。画面の部分更新は Turbo
- **Worker** は時間のかかる処理 (メール送信) と定期処理 (期限切れセッションの削除) を担当する
- ジョブキュー・キャッシュも PostgreSQL に置く (Solid Queue / Solid Cache)。**Redis は使わない** ([ADR-0002](adr/0002-postgresql-and-solid-stack.md))
- LLM はアプリから直接呼ばない。ユーザーがコピー&ペーストで仲介する ([ADR-0005](adr/0005-single-json-schema-for-import.md))

## 2. 実行環境

### 開発 (`compose.yaml`)

```mermaid
flowchart LR
  browser([ブラウザ<br/>localhost:3000])
  subgraph compose[docker compose]
    web["web<br/>bin/rails server"]
    css["css<br/>tailwindcss:watch"]
    worker["worker<br/>bin/jobs"]
    db[(db<br/>postgres:18)]
  end
  src[/ホストのソースコード/]

  browser --> web
  web --> db
  worker --> db
  src -. ボリュームマウント .- web
  src -. ボリュームマウント .- css
  src -. ボリュームマウント .- worker
  css -.->|"app/assets/builds/tailwind.css を出力"| src
```

- ホストに Ruby は不要。すべてコンテナ内で動く ([ADR-0001](adr/0001-docker-only-development.md))
- ソースはマウントしているので、編集すれば web が自動で再読み込みする
- 送信メールは http://localhost:3000/letter_opener で確認する (実際には送られない)

### 本番 (AWS ECS 想定)

```mermaid
flowchart TB
  user([利用者]) -- HTTPS:443 --> alb[ALB<br/>TLS 終端]
  subgraph vpc[VPC]
    alb -- HTTP:8080 --> web1[web タスク]
    alb -- HTTP:8080 --> web2[web タスク]
    worker[worker タスク<br/>./bin/jobs]
    migrate[migrate タスク<br/>./bin/rails db:prepare<br/>デプロイ前に1回]
    rds[(RDS PostgreSQL<br/>primary / cache / queue)]
    web1 & web2 & worker & migrate --> rds
  end
  worker --> ses[[Amazon SES]]
  secrets[[Secrets Manager]] -. SECRET_KEY_BASE 等 .-> web1 & web2 & worker
```

| コンテナ | command | 役割 |
| --- | --- | --- |
| web | (既定) `./bin/thrust ./bin/rails server` | Thruster が :8080 で受け、Puma (:3000) に渡す。静的ファイル配信と圧縮も Thruster |
| worker | `./bin/jobs` | Solid Queue。メール送信と定期ジョブ |
| migrate | `./bin/rails db:prepare` | デプロイ前の単発タスク。web/worker は起動時にマイグレーションしない |

- **同じイメージを command 違いで使い回す** (12-factor の「ビルド・リリース・実行の分離」)
- 設定はすべて環境変数。一覧は [README](../README.md#本番イメージ-ecs-想定)、インフラ側の前提は [deployment.md](deployment.md)
- ポート 8080・マイグレーションを分ける理由は [ADR-0006](adr/0006-production-container-design.md)

## 3. ディレクトリ構成と責務

```
app/
├── controllers/          リクエストを受けてモデルを呼び、レスポンスを返す (ロジックは書かない)
│   ├── concerns/authentication.rb   ログイン状態の管理 (全コントローラに include)
│   ├── conferences/      カンファレンス配下のサブリソース (exports)
│   ├── conference_imports/  インポート配下のサブリソース (schemas)
│   └── talks/            セッション配下のサブリソース (favorites)
├── models/               データとビジネスルール
│   ├── (ActiveRecord)    user, session, conference, talk, tag, tagging
│   └── (ActiveModel)     conference_import (フォームオブジェクト), password_reset_throttle, current
├── services/             複数モデルにまたがる変換 (conference_markdown_exporter)
├── jobs/                 非同期処理 (mail_delivery_job, expired_sessions_cleanup_job)
├── mailers/              メール (passwords_mailer)
├── schemas/              JSON Schema (インポート形式の唯一の定義)
├── views/                ERB テンプレート (HTML / Turbo Stream / メール)
├── javascript/controllers/  Stimulus コントローラ (char_count, clipboard)
└── assets/tailwind/      Tailwind CSS (独自ユーティリティは @utility)
config/
├── routes.rb             URL → コントローラの対応表
├── locales/ja.yml        画面の文言すべて
├── environments/         環境ごとの設定 (production.rb が本番)
└── recurring.yml         定期ジョブの設定
db/
├── migrate/              マイグレーション (スキーマの変更履歴)
├── schema.rb             現在のスキーマ (自動生成。手で書かない)
└── queue_schema.rb, cache_schema.rb   Solid Queue / Solid Cache 用
spec/                     テスト (models / requests / system / ...)
```

### ロジックの置き場所

```mermaid
flowchart LR
  req([HTTP リクエスト]) --> routes[routes.rb]
  routes --> ctrl[Controller<br/>認可・パラメータ・レスポンス]
  ctrl --> model[Model<br/>検証・関連・スコープ]
  ctrl --> form[Form Object<br/>ConferenceImport]
  ctrl --> service[Service<br/>ConferenceMarkdownExporter]
  ctrl -- deliver_later --> job[Job<br/>MailDeliveryJob]
  form --> model
  service --> model
  job --> mailer[Mailer]
  ctrl --> view[View<br/>ERB / Turbo Stream]
```

| 置き場所 | 判断基準 | 例 |
| --- | --- | --- |
| Model | そのモデルだけで完結するルール | `Talk#tag_list=`, `Conference#used_tags` |
| Form Object | DB のテーブルに対応しない入力 | `ConferenceImport` (JSON → 複数レコード) |
| Service | 複数モデルを読んで何かを作る | `ConferenceMarkdownExporter` |
| Job | 時間がかかる / 外部と通信する / 定期実行 | `MailDeliveryJob`, `ExpiredSessionsCleanupJob` |
| Controller | 上記を呼ぶだけ。REST の7アクションのみ | REST 以外の操作はサブリソースに切り出す (`Talks::FavoritesController#update`) |

## 4. ルーティング

| メソッド | パス | コントローラ#アクション | 用途 |
| --- | --- | --- | --- |
| GET | `/` | `conferences#index` | 一覧 (トップ) |
| GET/POST | `/session/new`, `/session` | `sessions#new/create` | ログイン |
| DELETE | `/session` | `sessions#destroy` | ログアウト |
| GET/POST | `/registration/new`, `/registration` | `registrations#new/create` | 新規登録 |
| GET/POST | `/passwords/new`, `/passwords` | `passwords#new/create` | リセットメール要求 |
| GET/PATCH | `/passwords/:token/edit`, `/passwords/:token` | `passwords#edit/update` | 新パスワード設定 |
| (7種) | `/conferences[/:id]` | `conferences#*` | カンファレンス CRUD |
| GET | `/conferences/:id/export` | `conferences/exports#show` | Markdown ダウンロード |
| GET/POST | `/conferences/:id/talks/new`, `/conferences/:id/talks` | `talks#new/create` | セッション作成 |
| GET/PATCH/DELETE | `/talks/:id[/edit]` | `talks#show/edit/update/destroy` | セッション (shallow ルート) |
| PATCH | `/talks/:id/favorite` | `talks/favorites#update` | お気に入り切替 (Turbo Stream) |
| GET/POST | `/conference_import/new`, `/conference_import` | `conference_imports#new/create` | JSON インポート |
| GET | `/conference_import/schema(.json)` | `conference_imports/schemas#show` | JSON Schema |
| GET | `/up` | `rails/health#show` | ALB のヘルスチェック |

実際の一覧は `docker compose exec web bin/rails routes` で確認できる。

## 5. 主要な処理の流れ

### 5.1 リクエストの共通処理 (認証)

すべてのコントローラは `Authentication` concern を通る。ログインしていなければログイン画面へ。

```mermaid
sequenceDiagram
  autonumber
  actor U as ブラウザ
  participant C as Controller<br/>(Authentication)
  participant S as Session (DB)
  U->>C: GET /conferences (Cookie: session_id=署名付きID)
  C->>C: cookies.signed[:session_id] を検証
  C->>S: Session.active.find_by(id:)
  alt 有効なセッションあり
    S-->>C: session
    opt 最終更新から1時間以上経過 (stale?)
      C->>S: refresh! (updated_at を更新 = 有効期限を延長)
      C-->>U: Cookie の期限も延長
    end
    C->>C: Current.session = session
    C-->>U: 200 画面
  else なし / 期限切れ (30日)
    C-->>U: 302 /session/new
  end
```

- セッションは DB に保存し、Cookie には署名付きの ID だけを入れる
- 有効期限は「最後のアクセスから30日」(スライディング方式)。毎リクエストで UPDATE しないよう1時間ごとにまとめて延長
- 期限切れのレコードは `ExpiredSessionsCleanupJob` が毎日4時に削除 (`config/recurring.yml`)

### 5.2 お気に入りの切り替え (Turbo Stream)

ページ全体を再読み込みせず、ボタンだけを差し替える。JavaScript は書いていない。

```mermaid
sequenceDiagram
  autonumber
  actor U as ブラウザ (Turbo)
  participant F as Talks::FavoritesController
  participant T as Talk
  U->>F: PATCH /talks/1/favorite<br/>Accept: text/vnd.turbo-stream.html
  F->>T: Talk.owned_by(current_user).find(1)
  F->>T: update!(favorite: !favorite)
  F-->>U: turbo-stream action="replace" target="favorite_talk_1"<br/>(_favorite_button.html.erb を描画)
  U->>U: DOM の該当部分だけ置き換え
```

### 5.3 JSON インポート

```mermaid
sequenceDiagram
  autonumber
  actor U as 利用者
  participant L as LLM
  participant C as ConferenceImportsController
  participant I as ConferenceImport<br/>(Form Object)
  participant DB as PostgreSQL
  U->>C: GET /conference_import/new
  C-->>U: 画面 (プロンプト + JSON Schema)
  U->>L: プロンプトとタイムテーブルを貼り付け
  L-->>U: JSON
  U->>C: POST /conference_import (payload=JSON)
  C->>I: new(user:, payload:).save
  I->>I: 1. コードフェンス除去・JSON パース
  I->>I: 2. JSON Schema 検証 (json_schemer)
  I->>I: 3. 日時の実在チェック
  I->>I: 4. Conference / Talk を build して valid?
  alt すべて OK
    I->>DB: conference.save! (トランザクション内で talks・tags も保存)
    C-->>U: 302 カンファレンス詳細
  else どこかでエラー
    I-->>C: errors (/talks/3/title のような JSON Pointer 付き)
    C-->>U: 422 フォーム再表示
  end
```

- 検証を段階に分けるのは、JSON Schema で表せない制約 (終了日 ≥ 開始日など) をモデル側で見るため
- 1件でも失敗したら何も保存しない (all or nothing)

### 5.4 パスワードリセット (非同期メール + 送信数制限)

```mermaid
sequenceDiagram
  autonumber
  actor U as 利用者
  participant P as PasswordsController
  participant RL as rate_limit<br/>(IP 単位)
  participant TH as PasswordResetThrottle
  participant Q as Solid Queue
  participant W as Worker<br/>MailDeliveryJob
  participant M as SMTP (SES)
  U->>P: POST /passwords (email_address)
  P->>RL: IP ごと 3分10回 / 1時間20回
  alt 超過
    P-->>U: 「時間をおいて」
  else
    P->>P: User.find_by(email_address:)
    opt ユーザーが存在
      P->>TH: allow? (宛先ごと 1時間3通 → 全体 1時間100通)
      opt 許可
        P->>Q: deliver_later (ジョブを INSERT)
      end
    end
    P-->>U: 常に同じ「送信しました(登録済みの場合)」
  end
  Q-->>W: ジョブ取得
  W->>M: SMTP 送信
  alt 一時的な失敗 (タイムアウト等)
    W->>Q: 間隔を空けて再試行 (最大5回)
  end
```

- 応答を常に同じにするのは、**アドレスが登録済みかどうかを推測させない**ため
- 送信数は「リクエスト数」ではなく「実際に送った数」で数える ([ADR-0008](adr/0008-rate-limiting-with-rails-cache.md))

## 6. 横断的な関心事

| 関心事 | 実装 |
| --- | --- |
| 認証 | Rails 8 の authentication ジェネレータ (`has_secure_password` + DB セッション) |
| 認可 | すべて `current_user` 起点で検索 (`current_user.conferences.find`, `Talk.owned_by`)。他人のデータは 404 |
| 入力検証 | モデルの `validates` + DB 制約 (NOT NULL / 外部キー / ユニーク / CHECK) の二重 |
| レート制限 | `rate_limit` (Rails 8 標準) と `PasswordResetThrottle`。カウンタは `Rails.cache` |
| 国際化 | 文言はすべて `config/locales/ja.yml`。未定義の訳があると開発・テストで例外 |
| N+1 検出 | Bullet (テストでは例外にする) |
| セキュリティヘッダ | CSP (外部オリジン不許可)、HSTS、Host ヘッダ許可リスト。詳細は [deployment.md](deployment.md) |
| ログ | 本番は標準出力 (CloudWatch Logs へ)。リクエスト ID 付き |
