import { useEffect, useState } from "react";
import {
  Calendar,
  Filter,
  Grid3X3,
  LayoutList,
  LogOut,
  Search,
  Settings,
  ShoppingBag,
  Upload,
  X,
} from "lucide-react";
import { Badge } from "../controls/Badge";
import { Input } from "../controls/Input";
import { ScrollArea } from "../controls/ScrollArea";
import { FaceGroup } from "../FaceGroup";
import { PurchaseModal } from "../PurchaseModal";
import { PhotoViewer } from "../PhotoViewer";
import { Separator } from "../controls/Separator";
import { graphql, useLazyLoadQuery } from "react-relay";
import PhotoCollection from "../PhotoCollection";
import { BaseApplicationQuery } from "./__generated__/BaseApplicationQuery.graphql";
import { useNavigate } from "react-router";
import { QueryBoundary, useRetryKey } from "../QueryBoundary";

// Below this width the sidebar becomes a drawer over the photos.
const DESKTOP_QUERY = "(min-width: 768px)";

function useIsDesktop() {
  const [isDesktop, setIsDesktop] = useState(
    () =>
      typeof window === "undefined" ||
      !window.matchMedia ||
      window.matchMedia(DESKTOP_QUERY).matches,
  );

  useEffect(() => {
    if (!window.matchMedia) return;
    const media = window.matchMedia(DESKTOP_QUERY);
    const update = () => setIsDesktop(media.matches);
    media.addEventListener("change", update);
    return () => media.removeEventListener("change", update);
  }, []);

  return isDesktop;
}

const BASE_QUERY = graphql`
  query BaseApplicationQuery($faceId: ID, $folderId: ID) {
    folders(faceId: $faceId) {
      nodes {
        id
        name
        photoCount
      }
    }
    faces(folderId: $folderId) {
      ...FaceFragment_faces
    }
  }
`;

