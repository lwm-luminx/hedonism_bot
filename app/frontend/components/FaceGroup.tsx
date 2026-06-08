import {User} from "lucide-react";
import Face from './Face'

import {useState} from "react";
import {graphql, useFragment} from "react-relay";
import {FaceFragment_faces$key} from "./__generated__/FaceFragment_faces.graphql";

const FACES_FRAGMENT = graphql`
    fragment FaceFragment_faces on FaceConnection {
        nodes {
            id
            ...FaceFragment_face
        }
    }
`

interface FaceGroupProps {
    faces: FaceFragment_faces$key
    selectedFaceId: string | null;
    onSelect: (faceId: string | null) => void;
}

export function FaceGroup({faces, selectedFaceId, onSelect}: FaceGroupProps) {
    let [faceId, setFaceId] = useState<string | null>(selectedFaceId);
    const data = useFragment(FACES_FRAGMENT, faces);
    return data ? (
        <div className="flex flex-col gap-2">
            <p
                className="text-xs uppercase tracking-widest mb-1"
                style={{color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace"}}
            >
                People
            </p>
            {/* All photos option */}
            <button
                className="flex items-center gap-2.5 px-2 py-1.5 rounded transition-colors text-left"
                style={{
                    background: faceId === null ? "rgba(201,169,110,0.12)" : "transparent",
                    color: faceId === null ? "var(--primary)" : "var(--foreground)",
                    borderRadius: "var(--radius-sm)",
                }}
                onClick={() => {
                    setFaceId(null);
                    onSelect?.(null);
                }
                }>
                <div className="w-8 h-8 rounded-full flex items-center justify-center shrink-0"
                     style={{background: "var(--muted)"}}>
                    <User className="w-4 h-4" style={{color: "var(--muted-foreground)"}}/>
                </div>
                <div className="min-w-0">
                    <p className="text-sm truncate" style={{fontFamily: "'Inter', sans-serif"}}>
                        All Photos
                    </p>
                </div>
            </button>

            {data.nodes?.map(face => face ? (
                <Face key={face!.id} face={face!} selected={faceId === face!.id} onSelect={() => {
                    setFaceId(face!.id);
                    onSelect?.(face!.id)
                }}/>
            ) : null)}
        </div>
    ) : null;
}
