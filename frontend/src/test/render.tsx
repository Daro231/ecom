import * as React from "react";
import { render } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "sonner";
import { useAuthStore } from "@/store/authStore";
import type { User } from "@/types";
import { mockNav } from "./nav";

export function newClient() {
  return new QueryClient({ defaultOptions: { queries: { retry: false, gcTime: 0, staleTime: 0 }, mutations: { retry: false } } });
}

export function signIn(user: User | null) {
  useAuthStore.setState(user ? { token: "test-token", user, hydrated: true } : { token: null, user: null, hydrated: true });
}

/** Render inside the REAL layout: the store layout (header + footer) or the admin shell (sidebar). */
export async function renderIn(layout: "store" | "admin" | "none", ui: React.ReactNode, opts: { user?: User | null; path?: string } = {}) {
  signIn(opts.user === undefined ? null : opts.user);
  if (opts.path) mockNav.path = opts.path;
  const client = newClient();
  let wrapped: React.ReactNode = ui;
  if (layout === "store") {
    const { default: StoreLayout } = await import("@/app/(store)/layout");
    wrapped = <StoreLayout>{ui}</StoreLayout>;
  } else if (layout === "admin") {
    const { default: AdminLayout } = await import("@/app/admin/layout");
    wrapped = <AdminLayout>{ui}</AdminLayout>;
  }
  return { client, ...render(<QueryClientProvider client={client}>{wrapped}<Toaster /></QueryClientProvider>) };
}
