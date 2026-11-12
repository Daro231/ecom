import { del, post, put } from "@/lib/api";
import type { Review } from "@/types";

export const reviewService = {
  create: (productId: number, b: { rating: number; comment?: string }) =>
    post<Review>(`/products/${productId}/reviews`, b),
  update: (id: number, b: { rating: number; comment?: string }) => put<Review>(`/reviews/${id}`, b),
  remove: (id: number) => del(`/reviews/${id}`),
};
