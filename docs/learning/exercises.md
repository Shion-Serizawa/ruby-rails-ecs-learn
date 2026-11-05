# 練習問題

このリポジトリに機能を足しながら Ruby / Rails を身につけるための課題。上から順に難しくなる。
各課題は **ブランチを切って PR を出す** ところまでやると、開発フロー全体の練習にもなる。

完了の条件はどの課題も同じ。

- [ ] spec を書いた (先に書けるとなお良い)
- [ ] `rspec` / `rubocop` / `erb_lint` が通る
- [ ] 画面の文言は `config/locales/ja.yml` に置いた

---

## Lv.1 読む・動かす

### 1-1. コンソールでデータを触る

`docker compose exec web bin/rails db:seed` のあと、`bin/rails console` で次を試す。

```ruby
user = User.find_by(email_address: "demo@example.com")
conf = user.conferences.first
conf.talks.chronological.map(&:title)
conf.talks.favorites.count
Talk.tagged_with("ruby").to_sql        # どんな SQL になるか読む
conf.talks.first.update(rating: 6)     # => false になる。なぜ？ errors.full_messages を見る
```

**ねらい**: ActiveRecord のクエリと検証を体感する。

### 1-2. テストを壊してみる

`app/models/conference.rb` の `validates :name, presence: true` を消して
`bundle exec rspec spec/models/conference_spec.rb` を実行する。どのテストが、どんなメッセージで落ちるか確認したら元に戻す。

**ねらい**: テストが仕様を守っていることを確かめる。

### 1-3. 1リクエストを追いかける

ブラウザでお気に入りの ★ を押したときに通るファイルを、順番にすべて挙げる
(ルート → コントローラ → モデル → ビュー)。答え合わせは [architecture.md](../architecture.md) の 5.2。

---

## Lv.2 小さな機能追加

### 2-1. カンファレンスにメモ欄を足す

[development.md の「機能追加の手順」](../development.md#3-機能追加の手順-例-カンファレンスにメモ欄を足す) をそのままやる。

**ねらい**: マイグレーション → モデル → コントローラ → ビュー → テストの一周。

### 2-2. 聴講の進み具合を表示する

カンファレンス詳細に「聴講済み 3 / 10」のように表示する。

- ヒント: `Conference` に `attended_talks_count` のようなメソッドを作る。`talks.attended.count` (enum がスコープを自動で作る)
- テスト: model spec で件数を確認

### 2-3. タイトルで検索する

カンファレンス詳細に検索欄を置き、タイトルの部分一致でセッションを絞り込む。

- ヒント: `Talk` に `scope :search, ->(q) { where("title ILIKE ?", "%#{sanitize_sql_like(q)}%") }`
- **注意**: `"title ILIKE '%#{q}%'"` のように文字列に直接埋め込むと **SQL インジェクション** になる。`?` プレースホルダを使う理由を説明できるようにする
- 既存の `filter_by` に `q:` を足すと、タグ絞り込みと組み合わせられる

---

## Lv.3 Rails らしい機能

### 3-1. タグ一覧ページ

`/tags` で自分のタグを使用回数つきで一覧する。タグを押すとそのタグのセッション一覧へ。

- ヒント: `resources :tags, only: :index`、`current_user.tags.joins(:taggings).group(:id).order(count: :desc)` …のように集計する
- N+1 に注意 (Bullet が教えてくれる)
- request spec で「他人のタグが出ないこと」を確認

### 3-2. メモをその場で編集する (Turbo Frame)

セッション詳細のメモ部分を `turbo_frame_tag` で囲み、「編集」を押すとページ遷移せずにその場でフォームに切り替わるようにする。

- ヒント: `<%= turbo_frame_tag dom_id(@talk, :notes) do %>` を show と edit の両方に置くと、同じ ID の枠だけが差し替わる
- JavaScript は書かなくてよい

### 3-3. 評価を星のクリックで入力する (Stimulus)

セレクトボックスの代わりに ★★★☆☆ をクリックして評価を選べるようにする。

- ヒント: `app/javascript/controllers/rating_controller.js` を作り、クリックで hidden field の値を書き換える
- JS が無効でも送信できるよう、hidden field ではなく radio ボタンを見た目だけ星にする方法もある
- system spec (`:js`) で「星をクリック → 保存 → 評価が反映」を確認

---

## Lv.4 設計を考える

### 4-1. JSON API を足す

`GET /conferences/:id.json` でカンファレンスとセッションを JSON で返す (jbuilder は導入済み)。

- 考えること: 認証はどうする？ (今は Cookie。API なら トークン?) インポートの JSON Schema と形を揃えるべき？
- 決めたことは [ADR](../adr/README.md) に書く

### 4-2. カレンダー (iCalendar) でエクスポート

聴講予定のセッションを `.ics` でダウンロードし、Google カレンダー等に取り込めるようにする。

- ヒント: `Conferences::ExportsController` に `respond_to` で形式を足すか、別リソースにするか考える
- `starts_at` が無いセッションはどうする？ 終了時刻は？

### 4-3. 同じカンファレンスを他の人と共有する

今はカンファレンスがユーザーごと。チームで同じタイムテーブルを共有し、メモは各自で持てるようにするには？

- データモデルの変更 (ER 図) を先に描いてから実装する
- 既存データの移行 (データマイグレーション) も必要になる。strong_migrations の警告を読む

---

## 困ったら

- エラーメッセージを最後まで読む。Rails のエラーはたいてい解決策まで書いてある
- [development.md のよくある症状](../development.md#よくある症状)
- `debugger` で止めて、変数の中身を見る
- AI に聞くときは、`CLAUDE.md` と関係するファイルを読ませてから質問すると、このリポジトリの規約に沿った答えが返ってくる
