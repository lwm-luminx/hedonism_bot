import React from "react";
import { render } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import "@testing-library/jest-dom/vitest";
import { Separator } from "../Separator";

describe("Separator Component", () => {
  it("renders without crashing", () => {
    const { getByTestId } = render(
      <div data-testid="container">
        <Separator />
      </div>,
    );
    expect(getByTestId("container")).toBeInTheDocument();
  });
});
