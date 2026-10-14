use std::path::Path;
use std::sync::Mutex;
use image::DynamicImage;
use ort::{session::Session, value::Tensor};
use serde::{Deserialize, Serialize};

use crate::error::OnnxError;
use crate::image_utils::preprocess_face_crop;

pub const ARCFACE_EMBEDDING_DIM: usize = 512;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "camelCase")]
pub struct FacialArea {
    pub x: u32,
    pub y: u32,
    pub w: u32,
    pub h: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "camelCase")]
pub struct FaceObject {
    pub facial_area: FacialArea,
    pub face_confidence: f32,
    pub embedding: Vec<f32>,
}

/// Pipeline for face detection (RetinaFace) and facial embeddings (ArcFace).
pub struct FaceRecognizer {
    arcface_session: Mutex<Session>,
    detector_session: Option<Mutex<Session>>,
}

impl FaceRecognizer {
    /// Initializes ArcFace embedding model, and an optional face detector model.
    pub fn new(
        arcface_model_path: impl AsRef<Path>,
        detector_model_path: Option<impl AsRef<Path>>,
    ) -> Result<Self, OnnxError> {
        let arcface_path = arcface_model_path.as_ref();
        if !arcface_path.exists() {
            return Err(OnnxError::ModelInit(format!(
                "ArcFace model does not exist at {:?}",
                arcface_path
            )));
        }

        let env = ort::init()
            .with_name("who_dis_face")
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

        let arcface_session = builder
            .commit_from_file(arcface_path)
            .map_err(|e| OnnxError::ModelInit(format!("Failed to load ArcFace model: {e}")))?;

        let detector_session = if let Some(p) = detector_model_path {
            let p = p.as_ref();
            if p.exists() {
                let det_builder = Session::builder(&env)
                    .map_err(|e| OnnxError::ModelInit(e.to_string()))?;
                #[cfg(feature = "coreml")]
                let mut det_builder = {
                    let ep = ort::ep::CoreML::default().build();
                    det_builder.with_execution_providers([ep])
                        .map_err(|e| OnnxError::ModelInit(format!("Failed to register CoreML EP: {e}")))?
                };
                #[cfg(not(feature = "coreml"))]
                let mut det_builder = det_builder;
                Some(Mutex::new(det_builder.commit_from_file(p).map_err(|e| {
                    OnnxError::ModelInit(format!("Failed to load detector model from {:?}: {e}", p))
                })?))
            } else {
                None
            }
        } else {
            None
        };

        Ok(Self {
            arcface_session: Mutex::new(arcface_session),
            detector_session,
        })
    }

    /// Extracts a 512-dim ArcFace embedding from a cropped region of an image.
    pub fn embed_face(&self, img: &DynamicImage, rect: &FacialArea) -> Result<Vec<f32>, OnnxError> {
        // DeepFace uses expand_percentage=20
        let crop = preprocess_face_crop(img, rect.x, rect.y, rect.w, rect.h, 20.0)?;
        let tensor = Tensor::from_array(crop)
            .map_err(|e| OnnxError::Inference(format!("Failed to build face tensor: {e}")))?;

        let mut session = self.arcface_session.lock().map_err(|_| {
            OnnxError::Inference("Failed to acquire ArcFace session lock".into())
        })?;

        let outputs = session
            .run(ort::inputs![tensor])
            .map_err(|e| OnnxError::Inference(format!("ArcFace inference failed: {e}")))?;

        let output_value = outputs.iter().next().map(|(_, v)| v).ok_or_else(|| {
            OnnxError::Inference("No output tensor from ArcFace".into())
        })?;

        let (_shape, data) = output_value
            .try_extract_tensor::<f32>()
            .map_err(|e| OnnxError::Inference(format!("Failed to extract ArcFace output: {e}")))?;

        if data.len() != ARCFACE_EMBEDDING_DIM {
            return Err(OnnxError::TensorShapeMismatch {
                expected: format!("1x{}", ARCFACE_EMBEDDING_DIM),
                actual: format!("{}", data.len()),
            });
        }

        // Normalize embedding vector (L2 norm)
        let mut embedding = data.to_vec();
        let norm = embedding.iter().map(|v| v * v).sum::<f32>().sqrt();
        if norm > 0.0 {
            for v in embedding.iter_mut() {
                *v /= norm;
            }
        }

        Ok(embedding)
    }

    /// Runs face detection and extracts embeddings for all detected faces with confidence >= min_confidence.
    /// (Matches Python DeepFace filter: face_confidence > 0.9)
    pub fn process_image(
        &self,
        _img: &DynamicImage,
        _min_confidence: f32,
    ) -> Result<Vec<FaceObject>, OnnxError> {
        let _detector = self.detector_session.as_ref().ok_or_else(|| {
            OnnxError::ModelInit("Detector model session not configured".into())
        })?;

        // TODO: Detailed RetinaFace/SCRFD anchor decode / NMS pass
        let results = Vec::new();
        Ok(results)
    }
}
