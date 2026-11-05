require "rails_helper"

RSpec.describe ExpiredSessionsCleanupJob do
  it "有効期限切れのセッションだけを削除する" do
    user = create(:user)
    active = user.sessions.create!
    expired = user.sessions.create!(updated_at: 31.days.ago)

    described_class.perform_now

    expect(Session.where(id: [active.id, expired.id])).to contain_exactly(active)
  end
end
