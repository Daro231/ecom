import { Suspense } from "react";
import type { Metadata } from "next";
import { ProductsView } from "@/components/store/products-view";

export const metadata: Metadata = { title: "Shop" };
export default function ProductsPage() {
  return (
    <Suspense fallback={null}>
      <ProductsView />
    </Suspense>
  );
}
