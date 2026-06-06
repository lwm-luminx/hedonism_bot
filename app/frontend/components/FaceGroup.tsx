import { User } from "lucide-react";
import {ImageWithFallback} from "./ImageWithCallback";
import {cva} from "class-variance-authority";

export interface Face {
    id: string;
    label: string;
    thumbnailUrl: string;
    photoCount: number;
}

interface FaceGroupProps {
    faces: Face[];
    selectedFaceId: string | null;
    onSelect: (faceId: string | null) => void;
}

const faceGroupVariants = cva("w-8 h-8 rounded-full overflow-hidden shrink-0 ring-1", {
    variants: {
        selected: {
            true: "ring-current outline-2",
            false: "ring-transparent outline-transparent"
        }
    }
});

export function FaceGroup({ faces, selectedFaceId, onSelect }: FaceGroupProps) {
    return (
        <div className="flex flex-col gap-2">
            <p
                className="text-xs uppercase tracking-widest mb-1"
                style={{ color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace" }}
            >
                People
            </p>
            {/* All photos option */}
            <button
                className="flex items-center gap-2.5 px-2 py-1.5 rounded transition-colors text-left"
                style={{
                    background: selectedFaceId === null ? "rgba(201,169,110,0.12)" : "transparent",
                    color: selectedFaceId === null ? "var(--primary)" : "var(--foreground)",
                    borderRadius: "var(--radius-sm)",
                }}
                onClick={() => onSelect(null)}
            >
                <div
                    className="w-8 h-8 rounded-full flex items-center justify-center shrink-0"
                    style={{ background: "var(--muted)" }}
                >
                    <User className="w-4 h-4" style={{ color: "var(--muted-foreground)" }} />
                </div>
                <div className="min-w-0">
                    <p className="text-sm truncate" style={{ fontFamily: "'Inter', sans-serif" }}>
                        All Photos
                    </p>
                </div>
            </button>

            {faces.map((face) => (
                <button
                    key={face.id}
                    className="flex items-center gap-2.5 px-2 py-1.5 rounded transition-colors text-left"
                    style={{
                        background: selectedFaceId === face.id ? "rgba(201,169,110,0.12)" : "transparent",
                        color: selectedFaceId === face.id ? "var(--primary)" : "var(--foreground)",
                        borderRadius: "var(--radius-sm)",
                    }}
                    onClick={() => onSelect(face.id)}
                >
                    <div
                        className={faceGroupVariants({ selected: selectedFaceId === face.id })}
                    >
                        <ImageWithFallback
                            src={face.thumbnailUrl}
                            alt={face.label}
                            className="w-full h-full object-cover object-top"
                        />
                    </div>
                    <div className="min-w-0 flex-1">
                        <p className="text-sm truncate" style={{ fontFamily: "'Inter', sans-serif" }}>
                            {face.label}
                        </p>
                        <p
                            className="text-xs"
                            style={{ color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace" }}
                        >
                            {face.photoCount} photo{face.photoCount !== 1 ? "s" : ""}
                        </p>
                    </div>
                </button>
            ))}
        </div>
    );
}
