import React from "react";
import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import "@testing-library/jest-dom/vitest";
import { Badge } from "../Badge";

describe("Badge Component", () => {
  it("renders correctly with default variant", () => {
    render(<Badge>Default Badge</Badge>);
    const badge = screen.getByText("Default Badge");
    expect(badge).toBeInTheDocument();
    expect(badge.className).toContain("badge-default");
  });

  it("renders correctly with secondary variant", () => {
    render(<Badge variant="secondary">Secondary Badge</Badge>);
    const badge = screen.getByText("Secondary Badge");
    expect(badge).toBeInTheDocument();
    expect(badge.className).toContain("badge-secondary");
  });
});
