# このリポジトリで学ぶ Ruby 文法

Ruby を初めて触る人向けに、**このリポジトリに実際に出てくる書き方** を順に説明する。
他の言語 (JavaScript / Python / Java など) の経験がある前提で、違いが大きいところを中心にする。

手元で試すには Rails コンソールを使う。

```sh
docker compose exec web bin/rails console
```

```ruby
irb> 1 + 1
=> 2
```

---

## 1. すべてがオブジェクト・メソッド呼び出し

Ruby では数値も `nil` もオブジェクトで、`.` でメソッドを呼べる。

```ruby
5.times { puts "hi" }      # 5回繰り返す
"Ruby".downcase            # => "ruby"
nil.to_s                   # => ""
```

**括弧は省略できる**。Rails のコードは省略形が多いので、最初はここで戸惑う。

```ruby
# app/models/conference.rb
validates :name, presence: true, length: { maximum: 100 }
# ↑ 実はこう書いたのと同じ ↓
validates(:name, { presence: true, length: { maximum: 100 } })
```

`validates` はキーワードではなく、クラス定義の中で呼んでいる **ただのメソッド** (クラスメソッド)。
`belongs_to` / `has_many` / `before_action` / `rate_limit` も同じ。Rails の「宣言的な書き方」の正体はこれ。

## 2. シンボル `:name`

`:name` は **シンボル**。名前を表す軽量な不変の値で、文字列 `"name"` とは別物。
メソッド名・属性名・ハッシュのキーなど「識別子」として使う。

```ruby
:name == :name     # => true (同じオブジェクト)
:name == "name"    # => false
```

配列をまとめて書く記法もよく出る。

```ruby
# app/controllers/talks_controller.rb
before_action :set_talk, only: %i[show edit update destroy]
# %i[...] はシンボルの配列 → [:show, :edit, :update, :destroy]
# %w[...] なら文字列の配列
```

## 3. ハッシュとキーワード引数

```ruby
{ name: "RubyKaigi", venue: "函館" }   # キーがシンボルのハッシュ ({ :name => "RubyKaigi" } と同じ)
```

メソッドの最後の引数がハッシュなら `{}` を省略できる。上の `validates` がまさにそれ。

**ハッシュの省略記法** (Ruby 3.1+): 変数名とキー名が同じなら値を省略できる。

```ruby
# app/models/talk.rb
owner.tags.find_or_create_by!(name:)     # name: name と同じ
```

```ruby
# app/controllers/concerns/authentication.rb
def allow_unauthenticated_access(**)              # 受け取ったキーワード引数を
  skip_before_action(:require_authentication, **) # そのまま渡す (匿名の引数転送)
end
```

## 4. ブロック `{ }` / `do ... end`

メソッドに「処理のかたまり」を渡す仕組み。Ruby で最も重要な機能の1つ。

```ruby
[1, 2, 3].map { |n| n * 2 }   # => [2, 4, 6]

[1, 2, 3].each do |n|          # 複数行のときは do ... end
  puts n
end
```

**`it`** (Ruby 3.4+): ブロック引数が1つなら名前を付けずに `it` で参照できる。

```ruby
# app/models/talk.rb
value.to_s.split(",").map { it.strip.downcase }.compact_blank.uniq
#                         ↑ { |name| name.strip.downcase } と同じ
```

この1行は「カンマで分割 → 前後の空白除去と小文字化 → 空文字を除く → 重複を除く」。
**メソッドチェーン** でデータを変換していくのは Ruby らしい書き方。

## 5. ラムダ `->`

ブロックを値として持ち運べるようにしたもの。Rails では「あとで評価したい処理」を渡すのに使う。

```ruby
# app/models/talk.rb
scope :owned_by, ->(user) { joins(:conference).where(conferences: { user_id: user.id }) }
# Talk.owned_by(current_user) と呼ばれたときに、初めて中身が実行される
```

```ruby
# app/models/user.rb
normalizes :email_address, with: ->(e) { e.strip.downcase }   # 代入のたびに呼ばれる
```

## 6. nil の扱い

Ruby では `nil` と `false` だけが偽。**`0` や `""` は真** (JavaScript や Python と違う)。

| 書き方 | 意味 | 例 |
| --- | --- | --- |
| `a&.b` | `a` が nil なら nil、そうでなければ `a.b` | `Session.active.find_by(...)&.tap { ... }` (authentication.rb) |
| `a \|\| b` | `a` が偽なら `b` | `session.delete(:return_to_after_authenticating) \|\| root_url` |
| `a \|\|= b` | `a` が偽のときだけ `b` を代入 (メモ化) | `@schema_json \|\|= SCHEMA_PATH.read` (conference_import.rb) |
| `x.presence` | 空 (`""`, `[]`, `nil`) なら nil、そうでなければ自分 | `conference.venue.presence \|\| "-"` |
| `x.blank?` / `x.present?` | 空かどうか | `params[:tag].present?` |

