from io import BytesIO

import requests
from gql import gql
from PIL import Image

from hedonism.who_dis.support import get_photo_url, graph_client

model_name = "google/vit-large-patch32-224-in21k"
processor = None
model = None

def load_model():
    global processor, model
    if processor is None or model is None:
        from transformers import AutoImageProcessor, AutoModel
        processor = AutoImageProcessor.from_pretrained(model_name)
        model = AutoModel.from_pretrained(model_name)

def extract_visual_features(photo_id):
    # 2. Download and prepare the image
    photo_url = get_photo_url(photo_id)
    if not photo_url:
        return

    response = requests.get(photo_url, timeout=60)
    response.raise_for_status()
    image = Image.open(BytesIO(response.content)).convert("RGB")

    import torch
    load_model()

    # 3. Preprocess the image (resizes to 224x224 and normalizes)
    inputs = processor(images=image, return_tensors="pt")

    # 4. Extract embeddings without computing gradients
    with torch.no_grad():
        outputs = model(**inputs)

    # 5. Extract the embedding from the last hidden state
    # ViT outputs the [CLS] token at index 0, which represents the whole image
    last_hidden_states = outputs.last_hidden_state
    image_embedding = last_hidden_states[:, 0, :]
    embedding = image_embedding[0].tolist()

    # Output shape will be: torch.Size([1, 1024])
    print("Embedding Shape:", image_embedding.shape)
    print("Embedding Tensor:\n", image_embedding)

    embedding_update = gql(
        """
        mutation PhotoFeature($photoId: ID!, $embedding: [Float!]!) {
          photoFeaturesUpdate(embedding: $embedding, id: $photoId) {
            photo {
              id
            }
          }
        }
    """
    )

    embedding_update.variable_values = {"photoId": photo_id, "embedding": embedding}
    result = graph_client().execute(embedding_update)
    print(f"Result of Mutation: {result}")

