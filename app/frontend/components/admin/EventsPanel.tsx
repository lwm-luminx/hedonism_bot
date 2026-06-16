import { useState } from "react";
import {
  CalendarDays,
  ChevronDown,
  Image,
  MapPin,
  Pencil,
  Plus,
  Trash2,
} from "lucide-react";
import { Dialog, DialogContent, DialogTitle } from "../controls/Dialog";
import { Label } from "../controls/Label";
import { Input } from "../controls/Input";
import { graphql, useLazyLoadQuery } from "react-relay";
import { AdminEventQuery } from "./__generated__/AdminEventQuery.graphql";

interface EventForm {
  name: string;
  date: string;
  venueId: string;
}

const ADMIN_EVENT_QUERY = graphql`
  query AdminEventQuery {
    events {
      totalCount
      nodes {
        id
        name
        date
        venue {
          id
        }
      }
    }
    venues {
      totalCount
      nodes {
        id
        name
        city
      }
    }
    photos {
      nodes {
        id
        event {
          id
        }
      }
    }
  }
`;

const emptyForm = (): EventForm => ({ name: "", date: "", venueId: "" });

export function EventsPanel() {
  const data = useLazyLoadQuery<AdminEventQuery>(ADMIN_EVENT_QUERY, {});
  const [modalMode, setModalMode] = useState<"create" | "edit" | null>(null);
  const [form, setForm] = useState<EventForm>(emptyForm());
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);
  const [errors, setErrors] = useState<Partial<EventForm>>({});

  const openCreate = () => {
    setForm(emptyForm());
    setErrors({});
    setModalMode("create");
  };

  const validate = (): boolean => {
    const e: Partial<EventForm> = {};
    if (!form.name.trim()) e.name = "Name is required";
    if (!form.date) e.date = "Date is required";
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const handleSave = () => {
    if (!validate()) return;

    setModalMode(null);
  };

  return (
    <div className="flex flex-col gap-6 p-6">
      <div className="flex items-center justify-between">
        <div>
          <h2
            style={{
              fontFamily: "'Playfair Display', serif",
              color: "var(--foreground)",
              fontSize: "1.25rem",
            }}
          >
            Events
          </h2>
          <p
            className="mt-1 text-xs"
            style={{
              color: "var(--muted-foreground)",
              fontFamily: "'DM Mono', monospace",
            }}
          >
            {data?.events?.totalCount} event
            {data?.events?.totalCount !== 1 ? "s" : ""}
          </p>
        </div>
        <button
          onClick={openCreate}
          className="flex items-center gap-2 px-3 py-1.5 text-sm transition-colors"
          style={{
            background: "var(--primary)",
            color: "var(--primary-foreground)",
            borderRadius: "var(--radius-sm)",
            fontFamily: "'Inter', sans-serif",
          }}
        >
          <Plus className="h-3.5 w-3.5" />
          New event
        </button>
      </div>

      {/* Event rows */}
      <div
        className="flex flex-col overflow-hidden border"
        style={{
          borderColor: "var(--border)",
          borderRadius: "var(--radius-sm)",
        }}
      >
        {data?.events?.totalCount === 0 && (
          <div className="py-12 text-center">
            <p
              style={{
                color: "var(--muted-foreground)",
                fontFamily: "'Playfair Display', serif",
              }}
            >
              No events yet
            </p>
          </div>
        )}
        {data?.events?.nodes?.map((ev, i) => {
          const venue = data?.venues?.nodes?.find(
            (v) => v?.id === ev?.venue?.id,
          );
          const photoCount = data?.photos?.nodes?.filter(
            (p) => p?.event?.id === ev?.id,
          ).length;
          return (
            <div
              key={ev?.id}
              className="flex items-center gap-4 px-4 py-3.5"
              style={{
                borderTop: i > 0 ? "1px solid var(--border)" : "none",
                background: i % 2 === 0 ? "var(--card)" : "transparent",
              }}
            >
              <CalendarDays
                className="h-4 w-4 shrink-0"
                style={{ color: "var(--primary)" }}
              />
              <div className="min-w-0 flex-1">
                <p
                  style={{ color: "var(--foreground)", fontSize: "0.9375rem" }}
                >
                  {ev?.name}
                </p>
                <div className="mt-0.5 flex flex-wrap items-center gap-3">
                  <span
                    className="text-xs"
                    style={{
                      color: "var(--muted-foreground)",
                      fontFamily: "'DM Mono', monospace",
                    }}
                  >
                    {ev?.date}
                  </span>
                  {venue ? (
                    <span
                      className="flex items-center gap-1 text-xs"
                      style={{
                        color: "var(--muted-foreground)",
                        fontFamily: "'DM Mono', monospace",
                      }}
                    >
                      <MapPin className="h-3 w-3" />
                      {venue.name}
                    </span>
                  ) : (
                    <span
                      className="text-xs"
                      style={{
                        color: "var(--muted-foreground)",
                        fontFamily: "'DM Mono', monospace",
                        opacity: 0.5,
                      }}
                    >
                      No venue
                    </span>
                  )}
                  <span
                    className="flex items-center gap-1 text-xs"
                    style={{
                      color: "var(--muted-foreground)",
                      fontFamily: "'DM Mono', monospace",
                    }}
                  >
                    <Image className="h-3 w-3" />
                    {photoCount} photo{photoCount !== 1 ? "s" : ""}
                  </span>
                </div>
              </div>
              <div className="flex shrink-0 items-center gap-1">
                <button
                  className="hover:bg-muted rounded p-1.5 transition-colors"
                  style={{
                    color: "var(--muted-foreground)",
                    borderRadius: "var(--radius-sm)",
                  }}
                  title="Edit"
                >
                  <Pencil className="h-3.5 w-3.5" />
                </button>
                <button
                  onClick={() => setDeleteConfirm(ev!.id)}
                  className="hover:bg-muted rounded p-1.5 transition-colors"
                  style={{
                    color: "var(--muted-foreground)",
                    borderRadius: "var(--radius-sm)",
                  }}
                  title="Delete"
                >
                  <Trash2 className="h-3.5 w-3.5" />
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* Create / Edit modal */}
      <Dialog open={modalMode !== null} onOpenChange={() => setModalMode(null)}>
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
              {modalMode === "create" ? "New Event" : "Edit Event"}
            </DialogTitle>
          </div>
          <div className="flex flex-col gap-4 p-6">
            <div>
              <Label
                className="mb-1.5 block text-xs"
                style={{
                  color: "var(--muted-foreground)",
                  fontFamily: "'DM Mono', monospace",
                }}
              >
                Event name *
              </Label>
              <Input
                value={form.name}
                onChange={(e) =>
                  setForm((f) => ({ ...f, name: e.target.value }))
                }
                placeholder="Annual Gala 2025"
                style={{
                  background: "var(--input-background)",
                  border: `1px solid ${errors.name ? "var(--destructive)" : "var(--border)"}`,
                  color: "var(--foreground)",
                  borderRadius: "var(--radius-sm)",
                }}
              />
              {errors.name && (
                <p
                  className="mt-1 text-xs"
                  style={{ color: "var(--destructive)" }}
                >
                  {errors.name}
                </p>
              )}
            </div>
            <div>
              <Label
                className="mb-1.5 block text-xs"
                style={{
                  color: "var(--muted-foreground)",
                  fontFamily: "'DM Mono', monospace",
                }}
              >
                Date *
              </Label>
              <Input
                type="date"
                value={form.date}
                onChange={(e) =>
                  setForm((f) => ({ ...f, date: e.target.value }))
                }
                style={{
                  background: "var(--input-background)",
                  border: `1px solid ${errors.date ? "var(--destructive)" : "var(--border)"}`,
                  color: "var(--foreground)",
                  borderRadius: "var(--radius-sm)",
                  colorScheme: "dark",
                }}
              />
              {errors.date && (
                <p
                  className="mt-1 text-xs"
                  style={{ color: "var(--destructive)" }}
                >
                  {errors.date}
                </p>
              )}
            </div>
            <div>
              <Label
                className="mb-1.5 block text-xs"
                style={{
                  color: "var(--muted-foreground)",
                  fontFamily: "'DM Mono', monospace",
                }}
              >
                Venue
              </Label>
              <div className="relative">
                <select
                  value={form.venueId}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, venueId: e.target.value }))
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
                  <option value="">— No venue —</option>
                  {data?.venues?.nodes?.map(
                    (v) =>
                      v && (
                        <option key={v.id} value={v.id}>
                          {v.name} · {v.city}
                        </option>
                      ),
                  )}
                </select>
                <ChevronDown
                  className="pointer-events-none absolute top-1/2 right-2.5 h-3.5 w-3.5 -translate-y-1/2"
                  style={{ color: "var(--muted-foreground)" }}
                />
              </div>
            </div>
            <div className="flex gap-2 pt-1">
              <button
                onClick={handleSave}
                className="flex-1 rounded py-2 text-sm transition-colors"
                style={{
                  background: "var(--primary)",
                  color: "var(--primary-foreground)",
                  borderRadius: "var(--radius-sm)",
                  fontFamily: "'Inter', sans-serif",
                }}
              >
                {modalMode === "create" ? "Create event" : "Save changes"}
              </button>
              <button
                onClick={() => setModalMode(null)}
                className="rounded px-4 py-2 text-sm transition-colors"
                style={{
                  background: "var(--secondary)",
                  color: "var(--foreground)",
                  borderRadius: "var(--radius-sm)",
                  fontFamily: "'Inter', sans-serif",
                  border: "1px solid var(--border)",
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
              Delete event?
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
              This will remove the event. Photos assigned to it will remain but
              will have no event.
            </p>
            <div className="flex gap-2">
              <button
                onClick={() => deleteConfirm}
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
