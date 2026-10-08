import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

describe("error reporting", () => {
  let beacon: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    vi.resetModules();
    vi.stubEnv("PROD", true);
    beacon = vi.fn(() => true);
    Object.defineProperty(navigator, "sendBeacon", {
      value: beacon,
      configurable: true,
    });
  });

  afterEach(() => vi.unstubAllEnvs());

  it("sends an error to /client_errors once", async () => {
    const { reportError } = await import("../../services/errorReporting");

    reportError(new TypeError("boom"), { kind: "boundary", component_stack: "at Gallery" });
    reportError(new TypeError("boom"), { kind: "boundary" });

    expect(beacon).toHaveBeenCalledTimes(1);
    const [url, body] = beacon.mock.calls[0];
    expect(url).toBe("/client_errors");
    expect(JSON.parse(body)).toMatchObject({
      kind: "boundary",
      message: "TypeError: boom",
      component_stack: "at Gallery",
    });
  });

  it("reports unhandled rejections", async () => {
    const { startErrorReporting } = await import("../../services/errorReporting");
    startErrorReporting();

    const event = new Event("unhandledrejection");
    Object.assign(event, { reason: "network down" });
    window.dispatchEvent(event);

    expect(JSON.parse(beacon.mock.calls[0][1])).toMatchObject({
      kind: "unhandledrejection",
      message: "network down",
    });
  });

  it("stays quiet outside production builds", async () => {
    vi.stubEnv("PROD", false);
    const { reportError } = await import("../../services/errorReporting");

    reportError(new Error("dev only"));

    expect(beacon).not.toHaveBeenCalled();
  });
});
