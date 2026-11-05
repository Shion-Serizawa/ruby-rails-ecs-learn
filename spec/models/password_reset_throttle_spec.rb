require "rails_helper"

RSpec.describe PasswordResetThrottle do
  let(:user) { create(:user) }

  def allowed?(target) = described_class.new(target).allow?

  it "同じユーザーには1時間に3通まで許可する" do
    expect(Array.new(4) { allowed?(user) }).to eq [true, true, true, false]
  end

  it "1時間経てば再び許可する" do
    3.times { allowed?(user) }
    travel 61.minutes do
      expect(allowed?(user)).to be true
    end
  end

  it "ユーザーごとに独立して数える" do
    3.times { allowed?(user) }
    expect(allowed?(create(:user))).to be true
  end

  it "全体で1時間に100通を超えたら誰にも送らない" do
    stub_const("#{described_class}::GLOBAL_LIMIT", 2)
    users = create_list(:user, 3)

    expect(users.map { allowed?(it) }).to eq [true, true, false]
  end

  it "キャッシュが使えないときは送らない (安全側に倒す)" do
    throttle = described_class.new(user, cache: ActiveSupport::Cache::NullStore.new)
    expect(throttle.allow?).to be false
  end
end
