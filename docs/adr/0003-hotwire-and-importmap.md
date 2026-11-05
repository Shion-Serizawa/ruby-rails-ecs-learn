# ADR-0003: フロントエンドは Hotwire + importmap (Node.js なし)

- 状態: 採用
- 日付: 2026-11-04

## 背景

- 目的は Ruby / Rails の学習。フロントエンドのビルド環境 (Node.js, webpack 等) の学習は優先度が低い
- 画面は一覧・詳細・フォームが中心で、SPA にする必要はない

## 決定

- 画面はサーバで HTML を描画し、部分更新は Turbo (Turbo Drive / Turbo Stream) で行う
- 少しの JavaScript は Stimulus コントローラに書く (`app/javascript/controllers`)
- JS はバンドルせず importmap で配信する。CSS は tailwindcss-rails (単体バイナリ) でビルドする

## 検討した他の案

| 案 | 採用しなかった理由 |
| --- | --- |
| React / Vue の SPA + Rails API | 学習範囲が倍になる。API 設計・認証の扱いも複雑になる |
| jsbundling-rails (esbuild) | npm パッケージが必要になったら検討する。現状は不要 |

## 結果

- 良い: Node.js 不要。お気に入りボタン (Turbo Stream) のような部分更新も JS をほぼ書かずに実現できる
- 悪い: リッチな UI (ドラッグ&ドロップ等) は作りにくい
- 注意: CSP で外部オリジンを許可していないため、CDN から JS を読み込むことはできない (importmap で vendor に取り込む)
