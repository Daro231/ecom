import "@testing-library/jest-dom/vitest";
import { afterEach, vi } from "vitest";
import { cleanup } from "@testing-library/react";
import { mockNav } from "./nav";
import { useCheckoutStore } from "@/store/checkoutStore";
import { useBadgeStore } from "@/store/badgeStore";

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
  useCheckoutStore.getState().reset();
  useBadgeStore.getState().reset();
  mockNav.path = "/";
  mockNav.search = "";
  try { localStorage.clear(); sessionStorage.clear(); } catch { /* ignore */ }
});

class RO { observe() {} unobserve() {} disconnect() {} }
vi.stubGlobal("ResizeObserver", RO);
if (!window.matchMedia) {
  window.matchMedia = ((q: string) => ({ matches: false, media: q, addEventListener() {}, removeEventListener() {}, addListener() {}, removeListener() {}, onchange: null, dispatchEvent: () => false })) as typeof window.matchMedia;
}
Element.prototype.scrollIntoView = vi.fn();
Element.prototype.hasPointerCapture = vi.fn(() => false);
Element.prototype.releasePointerCapture = vi.fn();

vi.mock("next/navigation", async () => {
  const { mockNav } = await import("./nav");
  return {
    useRouter: () => mockNav.router,
    usePathname: () => mockNav.path,
    useSearchParams: () => new URLSearchParams(mockNav.search),
  };
});
vi.mock("next/image", () => ({
  // eslint-disable-next-line @next/next/no-img-element
  default: ({ src, alt, onError }: { src: string; alt: string; onError?: () => void }) => <img src={src} alt={alt} onError={onError} />,
}));
