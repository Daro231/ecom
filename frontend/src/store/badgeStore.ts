import { create } from "zustand";

interface BadgeState {
  cartCount: number;
  unreadCount: number;
  setCartCount: (n: number) => void;
  setUnreadCount: (n: number) => void;
  reset: () => void;
}
export const useBadgeStore = create<BadgeState>((set) => ({
  cartCount: 0,
  unreadCount: 0,
  setCartCount: (cartCount) => set({ cartCount }),
  setUnreadCount: (unreadCount) => set({ unreadCount }),
  reset: () => set({ cartCount: 0, unreadCount: 0 }),
}));
