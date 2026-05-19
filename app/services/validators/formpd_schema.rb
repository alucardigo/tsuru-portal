require "json-schema"

module Validators
  class FormpdSchema
    Result = Struct.new(:success?, :payload, :reason, :errors, keyword_init: true)

    SCHEMA_PATH = Rails.root.join("lib/schemas/formpd_v2026.json").freeze

    def self.schema
      @schema ||= JSON.parse(File.read(SCHEMA_PATH))
    end

    def self.call(payload:)
      new(payload).call
    end

    def initialize(payload)
      @payload = payload.is_a?(String) ? JSON.parse(payload) : payload.deep_stringify_keys
    end

    def call
      errors = JSON::Validator.fully_validate(self.class.schema, @payload)
      if errors.empty?
        Result.new(success?: true, payload: { document: @payload, schema_versao: @payload["schema_versao"] })
      else
        Result.new(success?: false, errors: errors, reason: "FORMP&D nao atende ao schema MCTI v2026")
      end
    end
  end
end
