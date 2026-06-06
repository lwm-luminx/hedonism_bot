import { useState, useMemo } from "react";
import { Calendar, Camera, Filter, Grid3X3, LayoutList, Search, ShoppingBag, X } from "lucide-react";
import { Badge } from "./Badge";
import { Input } from "./Input";
import { ScrollArea } from "./ScrollArea";
import { PhotoCard, type Photo } from "./PhotoCard";
import { FaceGroup, type Face } from "./FaceGroup";
import { PurchaseModal } from "./PurchaseModal";
import { PhotoViewer } from "./PhotoViewer";
import {Separator} from "./Separator";

{/* MARKER-MAKE-KIT-INVOKED */}

const EVENTS = [
    { id: "evt1", name: "Annual Gala 2024", date: "2024-11-15" },
    { id: "evt2", name: "Tech Summit Spring", date: "2024-05-22" },
    { id: "evt3", name: "Leadership Retreat", date: "2024-08-08" },
];

const FACES: Face[] = [
    {
        id: "f1",
        label: "Sarah Chen",
        thumbnailUrl: "https://images.unsplash.com/photo-1514960919797-5ff58c52e5ba?w=80&h=80&fit=crop&auto=format",
        photoCount: 12,
    },
    {
        id: "f2",
        label: "Marcus Webb",
        thumbnailUrl: "https://images.unsplash.com/photo-1542190891-2093d38760f2?w=80&h=80&fit=crop&auto=format",
        photoCount: 9,
    },
    {
        id: "f3",
        label: "Priya Nair",
        thumbnailUrl: "https://images.unsplash.com/photo-1636990165439-ad91410514e9?w=80&h=80&fit=crop&auto=format",
        photoCount: 7,
    },
    {
        id: "f4",
        label: "Thomas Reid",
        thumbnailUrl: "https://images.unsplash.com/photo-1722078504991-5a4d24db4ab4?w=80&h=80&fit=crop&auto=format",
        photoCount: 5,
    },
];

