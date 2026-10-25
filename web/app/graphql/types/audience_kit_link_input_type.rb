module Types
  class AudienceKitLinkInputType < Types::BaseInputObject
    description "An AudienceKit event, or a venue with no listed event, to link an album to in one audience."

    argument :audience_id, ID, required: true, description: "AudienceKit's audience id"
    argument :event_id, ID, required: false, description: "AudienceKit's event id"
    argument :venue_id, ID, required: false, description: "AudienceKit's venue id, when there is no event"
  end
end
