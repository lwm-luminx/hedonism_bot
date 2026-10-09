from .tasks.caption_image import caption_image
from .tasks.extract_facial_data import extract_facial_data
from .tasks.extract_visual_features import extract_visual_features

TASKS = {
    "hedonism.who_dis.worker.caption_image": caption_image,
    "hedonism.who_dis.worker.extract_facial_data": extract_facial_data,
    "hedonism.who_dis.worker.extract_visual_features": extract_visual_features,
}
