import { Download, ShoppingCart, X, ChevronLeft, ChevronRight } from "lucide-react";
import type { Photo } from "./PhotoCard";
import {Button} from "./Button";
import {ImageWithFallback} from "./ImageWithCallback";

interface PhotoViewerProps {
    photo: Photo | null;
    photos: Photo[];
    open: boolean;
    onClose: () => void;
    onPurchase: (photo: Photo) => void;
    onNavigate: (photo: Photo) => void;
}

export function PhotoViewer({ photo, photos, open, onClose, onPurchase, onNavigate }: PhotoViewerProps) {
    if (!open || !photo) return null;

    const currentIndex = photos.findIndex((p) => p.id === photo.id);
    const hasPrev = currentIndex > 0;
    const hasNext = currentIndex < photos.length - 1;

    return (
        <div
            className="fixed inset-0 z-50 flex items-center justify-center"
            style={{ background: "rgba(0,0,0,0.92)" }}
            onClick={onClose}
        >
            {/* Close */}
            <button
                className="absolute top-4 right-4 p-2 rounded transition-colors hover:bg-white/10"
                style={{ color: "var(--foreground)" }}
                onClick={onClose}
            >
                <X className="w-5 h-5" />
            </button>

            {/* Prev */}
            {hasPrev && (
                <button
                    className="absolute left-4 top-1/2 -translate-y-1/2 p-2 rounded transition-colors hover:bg-white/10"
                    style={{ color: "var(--foreground)" }}
                    onClick={(e) => {
                        e.stopPropagation();
                        onNavigate(photos[currentIndex - 1]);
                    }}
                >
                    <ChevronLeft className="w-6 h-6" />
                </button>
            )}

            {/* Next */}
            {hasNext && (
                <button
                    className="absolute right-4 top-1/2 -translate-y-1/2 p-2 rounded transition-colors hover:bg-white/10"
                    style={{ color: "var(--foreground)" }}
                    onClick={(e) => {
                        e.stopPropagation();
                        onNavigate(photos[currentIndex + 1]);
                    }}
                >
                    <ChevronRight className="w-6 h-6" />
                </button>
            )}

            {/* Main content */}
            <div
                className="flex flex-col items-center gap-4 max-w-4xl w-full px-16"
                onClick={(e) => e.stopPropagation()}
            >
                <div className="relative w-full max-h-[70vh] flex items-center justify-center">
                    <ImageWithFallback
                        src={photo.url}
                        alt={photo.title}
                        className="max-w-full max-h-[70vh] object-contain"
                        style={{
                            borderRadius: "var(--radius-sm)",
                            filter: photo.purchased ? "none" : "blur(12px) brightness(0.5)",
                        }}
                    />
                    {!photo.purchased && (
                        <div className="absolute inset-0 flex flex-col items-center justify-center gap-3">
                            <p
                                style={{
                                    fontFamily: "'Playfair Display', serif",
                                    color: "var(--foreground)",
                                    fontSize: "1.125rem",
                                    textAlign: "center",
                                }}
                            >
                                Purchase to view full resolution
                            </p>
                            <Button
                                style={{
                                    background: "var(--primary)",
                                    color: "var(--primary-foreground)",
                                    fontFamily: "'Inter', sans-serif",
                                    borderRadius: "var(--radius-sm)",
                                }}
                                onClick={() => onPurchase(photo)}
                            >
                                <ShoppingCart className="w-4 h-4 mr-2" />
                                Purchase for ${photo.price}
                            </Button>
                        </div>
                    )}
                </div>

                {/* Meta bar */}
                <div
                    className="w-full flex items-center justify-between px-4 py-3 rounded"
                    style={{ background: "var(--card)", border: "1px solid var(--border)" }}
                >
                    <div>
                        <p style={{ fontFamily: "'Inter', sans-serif", color: "var(--foreground)", fontSize: "0.9375rem" }}>
                            {photo.title}
                        </p>
                        <p className="text-xs mt-0.5" style={{ color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace" }}>
                            {photo.event} · {photo.date} · {currentIndex + 1} of {photos.length}
                        </p>
                    </div>
                    <div className="flex items-center gap-2">
                        {photo.purchased ? (
                            <Button
                                size="sm"
                                style={{
                                    background: "var(--primary)",
                                    color: "var(--primary-foreground)",
                                    fontFamily: "'Inter', sans-serif",
                                    borderRadius: "var(--radius-sm)",
                                }}
                            >
                                <Download className="w-4 h-4 mr-1.5" />
                                Download
                            </Button>
                        ) : (
                            <Button
                                size="sm"
                                style={{
                                    background: "var(--primary)",
                                    color: "var(--primary-foreground)",
                                    fontFamily: "'Inter', sans-serif",
                                    borderRadius: "var(--radius-sm)",
                                }}
                                onClick={() => onPurchase(photo)}
                            >
                                <ShoppingCart className="w-4 h-4 mr-1.5" />
                                ${photo.price}
                            </Button>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}
