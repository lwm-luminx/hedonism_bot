import {ChevronLeft, ChevronRight, Download, ShoppingCart, X} from "lucide-react";
import {Button} from "./Button";
import {ImageWithFallback} from "./ImageWithFallback";
import {graphql, useLazyLoadQuery} from "react-relay";
import {PhotoViewerQuery} from "./__generated__/PhotoViewerQuery.graphql";

const PHOTO_QUERY = graphql`
query PhotoViewerQuery($id: ID!) {
    node(id: $id) {
        ... on Photo {
            id @required(action: THROW)
            previewUrl
            alternateDescription
            isPurchased
            takenAt
        }
    }
}
`;

interface PhotoViewerProps {
    id: string | null;
    open: boolean;
    onClose: () => void;
    onPurchase: (photo: string) => void;
    onNavigate?: (photo: string) => void;
}

export function PhotoViewer({id, open, onClose, onPurchase, onNavigate}: PhotoViewerProps) {
    if (!open || !id) return null;

    const data = useLazyLoadQuery<PhotoViewerQuery>(PHOTO_QUERY, {id: id});
    if (!data.node) return null;

    const hasPrev = true;
    const hasNext = true;

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center" style={{background: "rgba(0,0,0,0.92)"}} onClick={onClose}>
            {/* Close */}
            <button className="absolute top-4 right-4 p-2 rounded transition-colors hover:bg-white/10" style={{color: "var(--foreground)"}} onClick={onClose}>
                <X className="w-5 h-5"/>
            </button>

            {/* Prev */}
            {hasPrev && (
                <button
                    className="absolute left-4 top-1/2 -translate-y-1/2 p-2 rounded transition-colors hover:bg-white/10"
                    style={{color: "var(--foreground)"}}
                    onClick={(e) => {
                        e.stopPropagation();

                    }}
                >
                    <ChevronLeft className="w-6 h-6"/>
                </button>
            )}

            {/* Next */}
            {hasNext && (
                <button
                    className="absolute right-4 top-1/2 -translate-y-1/2 p-2 rounded transition-colors hover:bg-white/10"
                    style={{color: "var(--foreground)"}}
                    onClick={(e) => {
                        e.stopPropagation();
                    }}
                >
                    <ChevronRight className="w-6 h-6"/>
                </button>
            )}

            {/* Main content */}
            <div
                className="flex flex-col items-center gap-4 max-w-4xl w-full px-16"
                onClick={(e) => e.stopPropagation()}
            >
                <div className="relative w-full max-h-[70vh] flex items-center justify-center">
                    <ImageWithFallback
                        src={data.node.previewUrl ?? "A gallery image"}
                        alt={data.node.alternateDescription}
                        className="max-w-full max-h-[70vh] object-contain"
                        style={{
                            borderRadius: "var(--radius-sm)",
                            filter: data.node.isPurchased ? "none" : "blur(3px) brightness(0.5)",
                        }}
                    />
                    {!data.node.isPurchased && (
                        <div className="absolute inset-0 flex flex-col items-center justify-center gap-3">
                            <p className="gallery-button-caption">
                                Purchase to view full resolution
                            </p>
                            <Button className="gallery-button" onClick={() => onPurchase?.(id)}>
                                <ShoppingCart className="w-4 h-4 mr-2"/>
                                Purchase for
                            </Button>
                        </div>
                    )}
                </div>

                {/* Meta bar */}
                <div
                    className="w-full flex items-center justify-between px-4 py-3 rounded"
                    style={{background: "var(--card)", border: "1px solid var(--border)"}}
                >
                    <div>
                        <p style={{
                            fontFamily: "'Inter', sans-serif",
                            color: "var(--foreground)",
                            fontSize: "0.9375rem"
                        }}>

                        </p>
                        <p className="text-xs mt-0.5"
                           style={{color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace"}}>

                        </p>
                    </div>
                    <div className="flex items-center gap-2">
                        {data.node.isPurchased ? (
                            <Button size="sm" className="gallery-button">
                                <Download className="w-4 h-4 mr-1.5"/>
                                Download
                            </Button>
                        ) : (
                            <Button size="sm" className="gallery-button">
                                <ShoppingCart className="w-4 h-4 mr-1.5"/>
                            </Button>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}
