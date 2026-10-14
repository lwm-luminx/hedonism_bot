import "@testing-library/jest-dom/vitest";
import "jsdom";
import { vi } from "vitest";

// @ts-ignore
(global as any).jest = vi;
