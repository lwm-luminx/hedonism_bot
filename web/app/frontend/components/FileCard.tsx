import { type UploadFile } from "./pages/UploadPage";
import { CheckCircle2, Loader2, X, XCircle } from "lucide-react";
import { useState } from "react";
import { heicTo } from "heic-to";

function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

interface FileCardProps {
  file: UploadFile;
  onRemove: (id: string) => void;
  uploading: boolean;
}

export function FileCard({ file, onRemove, uploading }: FileCardProps) {
  const [previewUrl, setPreviewUrl] = useState<string | null>(file.previewUrl);
  const [isConverting, setIsConverting] = useState(false);
  const canRemove = !uploading || file.status !== "uploading";
  const mainFile = file.rawPhoto ?? file.processedPhotos[0];

  if (!previewUrl && !isConverting) {
    const processedPhoto = file.processedPhotos.length
      ? file.processedPhotos[0]
      : null;
    if (processedPhoto) {
      if (processedPhoto.name.toLowerCase().endsWith(".hif")) {
        setIsConverting(true);
        // Convert to JPEG
        heicTo({
          blob: processedPhoto,
          type: "image/jpeg",
        }).then((conversionResult) => {
          setPreviewUrl(URL.createObjectURL(conversionResult));
        });
      }
    }
  }

  return (
    <div
      className="relative group overflow-hidden flex flex-col"
      style={{
        borderRadius: "var(--radius-sm)",
        border: "1px solid var(--border)",
        background: "var(--card)",
      }}
    >
      {/* Thumbnail */}
      <div className="relative aspect-4/3 overflow-hidden bg-muted">
        {previewUrl ? (
          <img
            src={previewUrl}
            alt={mainFile.name}
            className="w-full h-full object-cover"
            style={{
              filter:
                file.status === "done"
                  ? "none"
                  : file.status === "error"
                    ? "brightness(0.5) saturate(0)"
                    : "none",
              transition: "filter 0.3s",
            }}
          />
        ) : null}

        {/* Status overlay */}
        {file.status === "done" && (
          <div
            className="absolute inset-0 flex items-center justify-center"
            style={{ background: "rgba(0,0,0,0.35)" }}
          >
            <CheckCircle2
              className="w-8 h-8"
              style={{ color: "var(--primary)" }}
            />
          </div>
        )}
        {file.status === "error" && (
          <div
            className="absolute inset-0 flex flex-col items-center justify-center gap-1"
            style={{ background: "rgba(0,0,0,0.6)" }}
          >
            <XCircle
              className="w-7 h-7"
              style={{ color: "var(--destructive)" }}
            />
            <p
              className="text-xs"
              style={{
                color: "#fff",
                fontFamily: "'DM Mono', monospace",
              }}
            >
              Failed
            </p>
            {file.errorMsg && (
              <p
                className="px-2 text-center text-xs"
                style={{ color: "#fff", fontFamily: "'Inter', sans-serif" }}
              >
                {file.errorMsg}
              </p>
            )}
          </div>
        )}
        {file.status === "uploading" && (
          <div
            className="absolute inset-0 flex items-center justify-center"
            style={{ background: "rgba(0,0,0,0.4)" }}
          >
            <Loader2
              className="w-7 h-7 animate-spin"
              style={{ color: "var(--primary)" }}
            />
          </div>
        )}

        {/* Remove button */}
        {canRemove && (
          <button
            onClick={(e) => {
              e.stopPropagation();
              onRemove(file.id);
            }}
            className="absolute top-1.5 right-1.5 p-1 rounded transition-opacity opacity-0 group-hover:opacity-100"
            style={{
              background: "rgba(15,15,15,0.75)",
              color: "#fff",
              borderRadius: "var(--radius-sm)",
            }}
            title="Remove"
          >
            <X className="w-3 h-3" />
          </button>
        )}
      </div>

      {/* Progress bar */}
      {(file.status === "uploading" || file.status === "done") && (
        <div
          className="absolute bottom-0 left-0 right-0 h-0.5 transition-all duration-200"
          style={{
            background: "var(--muted)",
          }}
        >
          <div
            className="h-full transition-all duration-200"
            style={{
              width: `${file.progress}%`,
              background:
                file.status === "done" ? "var(--primary)" : "var(--primary)",
            }}
          />
        </div>
      )}

      {/* Filename + size */}
      <div className="px-2 py-1.5 flex flex-col gap-0.5">
        <p
          className="text-xs truncate"
          style={{
            color: "var(--foreground)",
            fontFamily: "'Inter', sans-serif",
          }}
          title={file.title}
        >
          {mainFile.name}
        </p>
        <p
          className="text-xs"
          style={{
            color: "var(--muted-foreground)",
            fontFamily: "'DM Mono', monospace",
          }}
        >
          {formatBytes(mainFile.size)}
          {file.status === "uploading" && (
            <span style={{ color: "var(--primary)" }}>
              {" "}
              · {Math.round(file.progress)}%
            </span>
          )}
          {file.status === "done" && (
            <span style={{ color: "var(--primary)" }}> · Done</span>
          )}
          {file.status === "error" && (
            <span style={{ color: "var(--destructive)" }}> · Error</span>
          )}
        </p>
      </div>
    </div>
  );
}
