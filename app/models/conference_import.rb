# LLM 等で整形した JSON からカンファレンスとセッションを一括登録するフォームオブジェクト
#
#   import = ConferenceImport.new(user: Current.user, payload: json_string)
#   import.save # => true / false (errors に理由)
class ConferenceImport
  include ActiveModel::Model
  include ActiveModel::Attributes

  SCHEMA_PATH = Rails.root.join("app/schemas/conference_import.schema.json")
  MAX_PAYLOAD_BYTES = 1.megabyte
  MAX_ERRORS = 20
  # スキーマの pattern は形式しか見ないので、日時として実在するかはここで確かめる
  # (2026-02-30 や 25:00 を Time.zone.parse に渡すと、例外になるか別の日時に繰り上がってしまう)
  STARTS_AT_FORMAT = /\A(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?(?:Z|[+-]\d{2}:\d{2})?\z/

  attribute :payload, :string
  attr_accessor :user
  attr_reader :conference

  validates :payload, presence: true
  validate :payload_must_be_valid_json, :payload_must_conform_to_schema, :starts_at_must_exist,
           if: -> { payload.present? }

  def self.schema_json
    @schema_json ||= SCHEMA_PATH.read.freeze
  end

  def self.schemer
    @schemer ||= JSONSchemer.schema(JSON.parse(schema_json))
  end

  # カンファレンスとセッションは save! 1回で同一トランザクション内に保存される (全件成功 or 全件ロールバック)
  def save
    return false if invalid?

    @conference = build_conference
    return false unless records_valid?

    @conference.save!
    true
  end

  private

  # LLM が ```json ... ``` で囲んで返すことが多いので取り除く
  def normalized_payload
    payload.to_s.strip.sub(/\A```(?:json)?\s*\n/, "").sub(/\n```\s*\z/, "")
  end

  def data
    @data ||= JSON.parse(normalized_payload)
  rescue JSON::ParserError
    nil
  end

  def payload_must_be_valid_json
    if payload.bytesize > MAX_PAYLOAD_BYTES
      errors.add(:payload, :too_large)
    elsif !data.is_a?(Hash)
      errors.add(:payload, :invalid_json)
    end
  end

  def payload_must_conform_to_schema
    return if errors.any?

    self.class.schemer.validate(data).first(MAX_ERRORS).each do |error|
      pointer = error["data_pointer"].presence || "/"
      errors.add(:base, :schema_violation, pointer:, detail: error["error"])
    end
  end

  def starts_at_must_exist
    return if errors.any?

    Array(data["talks"]).each_with_index do |talk, index|
      value = talk["starts_at"]
      next if value.blank? || valid_starts_at?(value)

      errors.add(:base, :nonexistent_datetime, pointer: "/talks/#{index}/starts_at", value:)
    end
  end

  def valid_starts_at?(value)
    match = STARTS_AT_FORMAT.match(value) or return false
    year, month, day, hour, minute, second = match.captures.map(&:to_i)
    Date.valid_date?(year, month, day) && hour < 24 && minute < 60 && second < 60
  end

  def build_conference
    attrs = data.slice("name", "venue", "starts_on", "ends_on", "website_url")
    user.conferences.build(attrs).tap do |conference|
      data.fetch("talks", []).each do |talk|
        conference.talks.build(talk_attributes(talk))
      end
    end
  end

  def talk_attributes(talk)
    talk.slice("title", "speaker", "room", "status", "rating", "notes", "favorite")
        .merge("starts_at" => talk["starts_at"].presence && Time.zone.parse(talk["starts_at"]),
               "tag_list" => Array(talk["tags"]).join(","))
        .compact
  end

  # モデルのバリデーションエラーを JSON 上の位置 (JSON Pointer) 付きでフォームに載せる
  def records_valid?
    collect_conference_errors
    collect_talk_errors
    errors.empty?
  end

  def collect_conference_errors
    return if conference.valid?

    conference.errors.each do |error|
      next if error.attribute == :talks # 個別のセッションのエラーは collect_talk_errors で詳細に出す

      add_record_error("/#{error.attribute}", error)
    end
  end

  def collect_talk_errors
    conference.talks.each_with_index do |talk, index|
      next if talk.valid?

      talk.errors.each { |error| add_record_error("/talks/#{index}/#{error.attribute}", error) }
    end
  end

  def add_record_error(pointer, error)
    errors.add(:base, :record_invalid, pointer:, detail: error.full_message)
  end
end
