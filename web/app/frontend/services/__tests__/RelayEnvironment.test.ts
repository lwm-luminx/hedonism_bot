import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { relayEnvironment } from "../RelayEnvironment";

beforeEach(() => {
  document.head.innerHTML = "";
  vi.stubGlobal("fetch", vi.fn());
});
afterEach(() => {
  document.head.innerHTML = "";
  vi.unstubAllGlobals();
});
async function execute() {
  return relayEnvironment
    .getNetwork()
    .execute(
      {
        name: "Upload",
        id: null,
        text: "mutation Upload { createPhotoPromise { promise { id } } }",
        operationKind: "mutation",
        metadata: {},
        cacheID: "upload",
      },
      { id: "promise" },
      {},
    )
    .toPromise();
}
describe("GraphQL transport", () => {
  it.each([true, false])(
    "sends JSON with CSRF token present=%s",
    async (tokenPresent) => {
      if (tokenPresent)
        document.head.innerHTML =
          '<meta name="csrf-token" content="csrf-test">';
      vi.mocked(fetch).mockResolvedValue(
        new Response(JSON.stringify({ data: { ok: true } }), { status: 200 }),
      );
      await expect(execute()).resolves.toEqual({ data: { ok: true } });
      expect(fetch).toHaveBeenCalledWith(
        "/graphql",
        expect.objectContaining({
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": tokenPresent ? "csrf-test" : "",
          },
        }),
      );
      const options = vi.mocked(fetch).mock.calls[0][1]!;
      expect(JSON.parse(options.body as string)).toEqual({
        query: expect.stringContaining("createPhotoPromise"),
        variables: { id: "promise" },
      });
    },
  );
  it.each([403, 422, 500])("rejects HTTP %s", async (status) => {
    vi.mocked(fetch).mockResolvedValue(new Response("Failed", { status }));
    await expect(execute()).rejects.toThrow(
      `GraphQL request failed: HTTP ${status}`,
    );
  });
  it("preserves network failures", async () => {
    vi.mocked(fetch).mockRejectedValue(new Error("Offline"));
    await expect(execute()).rejects.toThrow("Offline");
  });
  it("passes GraphQL errors to Relay without treating HTTP 200 as mutation success", async () => {
    const response = { errors: [{ message: "Upload not found" }] };
    vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify(response)));
    await expect(execute()).resolves.toEqual(response);
  });
});
