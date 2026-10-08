import React from "react";
import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import "@testing-library/jest-dom/vitest";
import { QueryBoundary, useRetryKey } from "../QueryBoundary";

function FailsFirstTime() {
  const attempt = useRetryKey();
  if (attempt === 0) throw new Error("GraphQL request failed (HTTP 500)");
  return <span>Loaded on attempt {attempt}</span>;
}

describe("QueryBoundary", () => {
  it("shows a retry instead of a blank page, and retries with a new key", () => {
    vi.spyOn(console, "error").mockImplementation(() => {});

    render(
      <div>
        <h1>Header stays</h1>
        <QueryBoundary message="Couldn't load photos.">
          <FailsFirstTime />
        </QueryBoundary>
      </div>,
    );

    expect(screen.getByText("Header stays")).toBeInTheDocument();
    expect(screen.getByRole("alert")).toHaveTextContent("Couldn't load photos.");

    fireEvent.click(screen.getByText("Try again"));

    expect(screen.getByText("Loaded on attempt 1")).toBeInTheDocument();
  });
});
