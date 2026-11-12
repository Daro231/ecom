import { useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { errorMessage } from "@/lib/api-error";

/** Mutation helper: toast on success/error and invalidate query keys. */
export function useAdminAction<V, R>(fn: (v: V) => Promise<R>, opts: { success: string | ((r: R) => string); invalidate?: string[]; onError?: (e: unknown) => string | void }) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: fn,
    onSuccess: (r) => {
      toast.success(typeof opts.success === "function" ? opts.success(r) : opts.success);
      (opts.invalidate ?? []).forEach((k) => qc.invalidateQueries({ queryKey: [k] }));
    },
    onError: (e) => toast.error(opts.onError?.(e) || errorMessage(e)),
  });
}
