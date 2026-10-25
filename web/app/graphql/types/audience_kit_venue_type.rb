module Types
  class AudienceKitVenueType < Types::BaseObject
    description "An AudienceKit venue a photographer may link an album to."

    field :id, ID, null: false, description: "AudienceKit's venue id"
    field :name, String, null: false
    field :address, String, null: true
    field :locale, String, null: true, description: "Its metro"
    field :latitude, Float, null: true
    field :longitude, Float, null: true

    def id = object["id"]
    def name = object["name"].to_s
    def address = object["address"]
    def locale = object["locale"]
    def latitude = object["latitude"]
    def longitude = object["longitude"]
  end
end
