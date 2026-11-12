import { QueryClient } from "@tanstack/react-query";
import { ApiError } from "./api-error";

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      refetchOnWindowFocus: false,
      retry: (count, err) => {
        if (err instanceof ApiError && err.status >= 400 && err.status < 500) return false;
        return count < 1;
      },
    },
  },
});
