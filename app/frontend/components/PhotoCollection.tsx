import {graphql, useFragment} from "react-relay";
import {PhotoCard} from "./PhotoCard";
import {PhotoCollection_photos$key} from "./__generated__/PhotoCollection_photos.graphql";

const PHOTOS_FRAGMENT = graphql`
    fragment PhotoCollection_photos on Photo @relay(plural: true) {
        id
        ...PhotoFragment
    }
`;

interface PhotoCollectionProps {
    photos: PhotoCollection_photos$key;
    onSelect?: (photo: string) => void;
}

export default function PhotoCollection({photos, onSelect}: PhotoCollectionProps) {
    const data = useFragment(PHOTOS_FRAGMENT, photos)

    const photo_cards = data?.map(photo => {
            return <PhotoCard key={photo.id} photo={photo} onSelect={(id) => onSelect?.(id)} />
        }
    );

    return <div className="p-4 grid gap-3" style={{gridTemplateColumns: `repeat(${4}, minmax(0, 1fr))`}}>
        {photo_cards}
    </div>
}