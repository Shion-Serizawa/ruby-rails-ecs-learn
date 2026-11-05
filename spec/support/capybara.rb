require "capybara/rspec"

# コンテナ内の Chromium をヘッドレスで使う (selenium-manager は linux/arm64 非対応のためパスを明示)
Capybara.register_driver :headless_chromium do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.binary = ENV.fetch("CHROME_BIN", "/usr/bin/chromium")
  %w[headless=new no-sandbox disable-dev-shm-usage disable-gpu window-size=1400,1000].each do |arg|
    options.add_argument("--#{arg}")
  end
  service = Selenium::WebDriver::Service.chrome(path: ENV.fetch("CHROMEDRIVER_PATH", "/usr/bin/chromedriver"))
  Capybara::Selenium::Driver.new(app, browser: :chrome, options:, service:)
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, :js, type: :system) do
    driven_by :headless_chromium
  end
end
