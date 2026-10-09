import { useState } from "react";
import { csrfToken } from "../../services/csrf";

type PairingCode = { code: string; expires_at: string; photographer: string };

export function DevicesPanel() {
  const [pairing, setPairing] = useState<PairingCode | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function generateCode() {
    setBusy(true);
    setError(null);
    setPairing(null);
    try {
      const response = await fetch("/admin/device_codes", {
        method: "POST",
        headers: { "X-CSRF-Token": csrfToken(), Accept: "application/json" },
      });
      if (!response.ok)
        throw new Error(
          "Could not create a pairing code. Check that you are signed in as this photographer’s admin.",
        );
      setPairing(await response.json());
    } catch (cause) {
      setError(
        cause instanceof Error ? cause.message : "Could not reach the server.",
      );
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="max-w-2xl space-y-6 p-8">
      <h1 className="text-2xl">Devices</h1>
      <section
        className="space-y-4 rounded-lg border p-6"
        style={{ borderColor: "var(--border)", background: "var(--card)" }}
      >
        <h2 className="text-xl">Connect Cogsworth</h2>
        <p>
          Connect the Mac uploader to this photographer with a one-use pairing
          code. You can also use this code in Chip.
        </p>
        <ol className="list-decimal space-y-2 pl-5">
          <li>Generate a code below.</li>
          <li>Open Cogsworth’s Settings and enter it in Device code.</li>
          <li>
            Choose Connect with device code and check the connected
            photographer.
          </li>
        </ol>
        <button
          className="rounded border px-4 py-2 disabled:opacity-50"
          onClick={generateCode}
          disabled={busy}
        >
          {busy ? "Generating…" : "Generate pairing code"}
        </button>
        {error && <p role="alert">{error}</p>}
        {pairing && (
          <div role="status" className="space-y-2">
            <p>
              Pair with <strong>{pairing.photographer}</strong>
            </p>
            <code className="block text-xl break-all select-all">
              {pairing.code}
            </code>
            <p>
              Expires at {new Date(pairing.expires_at).toLocaleTimeString()}.
              Each code works once.
            </p>
            <p>
              Keep this code private: anyone with it can connect an uploader to
              this photographer.
            </p>
          </div>
        )}
        <p className="text-sm">
          Prefer browser sign-in? Enter your photographer subdomain in Cogsworth
          Settings and choose Sign in via browser.
        </p>
      </section>
    </div>
  );
}
