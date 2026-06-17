import { Suspense, useState } from "react";
import {
  Calendar,
  Camera,
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
import { Spinner } from "../controls/Spinner";

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
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [gridCols, setGridCols] = useState<3 | 4>(3);
  const [viewerPhoto, setViewerPhoto] = useState<string | null>(null);
  const navigate = useNavigate();

  const data = useLazyLoadQuery<BaseApplicationQuery>(BASE_QUERY, {
    faceId: selectedFaceId,
    folderId: selectedEventId,
  });

  const user = {
    user_metadata: {
      avatar_url: null,
      full_name: "John Doe",
    },
    email: "john.doe@example.com",
  };

  return (
    <div
      className="flex min-h-screen flex-col"
      style={{
        background: "var(--background)",
        fontFamily: "'Inter', sans-serif",
      }}
    >
      {/* Top nav */}
      <header
        className="flex shrink-0 items-center justify-between border-b px-6 py-3.5"
        style={{ borderColor: "var(--border)", background: "var(--card)" }}
      >
        <div className="flex items-center gap-3">
          <Camera className="h-4.5 w-4.5" style={{ color: "var(--primary)" }} />
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
          <Separator
            orientation="vertical"
            className="mx-1 h-4"
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
        <div className="flex items-center gap-3">
          <div className="relative">
            <Search
              className="pointer-events-none absolute top-1/2 left-2.5 h-3.5 w-3.5 -translate-y-1/2"
              style={{ color: "var(--muted-foreground)" }}
            />
            <Input
              placeholder="Search photos…"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="h-8 w-52 pl-8 text-sm"
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
                className="absolute top-1/2 right-2.5 -translate-y-1/2"
                onClick={() => setSearchQuery("")}
                style={{ color: "var(--muted-foreground)" }}
              >
                <X className="h-3.5 w-3.5" />
              </button>
            )}
          </div>
          <button
            onClick={() => {
              navigate("/upload");
            }}
            className="flex items-center gap-1.5 rounded px-3 py-1.5 transition-colors"
            style={{
              background: "var(--secondary)",
              color: "var(--foreground)",
              borderRadius: "var(--radius-sm)",
              border: "1px solid var(--border)",
              fontFamily: "'Inter', sans-serif",
              fontSize: "0.8125rem",
            }}
          >
            <Upload className="h-3.5 w-3.5" />
            Upload
          </button>
          <button
            onClick={() => navigate("/admin")}
            className="flex items-center gap-1.5 rounded px-3 py-1.5 transition-colors"
            style={{
              background: "var(--secondary)",
              color: "var(--foreground)",
              borderRadius: "var(--radius-sm)",
              border: "1px solid var(--border)",
              fontFamily: "'Inter', sans-serif",
              fontSize: "0.8125rem",
            }}
          >
            <Settings className="h-3.5 w-3.5" />
            Admin
          </button>

          <div
            className="flex items-center gap-1.5 rounded px-3 py-1.5"
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
              {0} owned
            </span>
          </div>

          <div className="ml-1 flex items-center gap-2">
            {user.user_metadata?.avatar_url ? (
              <img
                src={user.user_metadata.avatar_url}
                alt={user.user_metadata?.full_name ?? "User"}
                className="h-7 w-7 rounded-full object-cover"
                style={{ border: "1.5px solid var(--border)" }}
              />
            ) : (
              <div
                className="flex h-7 w-7 items-center justify-center rounded-full text-xs"
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
              className="hidden max-w-28 truncate text-xs sm:block"
              style={{
                color: "var(--muted-foreground)",
                fontFamily: "'Inter', sans-serif",
              }}
            >
              {user.user_metadata?.full_name ?? user.email}
            </span>
            <button
              className="hover:bg-muted rounded p-1.5 transition-colors"
              style={{
                color: "var(--muted-foreground)",
                borderRadius: "var(--radius-sm)",
              }}
              title="Sign out"
            >
              <LogOut className="h-3.5 w-3.5" />
            </button>
          </div>
        </div>
      </header>

      <div
        className="flex flex-1 overflow-hidden"
        style={{ height: "calc(100vh - 57px)" }}
      >
        {/* Sidebar */}
        {sidebarOpen && (
          <aside
            className="flex w-56 shrink-0 flex-col border-r"
            style={{
              borderColor: "var(--border)",
              background: "var(--sidebar)",
            }}
          >
            <ScrollArea className="flex-1 p-4">
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
                    className="flex items-center gap-2 rounded px-2 py-1.5 text-left transition-colors"
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
                    onClick={() => setSelectedEventId(null)}
                  >
                    <Calendar className="h-3.5 w-3.5 shrink-0" />
                    <span className="text-sm">All events</span>
                  </button>
                  {data?.folders?.nodes?.map((event) =>
                    event ? (
                      <button
                        key={event.id}
                        className="flex flex-col rounded px-2 py-1.5 text-left transition-colors"
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
                        onClick={() => setSelectedEventId(event!.id!)}
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

              <Separator
                className="mb-4"
                style={{ background: "var(--border)" }}
              />

              <FaceGroup
                faces={data.faces}
                selectedFaceId={selectedFaceId}
                onSelect={setSelectedFaceId}
              />
            </ScrollArea>
          </aside>
        )}

        {/* Main gallery */}
        <main className="flex flex-1 flex-col overflow-hidden">
          {/* Toolbar */}
          <div
            className="flex shrink-0 items-center justify-between border-b px-5 py-2.5"
            style={{ borderColor: "var(--border)", background: "var(--card)" }}
          >
            <div className="flex items-center gap-3">
              <button
                className="hover:bg-muted rounded p-1.5 transition-colors"
                onClick={() => setSidebarOpen((v) => !v)}
                style={{
                  color: "var(--muted-foreground)",
                  borderRadius: "var(--radius-sm)",
                }}
                title="Toggle sidebar"
              >
                <Filter className="h-3.5 w-3.5" />
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
                  className="cursor-pointer gap-1 text-xs select-none"
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
                  className="cursor-pointer gap-1 text-xs select-none"
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
            <div className="flex items-center gap-0.5">
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
            <Suspense fallback={<Spinner />}>
              <PhotoCollection
                faceId={selectedFaceId}
                eventId={selectedEventId}
                onSelect={(id) => {
                  console.log("Selected photo:", id);
                  setViewerPhoto(id);
                }}
              />
            </Suspense>
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
