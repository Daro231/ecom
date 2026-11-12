import { queryClient } from "./query-client";
import { useAuthStore } from "@/store/authStore";
import { useBadgeStore } from "@/store/badgeStore";
import { useCheckoutStore, CHECKOUT_STORAGE_KEY } from "@/store/checkoutStore";
import { AUTH_STORAGE_KEY } from "./constants";

/** Wipe every trace of the signed-in user (token, cookies, persisted state, caches, badges). */
export function clearSession() {
  useAuthStore.getState().clear();
  try {
    localStorage.removeItem(AUTH_STORAGE_KEY);
    sessionStorage.removeItem(CHECKOUT_STORAGE_KEY);
  } catch {
    /* storage unavailable */
  }
  queryClient.clear();
  useBadgeStore.getState().reset();
  useCheckoutStore.getState().reset();
}

/** Full logout: clear everything and hard-replace the history entry with /login. */
export function logout() {
  clearSession();
  if (typeof window !== "undefined") window.location.replace("/login");
}