export default function GalleryPage() {
  const [selectedEventId, setSelectedEventId] = useState<string | null>(null);
  const [selectedFaceId, setSelectedFaceId] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [purchasePhoto, setPurchasePhoto] = useState<string | null>(null);
  const isDesktop = useIsDesktop();
  const [sidebarOpen, setSidebarOpen] = useState(isDesktop);
  const [gridCols, setGridCols] = useState<3 | 4>(3);
  const [viewerPhoto, setViewerPhoto] = useState<string | null>(null);
  const navigate = useNavigate();

  // Open the sidebar on desktop and tuck it away on phones whenever the
  // window crosses the breakpoint.
  useEffect(() => setSidebarOpen(isDesktop), [isDesktop]);

  const closeDrawer = () => {
    if (!isDesktop) setSidebarOpen(false);
  };

  const user = {
    user_metadata: {
      avatar_url: null,
      full_name: "John Doe",
    },
    email: "john.doe@example.com",
  };

  return (
    <div
      className="flex h-dvh flex-col"
      style={{
        background: "var(--background)",
        fontFamily: "'Inter', sans-serif",
      }}
    >
      {/* Top nav */}
      <header
        className="flex shrink-0 flex-wrap items-center justify-between gap-x-3 gap-y-2 border-b px-3 py-2.5 sm:px-6 sm:py-3.5"
        style={{ borderColor: "var(--border)", background: "var(--card)" }}
      >
        <div className="flex min-w-0 items-center gap-3">
          <img src="/lumiere-mark.svg" alt="" className="h-6 w-6 shrink-0" />
          <span
            style={{
              fontFamily: "'Playfair Display', serif",
              color: "var(--foreground)",
              fontSize: "1.125rem",
              letterSpacing: "0.01em",
            }}
            className="truncate"
          >
            Lumière Archive
          </span>
          <Separator
            orientation="vertical"
            className="mx-1 hidden h-4 sm:block"
            style={{ background: "var(--border)" }}
          />
          <span
            className="text-xs"
            style={{
              color: "var(--muted-foreground)",
              fontFamily: "'DM Mono', monospace",
            }}
          ></span>
        </div>
        <div className="relative order-last w-full sm:order-none sm:ml-auto sm:w-auto">
          <Search
            className="pointer-events-none absolute top-1/2 left-2.5 h-3.5 w-3.5 -translate-y-1/2"
            style={{ color: "var(--muted-foreground)" }}
          />
          <Input
            placeholder="Search photos…"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="h-10 w-full pl-8 text-base sm:h-8 sm:w-52 sm:text-sm"
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
              className="absolute top-1/2 right-1 -translate-y-1/2 p-1.5"
              onClick={() => setSearchQuery("")}
              aria-label="Clear search"
              style={{ color: "var(--muted-foreground)" }}
            >
              <X className="h-3.5 w-3.5" />
            </button>
          )}
        </div>
        <div className="flex items-center gap-1.5 sm:gap-3">
          <button
            onClick={() => {
              navigate("/upload");
            }}
            className="flex h-10 w-10 items-center justify-center gap-1.5 rounded transition-colors lg:h-auto lg:w-auto lg:px-3 lg:py-1.5"
            aria-label="Upload"
            style={{
              background: "var(--secondary)",
              color: "var(--foreground)",
              borderRadius: "var(--radius-sm)",
              border: "1px solid var(--border)",
              fontFamily: "'Inter', sans-serif",
              fontSize: "0.8125rem",
            }}
          >
            <Upload className="h-4 w-4 lg:h-3.5 lg:w-3.5" />
            <span className="hidden lg:inline">Upload</span>
          </button>
          <button
            onClick={() => navigate("/admin")}
            className="flex h-10 w-10 items-center justify-center gap-1.5 rounded transition-colors lg:h-auto lg:w-auto lg:px-3 lg:py-1.5"
            aria-label="Admin"
            style={{
              background: "var(--secondary)",
              color: "var(--foreground)",
              borderRadius: "var(--radius-sm)",
              border: "1px solid var(--border)",
              fontFamily: "'Inter', sans-serif",
              fontSize: "0.8125rem",
            }}
          >
            <Settings className="h-4 w-4 lg:h-3.5 lg:w-3.5" />
            <span className="hidden lg:inline">Admin</span>
          </button>

          <div
            className="flex h-10 items-center gap-1.5 rounded px-2.5 lg:h-auto lg:px-3 lg:py-1.5"
            style={{
              background: "rgba(201,169,110,0.12)",
              color: "var(--primary)",
              borderRadius: "var(--radius-sm)",
              border: "1px solid rgba(201,169,110,0.2)",
            }}
          >
            <ShoppingBag className="h-3.5 w-3.5" />
            <span
              className="text-xs"
              style={{ fontFamily: "'DM Mono', monospace" }}
            >
              {0}
              <span className="hidden lg:inline"> owned</span>
            </span>
          </div>

          <div className="flex items-center gap-1 lg:ml-1 lg:gap-2">
            {user.user_metadata?.avatar_url ? (
              <img
                src={user.user_metadata.avatar_url}
                alt={user.user_metadata?.full_name ?? "User"}
                className="hidden h-7 w-7 rounded-full object-cover lg:block"
                style={{ border: "1.5px solid var(--border)" }}
              />
            ) : (
              <div
                className="hidden h-7 w-7 items-center justify-center rounded-full text-xs lg:flex"
                style={{
                  background: "rgba(201,169,110,0.15)",
                  color: "var(--primary)",
                  fontFamily: "'Inter', sans-serif",
                  fontWeight: 600,
                  border: "1.5px solid var(--border)",
                }}
              >
                {(user.user_metadata?.full_name ??
                  user.email ??
                  "?")[0].toUpperCase()}
              </div>
            )}
            <span
              className="hidden max-w-28 truncate text-xs lg:block"
              style={{
                color: "var(--muted-foreground)",
                fontFamily: "'Inter', sans-serif",
              }}
            >
              {user.user_metadata?.full_name ?? user.email}
            </span>
            <button
              className="hover:bg-muted rounded p-2.5 transition-colors lg:p-1.5"
              style={{
                color: "var(--muted-foreground)",
                borderRadius: "var(--radius-sm)",
              }}
              title="Sign out"
              aria-label="Sign out"
            >
              <LogOut className="h-3.5 w-3.5" />
            </button>
          </div>
        </div>
      </header>

      <div className="relative flex min-h-0 flex-1 overflow-hidden">
        {/* Sidebar: a column on desktop, a drawer over the photos on phones */}
        {sidebarOpen && !isDesktop && (
          <div
            className="fixed inset-0 z-30"
            style={{ background: "rgba(0,0,0,0.6)" }}
            onClick={() => setSidebarOpen(false)}
            aria-hidden="true"
          />
        )}
        {sidebarOpen && (
          <aside
            className={
              isDesktop
                ? "flex w-56 shrink-0 flex-col border-r"
                : "fixed inset-y-0 left-0 z-40 flex w-72 max-w-[85vw] flex-col border-r shadow-2xl"
            }
            style={{
              borderColor: "var(--border)",
              background: "var(--sidebar)",
            }}
            aria-label="Filters"
          >
            {!isDesktop && (
              <div
                className="flex shrink-0 items-center justify-between border-b py-1 pr-1 pl-4"
                style={{ borderColor: "var(--border)" }}
              >
                <span
                  className="text-xs tracking-widest uppercase"
                  style={{
                    color: "var(--muted-foreground)",
                    fontFamily: "'DM Mono', monospace",
                  }}
                >
                  Filters
                </span>
                <button
                  className="hover:bg-muted rounded p-3 transition-colors"
                  style={{ color: "var(--muted-foreground)" }}
                  onClick={() => setSidebarOpen(false)}
                  aria-label="Close filters"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
            )}
            <ScrollArea className="min-h-0 flex-1 p-4">
              <QueryBoundary message="Couldn't load events and faces.">
                <GallerySidebar
                  selectedEventId={selectedEventId}
                  onSelectEvent={(id) => {
                    setSelectedEventId(id);
                    closeDrawer();
                  }}
                  selectedFaceId={selectedFaceId}
                  onSelectFace={(id) => {
                    setSelectedFaceId(id);
                    closeDrawer();
                  }}
                />
              </QueryBoundary>
            </ScrollArea>
          </aside>
        )}

        {/* Main gallery */}
        <main className="flex min-w-0 flex-1 flex-col overflow-hidden">
          {/* Toolbar */}
          <div
            className="flex shrink-0 items-center justify-between border-b px-2 py-1.5 sm:px-5 sm:py-2.5"
            style={{ borderColor: "var(--border)", background: "var(--card)" }}
          >
            <div className="flex items-center gap-3">
              <button
                className="hover:bg-muted flex items-center gap-2 rounded p-2.5 transition-colors md:p-1.5"
                onClick={() => setSidebarOpen((v) => !v)}
                style={{
                  color: "var(--muted-foreground)",
                  borderRadius: "var(--radius-sm)",
                }}
                title="Toggle sidebar"
                aria-expanded={sidebarOpen}
              >
                <Filter className="h-4 w-4 md:h-3.5 md:w-3.5" />
                <span className="text-sm md:hidden">Filters</span>
              </button>
              <span
                className="text-xs"
                style={{
                  color: "var(--muted-foreground)",
                  fontFamily: "'DM Mono', monospace",
                }}
              ></span>
              {selectedEventId && (
                <Badge
                  className="cursor-pointer gap-1 px-2.5 py-1.5 text-xs select-none md:px-2 md:py-0.5"
                  style={{
                    background: "rgba(201,169,110,0.15)",
                    color: "var(--primary)",
                    borderRadius: "var(--radius-sm)",
                    border: "1px solid rgba(201,169,110,0.3)",
                  }}
                  onClick={() => setSelectedEventId(null)}
                >
                  <X className="h-3 w-3" />
                </Badge>
              )}
              {selectedFaceId && (
                <Badge
                  className="cursor-pointer gap-1 px-2.5 py-1.5 text-xs select-none md:px-2 md:py-0.5"
                  style={{
                    background: "rgba(201,169,110,0.15)",
                    color: "var(--primary)",
                    borderRadius: "var(--radius-sm)",
                    border: "1px solid rgba(201,169,110,0.3)",
                  }}
                  onClick={() => setSelectedFaceId(null)}
                >
                  <X className="h-3 w-3" />
                </Badge>
              )}
            </div>
            {/* Column choice only applies on wide screens */}
            <div className="hidden items-center gap-0.5 lg:flex">
              <button
                className="rounded p-1.5 transition-colors"
                style={{
                  background:
                    gridCols === 3 ? "rgba(201,169,110,0.15)" : "transparent",
                  color:
                    gridCols === 3
                      ? "var(--primary)"
                      : "var(--muted-foreground)",
                  borderRadius: "var(--radius-sm)",
                }}
                onClick={() => setGridCols(3)}
                title="3 columns"
              >
                <Grid3X3 className="h-3.5 w-3.5" />
              </button>
              <button
                className="rounded p-1.5 transition-colors"
                style={{
                  background:
                    gridCols === 4 ? "rgba(201,169,110,0.15)" : "transparent",
                  color:
                    gridCols === 4
                      ? "var(--primary)"
                      : "var(--muted-foreground)",
                  borderRadius: "var(--radius-sm)",
                }}
                onClick={() => setGridCols(4)}
                title="4 columns"
              >
                <LayoutList className="h-3.5 w-3.5" />
              </button>
            </div>
          </div>

          {/* PhotoTake grid */}
          <ScrollArea className="flex-1">
            <QueryBoundary message="Couldn't load photos.">
              <PhotoCollection
                faceId={selectedFaceId}
                eventId={selectedEventId}
                columns={gridCols}
                onSelect={(id) => {
                  console.log("Selected photo:", id);
                  setViewerPhoto(id);
                }}
              />
            </QueryBoundary>
          </ScrollArea>
        </main>
      </div>

      <PhotoViewer
        id={viewerPhoto}
        open={viewerPhoto !== null}
        onClose={() => setViewerPhoto(null)}
        onPurchase={(_id) => {
          setViewerPhoto(null);
        }}
      />

      <PurchaseModal
        photoId={purchasePhoto}
        open={purchasePhoto !== null}
        onClose={() => setPurchasePhoto(null)}
        onPurchaseComplete={() => {}}
      />
    </div>
  );
}

