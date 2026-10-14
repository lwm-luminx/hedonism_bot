import { useState } from "react";
import { graphql, useLazyLoadQuery, useMutation } from "react-relay";
import { AdminEventQuery } from "./__generated__/AdminEventQuery.graphql";
import { EventsPanelDeleteMutation } from "./__generated__/EventsPanelDeleteMutation.graphql";

const QUERY = graphql`
  query AdminEventQuery {
    folders {
      totalCount
      nodes {
        id
        name
        photoCount
      }
    }
  }
`;
const DELETE = graphql`
  mutation EventsPanelDeleteMutation($id: ID!) {
    deleteAlbum(id: $id) {
      deletedId
    }
  }
`;

export function EventsPanel() {
  const [fetchKey, setFetchKey] = useState(0);
  const data = useLazyLoadQuery<AdminEventQuery>(
    QUERY,
    {},
    { fetchKey, fetchPolicy: "network-only" },
  );
  const [commit, deleting] = useMutation<EventsPanelDeleteMutation>(DELETE);
  const [error, setError] = useState<string | null>(null);
  const [confirm, setConfirm] = useState<string | null>(null);

  const remove = (id: string) => {
    setError(null);
    commit({
      variables: { id },
      onCompleted: (_, errors) => {
        if (errors?.length) {
          setError(errors.map((e) => e.message).join("; "));
          return;
        }
        setConfirm(null);
        setFetchKey((key) => key + 1);
      },
      onError: (error) => setError(error.message),
    });
  };

  return (
    <div className="flex flex-col gap-6 p-6">
      <h2 className="text-xl">Events</h2>
      <p className="text-muted-foreground text-sm">
        {data.folders.totalCount} gallery albums
      </p>
      {error && (
        <p role="alert" className="text-destructive">
          {error}
        </p>
      )}
      {data.folders.totalCount === 0 && <p>No events yet</p>}
      {data.folders.nodes?.map(
        (album) =>
          album && (
            <div
              key={album.id}
              className="flex flex-col gap-3 rounded border p-4"
            >
              <div className="flex items-center justify-between gap-4">
                <div>
                  <p>{album.name}</p>
                  <p className="text-muted-foreground text-sm">
                    {album.photoCount} photos
                  </p>
                </div>
                <button
                  disabled={deleting}
                  onClick={() => {
                    setError(null);
                    setConfirm(album.id);
                  }}
                >
                  Delete
                </button>
              </div>
              {confirm === album.id && (
                <div className="flex flex-col gap-3">
                  <p>
                    This permanently deletes this event album and all its photos
                    and stored files.
                  </p>
                  <div className="flex gap-4">
                    <button
                      disabled={deleting}
                      onClick={() => remove(album.id)}
                    >
                      {deleting ? "Deleting…" : "Delete event and photos"}
                    </button>
                    <button
                      disabled={deleting}
                      onClick={() => setConfirm(null)}
                    >
                      Cancel
                    </button>
                  </div>
                </div>
              )}
            </div>
          ),
      )}
    </div>
  );
}
