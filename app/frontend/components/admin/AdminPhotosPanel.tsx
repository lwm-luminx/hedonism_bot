import { useMemo, useState } from "react";
import { CalendarDays, Check, ChevronDown, LayoutGrid, List, MapPin, Pencil, Search, Trash2, X } from "lucide-react";
import { Dialog, DialogContent, DialogTitle } from "../controls/Dialog";
import { Input } from "../controls/Input";
import { Label } from "../controls/Label";
import { ScrollArea } from "../controls/ScrollArea";
import { graphql, useLazyLoadQuery } from "react-relay";
import { AdminPhotosQuery } from "./__generated__/AdminPhotosQuery.graphql";

const ADMIN_PHOTOS_QUERY = graphql`
  query AdminPhotosQuery {
    photos @required(action: THROW) {
      totalCount
      nodes @required(action: THROW) {
        id
        name
        price
        previewUrl
        takenAt
        event {
          id
          name
          venue {
            id
            name
          }
        }
      }
    }
    events @required(action: THROW) {
      totalCount
      nodes @required(action: THROW) {
        id
        name
        venue {
          id
        }
      }
    }
    venues @required(action: THROW) {
      nodes @required(action: THROW) {
        id
        name
        city
      }
    }
  }
`;

interface Photo {
  name: string;
  eventId: string;
  price: number;
  previewUrl: string;
}

