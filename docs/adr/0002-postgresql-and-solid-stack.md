# ADR-0002: DB は PostgreSQL、キュー/キャッシュも DB に置く (Redis なし)

- 状態: 採用
- 日付: 2026-11-04

## 背景

- 本番は AWS (RDS が使える)。ECS で複数タスクを動かすため、SQLite (ファイル) は使えない
- 非同期ジョブとキャッシュ (レート制限のカウンタ) が必要
- 学習用なので、管理するミドルウェアは少ないほうがよい

## 決定

- DB は PostgreSQL (本番は RDS)
- ジョブキューは Solid Queue、キャッシュは Solid Cache。どちらも Rails 8 標準で、PostgreSQL 上のテーブルを使う
- 本番では用途ごとに DB を分ける (`<DB_NAME>`, `_cache`, `_queue`)。同じ RDS インスタンス内の別データベース
- Action Cable (WebSocket) は使わないので外した

## 検討した他の案

| 案 | 採用しなかった理由 |
| --- | --- |
| Sidekiq + Redis (ElastiCache) | 実績は多いが、Redis の運用とコストが増える。この規模では DB で十分 |
| MySQL | 選択肢としては同等。Rails コミュニティでの情報量と CHECK 制約などの機能で PostgreSQL を選んだ |
| SQLite (Rails 8 の既定) | 複数タスクから同じファイルを共有できない |

## 結果

- 良い: 必要なのは RDS だけ。ジョブ投入とデータ更新を同じトランザクションにもできる
- 悪い: ジョブの処理量が非常に大きくなると DB の負荷になる (そうなったら Redis 系への移行を検討)
- 注意: レート制限のカウンタも DB (Solid Cache) にあるので、タスクを増やしても回数は共有される
