import {useState} from "react";
import {Download, ShoppingCart, ZoomIn} from "lucide-react";

import {Badge} from "./Badge";
import {ImageWithFallback} from "./ImageWithFallback";
import {graphql, useFragment} from "react-relay";
import {PhotoFragment$key} from "./__generated__/PhotoFragment.graphql";

const PHOTO_CARD_FRAGMENT = graphql`
        fragment PhotoFragment on Photo {
            id
            eventName
            isPurchased
            previewUrl
            takenAt
            caption
        }
    `;

interface PhotoCardProps {
    photo: PhotoFragment$key;
    onSelect?: (photo: string) => void;
    onPurchase?: (photo: string) => void;
}

export function PhotoCard({photo, onSelect, onPurchase}: PhotoCardProps) {
    const data = useFragment(PHOTO_CARD_FRAGMENT, photo);
    const [hovered, setHovered] = useState(false);

    return (
        <div
            className="group relative overflow-hidden cursor-pointer bg-card border border-border"
            style={{borderRadius: "var(--radius)"}}
            onMouseEnter={() => setHovered(true)}
            onMouseLeave={() => setHovered(false)}
            onClick={() => onSelect?.(data.id)}
        >
            <div className="relative aspect-4/3 overflow-hidden">
                <ImageWithFallback
                    src={data?.previewUrl ?? "/assets/images/placeholder.png"}
                    alt={data?.caption ?? "A gallery image"}
                    className="w-full object-cover transition-transform duration-500 group-hover:scale-105"
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
                {data?.isPurchased && (
                    <div className="absolute top-2 left-2">
                        <Badge className="text-xs"
                               style={{
                                   background: "var(--primary)",
                                   color: "var(--primary-foreground)",
                                   borderRadius: "var(--radius-sm)",
                               }}
                        >
                            <Download className="w-3 h-3 mr-1"/>
                            Owned
                        </Badge>
                    </div>
                )}
                {/* Hover actions */}
                <div
                    className="absolute bottom-0 left-0 right-0 p-3 flex items-end justify-between transition-all duration-300"
                    style={{opacity: hovered ? 1 : 0, transform: hovered ? "translateY(0)" : "translateY(8px)"}}
                >
                    <div>

                        <p style={{
                            color: "var(--foreground)",
                            fontFamily: "'Inter', sans-serif",
                            fontSize: "0.8125rem"
                        }}>
                            Event Name
                        </p>
                        <p
                            className="text-xs mb-0.5 truncate"
                            style={{color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace"}}
                        >
                            {data?.caption}
                        </p>
                    </div>
                    <div className="flex gap-1.5 ml-2 shrink-0">
                        <button
                            className="p-1.5 rounded transition-colors"
                            style={{background: "rgba(15,15,15,0.8)", color: "var(--foreground)"}}
                            onClick={(e) => {
                                onSelect?.(data.id)
                                e.stopPropagation();
                            }}
                            title="View full size"
                        >
                            <ZoomIn className="w-3.5 h-3.5"/>
                        </button>
                        {!data?.isPurchased && (
                            <button
                                className="p-1.5 rounded transition-colors"
                                style={{background: "var(--primary)", color: "var(--primary-foreground)"}}
                                onClick={(e) => {
                                    onPurchase?.(data.id)
                                    e.stopPropagation();
                                }}
                                title={`Purchase — $1`}
                            >
                                <ShoppingCart className="w-3.5 h-3.5"/>
                            </button>
                        )}
                    </div>
                </div>
            </div>
            {/* Bottom label */}
            <div className="px-3 py-2 flex items-center justify-between">
                <span className="text-xs"
                      style={{color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace"}}>
                  {data?.takenAt}
                </span>
                {data?.isPurchased ? (
                    <span className="text-xs" style={{color: "var(--primary)", fontFamily: "'Inter', sans-serif"}}>Download available</span>
                ) : (
                    <span className="text-xs"
                          style={{color: "var(--muted-foreground)", fontFamily: "'Inter', sans-serif"}}>$1</span>
                )}
            </div>
        </div>
    );
}
