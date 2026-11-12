import { get } from "@/lib/api";
import type { Brand, Category, PageResponse, Product, ProductQuery, Review, ShippingMethod } from "@/types";

function clean(q: object) {
  return Object.fromEntries(Object.entries(q).filter(([, v]) => v !== undefined && v !== "" && v !== null));
}
export const productService = {
  list: (q: ProductQuery) => get<PageResponse<Product>>("/products", clean(q)),
  byId: (id: number) => get<Product>(`/products/${id}`),
  bySlug: (slug: string) => get<Product>(`/products/slug/${slug}`),
  categories: () => get<Category[]>("/categories"),
  brands: () => get<Brand[]>("/brands"),
  shippingMethods: () => get<ShippingMethod[]>("/shipping/methods"),
  reviews: (id: number, page = 0, size = 10) => get<PageResponse<Review>>(`/products/${id}/reviews`, { page, size }),
};
