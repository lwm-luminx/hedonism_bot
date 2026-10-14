# frozen_string_literal: true

module Types
  class BinaryType < Types::BaseScalar
    def self.coerce_input(input_value, context)
      Base64.decode64(input_value)
    end

    def self.coerce_result(ruby_value, context)
      Base64.encode64(ruby_value)
    end
  end
end
