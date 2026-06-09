import {graphql, useFragment} from "react-relay";
import {ImageWithFallback} from "./ImageWithFallback";
import {cva} from "class-variance-authority";
import {FaceFragment_face$key} from "./__generated__/FaceFragment_face.graphql";

const FACE_FRAGMENT = graphql`
    fragment FaceFragment_face on Face {
        id
        thumbnailUrl
        photoCount
    }
`

const faceImageVariants = cva("w-8 h-8 rounded-full overflow-hidden shrink-0 ring-1", {
    variants: {
        selected: {
            true: "ring-current outline-2",
            false: "ring-transparent outline-transparent"
        }
    }
});

const faceButtonVariants = cva("flex items-center gap-2.5 px-2 py-1.5 rounded-sm transition-colors text-left", {
    variants: {
        selected: {
            true: "bg-[rgba(201,169,110,0.12)] text-primary",
            false: "bg-transparent text-foreground"
        }
    }
});

interface FaceProps {
    face: FaceFragment_face$key;
    selected: boolean;
    onSelect?: (faceId: string) => void;
}

export default function Face({face, onSelect, selected}: FaceProps) {
    const data = useFragment(FACE_FRAGMENT, face);

    const faceImage = data.thumbnailUrl ?
        <ImageWithFallback
            src={data.thumbnailUrl}
            className="w-full h-full object-cover object-top"
        /> : null


    return (
        <button className={faceButtonVariants({ selected: selected })} onClick={() => { if (onSelect) {onSelect(data.id)}}}>
            <div className={faceImageVariants({ selected: selected })}>
                { faceImage }
            </div>
            <div className="min-w-0 flex-1">
                <p className="text-sm truncate" style={{ fontFamily: "'Inter', sans-serif" }}>
                    Person X
                </p>
                <p className="text-xs" style={{ color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace" }}>
                    {data.photoCount} photos
                </p>
            </div>
        </button>
    )
}