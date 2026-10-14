import React from "react";
import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import "@testing-library/jest-dom/vitest";
import { ScrollArea } from "../ScrollArea";

describe("ScrollArea Component", () => {
  it("renders children", () => {
    render(<ScrollArea>Test Content</ScrollArea>);
    expect(screen.getByText("Test Content")).toBeInTheDocument();
  });
});
