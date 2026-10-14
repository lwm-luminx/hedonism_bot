pub mod error;
pub mod face;
pub mod image_utils;
pub mod vit;

pub use error::OnnxError;
pub use face::{FaceObject, FaceRecognizer, FacialArea, ARCFACE_EMBEDDING_DIM};
pub use image_utils::{preprocess_face_crop, preprocess_vit_image, ARCFACE_IMAGE_SIZE, VIT_IMAGE_SIZE};
pub use vit::{ViTExtractor, VIT_EMBEDDING_DIM};

#[cfg(test)]
mod tests {
    use super::*;
    use image::{DynamicImage, RgbImage};

    #[test]
    fn test_vit_preprocessing_dimensions() {
        let img = DynamicImage::ImageRgb8(RgbImage::new(400, 300));
        let tensor = preprocess_vit_image(&img).expect("Preprocessing failed");
        assert_eq!(tensor.shape(), &[1, 3, 224, 224]);
    }

    #[test]
    fn test_face_crop_preprocessing_dimensions() {
        let img = DynamicImage::ImageRgb8(RgbImage::new(400, 300));
        let tensor = preprocess_face_crop(&img, 50, 50, 100, 100, 20.0).expect("Face crop failed");
        assert_eq!(tensor.shape(), &[1, 3, 112, 112]);
    }
}
