"use client";
import * as React from "react";
import { QueryClientProvider } from "@tanstack/react-query";
import { ThemeProvider } from "next-themes";
import { Toaster } from "sonner";
import { queryClient } from "@/lib/query-client";
import { useAuthStore } from "@/store/authStore";

export function Providers({ children }: { children: React.ReactNode }) {
  React.useEffect(() => {
    // Make sure persisted auth is read even if rehydration finished before mount.
    if (!useAuthStore.persist.hasHydrated()) void useAuthStore.persist.rehydrate();
    else useAuthStore.setState({ hydrated: true });
  }, []);
  return (
    <ThemeProvider attribute="class" defaultTheme="light" enableSystem disableTransitionOnChange>
      <QueryClientProvider client={queryClient}>
        {children}
        <Toaster richColors position="top-right" closeButton />
      </QueryClientProvider>
    </ThemeProvider>
  );
}
