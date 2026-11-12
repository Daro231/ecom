"use client";
import * as React from "react";
import { usePathname, useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { authService } from "@/services/auth";
import { useAuthStore, isStaffRole } from "@/store/authStore";
import { clearSession } from "@/lib/session";

/**
 * Client-side guard (middleware does the first pass). Re-checks on bfcache restore so the Back
 * button after logout can never reveal protected pages, and verifies the token with /users/me.
 */
export function AuthGuard({ children, staffOnly }: { children: React.ReactNode; staffOnly?: boolean }) {
  const router = useRouter();
  const path = usePathname();
  const { token, user, hydrated, setUser } = useAuthStore();

  React.useEffect(() => {
    const onShow = (e: PageTransitionEvent) => {
      if (e.persisted && !useAuthStore.getState().token) window.location.replace("/login");
    };
    window.addEventListener("pageshow", onShow);
    return () => window.removeEventListener("pageshow", onShow);
  }, []);

  React.useEffect(() => {
    if (!hydrated) return;
    if (!token) {
      clearSession();
      router.replace(`/login?redirect=${encodeURIComponent(path)}`);
    } else if (staffOnly && user && !isStaffRole(user.role)) {
      router.replace("/");
    }
  }, [hydrated, token, user, staffOnly, path, router]);

  const me = useQuery({ queryKey: ["me"], queryFn: authService.me, enabled: hydrated && !!token });
  React.useEffect(() => {
    if (me.data) setUser(me.data);
  }, [me.data, setUser]);

  if (!hydrated || !token) return null;
  if (staffOnly && (!user || !isStaffRole(user.role))) return null;
  return <>{children}</>;
}
