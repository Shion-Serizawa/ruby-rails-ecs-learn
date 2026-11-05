# ADR-0001: 開発環境は Docker Compose で完結させる

- 状態: 採用
- 日付: 2026-11-04

## 背景

- 開発機 (Raspberry Pi, arm64) に Ruby が入っていない
- 本番は ECS (コンテナ) で動かす予定で、開発と本番の差を小さくしたい
- Ruby 初学者なので、Ruby のバージョン管理ツールの導入でつまずきたくない

## 決定

Ruby・PostgreSQL・Tailwind のビルドを含め、すべて `compose.yaml` のコンテナで動かす。
ホストに必要なのは Docker と (任意で) Lefthook のみ。

- 開発用イメージ `Dockerfile.dev` と本番用イメージ `Dockerfile` は分ける (開発用はビルドツールや Chromium を含む)
- コンテナ内のユーザーはホストと同じ UID にし、生成ファイルが root 所有にならないようにする
- gem は名前付きボリュームに置き、コンテナを作り直しても再インストール不要にする

## 検討した他の案

| 案 | 採用しなかった理由 |
| --- | --- |
| ホストに mise で Ruby を入れ、DB だけ Docker | エディタ補完は快適だが、開発と本番の差が増える。セットアップ手順も増える |
| Dev Containers | VS Code 前提になる。compose で十分 |

## 結果

- 良い: `docker compose up` だけで誰でも同じ環境になる。CI・本番との差が小さい
- 悪い: コマンドが長くなる (`docker compose exec web ...`)。エディタの Ruby 補完 (ruby-lsp) はホストに Ruby が無いと使いにくい
- 注意: Lefthook のフックもコンテナ経由でコマンドを実行している
