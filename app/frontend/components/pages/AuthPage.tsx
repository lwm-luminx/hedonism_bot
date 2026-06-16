import { useEffect, useState } from "react";
import { Camera } from "lucide-react";

export function AuthGate() {
  const [session, _setSession] = useState<string | null>(null);
  const [loading, _setLoading] = useState(true);
  const [signingIn, setSigningIn] = useState<"google" | "github" | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {}, []);

  const signInWith = async (provider: "google" | "github") => {
    setSigningIn(provider);
    setError(null);
  };

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

  if (!session) {
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
                Professional Event Photography
              </p>
            </div>
          </div>

          <div className="h-px" style={{ background: "var(--border)" }} />

          {/* Sign-in options */}
          <div className="flex flex-col gap-3">
            <p
              className="mb-1 text-center text-xs"
              style={{
                color: "var(--muted-foreground)",
                fontFamily: "'Inter', sans-serif",
              }}
            >
              Sign in to view and purchase your event photos
            </p>

            <button
              disabled={signingIn !== null}
              onClick={() => signInWith("google")}
              className="flex w-full items-center justify-center gap-3 border px-4 py-2.5 transition-colors"
              style={{
                borderColor: "var(--border)",
                borderRadius: "var(--radius-sm)",
                background:
                  signingIn === "google"
                    ? "rgba(201,169,110,0.08)"
                    : "var(--secondary)",
                color: "var(--foreground)",
                fontFamily: "'Inter', sans-serif",
                fontSize: "0.9375rem",
                opacity: signingIn && signingIn !== "google" ? 0.5 : 1,
                cursor: signingIn !== null ? "not-allowed" : "pointer",
              }}
            >
              {signingIn === "google" ? (
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
                <svg className="h-4 w-4" viewBox="0 0 24 24">
                  <path
                    fill="#4285F4"
                    d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                  />
                  <path
                    fill="#34A853"
                    d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                  />
                  <path
                    fill="#FBBC05"
                    d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z"
                  />
                  <path
                    fill="#EA4335"
                    d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                  />
                </svg>
              )}
              Continue with Google
            </button>

            <button
              disabled={signingIn !== null}
              onClick={() => signInWith("github")}
              className="flex w-full items-center justify-center gap-3 border px-4 py-2.5 transition-colors"
              style={{
                borderColor: "var(--border)",
                borderRadius: "var(--radius-sm)",
                background:
                  signingIn === "github"
                    ? "rgba(201,169,110,0.08)"
                    : "var(--secondary)",
                color: "var(--foreground)",
                fontFamily: "'Inter', sans-serif",
                fontSize: "0.9375rem",
                opacity: signingIn && signingIn !== "github" ? 0.5 : 1,
                cursor: signingIn !== null ? "not-allowed" : "pointer",
              }}
            >
              Continue with GitHub
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
          </div>

          <p
            className="text-center text-xs"
            style={{
              color: "var(--muted-foreground)",
              fontFamily: "'Inter', sans-serif",
              lineHeight: 1.6,
            }}
          >
            By signing in you agree to our terms of service.
            <br />
            Your photos are private and only visible to you.
          </p>
        </div>
      </div>
    );
  }

  return <></>;
}
