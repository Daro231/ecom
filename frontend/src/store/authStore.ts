import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import Cookies from "js-cookie";
import type { User } from "@/types";
import { AUTH_STORAGE_KEY, ROLE_COOKIE, TOKEN_COOKIE } from "@/lib/constants";

interface AuthState {
  token: string | null;
  user: User | null;
  hydrated: boolean;
  setAuth: (token: string, user: User) => void;
  setUser: (user: User) => void;
  clear: () => void;
}

const cookieOpts = { sameSite: "lax" as const, expires: 1, path: "/" };

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      user: null,
      hydrated: false,
      setAuth: (token, user) => {
        Cookies.set(TOKEN_COOKIE, token, cookieOpts);
        Cookies.set(ROLE_COOKIE, user.role, cookieOpts);
        set({ token, user });
      },
      setUser: (user) => {
        Cookies.set(ROLE_COOKIE, user.role, cookieOpts);
        set({ user });
      },
      clear: () => {
        Cookies.remove(TOKEN_COOKIE, { path: "/" });
        Cookies.remove(ROLE_COOKIE, { path: "/" });
        set({ token: null, user: null });
      },
    }),
    {
      name: AUTH_STORAGE_KEY,
      storage: createJSONStorage(() => localStorage),
      partialize: (s) => ({ token: s.token, user: s.user }),
      onRehydrateStorage: () => () => {
        useAuthStore.setState({ hydrated: true });
      },
    },
  ),
);

export const isStaffRole = (role?: string) => role === "ADMIN" || role === "STAFF";
