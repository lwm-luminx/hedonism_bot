import { graphql, useLazyLoadQuery } from "react-relay";
import { PhotoCard } from "./PhotoCard";
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
}

export default function PhotoCollection({
  faceId,
  eventId,
  onSelect,
}: PhotoCollectionProps) {
  const data = useLazyLoadQuery<PhotosViewQuery>(PHOTOS_FRAGMENT, {
    faceId: faceId,
    folderId: eventId,
  });

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
      className="p-4 grid gap-3"
      style={{ gridTemplateColumns: `repeat(${4}, minmax(0, 1fr))` }}
    >
      {photo_cards}
    </div>
  );
}
