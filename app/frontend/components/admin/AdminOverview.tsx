import { graphql, useLazyLoadQuery } from "react-relay";
import { AdminOverviewQuery } from "./__generated__/AdminOverviewQuery.graphql";

const ADMIN_OVERVIEW_QUERY = graphql`
  query AdminOverviewQuery {
    photos {
      totalCount
      nodes {
        isPurchased
      }
    }
    events {
      totalCount
    }
    venues {
      totalCount
    }
  }
`;

export function AdminOverview() {
  const data = useLazyLoadQuery<AdminOverviewQuery>(ADMIN_OVERVIEW_QUERY, {});

  const photosPerEvent = [
    {
      row: {
        event: null,
      },
      event: {
        name: null,
        date: null,
        id: null,
      },
      venue: {
        name: null,
      },
      count: 0,
    },
  ];
  const stats = [{ label: null, icon: null, value: null }];

  return (
    <div className="flex flex-col gap-8 p-6">
      <div>
        <h2
          style={{
            fontFamily: "'Playfair Display', serif",
            color: "var(--foreground)",
            fontSize: "1.25rem",
          }}
        >
          Overview
        </h2>
        <p
          className="mt-1 text-xs"
          style={{
            color: "var(--muted-foreground)",
            fontFamily: "'DM Mono', monospace",
          }}
        >
          Summary of your archive
        </p>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        {stats.map((s) => (
          <button
            key={s.label}
            className="flex flex-col gap-3 border p-4 text-left transition-colors"
            style={{
              background: "var(--card)",
              borderColor: "var(--border)",
              borderRadius: "var(--radius-sm)",
            }}
            onMouseEnter={(e) =>
              (e.currentTarget.style.borderColor = "rgba(201,169,110,0.4)")
            }
            onMouseLeave={(e) =>
              (e.currentTarget.style.borderColor = "var(--border)")
            }
          >
            <span style={{ color: "var(--primary)" }}>{s.icon}</span>
            <div>
              <p
                style={{
                  fontFamily: "'Playfair Display', serif",
                  color: "var(--foreground)",
                  fontSize: "1.5rem",
                  lineHeight: 1,
                }}
              >
                {s.value}
              </p>
              <p
                className="mt-1 text-xs"
                style={{
                  color: "var(--muted-foreground)",
                  fontFamily: "'DM Mono', monospace",
                }}
              >
                {s.label}
              </p>
            </div>
          </button>
        ))}
      </div>

      {/* Events breakdown */}
      <div>
        <p
          className="mb-3 text-xs tracking-widest uppercase"
          style={{
            color: "var(--muted-foreground)",
            fontFamily: "'DM Mono', monospace",
          }}
        >
          Events breakdown
        </p>
        <div
          className="overflow-hidden border"
          style={{
            borderColor: "var(--border)",
            borderRadius: "var(--radius-sm)",
          }}
        >
          {photosPerEvent.map((row, i) => (
            <div
              key={row.event.id}
              className="flex items-center justify-between px-4 py-3"
              style={{
                borderTop: i > 0 ? "1px solid var(--border)" : "none",
                background: i % 2 === 0 ? "var(--card)" : "transparent",
              }}
            >
              <div className="flex flex-col gap-0.5">
                <span
                  style={{ color: "var(--foreground)", fontSize: "0.9375rem" }}
                >
                  {row.event.name}
                </span>
                <span
                  className="text-xs"
                  style={{
                    color: "var(--muted-foreground)",
                    fontFamily: "'DM Mono', monospace",
                  }}
                >
                  {row.event.date}
                  {row.venue ? ` · ${row.venue.name}` : " · No venue"}
                </span>
              </div>
              <div className="flex items-center gap-4">
                <span
                  className="text-xs"
                  style={{
                    color: "var(--muted-foreground)",
                    fontFamily: "'DM Mono', monospace",
                  }}
                >
                  {row.count} photo{row.count !== 1 ? "s" : ""}
                </span>
                {/* Bar */}
                <div
                  className="h-1 w-24 overflow-hidden rounded-full"
                  style={{ background: "var(--muted)" }}
                >
                  <div
                    className="h-full rounded-full"
                    style={{
                      width: `${Math.round((row.count / data.photos.totalCount) * 100)}%`,
                      background: "var(--primary)",
                    }}
                  />
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
