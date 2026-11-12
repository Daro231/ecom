import { vi } from "vitest";

export const mockNav = {
  path: "/",
  search: "",
  router: { push: vi.fn(), replace: vi.fn(), back: vi.fn(), refresh: vi.fn(), prefetch: vi.fn(), forward: vi.fn() },
};
