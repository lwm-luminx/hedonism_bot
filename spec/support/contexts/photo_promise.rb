RSpec.shared_context 'when photo promise created' do
  before do
    mock_photographer
  end

  let(:create_promise_query) do
    <<~GQL
      mutation {
        createPhotoPromise {
          promise {
            id
            photographer {
              id
            }
          }
        }
      }
    GQL
  end
end