const PHOTOS: Photo[] = [
    {
        id: "p1",
        url: "https://images.unsplash.com/photo-1531058020387-3be344556be6?w=1200&h=900&fit=crop&auto=format",
        thumbnail: "https://images.unsplash.com/photo-1531058020387-3be344556be6?w=600&h=450&fit=crop&auto=format",
        title: "Opening Ceremony",
        date: "Nov 15, 2024",
        event: "Annual Gala 2024",
        faceIds: ["f1", "f2"],
        price: 24.99,
        purchased: false,
        width: 1200,
        height: 900,
    },
    {
        id: "p2",
        url: "https://images.unsplash.com/photo-1606744038221-5e0fa1c68fe6?w=1200&h=900&fit=crop&auto=format",
        thumbnail: "https://images.unsplash.com/photo-1606744038221-5e0fa1c68fe6?w=600&h=450&fit=crop&auto=format",
        title: "Keynote Address",
        date: "Nov 15, 2024",
        event: "Annual Gala 2024",
        faceIds: ["f2"],
        price: 19.99,
        purchased: false,
        width: 1200,
        height: 900,
    },
    {
        id: "p3",
        url: "https://images.unsplash.com/photo-1653821355736-0c2598d0a63e?w=1200&h=900&fit=crop&auto=format",
        thumbnail: "https://images.unsplash.com/photo-1653821355736-0c2598d0a63e?w=600&h=450&fit=crop&auto=format",
        title: "Awards Dinner",
        date: "Nov 15, 2024",
        event: "Annual Gala 2024",
        faceIds: ["f1", "f3", "f4"],
        price: 29.99,
        purchased: true,
        width: 1200,
        height: 900,
    },
    {
        id: "p4",
        url: "https://images.unsplash.com/photo-1651313948618-31644c7fec18?w=1200&h=900&fit=crop&auto=format",
        thumbnail: "https://images.unsplash.com/photo-1651313948618-31644c7fec18?w=600&h=450&fit=crop&auto=format",
        title: "Roundtable Discussion",
        date: "Nov 15, 2024",
        event: "Annual Gala 2024",
        faceIds: ["f1", "f2", "f3"],
        price: 24.99,
        purchased: false,
        width: 1200,
        height: 900,
    },
    {
        id: "p5",
        url: "https://images.unsplash.com/photo-1561489404-42f13a2f09a2?w=1200&h=900&fit=crop&auto=format",
        thumbnail: "https://images.unsplash.com/photo-1561489404-42f13a2f09a2?w=600&h=450&fit=crop&auto=format",
        title: "Welcome Remarks",
        date: "May 22, 2024",
        event: "Tech Summit Spring",
        faceIds: ["f3"],
        price: 19.99,
        purchased: false,
        width: 1200,
        height: 900,
    },
    {
        id: "p6",
        url: "https://images.unsplash.com/photo-1730134322176-862f1cf9bc9f?w=1200&h=900&fit=crop&auto=format",
        thumbnail: "https://images.unsplash.com/photo-1730134322176-862f1cf9bc9f?w=600&h=450&fit=crop&auto=format",
        title: "Breakout Sessions",
        date: "May 22, 2024",
        event: "Tech Summit Spring",
        faceIds: ["f2", "f4"],
        price: 24.99,
        purchased: false,
        width: 1200,
        height: 900,
    },
    {
        id: "p7",
        url: "https://images.unsplash.com/photo-1772690445981-78b22eacda4b?w=1200&h=900&fit=crop&auto=format",
        thumbnail: "https://images.unsplash.com/photo-1772690445981-78b22eacda4b?w=600&h=450&fit=crop&auto=format",
        title: "Panel Discussion",
        date: "May 22, 2024",
        event: "Tech Summit Spring",
        faceIds: ["f1", "f4"],
        price: 34.99,
        purchased: false,
        width: 1200,
        height: 900,
    },
    {
        id: "p8",
        url: "https://images.unsplash.com/photo-1722078504991-5a4d24db4ab4?w=1200&h=900&fit=crop&auto=format",
        thumbnail: "https://images.unsplash.com/photo-1722078504991-5a4d24db4ab4?w=600&h=450&fit=crop&auto=format",
        title: "Retreat Portraits",
        date: "Aug 8, 2024",
        event: "Leadership Retreat",
        faceIds: ["f4"],
        price: 19.99,
        purchased: false,
        width: 1200,
        height: 900,
    },
    {
        id: "p9",
        url: "https://images.unsplash.com/photo-1514960919797-5ff58c52e5ba?w=1200&h=900&fit=crop&auto=format",
        thumbnail: "https://images.unsplash.com/photo-1514960919797-5ff58c52e5ba?w=600&h=450&fit=crop&auto=format",
        title: "Team Candid",
        date: "Aug 8, 2024",
        event: "Leadership Retreat",
        faceIds: ["f1"],
        price: 14.99,
        purchased: true,
        width: 1200,
        height: 900,
    },
    {
        id: "p10",
        url: "https://images.unsplash.com/photo-1700514077430-3659e38eb5e7?w=1200&h=900&fit=crop&auto=format",
        thumbnail: "https://images.unsplash.com/photo-1700514077430-3659e38eb5e7?w=600&h=450&fit=crop&auto=format",
        title: "Venue Overview",
        date: "Aug 8, 2024",
        event: "Leadership Retreat",
        faceIds: [],
        price: 14.99,
        purchased: false,
        width: 1200,
        height: 900,
    },
    {
        id: "p11",
        url: "https://images.unsplash.com/photo-1542190891-2093d38760f2?w=1200&h=900&fit=crop&auto=format",
        thumbnail: "https://images.unsplash.com/photo-1542190891-2093d38760f2?w=600&h=450&fit=crop&auto=format",
        title: "Executive Portrait",
        date: "Nov 15, 2024",
        event: "Annual Gala 2024",
        faceIds: ["f2"],
        price: 39.99,
        purchased: false,
        width: 1200,
        height: 900,
    },
    {
        id: "p12",
        url: "https://images.unsplash.com/photo-1636990165439-ad91410514e9?w=1200&h=900&fit=crop&auto=format",
        thumbnail: "https://images.unsplash.com/photo-1636990165439-ad91410514e9?w=600&h=450&fit=crop&auto=format",
        title: "Networking Hour",
        date: "May 22, 2024",
        event: "Tech Summit Spring",
        faceIds: ["f3", "f1"],
        price: 24.99,
        purchased: false,
        width: 1200,
        height: 900,
    },
];

