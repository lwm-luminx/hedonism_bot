import { User } from "lucide-react";
import Face from './Face'
import {cva} from "class-variance-authority";
import {graphql, useLazyLoadQuery} from "react-relay";
import {FacesQuery} from "./__generated__/FacesQuery.graphql";
import {useState} from "react";

const FACES_QUERY = graphql`
    query FacesQuery {
        faces {
            nodes {
                id
                ...FaceFragment
            }
        }
    }
`;

interface FaceGroupProps {
    selectedFaceId: string | null;
    onSelect: (faceId: string | null) => void;
}

export function FaceGroup({ selectedFaceId, onSelect }: FaceGroupProps) {
    let data = useLazyLoadQuery<FacesQuery>(FACES_QUERY, {});
    let [faceId, setFaceId] = useState<string | null>(selectedFaceId);
    return (
        <div className="flex flex-col gap-2">
            <p
                className="text-xs uppercase tracking-widest mb-1"
                style={{ color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace" }}
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
                <div className="w-8 h-8 rounded-full flex items-center justify-center shrink-0" style={{ background: "var(--muted)" }}>
                    <User className="w-4 h-4" style={{ color: "var(--muted-foreground)" }} />
                </div>
                <div className="min-w-0">
                    <p className="text-sm truncate" style={{ fontFamily: "'Inter', sans-serif" }}>
                        All Photos
                    </p>
                </div>
            </button>

            {data.faces?.nodes?.map((face) => (
                <Face key={face!.id} face={face!} selected={faceId === face!.id} onSelect={() => { setFaceId(face!.id); onSelect?.(face!.id) }} />
            ))}
        </div>
    );
}
