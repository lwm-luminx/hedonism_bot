import {graphql, useFragment} from "react-relay";
import {ImageWithFallback} from "./ImageWithCallback";
import {useState} from "react";
import {cva} from "class-variance-authority";
import {FaceFragment_face$key} from "./__generated__/FaceFragment_face.graphql";


const FACE_FRAGMENT = graphql`
    fragment FaceFragment_face on Face {
        id
        thumbnailUrl
        photoCount
    }
`

const faceGroupVariants = cva("w-8 h-8 rounded-full overflow-hidden shrink-0 ring-1", {
    variants: {
        selected: {
            true: "ring-current outline-2",
            false: "ring-transparent outline-transparent"
        }
    }
});

interface FaceProps {
    face: FaceFragment_face$key;
    selected: boolean;
    onSelect?: (faceId: string) => void;
}

export default function Face({face, onSelect, selected}: FaceProps) {
    let data = useFragment(FACE_FRAGMENT, face);
    return <button className="flex items-center gap-2.5 px-2 py-1.5 rounded transition-colors text-left"
        style={{
            background: selected ? "rgba(201,169,110,0.12)" : "transparent",
            color: selected ? "var(--primary)" : "var(--foreground)",
            borderRadius: "var(--radius-sm)",
        }}
        onClick={() => { if (onSelect) {onSelect(data?.id)}}}>
        <div className={faceGroupVariants({ selected: selected })}>
            {data.thumbnailUrl ?
                <ImageWithFallback
                    src={data.thumbnailUrl}
                    className="w-full h-full object-cover object-top"
                />
                : null
            }
        </div>
        <div className="min-w-0 flex-1">
            <p className="text-sm truncate" style={{ fontFamily: "'Inter', sans-serif" }}>

            </p>
            <p className="text-xs" style={{ color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace" }}>
                {data.photoCount} photos
            </p>
        </div>
    </button>
}