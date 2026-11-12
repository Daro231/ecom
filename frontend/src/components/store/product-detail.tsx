"use client";
import * as React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { Minus, Plus, ShoppingCart, ShieldCheck, ChevronRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/card";
import { ProductImage } from "@/components/shared/product-image";
import { Stars } from "@/components/shared/rating";
import { ErrorState } from "@/components/shared/states";
import { Pagination } from "@/components/shared/pagination";
import { ReviewForm } from "./review-form";
import { useProductBySlug, useProductReviews } from "@/hooks/use-catalog";
import { useCartMutations } from "@/hooks/use-cart";
import { useOrders } from "@/hooks/use-account";
import { useAuthStore } from "@/store/authStore";
import { productService } from "@/services/product";
import { canReview } from "@/lib/reviews";
import { formatDate, formatUSD, stockLabel } from "@/lib/format";
import { cn } from "@/lib/utils";
import type { Product } from "@/types";

export function specRows(p: Product): [string, string][] {
  const rows: [string, string | undefined][] = [
    ["CPU", p.cpu],
    ["RAM", p.ram ? `${p.ram} GB` : undefined],
    ["Storage", p.storage],
    ["GPU", p.gpu],
    ["Screen", p.screenSize ? `${p.screenSize}"` : undefined],
    ["OS", p.os],
    ["Warranty", p.warrantyMonths ? `${p.warrantyMonths} months` : undefined],
  ];
  return rows.filter((r): r is [string, string] => !!r[1]?.toString().trim());
}

export function ProductDetail({ slug }: { slug: string }) {
  const router = useRouter();
  const q = useProductBySlug(slug);
  const token = useAuthStore((s) => s.token);
  const user = useAuthStore((s) => s.user);
  const { add } = useCartMutations();
  const [qty, setQty] = React.useState(1);
  const [img, setImg] = React.useState(0);
  const [rPage, setRPage] = React.useState(0);
  const p = q.data;
  const reviews = useProductReviews(p?.id, rPage);
  const allReviews = useQuery({
    queryKey: ["reviews-all", p?.id],
    queryFn: () => productService.reviews(p!.id, 0, 100),
    enabled: !!p && !!token,
  });
  const orders = useOrders();
  const eligible = !!p && canReview(token ? orders.data?.content : undefined, p.id, allReviews.data?.content, user?.id);

  if (q.isLoading) {
    return (
      <div className="grid gap-8 md:grid-cols-2">
        <Skeleton className="aspect-[4/3] max-w-[520px]" />
        <div className="space-y-4"><Skeleton className="h-8 w-3/4" /><Skeleton className="h-6 w-1/3" /><Skeleton className="h-32" /></div>
      </div>
    );
  }
  if (q.isError || !p) return <ErrorState title="Product not found" error={q.error} onRetry={() => q.refetch()} />;

  const stock = stockLabel(p.stockQuantity, p.lowStockThreshold);
  const out = p.stockQuantity <= 0;
  const images = p.images?.length ? p.images : [undefined];
  const specs = specRows(p);
  const addToCart = () => {
    if (!token) return router.push(`/login?redirect=${encodeURIComponent(`/products/${slug}`)}`);
    add.mutate({ productId: p.id, quantity: qty });
  };

  return (
    <div>
      <nav aria-label="Breadcrumb" className="mb-4 flex items-center gap-1 text-sm text-muted-foreground">
        <Link href="/" className="hover:text-foreground">Home</Link><ChevronRight className="h-3.5 w-3.5" />
        <Link href={`/products?categoryId=${p.category.id}`} className="hover:text-foreground">{p.category.name}</Link><ChevronRight className="h-3.5 w-3.5" />
        <span className="truncate text-foreground">{p.name}</span>
      </nav>
      <div className="grid gap-8 md:grid-cols-2">
        <div className="w-full max-w-[520px]">
          <ProductImage src={images[img]} alt={p.name} category={p.category.name} brand={p.brand.name} className="aspect-[4/3] w-full rounded-lg border" priority sizes="520px" />
          {images.length > 1 && (
            <ul className="mt-3 flex gap-2" aria-label="Product images">
              {images.map((src, i) => (
                <li key={i}>
                  <button type="button" onClick={() => setImg(i)} aria-label={`Show image ${i + 1}`} aria-current={i === img}
                    className={cn("block h-16 w-20 overflow-hidden rounded-md border-2 focus-visible:ring-2 focus-visible:ring-ring", i === img ? "border-primary" : "border-transparent")}>
                    <ProductImage src={src} alt="" category={p.category.name} brand={p.brand.name} className="h-full w-full" sizes="80px" />
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>

        <div className="space-y-4">
          <div>
            <p className="text-sm font-medium uppercase tracking-wide text-muted-foreground">{p.brand.name}</p>
            <h1 className="mt-1 text-2xl font-bold leading-tight md:text-3xl">{p.name}</h1>
            <div className="mt-2 flex items-center gap-2 text-sm">
              <Stars value={p.averageRating} /> <span className="text-muted-foreground">{p.averageRating.toFixed(1)} · {p.reviewCount} review{p.reviewCount === 1 ? "" : "s"}</span>
            </div>
          </div>
          <p className="text-3xl font-extrabold" data-testid="price">{formatUSD(p.price)}</p>
          <div>
            {stock.tone === "out" && <Badge tone="red">Out of stock</Badge>}
            {stock.tone === "low" && <Badge tone="amber">{stock.text}</Badge>}
            {stock.tone === "ok" && <Badge tone="green">In stock</Badge>}
          </div>
          {p.description && <p className="text-muted-foreground">{p.description}</p>}

          <div className="flex flex-wrap items-center gap-3 pt-2">
            <div className="flex items-center rounded-md border" role="group" aria-label="Quantity">
              <Button variant="ghost" size="icon" aria-label="Decrease quantity" disabled={out || qty <= 1} onClick={() => setQty((n) => Math.max(1, n - 1))}><Minus className="h-4 w-4" /></Button>
              <span className="w-10 text-center font-medium" aria-live="polite" data-testid="qty">{qty}</span>
              <Button variant="ghost" size="icon" aria-label="Increase quantity" disabled={out || qty >= p.stockQuantity} onClick={() => setQty((n) => Math.min(p.stockQuantity, n + 1))}><Plus className="h-4 w-4" /></Button>
            </div>
            <Button size="lg" disabled={out || add.isPending} onClick={addToCart}>
              <ShoppingCart className="h-5 w-5" /> {out ? "Out of stock" : add.isPending ? "Adding…" : "Add to cart"}
            </Button>
          </div>
          {p.warrantyMonths ? <p className="flex items-center gap-2 text-sm text-muted-foreground"><ShieldCheck className="h-4 w-4 text-primary" /> {p.warrantyMonths}-month warranty</p> : null}

          {specs.length > 0 && (
            <div className="overflow-hidden rounded-lg border">
              <table className="w-full text-sm" aria-label="Specifications">
                <tbody>
                  {specs.map(([k, v]) => (
                    <tr key={k} className="border-b last:border-0"><th scope="row" className="w-1/3 bg-muted/50 px-3 py-2 text-left font-medium">{k}</th><td className="px-3 py-2">{v}</td></tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      <section className="mt-12 max-w-[900px]" aria-label="Reviews">
        <h2 className="mb-4 text-xl font-bold">Customer reviews</h2>
        {eligible && <div className="mb-6"><ReviewForm productId={p.id} productName={p.name} /></div>}
        {reviews.isLoading ? <Skeleton className="h-24" /> : reviews.isError ? (
          <ErrorState error={reviews.error} onRetry={() => reviews.refetch()} />
        ) : reviews.data && reviews.data.content.length === 0 ? (
          <p className="text-muted-foreground">No reviews yet.</p>
        ) : (
          <>
            <ul className="space-y-3">
              {reviews.data?.content.map((r) => (
                <li key={r.id} className="rounded-lg border bg-card p-4">
                  <div className="flex flex-wrap items-center gap-2">
                    <Stars value={r.rating} size={14} /><span className="font-medium">{r.userName}</span>
                    {r.verifiedPurchase && <Badge tone="green">Verified purchase</Badge>}
                    <span className="ml-auto text-xs text-muted-foreground">{formatDate(r.createdAt)}</span>
                  </div>
                  {r.comment && <p className="mt-2 text-sm">{r.comment}</p>}
                </li>
              ))}
            </ul>
            <Pagination page={reviews.data?.page ?? 0} totalPages={reviews.data?.totalPages ?? 0} onPage={setRPage} />
          </>
        )}
      </section>
    </div>
  );
}
