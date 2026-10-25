# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :update_photo_promise_file_update, mutation: Mutations::UpdatePhotoPromiseFileUpdate
    field :create_photo_promise, mutation: Mutations::CreatePhotoPromise
    field :attach_photo_promise_files, mutation: Mutations::AttachPhotoPromiseFiles
    field :update_photo_caption, mutation: Mutations::UpdatePhotoCaption
    field :delete_album, mutation: Mutations::DeleteAlbum
    field :delete_photos, mutation: Mutations::DeletePhotos
    field :update_photo_face, mutation: Mutations::UpdatePhotoFacialRecognition
    field :archive_album, mutation: Mutations::ArchiveAlbum
    field :restore_album, mutation: Mutations::RestoreAlbum
    field :link_album_to_audience_kit, mutation: Mutations::LinkAlbumToAudienceKit
    field :unlink_album_from_audience_kit, mutation: Mutations::UnlinkAlbumFromAudienceKit
  end
end
