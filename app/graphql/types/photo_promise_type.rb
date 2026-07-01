module Types
  class PhotoPromiseType < Types::BaseObject
    implements GraphQL::Types::Relay::Node

    field :files, Types::PhotoPromiseFileType.connection_type, null: false
    field :photographer, Types::PhotographerType, null: false
    field :venue, Types::VenueType, null: true
    field :event, Types::EventType, null: true

    def files
      @object.photo_promise_files
    end
  end
end
