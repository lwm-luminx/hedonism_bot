# frozen_string_literal: true

class Page < ApplicationRecord
  PAGE_FIELDS = %w[name cover location].freeze

  validates :name, :facebook_id, :facebook_graph, presence: true
  validates :name_override, presence: { allow_nil: true }

  has_one :venue, dependent: :destroy
  has_one :person, dependent: :destroy

  belongs_to :photo_take
  belongs_to :cover_photo, class_name: "PhotoTake"

  has_many :reviews, dependent: :destroy

  has_many :user_likes, dependent: :destroy
  has_many :users, through: :user_likes

  has_many :events, lambda {
    where("start_at > ? OR end_at > ?", DateTime.now, DateTime.now).order(start_at: :asc)
  }, dependent: :destroy, inverse_of: :page

  def display_name
    name_override || name
  end

  def update_photo(photo)
    image_url = photo["url"]

    self.photo = Photo.for_url image_url
    save
  end

  def update_graph(graph, options = {})
    self.facebook_graph = graph
    self.name = graph["name"]

    self.photo = Photo.for_url(options[:photo_data]["url"]) if options[:photo_data]

    return unless graph["cover"]

    cover_url = graph["cover"]["source"]

    self.cover_photo = Photo.for_url cover_url
  end

  def self.default_client
    @default_client ||= Koala::Facebook::API.new(app_id: Rails.application.credentials.facebook.app_id,
                                                 app_secret: Rails.application.credentials.facebook.secret)
  end

  def self.page_for_facebook_id(client, facebook_id, hidden: false)
    unless facebook_id.to_s =~ /\d+/
      page_object = client.get_object facebook_id

      facebook_id = page_object["id"]
    end

    page = find_by(facebook_id: facebook_id)

    return page if page

    graph = client.get_object facebook_id, fields: PAGE_FIELDS
    page = Page.new(facebook_id: facebook_id, hidden: hidden)
    page.facebook_graph = graph
    page.name = graph["name"]
    photo_data = client.get_picture_data(graph["id"], type: :large)["data"]

    page.update_graph graph, photo: photo_data

    page.save

    page
  end
end
