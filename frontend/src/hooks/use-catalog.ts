import { useQuery, keepPreviousData } from "@tanstack/react-query";
import { productService } from "@/services/product";
import type { ProductQuery } from "@/types";

export const useProducts = (q: ProductQuery, enabled = true) =>
  useQuery({ queryKey: ["products", q], queryFn: () => productService.list(q), placeholderData: keepPreviousData, enabled });
export const useProductBySlug = (slug: string) =>
  useQuery({ queryKey: ["product", slug], queryFn: () => productService.bySlug(slug) });
export const useCategories = () =>
  useQuery({ queryKey: ["categories"], queryFn: productService.categories, staleTime: 5 * 60_000 });
export const useBrands = () =>
  useQuery({ queryKey: ["brands"], queryFn: productService.brands, staleTime: 5 * 60_000 });
export const useShippingMethods = () =>
  useQuery({ queryKey: ["shipping"], queryFn: productService.shippingMethods, staleTime: 5 * 60_000 });
export const useProductReviews = (id: number | undefined, page: number) =>
  useQuery({
    queryKey: ["reviews", id, page],
    queryFn: () => productService.reviews(id as number, page),
    enabled: !!id,
    placeholderData: keepPreviousData,
  });
