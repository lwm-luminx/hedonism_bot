import { useState } from "react";
import { Archive, ArchiveRestore } from "lucide-react";
import { graphql, useLazyLoadQuery, useMutation } from "react-relay";
import { ArchiveConnections } from "./ArchiveConnections";
import { Button } from "../controls/Button";
import { StoragePanelQuery } from "./__generated__/StoragePanelQuery.graphql";
import { StoragePanelArchiveMutation } from "./__generated__/StoragePanelArchiveMutation.graphql";
import { StoragePanelRestoreMutation } from "./__generated__/StoragePanelRestoreMutation.graphql";

const STORAGE_PANEL_QUERY = graphql`
  query StoragePanelQuery {
    photographer {
      storage {
        totalBytes
        hotBytes
        archivedBytes
        archiveAvailable
        albums {
          albumId
          name
          photoCount
          bytes
          originalBytes
          archivedBytes
          transition
        }
      }
    }
  }
`;

const ARCHIVE_MUTATION = graphql`
  mutation StoragePanelArchiveMutation($id: ID!) {
    archiveAlbum(id: $id) {
      album {
        albumId
        transition
      }
    }
  }
`;

const RESTORE_MUTATION = graphql`
  mutation StoragePanelRestoreMutation($id: ID!) {
    restoreAlbum(id: $id) {
      album {
        albumId
        transition
      }
    }
  }
`;

const UNITS = ["B", "KB", "MB", "GB", "TB"];

// BigInt fields arrive as strings.
function formatBytes(value: string | number): string {
  let n = Number(value);
  let unit = 0;
  while (n >= 1000 && unit < UNITS.length - 1) {
    n /= 1000;
    unit += 1;
  }
  return `${unit === 0 ? n : n.toFixed(1)} ${UNITS[unit]}`;
}

const mono = { color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace" };

export function StoragePanel() {
  const [fetchKey, setFetchKey] = useState(0);
  const data = useLazyLoadQuery<StoragePanelQuery>(
    STORAGE_PANEL_QUERY,
    {},
    { fetchKey, fetchPolicy: "store-and-network" },
  );
  const [commitArchive] = useMutation<StoragePanelArchiveMutation>(ARCHIVE_MUTATION);
  const [commitRestore] = useMutation<StoragePanelRestoreMutation>(RESTORE_MUTATION);
  const [error, setError] = useState<string | null>(null);

  const storage = data.photographer.storage;
  const total = Number(storage.totalBytes);
  const archivedShare = total > 0 ? (Number(storage.archivedBytes) / total) * 100 : 0;

  const move = (albumId: string, direction: "archive" | "restore") => {
    setError(null);
    const commit = direction === "archive" ? commitArchive : commitRestore;
    commit({
      variables: { id: albumId },
      onCompleted: (_response, errors) => {
        if (errors?.length) setError(errors[0].message);
        setFetchKey((k) => k + 1);
      },
      onError: (e) => setError(e.message),
    });
  };

  return (
    <div className="flex flex-col gap-6 p-6">
      <div>
        <h2
          style={{
            fontFamily: "'Playfair Display', serif",
            color: "var(--foreground)",
            fontSize: "1.25rem",
          }}
        >
          Storage
        </h2>
        <p className="mt-1 text-xs" style={mono}>
          {formatBytes(storage.totalBytes)} stored · {formatBytes(storage.hotBytes)} standard ·{" "}
          {formatBytes(storage.archivedBytes)} archived
        </p>
      </div>

      <ArchiveConnections />

      <div
        className="h-2 w-full overflow-hidden"
        style={{ background: "var(--muted)", borderRadius: "var(--radius-sm)" }}
        role="img"
        aria-label={`${archivedShare.toFixed(0)}% archived`}
      >
        <div className="h-full" style={{ width: `${archivedShare}%`, background: "var(--primary)" }} />
      </div>

      {!storage.archiveAvailable && (
        <p className="text-xs" style={mono}>
          Archive storage is not set up, so albums cannot be moved yet. Set ARCHIVE_BUCKET_NAME and its keys
          on the server to enable it.
        </p>
      )}
      {error && (
        <p className="text-xs" role="alert" style={{ color: "var(--destructive)" }}>
          {error}
        </p>
      )}

      <div className="overflow-hidden border" style={{ borderColor: "var(--border)", borderRadius: "var(--radius-sm)" }}>
        {storage.albums.length === 0 && (
          <p className="px-4 py-3 text-xs" style={mono}>
            No albums yet.
          </p>
        )}
        {storage.albums.map((album, i) => {
          const original = Number(album.originalBytes);
          const archived = Number(album.archivedBytes);
          const fullyArchived = original > 0 && archived >= original;
          const busy = album.transition != null;
          return (
            <div
              key={album.albumId}
              className="flex items-center justify-between gap-4 px-4 py-3"
              style={{
                borderTop: i > 0 ? "1px solid var(--border)" : "none",
                background: i % 2 === 0 ? "var(--card)" : "transparent",
              }}
            >
              <div className="flex min-w-0 flex-col gap-0.5">
                <span className="truncate" style={{ color: "var(--foreground)", fontSize: "0.9375rem" }}>
                  {album.name}
                </span>
                <span className="text-xs" style={mono}>
                  {album.photoCount} photos · {formatBytes(album.bytes)}
                  {archived > 0 && ` · ${formatBytes(archived)} archived`}
                </span>
              </div>
              {busy ? (
                <span className="text-xs" style={mono}>
                  {album.transition === "ARCHIVING" ? "Archiving…" : "Restoring…"}
                </span>
              ) : fullyArchived ? (
                <Button
                  variant="outline"
                  size="sm"
                  disabled={!storage.archiveAvailable}
                  onClick={() => move(album.albumId, "restore")}
                >
                  <ArchiveRestore />
                  Restore
                </Button>
              ) : (
                <Button
                  variant="outline"
                  size="sm"
                  disabled={!storage.archiveAvailable || original === 0}
                  onClick={() => move(album.albumId, "archive")}
                >
                  <Archive />
                  Archive originals
                </Button>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
