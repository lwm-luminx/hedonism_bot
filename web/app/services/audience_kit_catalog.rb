# What a photographer may link albums to in AudienceKit, and linking them. AudienceKit decides which venues and events
# they may see (AudienceKit::Client#catalog); this also keeps to the audiences the photographer holds a live
# PhotographyGrant for, since only those can pull the photos.
class AudienceKitCatalog
  class Invalid < StandardError; end

  def initialize(photographer, client: AudienceKit::Client.new)
    @photographer = photographer
    @client = client
  end

  def audiences(**filters)
    granted = PhotographyGrant.active.where(photographer: @photographer).pluck(:audience_id).map(&:downcase)
    return [] if granted.empty?

    @client.catalog(@photographer.id, **filters)["audiences"].select do |audience|
      audience.is_a?(Hash) && granted.include?(audience["id"].to_s.downcase)
    end
  end

  # Links `album` in `audience_id` to the event (whose venue it takes) or, with no event, the venue. AudienceKit
  # confirms the photographer may link to it; the names it gives are cached for display.
  def link!(album, audience_id:, event_id: nil, venue_id: nil)
    raise Invalid, "Pick an event or a venue" if event_id.blank? && venue_id.blank?

    audience = audiences(audience_id: audience_id, event_id: event_id.presence, venue_id: venue_id.presence).first
    raise Invalid, "That audience isn't connected to this photographer" unless audience

    event = event_id.present? ? find(audience["events"], event_id) : nil
    raise Invalid, "That event isn't one this photographer can link to" if event_id.present? && !event

    venue = find(audience["venues"], event ? event["venueId"] : venue_id)
    raise Invalid, "That venue isn't one this photographer can link to" unless venue

    link = album.album_events.find_or_initialize_by(audience_id: audience["id"])
    link.update!(audience_name: audience["name"], audience_kit_venue_id: venue["id"], venue_name: venue["name"],
                 audience_kit_event_id: event&.dig("id"), event_name: event&.dig("name"),
                 event_start_at: event&.dig("startAt"))
    link
  end

  private

  def find(records, id)
    Array(records).find { |record| record.is_a?(Hash) && record["id"].to_s.casecmp?(id.to_s) }
  end
end
