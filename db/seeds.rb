# 開発用のサンプルデータ: bin/rails db:seed
# ログイン: demo@example.com / password123
return unless Rails.env.development?

user = User.find_or_create_by!(email_address: "demo@example.com") do |u|
  u.password = "password123"
end

conference = user.conferences.find_or_create_by!(name: "RubyKaigi 2026") do |c|
  c.venue = "函館市民会館"
  c.starts_on = Date.new(2026, 4, 22)
  c.ends_on = Date.new(2026, 4, 24)
  c.website_url = "https://rubykaigi.org/"
end

[
  { title: "Keynote", speaker: "Yukihiro Matsumoto", status: :attended, rating: 5, favorite: true,
    tag_list: "ruby, keynote", notes: "Ruby の今後の方向性について。" },
  { title: "YJIT/ZJIT の最新動向", speaker: "Shopify Ruby team", status: :attended, rating: 4,
    tag_list: "ruby, performance, jit" },
  { title: "Hotwire で作る快適な UI", speaker: "Rails contributor", status: :planned,
    tag_list: "rails, hotwire" }
].each.with_index do |attrs, i|
  conference.talks.find_or_create_by!(title: attrs[:title]) do |talk|
    talk.assign_attributes(attrs.merge(starts_at: Time.zone.parse("2026-04-22 10:00") + i.hours))
  end
end

Rails.logger.info "Seeded: #{user.email_address} / password123"
