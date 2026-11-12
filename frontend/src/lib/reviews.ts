import type { Order, Review } from "@/types";

/** The API has no "can I review" endpoint: derive it from delivered orders + the reviews list. */
export function canReview(orders: Order[] | undefined, productId: number, reviews: Review[] | undefined, userId?: number): boolean {
  if (!orders || !userId) return false;
  const delivered = orders.some((o) => o.status === "DELIVERED" && o.items.some((i) => i.productId === productId));
  const already = (reviews ?? []).some((r) => r.userId === userId);
  return delivered && !already;
}
