use image::{imageops::FilterType, DynamicImage, GenericImageView};
use ndarray::Array4;

use crate::error::OnnxError;

// ViT image size
pub const VIT_IMAGE_SIZE: u32 = 224;

// ArcFace canonical input size
pub const ARCFACE_IMAGE_SIZE: u32 = 112;

// Standard ImageNet normalization parameters used by Hugging Face ViT
const IMAGENET_MEAN: [f32; 3] = [0.485, 0.456, 0.406];
const IMAGENET_STD: [f32; 3] = [0.229, 0.224, 0.225];

/// Prepares an image for ViT feature extraction:
/// Resizes to 224x224, converts to RGB NCHW [1, 3, 224, 224], and normalizes with ImageNet mean/std.
pub fn preprocess_vit_image(img: &DynamicImage) -> Result<Array4<f32>, OnnxError> {
    let resized = img.resize_exact(VIT_IMAGE_SIZE, VIT_IMAGE_SIZE, FilterType::Triangle);
    let rgb = resized.to_rgb8();

    let mut array = Array4::<f32>::zeros((1, 3, VIT_IMAGE_SIZE as usize, VIT_IMAGE_SIZE as usize));

    for (x, y, pixel) in rgb.enumerate_pixels() {
        let (x, y) = (x as usize, y as usize);
        let channels = pixel.0; // [R, G, B]
        for c in 0..3 {
            let normalized = (channels[c] as f32 / 255.0 - IMAGENET_MEAN[c]) / IMAGENET_STD[c];
            array[[0, c, y, x]] = normalized;
        }
    }

    Ok(array)
}

/// Prepares a face crop for ArcFace embedding:
/// Expands bounding box by expand_percentage, clamps to image bounds, crops, resizes to 112x112,
/// and normalizes to [-1.0, 1.0] (canonical ArcFace normalization).
pub fn preprocess_face_crop(
    img: &DynamicImage,
    x: u32,
    y: u32,
    w: u32,
    h: u32,
    expand_percentage: f32,
) -> Result<Array4<f32>, OnnxError> {
    let (img_w, img_h) = img.dimensions();

    let pad_w = (w as f32 * (expand_percentage / 100.0) / 2.0).round() as u32;
    let pad_h = (h as f32 * (expand_percentage / 100.0) / 2.0).round() as u32;

    let crop_x = x.saturating_sub(pad_w);
    let crop_y = y.saturating_sub(pad_h);
    let crop_w = (w + 2 * pad_w).min(img_w.saturating_sub(crop_x)).max(1);
    let crop_h = (h + 2 * pad_h).min(img_h.saturating_sub(crop_y)).max(1);

    let cropped = img.crop_imm(crop_x, crop_y, crop_w, crop_h);
    let resized = cropped.resize_exact(ARCFACE_IMAGE_SIZE, ARCFACE_IMAGE_SIZE, FilterType::Triangle);
    let rgb = resized.to_rgb8();

    let mut array = Array4::<f32>::zeros((1, 3, ARCFACE_IMAGE_SIZE as usize, ARCFACE_IMAGE_SIZE as usize));

    for (x, y, pixel) in rgb.enumerate_pixels() {
        let (x, y) = (x as usize, y as usize);
        let channels = pixel.0;
        for c in 0..3 {
            // ArcFace normalization: (pixel - 127.5) / 128.0 => range approx [-1.0, 1.0]
            let norm = (channels[c] as f32 - 127.5) / 128.0;
            array[[0, c, y, x]] = norm;
        }
    }

    Ok(array)
}
