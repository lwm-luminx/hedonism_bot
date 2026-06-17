class Album
  include ActiveModel::API
  include GlobalID::Identification

  attr_accessor :id, :photos

  def initialize(id, photos)
    @id = id
    @photos = photos || []
  end

  def self.find(id)
    photos = Photo.where(folder_date: id).to_a
    new(id, photos)
  end
end
