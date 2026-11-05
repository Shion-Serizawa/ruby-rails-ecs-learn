require "rails_helper"

RSpec.describe ConferenceExportJob do
  it "エクスポートメールを送信する" do
    conference = create(:conference)

    expect { described_class.perform_now(conference) }
      .to change { ActionMailer::Base.deliveries.count }.by(1)

    mail = ActionMailer::Base.deliveries.last
    expect(mail.to).to eq [conference.user.email_address]
    expect(mail.attachments.first.content_type).to start_with "text/markdown"
  end
end
