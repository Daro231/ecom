"use client";
import * as React from "react";
import Link from "next/link";
import { Check, Copy, Cpu, Computer, Laptop, Monitor, Mouse, Truck, ShieldCheck, QrCode } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { ProductCard, ProductGridSkeleton } from "@/components/store/product-card";
import { ErrorState } from "@/components/shared/states";
import { useBrands, useCategories, useProducts } from "@/hooks/use-catalog";
import { PROMO_COUPON } from "@/lib/constants";

const CAT_ICONS: Record<string, React.ComponentType<{ className?: string }>> = {
  laptop: Laptop, desktop: Computer, monitor: Monitor, component: Cpu, accessory: Mouse,
};

function ProductRow({ title, sort, href }: { title: string; sort: string; href: string }) {
  const q = useProducts({ sort, size: 8, inStock: true });
  return (
    <section className="mt-12" aria-label={title}>
      <div className="mb-4 flex items-end justify-between">
        <h2 className="text-xl font-bold">{title}</h2>
        <Link href={href} className="text-sm font-medium text-primary hover:underline">See all</Link>
      </div>
      {q.isLoading ? <ProductGridSkeleton count={4} /> : q.isError ? <ErrorState error={q.error} onRetry={() => q.refetch()} /> : (
        <div className="grid grid-cols-2 gap-4 md:grid-cols-3 xl:grid-cols-4">
          {q.data?.content.slice(0, 8).map((p) => <ProductCard key={p.id} p={p} />)}
        </div>
      )}
    </section>
  );
}

export default function HomePage() {
  const cats = useCategories();
  const brands = useBrands();
  const [copied, setCopied] = React.useState(false);
  const copy = async () => {
    try {
      await navigator.clipboard.writeText(PROMO_COUPON);
      setCopied(true);
      toast.success(`Coupon ${PROMO_COUPON} copied`);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      toast.error("Could not copy — select the code manually");
    }
  };
  return (
    <div>
      <section className="overflow-hidden rounded-2xl bg-gradient-to-r from-navy via-navy-light to-[#1d4a85] p-8 text-white md:p-12" aria-label="Promotion">
        <p className="text-sm font-semibold uppercase tracking-widest text-brand">New season deals</p>
        <h1 className="mt-2 max-w-xl text-3xl font-extrabold leading-tight md:text-5xl">Upgrade your setup with the right computer.</h1>
        <p className="mt-3 max-w-lg text-slate-200">Laptops, desktops, monitors and parts with free shipping on orders over $1,000.</p>
        <div className="mt-6 flex flex-wrap items-center gap-3">
          <Button asChild size="lg"><Link href="/products">Shop now</Link></Button>
          {PROMO_COUPON && (
            <div className="flex items-center gap-2 rounded-md border border-dashed border-brand bg-white/10 py-1.5 pl-4 pr-1.5">
              <span className="text-sm">Use code <strong data-testid="promo-code" className="font-mono text-brand">{PROMO_COUPON}</strong></span>
              <Button size="sm" variant="secondary" onClick={copy} aria-label={`Copy coupon code ${PROMO_COUPON}`}>
                {copied ? <Check className="h-4 w-4" /> : <Copy className="h-4 w-4" />} {copied ? "Copied" : "Copy"}
              </Button>
            </div>
          )}
        </div>
      </section>

      <section className="mt-8 grid gap-3 sm:grid-cols-3" aria-label="Benefits">
        {[{ i: Truck, t: "Fast delivery", d: "Same-day in Phnom Penh" }, { i: QrCode, t: "Pay with KHQR", d: "Scan with any Bakong app" }, { i: ShieldCheck, t: "Warranty included", d: "Up to 36 months on selected items" }].map(({ i: I, t, d }) => (
          <div key={t} className="flex items-center gap-3 rounded-lg border bg-card p-4"><I className="h-8 w-8 text-primary" /><div><p className="font-semibold">{t}</p><p className="text-sm text-muted-foreground">{d}</p></div></div>
        ))}
      </section>

      <section className="mt-12" aria-label="Categories">
        <h2 className="mb-4 text-xl font-bold">Shop by category</h2>
        {cats.isError ? <ErrorState error={cats.error} onRetry={() => cats.refetch()} /> : (
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
            {(cats.data ?? Array.from({ length: 5 }).map((_, i) => ({ id: -i, name: "", slug: "" }))).map((c) => {
              const Icon = CAT_ICONS[c.slug] ?? Laptop;
              return c.name ? (
                <Link key={c.id} href={`/products?categoryId=${c.id}`} className="flex flex-col items-center gap-2 rounded-lg border bg-card p-5 text-center transition hover:border-primary hover:shadow-md focus-visible:ring-2 focus-visible:ring-ring">
                  <Icon className="h-9 w-9 text-primary" />
                  <span className="font-semibold">{c.name}</span>
                </Link>
              ) : <div key={c.id} className="h-28 animate-pulse rounded-lg bg-muted" />;
            })}
          </div>
        )}
      </section>

      <ProductRow title="New arrivals" sort="newest" href="/products?sort=newest" />
      <ProductRow title="Top rated" sort="rating" href="/products?sort=rating" />

      <section className="mt-12" aria-label="Brands">
        <h2 className="mb-4 text-xl font-bold">Shop by brand</h2>
        <div className="flex flex-wrap gap-3">
          {brands.data?.map((b) => (
            <Link key={b.id} href={`/products?brandId=${b.id}`} className="rounded-full border bg-card px-5 py-2 text-sm font-semibold transition hover:border-primary hover:text-primary focus-visible:ring-2 focus-visible:ring-ring">
              {b.name}
            </Link>
          ))}
          {brands.isLoading && <div className="h-9 w-64 animate-pulse rounded-full bg-muted" />}
        </div>
      </section>
    </div>
  );
}
