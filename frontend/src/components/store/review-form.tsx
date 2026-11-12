"use client";
import * as React from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/input";
import { StarInput } from "@/components/shared/rating";
import { reviewService } from "@/services/review";
import { ApiError, errorMessage } from "@/lib/api-error";

export function ReviewForm({ productId, productName, onDone }: { productId: number; productName?: string; onDone?: () => void }) {
  const qc = useQueryClient();
  const [rating, setRating] = React.useState(0);
  const [comment, setComment] = React.useState("");
  const m = useMutation({
    mutationFn: () => reviewService.create(productId, { rating, comment: comment.trim() || undefined }),
    onSuccess: () => {
      toast.success("Thanks for your review!");
      ["product", "reviews", "reviews-all", "products"].forEach((k) => qc.invalidateQueries({ queryKey: [k] }));
      onDone?.();
    },
    onError: (e) => toast.error(e instanceof ApiError && e.status === 409 ? "You have already reviewed this product" : errorMessage(e)),
  });
  return (
    <form
      aria-label={`Write a review${productName ? ` for ${productName}` : ""}`}
      onSubmit={(e) => { e.preventDefault(); if (rating > 0) m.mutate(); }}
      className="space-y-3 rounded-lg border bg-card p-4"
    >
      <h3 className="font-semibold">Write a review</h3>
      <StarInput value={rating} onChange={setRating} />
      <label htmlFor={`comment-${productId}`} className="sr-only">Your review</label>
      <Textarea id={`comment-${productId}`} placeholder="Share your experience (optional)" value={comment} onChange={(e) => setComment(e.target.value)} maxLength={1000} />
      <Button type="submit" disabled={rating === 0 || m.isPending}>{m.isPending ? "Submitting…" : "Submit review"}</Button>
      {rating === 0 && <p className="text-xs text-muted-foreground">Choose a star rating to submit.</p>}
    </form>
  );
}
