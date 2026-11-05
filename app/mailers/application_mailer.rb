class ApplicationMailer < ActionMailer::Base
  layout "mailer"
  self.delivery_job = MailDeliveryJob
end