export default function App() {
    const [photos, setPhotos] = useState<Photo[]>(PHOTOS);
    const [selectedEventId, setSelectedEventId] = useState<string | null>(null);
    const [selectedFaceId, setSelectedFaceId] = useState<string | null>(null);
    const [searchQuery, setSearchQuery] = useState("");
    const [viewerPhoto, setViewerPhoto] = useState<Photo | null>(null);
    const [purchasePhoto, setPurchasePhoto] = useState<Photo | null>(null);
    const [sidebarOpen, setSidebarOpen] = useState(true);
    const [gridCols, setGridCols] = useState<3 | 4>(3);

    const filteredPhotos = useMemo(() => {
        return photos.filter((p) => {
            const matchEvent = selectedEventId ? EVENTS.find((e) => e.id === selectedEventId)?.name === p.event : true;
            const matchFace = selectedFaceId ? p.faceIds.includes(selectedFaceId) : true;
            const matchSearch = searchQuery
                ? p.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
                p.event.toLowerCase().includes(searchQuery.toLowerCase())
                : true;
            return matchEvent && matchFace && matchSearch;
        });
    }, [photos, selectedEventId, selectedFaceId, searchQuery]);

    const handlePurchaseComplete = (photoId: string) => {
        setPhotos((prev) => prev.map((p) => (p.id === photoId ? { ...p, purchased: true } : p)));
    };

    const purchasedCount = photos.filter((p) => p.purchased).length;

    return (
        <div
            className="min-h-screen flex flex-col"
            style={{ background: "var(--background)", fontFamily: "'Inter', sans-serif" }}
        >
            {/* Top nav */}
            <header
                className="flex items-center justify-between px-6 py-3.5 border-b shrink-0"
                style={{ borderColor: "var(--border)", background: "var(--card)" }}
            >
                <div className="flex items-center gap-3">
                    <Camera className="w-4.5 h-4.5" style={{ color: "var(--primary)" }} />
                    <span
                        style={{
                            fontFamily: "'Inner', serif",
                            color: "var(--foreground)",
                            fontSize: "1.125rem",
                            letterSpacing: "0.01em",
                        }}
                    >
            Lumière Archive
          </span>
                    <Separator orientation="vertical" className="h-4 mx-1" style={{ background: "var(--border)" }} />
                    <span
                        className="text-xs"
                        style={{ color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace" }}
                    >
          </span>
                </div>
                <div className="flex items-center gap-3">
                    <div className="relative">
                        <Search
                            className="w-3.5 h-3.5 absolute left-2.5 top-1/2 -translate-y-1/2 pointer-events-none"
                            style={{ color: "var(--muted-foreground)" }}
                        />
                        <Input
                            placeholder="Search photos…"
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            className="pl-8 h-8 w-52 text-sm"
                            style={{
                                background: "var(--input-background)",
                                border: "1px solid var(--border)",
                                color: "var(--foreground)",
                                borderRadius: "var(--radius-sm)",
                                fontFamily: "'Inter', sans-serif",
                            }}
                        />
                        {searchQuery && (
                            <button
                                className="absolute right-2.5 top-1/2 -translate-y-1/2"
                                onClick={() => setSearchQuery("")}
                                style={{ color: "var(--muted-foreground)" }}
                            >
                                <X className="w-3.5 h-3.5" />
                            </button>
                        )}
                    </div>
                    <div
                        className="flex items-center gap-1.5 px-3 py-1.5 rounded"
                        style={{
                            background: "rgba(201,169,110,0.12)",
                            color: "var(--primary)",
                            borderRadius: "var(--radius-sm)",
                            border: "1px solid rgba(201,169,110,0.2)",
                        }}
                    >
                        <ShoppingBag className="w-3.5 h-3.5" />
                        <span className="text-xs" style={{ fontFamily: "'DM Mono', monospace" }}>
              {purchasedCount} owned
            </span>
                    </div>
                </div>
            </header>

            <div className="flex flex-1 overflow-hidden" style={{ height: "calc(100vh - 57px)" }}>
                {/* Sidebar */}
                {sidebarOpen && (
                    <aside
                        className="w-56 shrink-0 flex flex-col border-r"
                        style={{ borderColor: "var(--border)", background: "var(--sidebar)" }}
                    >
                        <ScrollArea className="flex-1 p-4">
                            {/* Events by date */}
                            <div className="mb-5">
                                <p
                                    className="text-xs uppercase tracking-widest mb-2.5"
                                    style={{ color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace" }}
                                >
                                    Events
                                </p>
                                <div className="flex flex-col gap-0.5">
                                    <button
                                        className="flex items-center gap-2 px-2 py-1.5 rounded text-left transition-colors"
                                        style={{
                                            background: selectedEventId === null ? "rgba(201,169,110,0.12)" : "transparent",
                                            color: selectedEventId === null ? "var(--primary)" : "var(--foreground)",
                                            borderRadius: "var(--radius-sm)",
                                        }}
                                        onClick={() => setSelectedEventId(null)}
                                    >
                                        <Calendar className="w-3.5 h-3.5 shrink-0" />
                                        <span className="text-sm">All events</span>
                                    </button>
                                    {EVENTS.map((event) => (
                                        <button
                                            key={event.id}
                                            className="flex flex-col px-2 py-1.5 rounded text-left transition-colors"
                                            style={{
                                                background: selectedEventId === event.id ? "rgba(201,169,110,0.12)" : "transparent",
                                                color: selectedEventId === event.id ? "var(--primary)" : "var(--foreground)",
                                                borderRadius: "var(--radius-sm)",
                                            }}
                                            onClick={() => setSelectedEventId(event.id)}
                                        >
                                            <span className="text-sm truncate">{event.name}</span>
                                            <span
                                                className="text-xs"
                                                style={{ color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace" }}
                                            >
                        {event.date}
                      </span>
                                        </button>
                                    ))}
                                </div>
                            </div>

                            <Separator className="mb-4" style={{ background: "var(--border)" }} />

                            <FaceGroup
                                faces={FACES}
                                selectedFaceId={selectedFaceId}
                                onSelect={setSelectedFaceId}
                            />
                        </ScrollArea>
                    </aside>
                )}

                {/* Main gallery */}
                <main className="flex-1 flex flex-col overflow-hidden">
                    {/* Toolbar */}
                    <div
                        className="flex items-center justify-between px-5 py-2.5 border-b shrink-0"
                        style={{ borderColor: "var(--border)", background: "var(--card)" }}
                    >
                        <div className="flex items-center gap-3">
                            <button
                                className="p-1.5 rounded transition-colors hover:bg-muted"
                                onClick={() => setSidebarOpen((v) => !v)}
                                style={{ color: "var(--muted-foreground)", borderRadius: "var(--radius-sm)" }}
                                title="Toggle sidebar"
                            >
                                <Filter className="w-3.5 h-3.5" />
                            </button>
                            <span className="text-xs" style={{ color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace" }}>
                {filteredPhotos.length} photo{filteredPhotos.length !== 1 ? "s" : ""}
              </span>
                            {selectedEventId && (
                                <Badge
                                    className="text-xs cursor-pointer gap-1 select-none"
                                    style={{
                                        background: "rgba(201,169,110,0.15)",
                                        color: "var(--primary)",
                                        borderRadius: "var(--radius-sm)",
                                        border: "1px solid rgba(201,169,110,0.3)",
                                    }}
                                    onClick={() => setSelectedEventId(null)}
                                >
                                    {EVENTS.find((e) => e.id === selectedEventId)?.name}
                                    <X className="w-3 h-3" />
                                </Badge>
                            )}
                            {selectedFaceId && (
                                <Badge
                                    className="text-xs cursor-pointer gap-1 select-none"
                                    style={{
                                        background: "rgba(201,169,110,0.15)",
                                        color: "var(--primary)",
                                        borderRadius: "var(--radius-sm)",
                                        border: "1px solid rgba(201,169,110,0.3)",
                                    }}
                                    onClick={() => setSelectedFaceId(null)}
                                >
                                    {FACES.find((f) => f.id === selectedFaceId)?.label}
                                    <X className="w-3 h-3" />
                                </Badge>
                            )}
                        </div>
                        <div className="flex items-center gap-0.5">
                            <button
                                className="p-1.5 rounded transition-colors"
                                style={{
                                    background: gridCols === 3 ? "rgba(201,169,110,0.15)" : "transparent",
                                    color: gridCols === 3 ? "var(--primary)" : "var(--muted-foreground)",
                                    borderRadius: "var(--radius-sm)",
                                }}
                                onClick={() => setGridCols(3)}
                                title="3 columns"
                            >
                                <Grid3X3 className="w-3.5 h-3.5" />
                            </button>
                            <button
                                className="p-1.5 rounded transition-colors"
                                style={{
                                    background: gridCols === 4 ? "rgba(201,169,110,0.15)" : "transparent",
                                    color: gridCols === 4 ? "var(--primary)" : "var(--muted-foreground)",
                                    borderRadius: "var(--radius-sm)",
                                }}
                                onClick={() => setGridCols(4)}
                                title="4 columns"
                            >
                                <LayoutList className="w-3.5 h-3.5" />
                            </button>
                        </div>
                    </div>

                    {/* Photo grid */}
                    <ScrollArea className="flex-1">
                        {filteredPhotos.length === 0 ? (
                            <div className="flex flex-col items-center justify-center h-64 gap-3">
                                <Camera className="w-8 h-8" style={{ color: "var(--muted-foreground)" }} />
                                <p
                                    style={{
                                        color: "var(--muted-foreground)",
                                        fontFamily: "'Playfair Display', serif",
                                        fontSize: "1rem",
                                    }}
                                >
                                    No photos match your filters
                                </p>
                                <button
                                    className="text-sm underline underline-offset-2 transition-opacity hover:opacity-70"
                                    style={{ color: "var(--primary)", fontFamily: "'Inter', sans-serif" }}
                                    onClick={() => {
                                        setSelectedEventId(null);
                                        setSelectedFaceId(null);
                                        setSearchQuery("");
                                    }}
                                >
                                    Clear all filters
                                </button>
                            </div>
                        ) : (
                            <div
                                className="p-4 grid gap-3"
                                style={{ gridTemplateColumns: `repeat(${gridCols}, minmax(0, 1fr))` }}
                            >
                                {filteredPhotos.map((photo) => (
                                    <PhotoCard
                                        key={photo.id}
                                        photo={photo}
                                        onSelect={(p) => setViewerPhoto(p)}
                                        onPurchase={(p) => setPurchasePhoto(p)}
                                    />
                                ))}
                            </div>
                        )}
                    </ScrollArea>
                </main>
            </div>

            <PhotoViewer
                photo={viewerPhoto}
                photos={filteredPhotos}
                open={viewerPhoto !== null}
                onClose={() => setViewerPhoto(null)}
                onPurchase={(p) => {
                    setViewerPhoto(null);
                    setPurchasePhoto(p);
                }}
                onNavigate={(p) => setViewerPhoto(p)}
            />

            <PurchaseModal
                photo={purchasePhoto}
                open={purchasePhoto !== null}
                onClose={() => setPurchasePhoto(null)}
                onPurchaseComplete={handlePurchaseComplete}
            />
        </div>
    );
}