`presence` / `blank?` / `compact_blank` は Ruby 本体ではなく **ActiveSupport** (Rails が Ruby に足した拡張)。
Rails のコードを読むときは「これは Ruby 標準か Rails の拡張か」を意識すると、ドキュメントを探しやすい。

`||=` は「初回だけ計算して結果を覚えておく」定番の書き方。

```ruby
# app/models/conference_import.rb
def self.schema_json
  @schema_json ||= SCHEMA_PATH.read.freeze   # 2回目以降はファイルを読まない
end
```

## 7. メソッド定義のいろいろ

```ruby
def full_name(first, last)
  "#{first} #{last}"      # 最後に評価した値が戻り値 (return は省略するのが普通)
end
```

**1行メソッド** (Ruby 3.0+):

```ruby
# app/models/session.rb
def expires_at = updated_at + TTL
def stale? = updated_at <= REFRESH_INTERVAL.ago
```

**名前の末尾の記号** は慣習で意味がある。

| 末尾 | 意味 | 例 |
| --- | --- | --- |
| `?` | 真偽値を返す | `stale?`, `valid?`, `favorite?` |
| `!` | 危険版 (例外を投げる / 自分を書き換える) | `save!` (失敗したら例外)、`save` は false を返す |
| `=` | 代入として呼べる | `def tag_list=(value)` → `talk.tag_list = "ruby"` |

**クラスメソッド** は `self.` を付ける。

```ruby
# app/models/talk.rb
def self.human_status(status)        # Talk.human_status(:planned) と呼ぶ
  I18n.t("activerecord.enums.talk.status.#{status}")
end
```

`private` より下に書いたメソッドはクラスの外から呼べない。

## 8. 条件分岐の書き方

```ruby
return if errors.any?                  # 後置 if (ガード節)。「〜なら抜ける」を1行で
errors.add(:ends_on, :before_starts_on) if ends_on < starts_on
next unless session.stale?             # unless = if not。ブロック内の next は continue に相当
```

```ruby
# app/models/conference_import.rb
match = STARTS_AT_FORMAT.match(value) or return false
# マッチしなければ (nil なら) false を返して抜ける
```

## 9. 範囲 (Range)

```ruby
(1..5).to_a        # => [1, 2, 3, 4, 5]
(1...5).to_a       # => [1, 2, 3, 4]  (終端を含まない)
```

終わりのない範囲は、Rails の `where` で「以上」「未満」を書くのに使える。

```ruby
# app/models/session.rb
scope :active,  -> { where(updated_at: TTL.ago..) }    # updated_at >= 30日前
scope :expired, -> { where(updated_at: ...TTL.ago) }   # updated_at <  30日前
```

`30.days` や `1.hour.ago` も ActiveSupport の拡張 (`Integer#days` など)。

## 10. 文字列

```ruby
"会場: #{venue}"           # ダブルクォートの中は式展開できる
'会場: #{venue}'           # シングルクォートは展開しない
```

複数行は **ヒアドキュメント** `<<~`。`~` を付けるとインデントが取り除かれる。

```ruby
# app/services/conference_markdown_exporter.rb
<<~MD
  # #{conference.name}

  - 期間: #{conference.starts_on} 〜 #{conference.ends_on}
MD
```

## 11. 例外

```ruby
# app/models/conference.rb (メソッド全体を begin で囲んだのと同じ)
def website_url_must_be_http
  uri = URI.parse(website_url)
  ...
rescue URI::InvalidURIError
  errors.add(:website_url, :invalid)
end
```

## 12. クラス・モジュール・mixin

```ruby
class Talk < ApplicationRecord   # 継承は < 
end
```

**モジュール** は「メソッドのかたまり」で、`include` すると取り込める (mixin)。
Ruby は多重継承ができない代わりにこれを使う。

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Authentication     # app/controllers/concerns/authentication.rb のメソッドが使えるようになる
  include Pagy::Method
end
```

Rails では mixin 用のモジュールを **concern** と呼び、`included do ... end` で
「include された側のクラスで実行したいこと」を書ける。

```ruby
# app/controllers/concerns/authentication.rb
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication   # include した全コントローラにこの before_action が付く
  end
end
```

モジュールは名前空間にも使う。`Talks::FavoritesController` は `Talks` モジュールの中の
`FavoritesController` で、ファイルは `app/controllers/talks/favorites_controller.rb`。

## 13. よく使うメソッド

```ruby
tap     # 自分をブロックに渡し、自分を返す。作ったオブジェクトに処理を足すときに便利
user.sessions.create!(...).tap do |session|
  Current.session = session
end   # => 作った session が返る

each_with_index  # インデックス付きで繰り返す (conference_import.rb のエラー位置の特定で使用)
select / map / find / any? / sum   # 配列操作の基本
```

## 14. 次に読むもの

- このリポジトリでの Rails の使われ方: [rails-guide.md](rails-guide.md)
- 手を動かす練習: [exercises.md](exercises.md)
- 公式リファレンス (日本語): https://docs.ruby-lang.org/ja/latest/doc/index.html
- Ruby の新機能: リリースノート (NEWS) https://docs.ruby-lang.org/en/master/NEWS_md.html
