import { Suspense, useDeferredValue, useState } from "react";
import { graphql, useLazyLoadQuery, useMutation } from "react-relay";
import { Dialog, DialogContent, DialogTitle } from "../controls/Dialog";
import { Input } from "../controls/Input";
import { AudienceKitLinksCatalogQuery } from "./__generated__/AudienceKitLinksCatalogQuery.graphql";
import { AudienceKitLinksLinkMutation } from "./__generated__/AudienceKitLinksLinkMutation.graphql";
import { AudienceKitLinksUnlinkMutation } from "./__generated__/AudienceKitLinksUnlinkMutation.graphql";

// The AudienceKit venues and events an album can go on: AudienceKit decides which the photographer may see (the
// audiences that connected them, in the metros their grant allows).
const CATALOG = graphql`
  query AudienceKitLinksCatalogQuery($query: String) {
    audienceKitCatalog(query: $query) {
      id
      name
      events {
        id
        name
        startAt
        venueId
        isCanceled
      }
      venues {
        id
        name
        address
        locale
      }
    }
  }
`;
const LINK = graphql`
  mutation AudienceKitLinksLinkMutation(
    $folderId: ID!
    $audienceId: ID!
    $eventId: ID
    $venueId: ID
  ) {
    linkAlbumToAudienceKit(
      folderId: $folderId
      audienceId: $audienceId
      eventId: $eventId
      venueId: $venueId
    ) {
      link {
        audienceId
      }
    }
  }
`;
const UNLINK = graphql`
  mutation AudienceKitLinksUnlinkMutation($folderId: ID!, $audienceId: ID!) {
    unlinkAlbumFromAudienceKit(folderId: $folderId, audienceId: $audienceId) {
      folder {
        id
      }
    }
  }
`;

export type AudienceKitLink = {
  readonly audienceId: string;
  readonly audienceName: string | null | undefined;
  readonly venueName: string | null | undefined;
  readonly eventName: string | null | undefined;
  readonly eventStartAt: string | null | undefined;
};

const when = (iso: string | null | undefined) =>
  iso
    ? new Date(iso).toLocaleDateString(undefined, {
        weekday: "short",
        month: "short",
        day: "numeric",
        year: "numeric",
      })
    : null;

type Pick = { audienceId: string; eventId?: string; venueId?: string };

function Catalog({
  query,
  busy,
  onPick,
}: {
  query: string;
  busy: boolean;
  onPick: (pick: Pick) => void;
}) {
  const data = useLazyLoadQuery<AudienceKitLinksCatalogQuery>(
    CATALOG,
    { query: query || null },
    { fetchPolicy: "store-and-network" },
  );
  if (data.audienceKitCatalog.length === 0) {
    return (
      <p className="text-muted-foreground text-sm">
        No AudienceKit audience has connected this photographer yet.
      </p>
    );
  }

  return (
    <div className="flex max-h-[60vh] flex-col gap-4 overflow-y-auto">
      {data.audienceKitCatalog.map((audience) => {
        const venues = new Map(audience.venues.map((venue) => [venue.id, venue]));
        return (
          <section key={audience.id} className="flex flex-col gap-2">
            <h3 className="font-medium">{audience.name}</h3>
            {audience.events.length === 0 && audience.venues.length === 0 && (
              <p className="text-muted-foreground text-sm">Nothing matches.</p>
            )}
            {audience.events.map((event) => (
              <button
                key={event.id}
                type="button"
                disabled={busy}
                className="flex flex-col items-start rounded border p-2 text-left"
                onClick={() => onPick({ audienceId: audience.id, eventId: event.id })}
              >
                <span>
                  {event.name}
                  {event.isCanceled && " (canceled)"}
                </span>
                <span className="text-muted-foreground text-sm">
                  {[when(event.startAt), event.venueId && venues.get(event.venueId)?.name]
                    .filter(Boolean)
                    .join(" · ")}
                </span>
              </button>
            ))}
            {query &&
              audience.venues.map((venue) => (
                <button
                  key={venue.id}
                  type="button"
                  disabled={busy}
                  className="flex flex-col items-start rounded border border-dashed p-2 text-left"
                  onClick={() => onPick({ audienceId: audience.id, venueId: venue.id })}
                >
                  <span>{venue.name} (venue, no event)</span>
                  <span className="text-muted-foreground text-sm">
                    {[venue.address, venue.locale].filter(Boolean).join(" · ")}
                  </span>
                </button>
              ))}
          </section>
        );
      })}
    </div>
  );
}

// An album's AudienceKit links, with a picker to add one and a button to remove each.
export function AudienceKitLinks({
  folderId,
  links,
  onChanged,
}: {
  folderId: string;
  links: ReadonlyArray<AudienceKitLink>;
  onChanged: () => void;
}) {
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState("");
  const query = useDeferredValue(search.trim());
  const [error, setError] = useState<string | null>(null);
  const [link, linking] = useMutation<AudienceKitLinksLinkMutation>(LINK);
  const [unlink, unlinking] = useMutation<AudienceKitLinksUnlinkMutation>(UNLINK);

  const done = (errors: ReadonlyArray<{ message: string }> | null | undefined) => {
    if (errors?.length) {
      setError(errors.map((e) => e.message).join("; "));
      return;
    }
    setOpen(false);
    onChanged();
  };

  const pick = (choice: Pick) => {
    setError(null);
    link({
      variables: { folderId, ...choice },
      onCompleted: (_, errors) => done(errors),
      onError: (e) => setError(e.message),
    });
  };

  const remove = (audienceId: string) => {
    setError(null);
    unlink({
      variables: { folderId, audienceId },
      onCompleted: (_, errors) => done(errors),
      onError: (e) => setError(e.message),
    });
  };

  return (
    <div className="flex flex-col gap-2">
      {links.map((item) => (
        <div key={item.audienceId} className="flex items-center justify-between gap-4 text-sm">
          <span>
            {item.audienceName ?? "AudienceKit"}:{" "}
            {[item.eventName, when(item.eventStartAt), item.venueName].filter(Boolean).join(" · ")}
          </span>
          <button disabled={unlinking} onClick={() => remove(item.audienceId)}>
            Unlink
          </button>
        </div>
      ))}
      <div>
        <button
          onClick={() => {
            setError(null);
            setOpen(true);
          }}
        >
          {links.length ? "Link to another event" : "Link to an AudienceKit event"}
        </button>
      </div>
      {error && !open && (
        <p role="alert" className="text-destructive text-sm">
          {error}
        </p>
      )}
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogTitle>Link album to an event</DialogTitle>
          <p className="text-muted-foreground text-sm">
            Its published photos show on the event and venue in that audience&apos;s apps within the hour. Search
            for a venue when the night has no listed event.
          </p>
          <Input
            placeholder="Search events and venues"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          {error && (
            <p role="alert" className="text-destructive text-sm">
              {error}
            </p>
          )}
          <Suspense fallback={<p className="text-muted-foreground text-sm">Loading AudienceKit…</p>}>
            <Catalog query={query} busy={linking} onPick={pick} />
          </Suspense>
        </DialogContent>
      </Dialog>
    </div>
  );
}
