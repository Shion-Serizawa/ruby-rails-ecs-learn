# rate_limit 等のカウンタが example 間で持ち越されないようにする
RSpec.configure do |config|
  config.before { Rails.cache.clear }
end
