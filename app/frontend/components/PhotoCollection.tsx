import {graphql, useFragment} from "react-relay";
import {PhotoCard} from "./PhotoCard";
import {PhotoCollection_photos$key} from "./__generated__/PhotoCollection_photos.graphql";

const PHOTOS_FRAGMENT = graphql`
    fragment PhotoCollection_photos on Photo @relay(plural: true) {
        id
        ...PhotoFragment
    }
`;

export default function PhotoCollection({photos}: { photos: PhotoCollection_photos$key }) {
    const data = useFragment(PHOTOS_FRAGMENT, photos)

    const photo_cards = data.map(photo => {
            return <PhotoCard key={photo.id} photo={photo} />
        }
    );

    return <div className="p-4 grid gap-3" style={{gridTemplateColumns: `repeat(${3}, minmax(0, 1fr))`}}>
        {photo_cards}
    </div>
}