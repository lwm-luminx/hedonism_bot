import { useState } from "react";
import { Download, ShoppingCart, ZoomIn } from "lucide-react";

import {Badge} from "./Badge";
import {ImageWithFallback} from "./ImageWithCallback";

export interface Photo {
    id: string;
    url: string;
    thumbnail: string;
    title: string;
    date: string;
    faceIds: string[];
    price: number;
    purchased: boolean;
    width: number;
    height: number;
    event: string;
}

interface PhotoCardProps {
    photo: Photo;
    onSelect: (photo: Photo) => void;
    onPurchase: (photo: Photo) => void;
}

export function PhotoCard({ photo, onSelect, onPurchase }: PhotoCardProps) {
    const [hovered, setHovered] = useState(false);

    return (
        <div
            className="group relative overflow-hidden cursor-pointer bg-card border border-border"
            style={{ borderRadius: "var(--radius)" }}
            onMouseEnter={() => setHovered(true)}
            onMouseLeave={() => setHovered(false)}
            onClick={() => onSelect(photo)}
        >
            <div className="relative aspect-[4/3] overflow-hidden">
                <ImageWithFallback
                    src={photo.thumbnail}
                    alt={photo.title}
                    className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                />
                {/* Gradient overlay */}
                <div
                    className="absolute inset-0 transition-opacity duration-300"
                    style={{
                        background: hovered
                            ? "linear-gradient(to top, rgba(0,0,0,0.85) 0%, rgba(0,0,0,0.2) 50%, transparent 100%)"
                            : "linear-gradient(to top, rgba(0,0,0,0.6) 0%, transparent 60%)",
                    }}
                />
                {/* Purchased badge */}
                {photo.purchased && (
                    <div className="absolute top-2 left-2">
                        <Badge
                            className="text-xs"
                            style={{
                                background: "var(--primary)",
                                color: "var(--primary-foreground)",
                                borderRadius: "var(--radius-sm)",
                            }}
                        >
                            <Download className="w-3 h-3 mr-1" />
                            Owned
                        </Badge>
                    </div>
                )}
                {/* Hover actions */}
                <div
                    className="absolute bottom-0 left-0 right-0 p-3 flex items-end justify-between transition-all duration-300"
                    style={{ opacity: hovered ? 1 : 0, transform: hovered ? "translateY(0)" : "translateY(8px)" }}
                >
                    <div>
                        <p
                            className="text-xs mb-0.5 truncate"
                            style={{ color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace" }}
                        >
                            {photo.event}
                        </p>
                        <p style={{ color: "var(--foreground)", fontFamily: "'Inter', sans-serif", fontSize: "0.8125rem" }}>
                            {photo.title}
                        </p>
                    </div>
                    <div className="flex gap-1.5 ml-2 shrink-0">
                        <button
                            className="p-1.5 rounded transition-colors"
                            style={{ background: "rgba(15,15,15,0.8)", color: "var(--foreground)" }}
                            onClick={(e) => {
                                e.stopPropagation();
                                onSelect(photo);
                            }}
                            title="View full size"
                        >
                            <ZoomIn className="w-3.5 h-3.5" />
                        </button>
                        {!photo.purchased && (
                            <button
                                className="p-1.5 rounded transition-colors"
                                style={{ background: "var(--primary)", color: "var(--primary-foreground)" }}
                                onClick={(e) => {
                                    e.stopPropagation();
                                    onPurchase(photo);
                                }}
                                title={`Purchase — $${photo.price}`}
                            >
                                <ShoppingCart className="w-3.5 h-3.5" />
                            </button>
                        )}
                    </div>
                </div>
            </div>
            {/* Bottom label */}
            <div className="px-3 py-2 flex items-center justify-between">
        <span
            className="text-xs"
            style={{ color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace" }}
        >
          {photo.date}
        </span>
                {photo.purchased ? (
                    <span className="text-xs" style={{ color: "var(--primary)", fontFamily: "'Inter', sans-serif" }}>
            Download available
          </span>
                ) : (
                    <span className="text-xs" style={{ color: "var(--muted-foreground)", fontFamily: "'Inter', sans-serif" }}>
            ${photo.price}
          </span>
                )}
            </div>
        </div>
    );
}
