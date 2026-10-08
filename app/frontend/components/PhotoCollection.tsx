import { graphql, useLazyLoadQuery } from "react-relay";
import { PhotoCard } from "./PhotoCard";
import { useRetryKey } from "./QueryBoundary";
import { PhotosViewQuery } from "./__generated__/PhotosViewQuery.graphql";

const PHOTOS_FRAGMENT = graphql`
  query PhotosViewQuery($faceId: ID, $folderId: ID) {
    photos(faceId: $faceId, folderId: $folderId) {
      nodes {
        id
        ...PhotoFragment
      }
    }
  }
`;

interface PhotoCollectionProps {
  eventId: string | null;
  faceId: string | null;
  onSelect?: (photo: string) => void;
  /** Columns on wide screens; phones get 2 and tablets 3 regardless. */
  columns?: 3 | 4;
}

export default function PhotoCollection({
  faceId,
  eventId,
  onSelect,
  columns = 3,
}: PhotoCollectionProps) {
  const data = useLazyLoadQuery<PhotosViewQuery>(
    PHOTOS_FRAGMENT,
    { faceId: faceId, folderId: eventId },
    { fetchKey: useRetryKey() },
  );

  if (!data) {
    return null;
  }

  const photo_cards = data?.photos?.nodes?.map((photo) => {
    return (
      photo && (
        <PhotoCard
          key={photo.id}
          photo={photo}
          onSelect={(id) => onSelect?.(id)}
        />
      )
    );
  });

  return (
    <div
      className={`grid grid-cols-2 gap-2 p-2 sm:grid-cols-3 sm:gap-3 sm:p-4 ${
        columns === 4 ? "lg:grid-cols-4" : ""
      }`}
    >
      {photo_cards}
    </div>
  );
}