interface GallerySidebarProps {
  selectedEventId: string | null;
  onSelectEvent: (id: string | null) => void;
  selectedFaceId: string | null;
  onSelectFace: (id: string | null) => void;
}

function GallerySidebar({
  selectedEventId,
  onSelectEvent,
  selectedFaceId,
  onSelectFace,
}: GallerySidebarProps) {
  const data = useLazyLoadQuery<BaseApplicationQuery>(
    BASE_QUERY,
    { faceId: selectedFaceId, folderId: selectedEventId },
    { fetchKey: useRetryKey() },
  );

  return (
    <>
      {/* Events by date */}
      <div className="mb-5">
        <p
          className="mb-2.5 text-xs tracking-widest uppercase"
          style={{
            color: "var(--muted-foreground)",
            fontFamily: "'DM Mono', monospace",
          }}
        >
          Events
        </p>
        <div className="flex flex-col gap-0.5">
          <button
            className="flex items-center gap-2 rounded px-2 py-2.5 text-left transition-colors md:py-1.5"
            style={{
              background:
                selectedEventId === null
                  ? "rgba(201,169,110,0.12)"
                  : "transparent",
              color:
                selectedEventId === null
                  ? "var(--primary)"
                  : "var(--foreground)",
              borderRadius: "var(--radius-sm)",
            }}
            onClick={() => onSelectEvent(null)}
          >
            <Calendar className="h-3.5 w-3.5 shrink-0" />
            <span className="text-sm">All events</span>
          </button>
          {data?.folders?.nodes?.map((event) =>
            event ? (
              <button
                key={event.id}
                className="flex flex-col rounded px-2 py-2 text-left transition-colors md:py-1.5"
                style={{
                  background:
                    selectedEventId === event?.id
                      ? "rgba(201,169,110,0.12)"
                      : "transparent",
                  color:
                    selectedEventId === event?.id
                      ? "var(--primary)"
                      : "var(--foreground)",
                  borderRadius: "var(--radius-sm)",
                }}
                onClick={() => onSelectEvent(event!.id!)}
              >
                <span className="truncate text-sm">{event?.name}</span>
                <span
                  className="text-xs"
                  style={{
                    color: "var(--muted-foreground)",
                    fontFamily: "'DM Mono', monospace",
                  }}
                >
                  {event?.photoCount} photos
                </span>
              </button>
            ) : null,
          )}
        </div>
      </div>

      <Separator className="mb-4" style={{ background: "var(--border)" }} />

      <FaceGroup
        faces={data.faces}
        selectedFaceId={selectedFaceId}
        onSelect={onSelectFace}
      />
    </>
  );
}
