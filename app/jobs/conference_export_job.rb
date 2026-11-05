class ConferenceExportJob < ApplicationJob
  queue_as :default

  retry_on Net::SMTPServerBusy, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError

  def perform(conference)
    markdown = ConferenceMarkdownExporter.new(conference).call
    ConferenceMailer.export(conference, markdown).deliver_now
  end
end
