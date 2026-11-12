import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { ProductImage } from "@/components/shared/product-image";
import { Stars } from "@/components/shared/rating";
import { formatUSD, stockLabel } from "@/lib/format";
import type { Product } from "@/types";

export function ProductCard({ p }: { p: Product }) {
  const stock = stockLabel(p.stockQuantity, p.lowStockThreshold);
  return (
    <Link
      href={`/products/${p.slug}`}
      data-testid="product-card"
      className="group flex flex-col overflow-hidden rounded-lg border bg-card shadow-sm transition hover:-translate-y-0.5 hover:shadow-md focus-visible:ring-2 focus-visible:ring-ring"
    >
      <ProductImage src={p.images?.[0]} alt={p.name} category={p.category.name} brand={p.brand.name} className="aspect-[4/3] w-full" />
      <div className="flex flex-1 flex-col gap-1.5 p-3">
        <span className="text-xs font-medium uppercase tracking-wide text-muted-foreground">{p.brand.name}</span>
        <h3 className="line-clamp-2 text-sm font-semibold group-hover:text-primary">{p.name}</h3>
        <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
          <Stars value={p.averageRating} size={14} />
          <span>({p.reviewCount})</span>
        </div>
        <div className="mt-auto flex items-center justify-between pt-1">
          <span className="text-lg font-bold">{formatUSD(p.price)}</span>
          {stock.tone === "out" && <Badge tone="red">Out of stock</Badge>}
          {stock.tone === "low" && <Badge tone="amber">{stock.text}</Badge>}
        </div>
      </div>
    </Link>
  );
}

export function ProductGridSkeleton({ count = 8 }: { count?: number }) {
  return (
    <div className="grid grid-cols-2 gap-4 md:grid-cols-3 xl:grid-cols-4" aria-busy="true" aria-label="Loading products">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="overflow-hidden rounded-lg border">
          <div className="aspect-[4/3] animate-pulse bg-muted" />
          <div className="space-y-2 p-3">
            <div className="h-3 w-1/3 animate-pulse rounded bg-muted" />
            <div className="h-4 w-full animate-pulse rounded bg-muted" />
            <div className="h-5 w-1/2 animate-pulse rounded bg-muted" />
          </div>
        </div>
      ))}
    </div>
  );
}
