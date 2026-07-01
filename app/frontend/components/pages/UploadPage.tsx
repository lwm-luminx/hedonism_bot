import {
  CSSProperties,
  DragEvent,
  Suspense,
  useCallback,
  useRef,
  useState,
} from "react";
import { ArrowLeft, CloudUpload, ImagePlus, Loader2 } from "lucide-react";
import { Progress } from "../controls/Progress";
import { FileCard } from "../FileCard";
import { isSafari } from "react-device-detect";
import { Link, useNavigate, useParams } from "react-router";
import { graphql, useLazyLoadQuery, useMutation } from "react-relay";
import type { CreatePhotoPromiseMutation } from "./__generated__/CreatePhotoPromiseMutation.graphql";
import type { PhotoPromiseQuery } from "./__generated__/PhotoPromiseQuery.graphql";

const RAW_FORMAT_EXTENSIONS = [".arw"];

export interface UploadFile {
  id: string;
  previewUrl: string | null;
  status: "queued" | "uploading" | "done" | "error";
  progress: number;
  title: string;
  rawPhoto: File;
  processedPhotos: File[];
  errorMsg?: string;
}

type Files = FileList | File[];

function stripExtension(filename: string) {
  return filename.substring(0, filename.lastIndexOf(".")) || filename;
}

function getExtension(filename: string) {
  const extension = filename.substring(filename.lastIndexOf(".")) || filename;
  return extension.toLowerCase();
}

const PHOTO_PROMISE_FRAGMENT = graphql`
  fragment PhotoPromiseFragment on PhotoPromise {
    id
    files {
      nodes {
        id
      }
    }
  }
`;

const PHOTO_PROMISE_QUERY = graphql`
  query PhotoPromiseQuery($id: ID!) {
    node(id: $id) {
      ...PhotoPromiseFragment @alias(as: "photoPromise")
    }
  }
`;

