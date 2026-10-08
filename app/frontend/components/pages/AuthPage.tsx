import { ReactNode, useEffect, useState } from "react";
import { Camera } from "lucide-react";
import { csrfToken } from "../../services/csrf";

export type SessionUser = {
  name: string | null;
  facebook_id: string;
  admin: boolean;
};

export async function signOut() {
  await fetch("/auth/session", {
    method: "DELETE",
    headers: { "X-CSRF-Token": csrfToken() },
  });
  window.location.assign("/admin");
}

// Shows the Facebook sign-in screen until an admin is signed in, then renders its children.
export function AuthGate({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<SessionUser | null>(null);
  const [loading, setLoading] = useState(true);
  const [signingIn, setSigningIn] = useState(false);
  const [error, setError] = useState<string | null>(() =>
    new URLSearchParams(window.location.search).get("auth_error"),
  );

  useEffect(() => {
    fetch("/auth/me", { headers: { Accept: "application/json" } })
      .then((response) => response.json())
      .then((body: { user: SessionUser | null }) => setUser(body.user))
      .catch(() => setError("Could not reach the server"))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div
        className="flex min-h-screen items-center justify-center"
        style={{ background: "var(--background)" }}
      >
        <div className="flex flex-col items-center gap-3">
          <Camera
            className="h-6 w-6 animate-pulse"
            style={{ color: "var(--primary)" }}
          />
          <p
            className="text-sm"
            style={{
              color: "var(--muted-foreground)",
              fontFamily: "'DM Mono', monospace",
            }}
          >
            Loading…
          </p>
        </div>
      </div>
    );
  }

  if (user?.admin) {
    return <>{children}</>;
  }

  return (
    <div
      className="flex min-h-screen items-center justify-center px-4"
      style={{ background: "var(--background)" }}
    >
      {/* Subtle background texture */}
      <div
        className="pointer-events-none absolute inset-0"
        style={{
          backgroundImage:
            "radial-gradient(ellipse 80% 60% at 50% 0%, rgba(201,169,110,0.07) 0%, transparent 70%)",
        }}
      />

      <div
        className="relative flex w-full max-w-sm flex-col gap-8 border p-8"
        style={{
          background: "var(--card)",
          borderColor: "var(--border)",
          borderRadius: "var(--radius)",
        }}
      >
        {/* Logo */}
        <div className="flex flex-col items-center gap-3 text-center">
          <div
            className="flex h-11 w-11 items-center justify-center rounded"
            style={{
              background: "rgba(201,169,110,0.12)",
              borderRadius: "var(--radius-sm)",
            }}
          >
            <Camera className="h-5 w-5" style={{ color: "var(--primary)" }} />
          </div>
          <div>
            <h1
              style={{
                fontFamily: "'Playfair Display', serif",
                color: "var(--foreground)",
                fontSize: "1.375rem",
                lineHeight: 1.3,
              }}
            >
              Lumière Archive
            </h1>
            <p
              className="mt-1 text-xs"
              style={{
                color: "var(--muted-foreground)",
                fontFamily: "'DM Mono', monospace",
              }}
            >
              Admin
            </p>
          </div>
        </div>

        <div className="h-px" style={{ background: "var(--border)" }} />

        {user ? (
          <div className="flex flex-col gap-3 text-center">
            <p
              className="text-sm"
              style={{
                color: "var(--foreground)",
                fontFamily: "'Inter', sans-serif",
              }}
            >
              {user.name ?? "This account"} doesn&apos;t have admin access.
            </p>
            <p
              className="text-xs"
              style={{
                color: "var(--muted-foreground)",
                fontFamily: "'DM Mono', monospace",
                lineHeight: 1.6,
              }}
            >
              Ask an admin to run
              <br />
              admins:grant[{user.facebook_id},{window.location.hostname.split(".")[0]}]
            </p>
            <button
              onClick={signOut}
              className="mt-2 w-full border px-4 py-2.5 transition-colors"
              style={{
                borderColor: "var(--border)",
                borderRadius: "var(--radius-sm)",
                background: "var(--secondary)",
                color: "var(--foreground)",
                fontFamily: "'Inter', sans-serif",
                fontSize: "0.9375rem",
              }}
            >
              Sign out
            </button>
          </div>
        ) : (
          <form
            method="post"
            action="/auth/facebook"
            onSubmit={() => {
              setSigningIn(true);
              setError(null);
            }}
            className="flex flex-col gap-3"
          >
            <input
              type="hidden"
              name="authenticity_token"
              value={csrfToken()}
            />
            <p
              className="mb-1 text-center text-xs"
              style={{
                color: "var(--muted-foreground)",
                fontFamily: "'Inter', sans-serif",
              }}
            >
              Sign in to manage the gallery
            </p>

            <button
              type="submit"
              disabled={signingIn}
              className="flex w-full items-center justify-center gap-3 px-4 py-2.5 transition-opacity"
              style={{
                borderRadius: "var(--radius-sm)",
                background: "#1877F2",
                color: "#FFFFFF",
                fontFamily: "'Inter', sans-serif",
                fontSize: "0.9375rem",
                opacity: signingIn ? 0.7 : 1,
                cursor: signingIn ? "not-allowed" : "pointer",
              }}
            >
              {signingIn ? (
                <svg
                  className="h-4 w-4 animate-spin"
                  viewBox="0 0 24 24"
                  fill="none"
                >
                  <circle
                    className="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    strokeWidth="4"
                  />
                  <path
                    className="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8v8z"
                  />
                </svg>
              ) : (
                <svg
                  className="h-4 w-4"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                >
                  <path d="M24 12.07C24 5.41 18.63 0 12 0S0 5.4 0 12.07C0 18.1 4.39 23.1 10.13 24v-8.44H7.08v-3.49h3.04V9.41c0-3.02 1.8-4.7 4.54-4.7 1.31 0 2.68.24 2.68.24v2.97h-1.5c-1.5 0-1.96.93-1.96 1.89v2.26h3.32l-.53 3.5h-2.8V24C19.62 23.1 24 18.1 24 12.07" />
                </svg>
              )}
              Continue with Facebook
            </button>

            {error && (
              <p
                className="mt-1 text-center text-xs"
                style={{
                  color: "var(--destructive)",
                  fontFamily: "'DM Mono', monospace",
                }}
              >
                {error}
              </p>
            )}
          </form>
        )}
      </div>
    </div>
  );
}
