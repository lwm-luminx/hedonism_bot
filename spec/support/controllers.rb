def mock_photographer(photographer = nil)
  photographer ||= create(:default_photographer)

  allow(Photographer).to receive_messages(default_photographer: photographer, find_by: photographer)
end