export function UploadPage() {
  const { promiseId } = useParams();
  const navigate = useNavigate();

  const [files, setFiles] = useState<UploadFile[]>([]);
  const [dragging, setDragging] = useState(false);
  const [uploading, setUploading] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const dragCounter = useRef(0);

  if (!promiseId) {
    navigate("/upload");
    return null;
  }

  const data = useLazyLoadQuery<PhotoPromiseQuery>(PHOTO_PROMISE_QUERY, {
    id: promiseId,
  });

  const addFiles = useCallback(async (incoming: Files) => {
    const imageFiles = Array.from(incoming).filter((f) =>
      f.type.startsWith("image/"),
    );

    const rawPhotos = imageFiles.filter((file) =>
      RAW_FORMAT_EXTENSIONS.includes(getExtension(file.name)),
    );
    const processedPhotos = new Set(imageFiles).difference(new Set(rawPhotos));

    const uploads: Record<string, UploadFile> = {};

    for (const rawPhoto of rawPhotos) {
      const basename = stripExtension(rawPhoto.name);

      uploads[basename] = {
        id: `${rawPhoto.name}-${rawPhoto.size}-${Date.now()}-${Math.random()}`,
        rawPhoto: rawPhoto,
        previewUrl: null,
        status: "queued",
        title: basename,
        processedPhotos: [],
        progress: 0,
      };
    }

    for (const processedPhoto of processedPhotos) {
      const basename = stripExtension(processedPhoto.name);
      if (basename in uploads) {
        uploads[basename].processedPhotos.push(processedPhoto);
        if (isSafari) {
          uploads[basename].previewUrl = URL.createObjectURL(processedPhoto);
        }
      } else {
        console.error(
          `Processed photo ${processedPhoto.name} does not have a corresponding raw photo (${processedPhoto.type})`,
        );
      }
    }

    setFiles((prev) => {
      const existing = Object.fromEntries(prev.map((f) => [f.title, f]));
      const newValues = {
        ...existing,
        ...uploads,
      };
      return Object.values(newValues);
    });
  }, []);

  const handleDragEnter = (e: DragEvent) => {
    e.preventDefault();
    dragCounter.current++;
    if (e.dataTransfer.items && e.dataTransfer.items.length > 0)
      setDragging(true);
  };
  const handleDragLeave = (e: DragEvent) => {
    e.preventDefault();
    dragCounter.current--;
    if (dragCounter.current === 0) setDragging(false);
  };
  const handleDragOver = (e: DragEvent) => e.preventDefault();

  const handleDrop = (e: DragEvent) => {
    e.preventDefault();
    dragCounter.current = 0;
    setDragging(false);
    if (e.dataTransfer.files.length > 0) addFiles(e.dataTransfer.files);
  };

  const removeFile = (id: string) => {
    setFiles((prev) => {
      const f = prev.find((f) => f.id === id);
      if (f?.previewUrl) {
        URL.revokeObjectURL(f.previewUrl);
      }
      return prev.filter((f) => f.id !== id);
    });
  };

  const clearAll = () => {
    files.forEach((f) => f.previewUrl && URL.revokeObjectURL(f.previewUrl));
    setFiles([]);
  };

  const performUpload = (id: string): Promise<void> => {
    return new Promise((resolve, reject) => {
      const file = files.find((f) => f.id === id);
      if (!file) return reject(new Error("File not found"));

      const formData = new FormData();
      formData.append("raw_image", file.rawPhoto);
      for (const [_index, processedPhoto] of file.processedPhotos.entries()) {
        formData.append("processed_image[]", processedPhoto);
      }

      const xhr = new XMLHttpRequest();

      xhr.open("POST", "/upload", true);

      xhr.upload.addEventListener("progress", function (event) {
        if (event.lengthComputable) {
          // Calculate percentage complete
          const percentage = Math.round((event.loaded / event.total) * 100);

          // Update DOM values
          setFiles((prevFiles) =>
            prevFiles.map((f) =>
              f.id === id
                ? { ...f, uploadProgress: percentage, status: "uploading" }
                : f,
            ),
          );
        }
      });

      xhr.onload = function () {
        if (xhr.status === 200) {
          setFiles((prevFiles) =>
            prevFiles.map((f) => (f.id === id ? { ...f, status: "done" } : f)),
          );
        } else {
          setFiles((prevFiles) =>
            prevFiles.map((f) => (f.id === id ? { ...f, status: "error" } : f)),
          );
        }
        resolve();
      };

      xhr.onerror = function () {
        setFiles((prevFiles) =>
          prevFiles.map((f) => (f.id === id ? { ...f, status: "error" } : f)),
        );
        resolve();
      };

      // 8. Execute request
      xhr.send(formData);
    });
  };

  const startUpload = async () => {
    const queued = files.filter((f) => f.status === "queued");
    if (queued.length === 0) return;
    setUploading(true);
    // Mark all queued as uploading
    setFiles((prev) =>
      prev.map((f) =>
        f.status === "queued" ? { ...f, status: "uploading" } : f,
      ),
    );
    // Upload with concurrency of 3
    const concurrency = 3;
    let i = 0;
    const ids = queued.map((f) => f.id);
    const worker = async () => {
      while (i < ids.length) {
        const id = ids[i++];
        await performUpload(id).catch(() => {});
      }
    };
    await Promise.all(
      Array.from({ length: Math.min(concurrency, ids.length) }, worker),
    );
    setUploading(false);
  };

  const retryFailed = () => {
    setFiles((prev) =>
      prev.map((f) =>
        f.status === "error"
          ? {
              ...f,
              status: "queued",
              progress: 0,
              errorMsg: undefined,
            }
          : f,
      ),
    );
  };

  const queuedCount = files.filter((f) => f.status === "queued").length;
  const uploadingCount = files.filter((f) => f.status === "uploading").length;
  const doneCount = files.filter((f) => f.status === "done").length;
  const errorCount = files.filter((f) => f.status === "error").length;
  const totalProgress = Math.round(
    files.length === 0 ? 0 : ((doneCount + 0.0) / (files.length + 0.0)) * 100,
  );

  const isEmpty = files.length === 0;

  return (
    <div
      className="flex min-h-screen flex-col"
      style={{
        background: "var(--background)",
        fontFamily: "'Inter', sans-serif",
      }}
    >
      {/* Header */}
      <header className="upload-header">
        <Link
          to="/"
          className="back-link flex items-center gap-1.5 transition-opacity hover:opacity-70"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to gallery
        </Link>
        <div className="h-4 w-px" style={{ background: "var(--border)" }} />
        <span className="upload-title">Upload Photos</span>
        {files.length > 0 && (
          <span className="upload-subheader">
            {files.length} file{files.length !== 1 ? "s" : ""}
          </span>
        )}
      </header>

      <div className="mx-auto flex w-full max-w-6xl flex-1 flex-col gap-5 px-6 py-6">
        {/* Drop zone */}
        <div
          onDragEnter={handleDragEnter}
          onDragLeave={handleDragLeave}
          onDragOver={handleDragOver}
          onDrop={handleDrop}
          onClick={() => !uploading && inputRef.current?.click()}
          className="relative flex cursor-pointer flex-col items-center justify-center gap-3 border-2 border-dashed py-10 transition-all select-none"
          style={{
            borderColor: dragging ? "var(--primary)" : "rgba(201,169,110,0.25)",
            background: dragging ? "rgba(201,169,110,0.06)" : "var(--card)",
            borderRadius: "var(--radius)",
            minHeight: isEmpty ? 240 : 120,
            cursor: uploading ? "not-allowed" : "pointer",
            opacity: uploading ? 0.6 : 1,
          }}
        >
          <input
            ref={inputRef}
            type="file"
            accept="image/*"
            multiple
            className="hidden"
            onChange={(e) => e.target.files && addFiles(e.target.files)}
            disabled={uploading}
          />
          <div
            className="flex h-12 w-12 items-center justify-center rounded-full transition-colors"
            style={{
              background: dragging ? "rgba(201,169,110,0.15)" : "var(--muted)",
            }}
          >
            <CloudUpload
              className="h-6 w-6 transition-colors"
              style={{
                color: dragging ? "var(--primary)" : "var(--muted-foreground)",
              }}
            />
          </div>
          <div className="text-center">
            <p
              style={{
                fontFamily: "'Playfair Display', serif",
                color: dragging ? "var(--primary)" : "var(--foreground)",
                fontSize: "1rem",
              }}
            >
              {dragging
                ? "Drop to add photos"
                : isEmpty
                  ? "Drag photos here"
                  : "Drag more photos here"}
            </p>
            <p
              className="mt-1 text-xs"
              style={{
                color: "var(--muted-foreground)",
                fontFamily: "'DM Mono', monospace",
              }}
            >
              {isEmpty
                ? "or click to browse · JPEG, PNG, WebP, HEIC"
                : "or click to browse"}
            </p>
          </div>
        </div>

        {/* File grid */}
        {files.length > 0 && (
          <>
            {/* Toolbar */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <span
                  className="text-xs"
                  style={{
                    color: "var(--muted-foreground)",
                    fontFamily: "'DM Mono', monospace",
                  }}
                >
                  {doneCount}/{files.length} uploaded
                  {errorCount > 0 && (
                    <span style={{ color: "var(--destructive)" }}>
                      {" "}
                      · {errorCount} failed
                    </span>
                  )}
                </span>
                {errorCount > 0 && !uploading && (
                  <button
                    className="text-xs underline underline-offset-2 transition-opacity hover:opacity-70"
                    style={{
                      color: "var(--primary)",
                      fontFamily: "'Inter', sans-serif",
                    }}
                    onClick={retryFailed}
                  >
                    Retry failed
                  </button>
                )}
              </div>
              <div className="flex items-center gap-2">
                {!uploading && queuedCount > 0 && (
                  <button
                    className="text-xs transition-opacity hover:opacity-70"
                    style={{
                      color: "var(--muted-foreground)",
                      fontFamily: "'Inter', sans-serif",
                    }}
                    onClick={clearAll}
                  >
                    Clear all
                  </button>
                )}
                <button
                  disabled={uploading || queuedCount === 0}
                  onClick={startUpload}
                  className="flex items-center gap-2 px-4 py-1.5 text-sm transition-opacity"
                  style={{
                    background:
                      uploading || queuedCount === 0
                        ? "var(--muted)"
                        : "var(--primary)",
                    color:
                      uploading || queuedCount === 0
                        ? "var(--muted-foreground)"
                        : "var(--primary-foreground)",
                    borderRadius: "var(--radius-sm)",
                    fontFamily: "'Inter', sans-serif",
                    cursor:
                      uploading || queuedCount === 0
                        ? "not-allowed"
                        : "pointer",
                    opacity: uploading ? 0.7 : 1,
                  }}
                >
                  {uploading ? (
                    <>
                      <Loader2 className="h-3.5 w-3.5 animate-spin" />
                      Uploading…
                    </>
                  ) : (
                    <>
                      <CloudUpload className="h-3.5 w-3.5" />
                      Upload{" "}
                      {queuedCount > 0
                        ? `${queuedCount} photo${queuedCount !== 1 ? "s" : ""}`
                        : ""}
                    </>
                  )}
                </button>
              </div>
            </div>

            {/* Overall progress bar — only visible while uploading */}
            {uploading && (
              <div className="flex flex-col gap-1.5">
                <Progress
                  value={totalProgress}
                  className="h-1"
                  style={
                    {
                      background: "var(--muted)",
                      "--tw-bg-opacity": 1,
                    } as CSSProperties
                  }
                />
                <p
                  className="text-xs"
                  style={{
                    color: "var(--muted-foreground)",
                    fontFamily: "'DM Mono', monospace",
                  }}
                >
                  {totalProgress}% — {uploadingCount} uploading, {doneCount}{" "}
                  done
                </p>
              </div>
            )}

            {/* Grid */}
            <div
              className="grid gap-3"
              style={{
                gridTemplateColumns: "repeat(auto-fill, minmax(160px, 1fr))",
              }}
            >
              {files.map((f) => (
                <FileCard
                  key={f.id}
                  file={f}
                  onRemove={removeFile}
                  uploading={uploading}
                />
              ))}

              {/* Add more tile */}
              {!uploading && (
                <button
                  onClick={() => inputRef.current?.click()}
                  className="flex flex-col items-center justify-center gap-2 border border-dashed transition-colors"
                  style={{
                    borderColor: "rgba(201,169,110,0.2)",
                    borderRadius: "var(--radius-sm)",
                    background: "transparent",
                    minHeight: 160,
                    color: "var(--muted-foreground)",
                    cursor: "pointer",
                  }}
                  onMouseEnter={(e) => {
                    (e.currentTarget as HTMLButtonElement).style.borderColor =
                      "var(--primary)";
                    (e.currentTarget as HTMLButtonElement).style.color =
                      "var(--primary)";
                  }}
                  onMouseLeave={(e) => {
                    (e.currentTarget as HTMLButtonElement).style.borderColor =
                      "rgba(201,169,110,0.2)";
                    (e.currentTarget as HTMLButtonElement).style.color =
                      "var(--muted-foreground)";
                  }}
                >
                  <ImagePlus className="h-5 w-5" />
                  <span
                    className="text-xs"
                    style={{
                      fontFamily: "'DM Mono', monospace",
                    }}
                  >
                    Add more
                  </span>
                </button>
              )}
            </div>
          </>
        )}
      </div>
    </div>
  );
}
