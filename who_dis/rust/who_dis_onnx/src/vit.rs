use std::path::Path;
use std::sync::Mutex;
use image::DynamicImage;
use ort::{session::Session, value::Tensor};

use crate::error::OnnxError;
use crate::image_utils::preprocess_vit_image;

pub const VIT_EMBEDDING_DIM: usize = 1024;

/// Feature extractor for Google ViT-Large (outputs 1024-dim embedding)
pub struct ViTExtractor {
    session: Mutex<Session>,
}

impl ViTExtractor {
    /// Loads a ViT ONNX model from the specified file path.
    pub fn new(model_path: impl AsRef<Path>) -> Result<Self, OnnxError> {
        let path = model_path.as_ref();
        if !path.exists() {
            return Err(OnnxError::ModelInit(format!(
                "ViT model file does not exist at {:?}",
                path
            )));
        }

        let env = ort::init()
            .with_name("who_dis_vit")
            .build()
            .map_err(|e| OnnxError::ModelInit(format!("Failed to initialize ONNX runtime: {e}")))?;

        let builder = Session::builder(&env)
            .map_err(|e| OnnxError::ModelInit(e.to_string()))?;

        #[cfg(feature = "coreml")]
        let mut builder = {
            let ep = ort::ep::CoreML::default().build();
            builder.with_execution_providers([ep])
                .map_err(|e| OnnxError::ModelInit(format!("Failed to register CoreML EP: {e}")))?
        };

        #[cfg(not(feature = "coreml"))]
        let mut builder = builder;

        let session = builder
            .commit_from_file(path)
            .map_err(|e| OnnxError::ModelInit(format!("Failed to load ViT model from {:?}: {e}", path)))?;

        Ok(Self {
            session: Mutex::new(session),
        })
    }

    /// Extracts a 1024-dimensional feature embedding from a DynamicImage.
    pub fn extract(&self, img: &DynamicImage) -> Result<Vec<f32>, OnnxError> {
        let input_tensor = preprocess_vit_image(img)?;
        let tensor = Tensor::from_array(input_tensor)
            .map_err(|e| OnnxError::Inference(format!("Failed to build input tensor: {e}")))?;

        let mut session = self.session.lock().map_err(|_| {
            OnnxError::Inference("Failed to acquire ViT session lock".into())
        })?;

        let outputs = session
            .run(ort::inputs![tensor])
            .map_err(|e| OnnxError::Inference(format!("ViT inference failed: {e}")))?;

        let output_value = outputs.iter().next().map(|(_, v)| v).ok_or_else(|| {
            OnnxError::Inference("No output tensor returned by ViT model".into())
        })?;

        let (_shape, data) = output_value
            .try_extract_tensor::<f32>()
            .map_err(|e| OnnxError::Inference(format!("Failed to extract output tensor: {e}")))?;

        if data.len() != VIT_EMBEDDING_DIM {
            return Err(OnnxError::TensorShapeMismatch {
                expected: format!("1x{}", VIT_EMBEDDING_DIM),
                actual: format!("{}", data.len()),
            });
        }

        Ok(data.to_vec())
    }

    /// Loads image bytes (JPEG, PNG, etc.) and extracts features.
    pub fn extract_from_bytes(&self, bytes: &[u8]) -> Result<Vec<f32>, OnnxError> {
        let img = image::load_from_memory(bytes)
            .map_err(|e| OnnxError::ImageProcessing(e.to_string()))?;
        self.extract(&img)
    }
}
