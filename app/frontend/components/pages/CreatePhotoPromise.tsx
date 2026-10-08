import { graphql, useMutation } from "react-relay";
import type { CreatePhotoPromiseMutation } from "./__generated__/CreatePhotoPromiseMutation.graphql";
import { ReactNode, Suspense, useEffect, useRef, useState } from "react";
import { Outlet, useNavigate, useParams } from "react-router";
import { Loader2 } from "lucide-react";

const CREATE_PHOTO_PROMISE_MUTATION = graphql`
  mutation CreatePhotoPromiseMutation {
    createPhotoPromise {
      promise {
        id
      }
    }
  }
`;

function Message({ children }: { children: ReactNode }) {
  return (
    <div
      className="flex min-h-screen items-center justify-center gap-2 text-sm"
      style={{ background: "var(--background)", color: "var(--muted-foreground)" }}
    >
      {children}
    </div>
  );
}

const loading = (
  <Message>
    <Loader2 className="h-4 w-4 animate-spin" /> Preparing upload…
  </Message>
);

// `/upload` starts an upload batch (a photo promise) and moves to `/upload/:promiseId`, which renders
// the upload page as this route's child.
export function CreatePhotoPromise() {
  const { promiseId } = useParams();
  const navigate = useNavigate();
  const [commitMutation] = useMutation<CreatePhotoPromiseMutation>(CREATE_PHOTO_PROMISE_MUTATION);
  const [error, setError] = useState<string | null>(null);
  const started = useRef(false);

  useEffect(() => {
    // The ref keeps StrictMode's double effect from starting two batches.
    if (promiseId || started.current) return;
    started.current = true;
    commitMutation({
      variables: {},
      onCompleted: (response, errors) => {
        const id = response.createPhotoPromise?.promise.id;
        if (id) navigate(`/upload/${id}`, { replace: true });
        else setError(errors?.[0]?.message ?? "Couldn't start an upload.");
      },
      onError: (e) => setError(e.message),
    });
  }, [promiseId]);

  if (error) return <Message>{error}</Message>;
  if (!promiseId) return loading;

  return (
    <Suspense fallback={loading}>
      <Outlet />
    </Suspense>
  );
}
