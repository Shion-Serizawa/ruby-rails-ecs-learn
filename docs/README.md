# ドキュメント

Conf Notes のドキュメント一覧。人間と AI エージェントの両方が読む前提で書いている。

## 読む人ごとのおすすめ順

### はじめて開発に参加する人

1. [../README.md](../README.md) — セットアップと起動
2. [architecture.md](architecture.md) — 全体構成と主要な処理の流れ
3. [domain-model.md](domain-model.md) — データの構造とルール
4. [development.md](development.md) — 開発の進め方・デバッグ・テスト
5. [../CONTRIBUTING.md](../CONTRIBUTING.md) — ブランチ・コミット・コーディング規約

### Ruby / Rails を学びたい人

1. [learning/ruby-basics.md](learning/ruby-basics.md) — このリポジトリのコードで学ぶ Ruby 文法
2. [learning/rails-guide.md](learning/rails-guide.md) — Rails の仕組みと、コードを読む順番
3. [learning/exercises.md](learning/exercises.md) — 手を動かす練習問題 (Lv.1〜4)
4. [glossary.md](glossary.md) — 用語集 (RubyKaigi でよく聞くキーワードも)

### デプロイ・インフラを担当する人

1. [architecture.md の「2. 実行環境」](architecture.md#2-実行環境)
2. [deployment.md](deployment.md) — インフラ (CDK) 側で満たすべきセキュリティ前提
3. [adr/0006-production-container-design.md](adr/0006-production-container-design.md) — コンテナ設計の理由
4. [../README.md の環境変数一覧](../README.md#本番イメージ-ecs-想定)

### AI エージェント

1. [../CLAUDE.md](../CLAUDE.md) (= `AGENTS.md`) — コマンド・完了条件・規約・ハマりどころ
2. 変更する領域に応じて architecture.md / domain-model.md / 関係する ADR

## 一覧

| ファイル | 内容 |
| --- | --- |
| [architecture.md](architecture.md) | システム構成図、実行環境 (開発 / ECS)、ディレクトリと責務、ルーティング、シーケンス図 |
| [domain-model.md](domain-model.md) | ER 図、クラス図、状態遷移図、ルールとその担保箇所 |
| [development.md](development.md) | 開発フロー、CI、コマンド集、機能追加の手順、デバッグ、テスト方針 |
| [deployment.md](deployment.md) | デプロイ時のセキュリティ前提 (インフラ側 / アプリ側) |
| [adr/](adr/README.md) | 設計判断の記録 |
| [glossary.md](glossary.md) | 用語集 |
| [learning/](learning/) | Ruby / Rails 学習ガイドと練習問題 |

## ドキュメントの更新ルール

- コードと食い違ったドキュメントは害になる。**構成・ルート・モデル・環境変数を変えたら、同じ PR でドキュメントも直す**
- 図は Mermaid で書く (GitHub 上でそのまま図として表示される)。画像ファイルにしない
- 「なぜ」を残したい判断は ADR にする
