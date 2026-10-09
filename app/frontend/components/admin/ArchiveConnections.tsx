import { useEffect, useState } from "react";

type Connection = {
  id: number;
  device_name: string;
  paths: string[];
  last_seen_at: string;
};

export function ArchiveConnections() {
  const [connections, setConnections] = useState<Connection[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [now, setNow] = useState(Date.now());
  useEffect(() => {
    let cancelled = false;
    async function refresh() {
      try {
        const response = await fetch("/admin/archive_storage_connections", {
          headers: { Accept: "application/json" },
        });
        if (!response.ok)
          throw new Error("Could not load connected archive storage.");
        const body = await response.json();
        if (!cancelled) {
          setConnections(body.connections);
          setError(null);
          setNow(Date.now());
        }
      } catch (cause) {
        if (!cancelled)
          setError(
            cause instanceof Error
              ? cause.message
              : "Could not reach the server.",
          );
      }
    }
    void refresh();
    const timer = window.setInterval(() => void refresh(), 30000);
    return () => {
      cancelled = true;
      window.clearInterval(timer);
    };
  }, []);

  return (
    <section
      className="space-y-3 rounded border p-4"
      style={{ borderColor: "var(--border)" }}
    >
      <h3>Connected local archive storage</h3>
      <p className="text-sm">
        In Cogsworth, choose Connect archive storage to register folders on your
        Mac or mounted NAS. These connections report available folders; album
        archive transfers currently use the server’s configured archive bucket.
      </p>
      {error && <p role="alert">{error}</p>}
      {connections.length === 0 && !error && (
        <p className="text-sm">No local archive storage connected yet.</p>
      )}
      {connections.map((connection) => (
        <div key={connection.id} className="space-y-1">
          <p>
            <strong>{connection.device_name}</strong> ·{" "}
            {now - Date.parse(connection.last_seen_at) < 150000
              ? "Online"
              : "Offline"}
          </p>
          {connection.paths.length ? (
            <ul className="list-disc pl-5 text-sm">
              {connection.paths.map((path) => (
                <li key={path} className="break-all">
                  {path}
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm">No archive folders available.</p>
          )}
          <p className="text-xs">
            Last seen {new Date(connection.last_seen_at).toLocaleString()}
          </p>
        </div>
      ))}
    </section>
  );
}
