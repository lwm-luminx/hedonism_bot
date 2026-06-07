# frozen_string_literal: true

module Types
  class FaceDataInputType < Types::BaseInputObject
    argument :embedding, [ Float ], required: true
    argument :face_confidence, Float, required: true
    argument :facial_area, GraphQL::Types::JSON, required: true
  end
end
