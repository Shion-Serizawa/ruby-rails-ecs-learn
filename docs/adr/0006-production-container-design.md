# ADR-0006: 本番コンテナは非 root・8080・マイグレーション分離

- 状態: 採用
- 日付: 2026-11-05

## 背景

ECS (Fargate) で、複数タスクを ALB の後ろに並べて動かす。

## 決定

1. コンテナは **非 root (uid 1000)** で動かす
2. Thruster は **8080** で待ち受ける (`HTTP_PORT=8080`)。ALB のターゲットも 8080
3. **マイグレーションは web の起動時に流さない**。デプロイ前に単発タスク (`./bin/rails db:prepare`) で流す。
   ローカル確認用に `RUN_DB_PREPARE=true` のときだけ起動時に流せる
4. `APP_HOST` と `MAILER_FROM` は必須。未設定なら起動時に失敗させる
5. web / worker / migrate は同じイメージを command 違いで使う

## 検討した他の案

| 案 | 採用しなかった理由 |
| --- | --- |
| :80 で待ち受ける (Rails の既定 Dockerfile) | 非 root は 1024 未満のポートを bind できない環境がある。ローカルの Docker で動くのは Docker が `ip_unprivileged_port_start=0` を設定しているからで、Fargate 相当の制限を再現すると `bind: permission denied` で起動しなかった |
| root で動かす | コンテナが乗っ取られたときの被害が大きくなる |
| web 起動時に毎回 db:prepare (Rails の既定) | 複数タスクが同時に起動するとマイグレーションが競合してタスクが落ちる |
| 環境変数に既定値を置く | 設定漏れに気づけない。リセットメールのリンクが `example.com` を指す事故になる |

## 結果

- 良い: デプロイ時の競合や設定漏れを起動時点で検出できる
- 悪い: CDK 側で migrate タスクを先に実行する仕組みが必要
- 注意: インフラ側の前提 (セキュリティグループ、Secrets Manager 等) は [deployment.md](../deployment.md)
