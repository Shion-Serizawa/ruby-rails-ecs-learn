require "rails_helper"

RSpec.describe ConferenceMailer do
  describe "#export" do
    subject(:mail) { described_class.export(conference, "# memo") }

    let(:conference) { create(:conference, name: "RubyKaigi 2026") }

    it "件名・宛先・添付ファイルを設定する" do
      expect(mail.subject).to eq "【Conf Notes】RubyKaigi 2026 の聴講メモ"
      expect(mail.to).to eq [conference.user.email_address]
      expect(mail.attachments.first.filename).to eq "rubykaigi-2026.md"
      expect(mail.attachments.first.decoded).to eq "# memo"
    end
  end
end
