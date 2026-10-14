use thiserror::Error;

#[derive(Error, Debug)]
pub enum OnnxError {
    #[error("Failed to load or initialize ONNX model: {0}")]
    ModelInit(String),

    #[error("Failed to decode or process image: {0}")]
    ImageProcessing(String),

    #[error("Inference execution failed: {0}")]
    Inference(String),

    #[error("Output tensor mismatch: expected {expected}, got {actual}")]
    TensorShapeMismatch {
        expected: String,
        actual: String,
    },

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
}
