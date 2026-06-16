import { useState } from "react";
import { Building2, CalendarDays, Pencil, Plus, Trash2 } from "lucide-react";
import { Dialog, DialogContent, DialogTitle } from "../controls/Dialog";
import { Input } from "../controls/Input";
import { Label } from "../controls/Label";
import { graphql, useLazyLoadQuery } from "react-relay";
import { AdminVenuesQuery } from "./__generated__/AdminVenuesQuery.graphql";

interface VenueForm {
  name: string;
  address: string;
  city: string;
}

const ADMIN_VENUES_QUERY = graphql`
  query AdminVenuesQuery {
    venues @required(action: THROW) {
      totalCount
      nodes @required(action: THROW) {
        id
        city
        name
        address
      }
    }
    events @required(action: THROW) {
      nodes @required(action: THROW) {
        id
        name
        venue {
          id
        }
      }
    }
  }
`;

const emptyForm = (): VenueForm => ({ name: "", address: "", city: "" });

export function VenuesPanel() {
  const data = useLazyLoadQuery<AdminVenuesQuery>(ADMIN_VENUES_QUERY, {});
  const [modalMode, setModalMode] = useState<"create" | "edit" | null>(null);

  const [form, setForm] = useState<VenueForm>(emptyForm());
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);
  const [errors, setErrors] = useState<Partial<VenueForm>>({});

  const openCreate = () => {
    setForm(emptyForm());
    setErrors({});

    setModalMode("create");
  };

  const validate = (): boolean => {
    const e: Partial<VenueForm> = {};
    if (!form.name.trim()) e.name = "Name is required";
    if (!form.city.trim()) e.city = "City is required";
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const handleSave = () => {
    if (!validate()) return;

    setModalMode(null);
  };

  const handleDelete = (_id: string) => {
    setDeleteConfirm(null);
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
            Venues
          </h2>
          <p
            className="mt-1 text-xs"
            style={{
              color: "var(--muted-foreground)",
              fontFamily: "'DM Mono', monospace",
            }}
          >
            {data.venues.totalCount} venue
            {data.venues.totalCount !== 1 ? "s" : ""}
          </p>
        </div>
        <button
          onClick={openCreate}
          className="flex items-center gap-2 px-3 py-1.5 text-sm"
          style={{
            background: "var(--primary)",
            color: "var(--primary-foreground)",
            borderRadius: "var(--radius-sm)",
            fontFamily: "'Inter', sans-serif",
          }}
        >
          <Plus className="h-3.5 w-3.5" />
          New venue
        </button>
      </div>

      <div
        className="flex flex-col overflow-hidden border"
        style={{
          borderColor: "var(--border)",
          borderRadius: "var(--radius-sm)",
        }}
      >
        {data.venues.totalCount === 0 && (
          <div className="py-12 text-center">
            <p
              style={{
                color: "var(--muted-foreground)",
                fontFamily: "'Playfair Display', serif",
              }}
            >
              No venues yet
            </p>
          </div>
        )}
        {data.venues.nodes.map((v, i) => {
          const linkedEvents = data.events.nodes.filter(
            (e) => e!.venue!.id === v!.id,
          );
          return (
            <div
              key={v!.id}
              className="flex items-center gap-4 px-4 py-3.5"
              style={{
                borderTop: i > 0 ? "1px solid var(--border)" : "none",
                background: i % 2 === 0 ? "var(--card)" : "transparent",
              }}
            >
              <Building2
                className="h-4 w-4 shrink-0"
                style={{ color: "var(--primary)" }}
              />
              <div className="min-w-0 flex-1">
                <p
                  style={{ color: "var(--foreground)", fontSize: "0.9375rem" }}
                >
                  {v!.name}
                </p>
                <div className="mt-0.5 flex flex-wrap items-center gap-3">
                  <span
                    className="text-xs"
                    style={{
                      color: "var(--muted-foreground)",
                      fontFamily: "'DM Mono', monospace",
                    }}
                  >
                    {v!.address ? `${v!.address}, ` : ""}
                    {v!.city}
                  </span>
                  {linkedEvents.length > 0 && (
                    <span
                      className="flex items-center gap-1 text-xs"
                      style={{
                        color: "var(--muted-foreground)",
                        fontFamily: "'DM Mono', monospace",
                      }}
                    >
                      <CalendarDays className="h-3 w-3" />
                      {linkedEvents.map((e) => e!.name).join(", ")}
                    </span>
                  )}
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
                  onClick={() => setDeleteConfirm(v!.id)}
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
              {modalMode === "create" ? "New Venue" : "Edit Venue"}
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
                Venue name *
              </Label>
              <Input
                value={form.name}
                onChange={(e) =>
                  setForm((f) => ({ ...f, name: e.target.value }))
                }
                placeholder="The Grand Ballroom"
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
                Address
              </Label>
              <Input
                value={form.address}
                onChange={(e) =>
                  setForm((f) => ({ ...f, address: e.target.value }))
                }
                placeholder="100 Harbor Blvd"
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
                City *
              </Label>
              <Input
                value={form.city}
                onChange={(e) =>
                  setForm((f) => ({ ...f, city: e.target.value }))
                }
                placeholder="San Francisco"
                style={{
                  background: "var(--input-background)",
                  border: `1px solid ${errors.city ? "var(--destructive)" : "var(--border)"}`,
                  color: "var(--foreground)",
                  borderRadius: "var(--radius-sm)",
                }}
              />
              {errors.city && (
                <p
                  className="mt-1 text-xs"
                  style={{ color: "var(--destructive)" }}
                >
                  {errors.city}
                </p>
              )}
            </div>
            <div className="flex gap-2 pt-1">
              <button
                onClick={handleSave}
                className="flex-1 rounded py-2 text-sm"
                style={{
                  background: "var(--primary)",
                  color: "var(--primary-foreground)",
                  borderRadius: "var(--radius-sm)",
                  fontFamily: "'Inter', sans-serif",
                }}
              >
                {modalMode === "create" ? "Create venue" : "Save changes"}
              </button>
              <button
                onClick={() => setModalMode(null)}
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
              Delete venue?
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
              Any events linked to this venue will have their venue cleared.
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