export function AdminPhotosPanel() {
  const data = useLazyLoadQuery<AdminPhotosQuery>(ADMIN_PHOTOS_QUERY, {});
  const [search, setSearch] = useState("");
  const [filterEventId, setFilterEventId] = useState<string>("all");
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [bulkModal, setBulkModal] = useState(false);
  const [editModal, setEditModal] = useState<Photo | null>(null);
  const [editForm, setEditForm] = useState({
    title: "",
    eventId: "",
    price: "",
  });
  const [bulkEventId, setBulkEventId] = useState("");
  const [viewMode, setViewMode] = useState<"grid" | "list">("grid");
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);

  const filtered = useMemo(() => {
    return data.photos.nodes.filter((p) => {
      const matchSearch = search
        ? p!.name.toLowerCase().includes(search.toLowerCase())
        : true;
      const matchEvent =
        filterEventId !== "all" ? p?.event?.id === filterEventId : true;
      return matchSearch && matchEvent;
    });
  }, [data.photos, search, filterEventId]);

  const toggleSelect = (id: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  };

  const toggleAll = () => {
    if (selected.size === filtered.length) {
      setSelected(new Set());
    } else {
      setSelected(new Set(filtered.map((p) => p!.id)));
    }
  };

  const openEdit = (_p: string) => {};

  const saveEdit = () => {};

  const openBulkMove = () => {
    setBulkModal(true);
  };

  const applyBulkMove = () => {
    if (!bulkEventId) return;

    setSelected(new Set());
    setBulkModal(false);
  };

  const handleDelete = (id: string) => {
    setDeleteConfirm(null);
    setSelected((prev) => {
      const n = new Set(prev);
      n.delete(id);
      return n;
    });
  };

  const bulkDelete = () => {
    setSelected(new Set());
  };

  return (
    <div className="flex h-full flex-col">
      {/* Toolbar */}
      <div
        className="flex shrink-0 flex-wrap items-center gap-3 border-b px-5 py-3"
        style={{ borderColor: "var(--border)", background: "var(--card)" }}
      >
        <div className="relative">
          <Search
            className="pointer-events-none absolute top-1/2 left-2.5 h-3.5 w-3.5 -translate-y-1/2"
            style={{ color: "var(--muted-foreground)" }}
          />
          <Input
            placeholder="Search photos…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="h-8 w-48 pl-8 text-sm"
            style={{
              background: "var(--input-background)",
              border: "1px solid var(--border)",
              color: "var(--foreground)",
              borderRadius: "var(--radius-sm)",
            }}
          />
          {search && (
            <button
              className="absolute top-1/2 right-2 -translate-y-1/2"
              onClick={() => setSearch("")}
              style={{ color: "var(--muted-foreground)" }}
            >
              <X className="h-3.5 w-3.5" />
            </button>
          )}
        </div>

        {/* Event filter */}
        <div className="relative">
          <select
            value={filterEventId}
            onChange={(e) => setFilterEventId(e.target.value)}
            className="h-8 appearance-none pr-7 pl-3 text-sm"
            style={{
              background: "var(--input-background)",
              border: "1px solid var(--border)",
              color: "var(--foreground)",
              borderRadius: "var(--radius-sm)",
              fontFamily: "'Inter', sans-serif",
            }}
          >
            <option value="all">All events</option>
            {data.events.nodes.map((ev) => (
              <option key={ev?.id} value={ev?.id}>
                {ev?.name}
              </option>
            ))}
          </select>
          <ChevronDown
            className="pointer-events-none absolute top-1/2 right-2 h-3 w-3 -translate-y-1/2"
            style={{ color: "var(--muted-foreground)" }}
          />
        </div>

        <span
          className="ml-1 text-xs"
          style={{
            color: "var(--muted-foreground)",
            fontFamily: "'DM Mono', monospace",
          }}
        >
          {filtered.length} photo{filtered.length !== 1 ? "s" : ""}
        </span>

        <div className="flex-1" />

        {/* Bulk actions */}
        {selected.size > 0 && (
          <div className="flex items-center gap-2">
            <span
              className="text-xs"
              style={{
                color: "var(--primary)",
                fontFamily: "'DM Mono', monospace",
              }}
            >
              {selected.size} selected
            </span>
            <button
              onClick={openBulkMove}
              className="flex items-center gap-1.5 rounded px-3 py-1.5 text-xs"
              style={{
                background: "rgba(201,169,110,0.12)",
                color: "var(--primary)",
                borderRadius: "var(--radius-sm)",
                border: "1px solid rgba(201,169,110,0.25)",
                fontFamily: "'Inter', sans-serif",
              }}
            >
              <CalendarDays className="h-3.5 w-3.5" />
              Move to event
            </button>
            <button
              onClick={bulkDelete}
              className="flex items-center gap-1.5 rounded px-3 py-1.5 text-xs"
              style={{
                background: "rgba(192,57,43,0.1)",
                color: "var(--destructive)",
                borderRadius: "var(--radius-sm)",
                border: "1px solid rgba(192,57,43,0.2)",
                fontFamily: "'Inter', sans-serif",
              }}
            >
              <Trash2 className="h-3.5 w-3.5" />
              Delete
            </button>
          </div>
        )}

        <div className="flex items-center gap-0.5">
          {(["grid", "list"] as const).map((m) => (
            <button
              key={m}
              onClick={() => setViewMode(m)}
              className="rounded p-1.5"
              style={{
                background:
                  viewMode === m ? "rgba(201,169,110,0.15)" : "transparent",
                color:
                  viewMode === m ? "var(--primary)" : "var(--muted-foreground)",
                borderRadius: "var(--radius-sm)",
              }}
            >
              {m === "grid" ? (
                <LayoutGrid className="h-3.5 w-3.5" />
              ) : (
                <List className="h-3.5 w-3.5" />
              )}
            </button>
          ))}
        </div>
      </div>

      <ScrollArea className="flex-1">
        {viewMode === "grid" ? (
          <div
            className="grid gap-3 p-4"
            style={{
              gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))",
            }}
          >
            {filtered.map((p) => {
              const isSelected = selected.has(p!.id);
              const venue = p?.event?.venue?.name;
              return (
                <div
                  key={p?.id}
                  className="group relative flex cursor-pointer flex-col overflow-hidden border transition-all"
                  style={{
                    borderColor: isSelected
                      ? "var(--primary)"
                      : "var(--border)",
                    background: isSelected
                      ? "rgba(201,169,110,0.06)"
                      : "var(--card)",
                    borderRadius: "var(--radius-sm)",
                    outline: isSelected ? "1px solid var(--primary)" : "none",
                  }}
                  onClick={() => toggleSelect(p!.id)}
                >
                  {/* Thumbnail */}
                  <div className="bg-muted relative aspect-4/3 overflow-hidden">
                    <img
                      src={p!.previewUrl!}
                      alt={p?.name}
                      className="h-full w-full object-cover"
                    />
                    {/* Select check */}
                    <div
                      className="absolute top-2 left-2 flex h-5 w-5 items-center justify-center rounded transition-all"
                      style={{
                        background: isSelected
                          ? "var(--primary)"
                          : "rgba(0,0,0,0.5)",
                        border: isSelected
                          ? "none"
                          : "1.5px solid rgba(255,255,255,0.6)",
                      }}
                    >
                      {isSelected && (
                        <Check
                          className="h-3 w-3"
                          style={{ color: "var(--primary-foreground)" }}
                        />
                      )}
                    </div>
                  </div>
                  <div className="flex flex-col gap-0.5 px-2.5 py-2">
                    <p
                      className="truncate text-sm"
                      style={{ color: "var(--foreground)" }}
                    >
                      {p!.name}
                    </p>
                    <p
                      className="truncate text-xs"
                      style={{
                        color: "var(--muted-foreground)",
                        fontFamily: "'DM Mono', monospace",
                      }}
                    >
                      {p?.event?.name}
                    </p>
                    {venue && (
                      <p
                        className="flex items-center gap-1 text-xs"
                        style={{
                          color: "var(--muted-foreground)",
                          fontFamily: "'DM Mono', monospace",
                        }}
                      >
                        <MapPin className="h-3 w-3 shrink-0" />
                        {venue}
                      </p>
                    )}
                  </div>
                  {/* Hover actions */}
                  <div
                    className="absolute top-2 right-2 flex gap-1 opacity-0 transition-opacity group-hover:opacity-100"
                    onClick={(e) => e.stopPropagation()}
                  >
                    <button
                      className="rounded p-1"
                      style={{
                        background: "rgba(15,15,15,0.75)",
                        color: "#fff",
                        borderRadius: "var(--radius-sm)",
                      }}
                      onClick={() => openEdit(p!.id)}
                      title="Edit"
                    >
                      <Pencil className="h-3 w-3" />
                    </button>
                    <button
                      className="rounded p-1"
                      style={{
                        background: "rgba(15,15,15,0.75)",
                        color: "#fff",
                        borderRadius: "var(--radius-sm)",
                      }}
                      onClick={() => setDeleteConfirm(p!.id)}
                      title="Delete"
                    >
                      <Trash2 className="h-3 w-3" />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        ) : (
          <div className="px-5 py-3">
            {/* List header */}
            <div
              className="mb-1 flex items-center gap-3 px-3 py-2 text-xs"
              style={{
                color: "var(--muted-foreground)",
                fontFamily: "'DM Mono', monospace",
              }}
            >
              <button
                onClick={toggleAll}
                className="flex h-5 w-5 shrink-0 items-center justify-center rounded border"
                style={{
                  borderColor: "var(--border)",
                  background:
                    selected.size === filtered.length && filtered.length > 0
                      ? "var(--primary)"
                      : "transparent",
                }}
              >
                {selected.size === filtered.length && filtered.length > 0 && (
                  <Check
                    className="h-3 w-3"
                    style={{ color: "var(--primary-foreground)" }}
                  />
                )}
              </button>
              <span className="flex-1">Title</span>
              <span className="w-44">Event</span>
              <span className="w-40">Venue</span>
              <span className="w-16 text-right">Price</span>
              <span className="w-16" />
            </div>
            <div
              className="overflow-hidden border"
              style={{
                borderColor: "var(--border)",
                borderRadius: "var(--radius-sm)",
              }}
            >
              {filtered.map((p, i) => {
                const isSelected = selected.has(p!.id);
                const venue = p?.event?.venue?.name;
                return (
                  <div
                    key={p?.id}
                    className="flex cursor-pointer items-center gap-3 px-3 py-2.5 transition-colors"
                    style={{
                      borderTop: i > 0 ? "1px solid var(--border)" : "none",
                      background: isSelected
                        ? "rgba(201,169,110,0.06)"
                        : i % 2 === 0
                          ? "var(--card)"
                          : "transparent",
                    }}
                    onClick={() => toggleSelect(p!.id)}
                  >
                    <div
                      className="flex h-5 w-5 shrink-0 items-center justify-center rounded border"
                      style={{
                        borderColor: isSelected
                          ? "var(--primary)"
                          : "var(--border)",
                        background: isSelected
                          ? "var(--primary)"
                          : "transparent",
                      }}
                    >
                      {isSelected && (
                        <Check
                          className="h-3 w-3"
                          style={{ color: "var(--primary-foreground)" }}
                        />
                      )}
                    </div>
                    <div className="flex min-w-0 flex-1 items-center gap-2">
                      <img
                        src={p!.previewUrl!}
                        alt={p?.name}
                        className="h-8 w-8 shrink-0 object-cover"
                        style={{ borderRadius: "var(--radius-sm)" }}
                      />
                      <span
                        className="truncate text-sm"
                        style={{ color: "var(--foreground)" }}
                      >
                        {p?.name}
                      </span>
                    </div>
                    <span
                      className="w-44 truncate text-xs"
                      style={{
                        color: "var(--muted-foreground)",
                        fontFamily: "'DM Mono', monospace",
                      }}
                    >
                      {p?.event?.name}
                    </span>
                    <span
                      className="w-40 truncate text-xs"
                      style={{
                        color: "var(--muted-foreground)",
                        fontFamily: "'DM Mono', monospace",
                      }}
                    >
                      {venue ?? <span style={{ opacity: 0.4 }}>—</span>}
                    </span>
                    <span
                      className="w-16 text-right text-xs"
                      style={{
                        color: "var(--muted-foreground)",
                        fontFamily: "'DM Mono', monospace",
                      }}
                    >
                      ${p!.price}
                    </span>
                    <div
                      className="flex w-16 items-center justify-end gap-1"
                      onClick={(e) => e.stopPropagation()}
                    >
                      <button
                        className="hover:bg-muted rounded p-1 transition-colors"
                        style={{
                          color: "var(--muted-foreground)",
                          borderRadius: "var(--radius-sm)",
                        }}
                        onClick={() => openEdit(p!.id)}
                      >
                        <Pencil className="h-3.5 w-3.5" />
                      </button>
                      <button
                        className="hover:bg-muted rounded p-1 transition-colors"
                        style={{
                          color: "var(--muted-foreground)",
                          borderRadius: "var(--radius-sm)",
                        }}
                        onClick={() => setDeleteConfirm(p!.id)}
                      >
                        <Trash2 className="h-3.5 w-3.5" />
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </ScrollArea>

      {/* Edit modal */}
      <Dialog open={editModal !== null} onOpenChange={() => setEditModal(null)}>
        <DialogContent
          style={{
            background: "var(--card)",
            borderColor: "var(--border)",
            borderRadius: "var(--radius)",
            padding: 0,
            overflow: "hidden",
          }}
        >
          <div
            className="border-b px-6 pt-5 pb-4"
            style={{ borderColor: "var(--border)" }}
          >
            <DialogTitle
              style={{
                fontFamily: "'Playfair Display', serif",
                color: "var(--foreground)",
                fontSize: "1.125rem",
              }}
            >
              Edit Photo
            </DialogTitle>
          </div>
          {editModal && (
            <div className="flex flex-col gap-4 p-6">
              <div className="flex items-start gap-4">
                <img
                  src={editModal.previewUrl}
                  alt={editModal.name}
                  className="h-20 w-20 shrink-0 object-cover"
                  style={{
                    borderRadius: "var(--radius-sm)",
                    border: "1px solid var(--border)",
                  }}
                />
                <div className="flex min-w-0 flex-col gap-1">
                  <p
                    className="text-xs"
                    style={{
                      color: "var(--muted-foreground)",
                      fontFamily: "'DM Mono', monospace",
                    }}
                  >
                    Photo Date
                  </p>
                </div>
              </div>
              <div>
                <Label
                  className="mb-1.5 block text-xs"
                  style={{
                    color: "var(--muted-foreground)",
                    fontFamily: "'DM Mono', monospace",
                  }}
                >
                  Title
                </Label>
                <Input
                  value={editForm.title}
                  onChange={(e) =>
                    setEditForm((f) => ({ ...f, title: e.target.value }))
                  }
                  style={{
                    background: "var(--input-background)",
                    border: "1px solid var(--border)",
                    color: "var(--foreground)",
                    borderRadius: "var(--radius-sm)",
                  }}
                />
              </div>
              <div>
                <Label
                  className="mb-1.5 block text-xs"
                  style={{
                    color: "var(--muted-foreground)",
                    fontFamily: "'DM Mono', monospace",
                  }}
                >
                  Event
                </Label>
                <div className="relative">
                  <select
                    value={editForm.eventId}
                    onChange={(e) =>
                      setEditForm((f) => ({ ...f, eventId: e.target.value }))
                    }
                    className="w-full appearance-none pr-8"
                    style={{
                      background: "var(--input-background)",
                      border: "1px solid var(--border)",
                      color: "var(--foreground)",
                      borderRadius: "var(--radius-sm)",
                      padding: "0.5rem 0.75rem",
                      fontFamily: "'Inter', sans-serif",
                      fontSize: "1rem",
                    }}
                  >
                    {data.events.nodes.map((ev) => (
                      <option key={ev!.id} value={ev!.id}>
                        {ev!.name}
                      </option>
                    ))}
                  </select>
                  <ChevronDown
                    className="pointer-events-none absolute top-1/2 right-2.5 h-3.5 w-3.5 -translate-y-1/2"
                    style={{ color: "var(--muted-foreground)" }}
                  />
                </div>
                {/* Show venue for selected event */}
                {(() => {
                  const ev = data.events.nodes.find(
                    (e) => e?.id === editForm.eventId,
                  );
                  const vn = data.venues.nodes.find(
                    (v) => v?.id === ev?.venue?.id,
                  );
                  return vn ? (
                    <p
                      className="mt-1 flex items-center gap-1 text-xs"
                      style={{
                        color: "var(--muted-foreground)",
                        fontFamily: "'DM Mono', monospace",
                      }}
                    >
                      <MapPin className="h-3 w-3" />
                      {vn.name} · {vn.city}
                    </p>
                  ) : null;
                })()}
              </div>
              <div>
                <Label
                  className="mb-1.5 block text-xs"
                  style={{
                    color: "var(--muted-foreground)",
                    fontFamily: "'DM Mono', monospace",
                  }}
                >
                  Price ($)
                </Label>
                <Input
                  type="number"
                  min="0"
                  step="0.01"
                  value={editForm.price}
                  onChange={(e) =>
                    setEditForm((f) => ({ ...f, price: e.target.value }))
                  }
                  style={{
                    background: "var(--input-background)",
                    border: "1px solid var(--border)",
                    color: "var(--foreground)",
                    borderRadius: "var(--radius-sm)",
                  }}
                />
              </div>
              <div className="flex gap-2 pt-1">
                <button
                  onClick={saveEdit}
                  className="flex-1 rounded py-2 text-sm"
                  style={{
                    background: "var(--primary)",
                    color: "var(--primary-foreground)",
                    borderRadius: "var(--radius-sm)",
                    fontFamily: "'Inter', sans-serif",
                  }}
                >
                  Save changes
                </button>
                <button
                  onClick={() => setEditModal(null)}
                  className="rounded px-4 py-2 text-sm"
                  style={{
                    background: "var(--secondary)",
                    color: "var(--foreground)",
                    borderRadius: "var(--radius-sm)",
                    border: "1px solid var(--border)",
                    fontFamily: "'Inter', sans-serif",
                  }}
                >
                  Cancel
                </button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* Bulk move modal */}
      <Dialog open={bulkModal} onOpenChange={() => setBulkModal(false)}>
        <DialogContent
          style={{
            background: "var(--card)",
            borderColor: "var(--border)",
            borderRadius: "var(--radius)",
            padding: 0,
            overflow: "hidden",
            maxWidth: "22rem",
          }}
        >
          <div
            className="border-b px-6 pt-5 pb-4"
            style={{ borderColor: "var(--border)" }}
          >
            <DialogTitle
              style={{
                fontFamily: "'Playfair Display', serif",
                color: "var(--foreground)",
                fontSize: "1.125rem",
              }}
            >
              Move {selected.size} photo{selected.size !== 1 ? "s" : ""} to
              event
            </DialogTitle>
          </div>
          <div className="flex flex-col gap-4 p-6">
            <div className="relative">
              <select
                value={bulkEventId}
                onChange={(e) => setBulkEventId(e.target.value)}
                className="w-full appearance-none pr-8"
                style={{
                  background: "var(--input-background)",
                  border: "1px solid var(--border)",
                  color: "var(--foreground)",
                  borderRadius: "var(--radius-sm)",
                  padding: "0.5rem 0.75rem",
                  fontFamily: "'Inter', sans-serif",
                  fontSize: "1rem",
                }}
              >
                {data.events.nodes.map((ev) => (
                  <option key={ev!.id} value={ev!.id}>
                    {ev!.name}
                  </option>
                ))}
              </select>
              <ChevronDown
                className="pointer-events-none absolute top-1/2 right-2.5 h-3.5 w-3.5 -translate-y-1/2"
                style={{ color: "var(--muted-foreground)" }}
              />
            </div>
            <div className="flex gap-2">
              <button
                onClick={applyBulkMove}
                className="flex-1 rounded py-2 text-sm"
                style={{
                  background: "var(--primary)",
                  color: "var(--primary-foreground)",
                  borderRadius: "var(--radius-sm)",
                  fontFamily: "'Inter', sans-serif",
                }}
              >
                Move photos
              </button>
              <button
                onClick={() => setBulkModal(false)}
                className="rounded px-4 py-2 text-sm"
                style={{
                  background: "var(--secondary)",
                  color: "var(--foreground)",
                  borderRadius: "var(--radius-sm)",
                  border: "1px solid var(--border)",
                  fontFamily: "'Inter', sans-serif",
                }}
              >
                Cancel
              </button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Delete confirm */}
      <Dialog
        open={deleteConfirm !== null}
        onOpenChange={() => setDeleteConfirm(null)}
      >
        <DialogContent
          style={{
            background: "var(--card)",
            borderColor: "var(--border)",
            borderRadius: "var(--radius)",
            padding: 0,
            overflow: "hidden",
            maxWidth: "22rem",
          }}
        >
          <div
            className="border-b px-6 pt-5 pb-4"
            style={{ borderColor: "var(--border)" }}
          >
            <DialogTitle
              style={{
                fontFamily: "'Playfair Display', serif",
                color: "var(--foreground)",
                fontSize: "1.125rem",
              }}
            >
              Delete photo?
            </DialogTitle>
          </div>
          <div className="flex flex-col gap-4 p-6">
            <p
              className="text-sm"
              style={{
                color: "var(--muted-foreground)",
                fontFamily: "'Inter', sans-serif",
              }}
            >
              This will permanently remove the photo from the archive.
            </p>
            <div className="flex gap-2">
              <button
                onClick={() => deleteConfirm && handleDelete(deleteConfirm)}
                className="flex-1 rounded py-2 text-sm"
                style={{
                  background: "var(--destructive)",
                  color: "var(--destructive-foreground)",
                  borderRadius: "var(--radius-sm)",
                  fontFamily: "'Inter', sans-serif",
                }}
              >
                Delete
              </button>
              <button
                onClick={() => setDeleteConfirm(null)}
                className="rounded px-4 py-2 text-sm"
                style={{
                  background: "var(--secondary)",
                  color: "var(--foreground)",
                  borderRadius: "var(--radius-sm)",
                  border: "1px solid var(--border)",
                  fontFamily: "'Inter', sans-serif",
                }}
              >
                Cancel
              </button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
