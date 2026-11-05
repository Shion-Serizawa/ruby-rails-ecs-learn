class ConferenceMailer < ApplicationMailer
  def export(conference, markdown)
    @conference = conference
    attachments["#{conference.name.parameterize.presence || "conference"}.md"] = {
      mime_type: "text/markdown", content: markdown
    }
    mail to: conference.user.email_address, subject: t(".subject", name: conference.name)
  end
end
