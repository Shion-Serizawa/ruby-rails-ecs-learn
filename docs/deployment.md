# デプロイ時のセキュリティ前提 (ECS / CDK)

アプリ側で対策済みのことと、インフラ側 (CDK) で満たす必要があることをまとめる。
アプリの対策はインフラの前提が崩れると効かなくなるものがあるので、CDK を変更するときはここも確認する。

## インフラ側で満たすこと

### 秘密情報

- `SECRET_KEY_BASE` / `DB_PASSWORD` / `SMTP_PASSWORD` はタスク定義の `secrets` (Secrets Manager) で渡す。
  `environment` に平文で書かない (タスク定義は `ecs:DescribeTaskDefinition` の権限で読めてしまう)
- `compose.production.yaml` の `SECRET_KEY_BASE` 既定値はローカル検証専用。本番に流用しない

### ネットワーク

- ALB は HTTPS リスナーで TLS を終端し、HTTP は HTTPS へリダイレクトする
- ターゲットグループのポートは 8080 (コンテナは非 root で動くため Thruster が非特権ポートで待ち受ける)。
  ヘルスチェックのパスは `/up`
- タスクのセキュリティグループは **ALB のセキュリティグループからのみ** インバウンドを許可する。
  アプリは `assume_ssl` で「前段で TLS 終端済み」とみなしているため、タスクに直接届く経路があってはならない
- RDS のセキュリティグループはタスクのセキュリティグループからのみ許可する
- RDS のパラメータグループで `rds.force_ssl = 1` (PostgreSQL 15 以降は既定で有効)。
  アプリ側も `sslmode=verify-full` で接続する (`DB_SSLMODE`)

### Host ヘッダ

- `APP_HOSTS` に公開ドメインを設定する (カンマ区切り)。設定外の Host のリクエストは 403 になる
- `/up` は Host の検査から除外済み (ALB のヘルスチェックは Host にタスクの IP を入れてくるため)

### クライアント IP とレート制限

ログイン・新規登録・パスワードリセットのレート制限は `request.remote_ip` 単位で数える。

- **ALB 直結なら追加設定は不要**。ALB の IP はプライベートアドレスで、Rails は既定でプライベートアドレスを
  信頼済みプロキシとして扱うため、`X-Forwarded-For` から正しいクライアント IP を取り出せる
- **CloudFront を前段に置く場合は要対応**。CloudFront のエッジはグローバル IP なので、全リクエストが
  CloudFront の IP から来たように見え、IP 単位の制限が全ユーザー共有になる (= 実質機能しない)。
  `config.action_dispatch.trusted_proxies` に CloudFront の IP レンジを加えるか、WAF のレートベースルールで制限する
- レート制限のカウンタは `Rails.cache` (本番は Solid Cache = DB) にあるので、タスクが複数でも共有される

### マイグレーションと DB 権限

- マイグレーションは web の起動時ではなく、デプロイ前の単発タスク (RunTask) で実行する
- 可能なら、web / worker が使う DB ユーザーには DDL 権限を与えず、マイグレーション用のユーザーと分ける

### ログ

- パスワードリセットのトークンは URL のパス (`/passwords/<token>/edit`) に入るため、
  Rails の `Started GET` 行と ALB のアクセスログに残る (`filter_parameters` で隠れるのはパラメータの行のみ)。
  トークンは15分で失効し、パスワード変更後は無効になるので**受け入れているリスク**。
  代わりに CloudWatch Logs / ALB ログの S3 バケットの閲覧権限を絞ること

### GitHub Actions からのデプロイ (OIDC)

- AWS の認証は OIDC で行い、アクセスキーを Secrets に置かない
- `permissions: id-token: write` はデプロイジョブにだけ付ける (ワークフロー全体には付けない)
- IAM ロールの信頼ポリシーの `sub` を
  `repo:Shion-Serizawa/ruby-rails-ecs-learn:environment:production` のように環境まで限定し、
  GitHub の Environment `production` で main ブランチからのみデプロイできるようにする
- `pull_request_target` や fork からの PR でデプロイジョブが動かないようにする
- Actions はコミット SHA で固定する (既存の CI と同じ。Dependabot が SHA とコメントのバージョンを更新する)

## アプリ側で対策済みのこと (参考)

| 対策 | 場所 |
| --- | --- |
| HTTPS 強制・HSTS・Cookie の Secure 属性 | `config.force_ssl` (`/up` はリダイレクト除外) |
| Host ヘッダの許可リスト | `config.hosts` (`APP_HOSTS`) |
| CSP (外部オリジン不許可、importmap は nonce) | `config/initializers/content_security_policy.rb` |
| ログインセッションの有効期限 (最終アクセスから30日) と期限切れの削除 | `Session::TTL`, `ExpiredSessionsCleanupJob` |
| ログイン試行の制限 (IP ごと + アカウントごと) | `SessionsController` |
| パスワードリセットメールの制限 (IP ごと + 宛先ごと + 全体) | `PasswordsController`, `PasswordResetThrottle` |
| インポート・エクスポートの回数制限 (ユーザーごと) | 各コントローラの `rate_limit` |
| DB 接続の TLS 検証 | `config/database.yml` (`DB_SSLMODE`) |
| SMTP の STARTTLS 必須 | `config/environments/production.rb` |

### 受け入れているリスク

- 新規登録時にメールアドレスの一意制約エラーが出るため、そのアドレスが登録済みかどうかを推測できる。
  防ぐにはメールアドレスの確認フロー (確認メールのリンクを踏んで初めて登録完了) が必要で、現状は対象外
- パスワードリセットのトークンがログに残る (上記「ログ」参照)
- パスワードリセットメールの全体上限 (1時間100通) は、多数の IP と登録済みアドレスを用意すれば使い切れる。
  これはメール送信元の評判を守るための遮断器で、発動時は `[PasswordResetThrottle] global limit exceeded`
  が警告ログに出る。CloudWatch のメトリクスフィルタでアラートを張ること
