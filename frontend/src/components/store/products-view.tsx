"use client";
import * as React from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { SlidersHorizontal, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input, Select } from "@/components/ui/input";
import { ProductCard, ProductGridSkeleton } from "./product-card";
import { EmptyState, ErrorState } from "@/components/shared/states";
import { Pagination } from "@/components/shared/pagination";
import { useBrands, useCategories, useProducts } from "@/hooks/use-catalog";
import { RAM_OPTIONS, SORT_OPTIONS } from "@/lib/constants";
import { categoryForKeyword } from "@/lib/search";
import { cn } from "@/lib/utils";
import type { ProductQuery } from "@/types";

const num = (v: string | null) => (v && !Number.isNaN(Number(v)) ? Number(v) : undefined);

export function ProductsView() {
  const router = useRouter();
  const path = usePathname();
  const sp = useSearchParams();
  const cats = useCategories();
  const brands = useBrands();
  const [showFilters, setShowFilters] = React.useState(false);

  const setParams = React.useCallback(
    (updates: Record<string, string | undefined>, keepPage = false) => {
      const next = new URLSearchParams(sp.toString());
      Object.entries(updates).forEach(([k, v]) => (v === undefined || v === "" ? next.delete(k) : next.set(k, v)));
      if (!keepPage) next.delete("page");
      const qs = next.toString();
      router.replace(qs ? `${path}?${qs}` : path, { scroll: false });
    },
    [sp, router, path],
  );

  // keyword that exactly equals a category name -> category filter instead
  const keyword = sp.get("keyword") ?? "";
  const matched = categoryForKeyword(keyword, cats.data);
  React.useEffect(() => {
    if (matched) setParams({ keyword: undefined, categoryId: String(matched.id) });
  }, [matched, setParams]);

  const query: ProductQuery = {
    keyword: matched ? undefined : keyword || undefined,
    categoryId: num(sp.get("categoryId")),
    brandId: num(sp.get("brandId")),
    minPrice: num(sp.get("minPrice")),
    maxPrice: num(sp.get("maxPrice")),
    ram: num(sp.get("ram")),
    minRating: num(sp.get("minRating")),
    inStock: sp.get("inStock") === "true" ? true : undefined,
    sort: sp.get("sort") ?? "newest",
    page: num(sp.get("page")) ?? 0,
    size: 12,
  };
  const waitingForCats = !!keyword && cats.isLoading;
  const products = useProducts(query, !waitingForCats && !matched);
  const loading = waitingForCats || !!matched || products.isLoading;

  const [minP, setMinP] = React.useState(sp.get("minPrice") ?? "");
  const [maxP, setMaxP] = React.useState(sp.get("maxPrice") ?? "");
  React.useEffect(() => {
    setMinP(sp.get("minPrice") ?? "");
    setMaxP(sp.get("maxPrice") ?? "");
  }, [sp]);

  const chips: { key: string; label: string; clear: Record<string, undefined> }[] = [];
  const cat = cats.data?.find((c) => c.id === query.categoryId);
  if (cat) chips.push({ key: "cat", label: cat.name, clear: { categoryId: undefined } });
  if (query.keyword) chips.push({ key: "kw", label: `“${query.keyword}”`, clear: { keyword: undefined } });
  const br = brands.data?.find((b) => b.id === query.brandId);
  if (br) chips.push({ key: "brand", label: br.name, clear: { brandId: undefined } });
  if (query.minPrice !== undefined || query.maxPrice !== undefined)
    chips.push({ key: "price", label: `$${query.minPrice ?? 0} – ${query.maxPrice !== undefined ? "$" + query.maxPrice : "any"}`, clear: { minPrice: undefined, maxPrice: undefined } });
  if (query.ram) chips.push({ key: "ram", label: `${query.ram} GB RAM`, clear: { ram: undefined } });
  if (query.minRating) chips.push({ key: "rating", label: `${query.minRating}★ & up`, clear: { minRating: undefined } });
  if (query.inStock) chips.push({ key: "stock", label: "In stock", clear: { inStock: undefined } });

  const data = products.data;
  return (
    <div className="grid gap-6 lg:grid-cols-[250px_1fr]">
      <aside aria-label="Filters" className={cn("space-y-6 rounded-lg border bg-card p-4 lg:block", showFilters ? "block" : "hidden")}>
        <fieldset>
          <legend className="mb-2 text-sm font-semibold">Category</legend>
          <div className="space-y-1">
            <FilterRadio name="cat" label="All" checked={!query.categoryId} onChange={() => setParams({ categoryId: undefined })} />
            {cats.data?.map((c) => (
              <FilterRadio key={c.id} name="cat" label={c.name} checked={query.categoryId === c.id} onChange={() => setParams({ categoryId: String(c.id) })} />
            ))}
          </div>
        </fieldset>
        <fieldset>
          <legend className="mb-2 text-sm font-semibold">Brand</legend>
          <div className="space-y-1">
            <FilterRadio name="brand" label="All brands" checked={!query.brandId} onChange={() => setParams({ brandId: undefined })} />
            {brands.data?.map((b) => (
              <FilterRadio key={b.id} name="brand" label={b.name} checked={query.brandId === b.id} onChange={() => setParams({ brandId: String(b.id) })} />
            ))}
          </div>
        </fieldset>
        <form
          onSubmit={(e) => { e.preventDefault(); setParams({ minPrice: minP || undefined, maxPrice: maxP || undefined }); }}
          aria-label="Price range"
        >
          <p className="mb-2 text-sm font-semibold">Price (USD)</p>
          <div className="flex items-center gap-2">
            <Input aria-label="Minimum price" inputMode="numeric" min={0} type="number" placeholder="Min" value={minP} onChange={(e) => setMinP(e.target.value)} />
            <span>–</span>
            <Input aria-label="Maximum price" inputMode="numeric" min={0} type="number" placeholder="Max" value={maxP} onChange={(e) => setMaxP(e.target.value)} />
          </div>
          <Button type="submit" size="sm" variant="secondary" className="mt-2 w-full">Apply</Button>
        </form>
        <fieldset>
          <legend className="mb-2 text-sm font-semibold">RAM</legend>
          <div className="flex flex-wrap gap-2">
            {RAM_OPTIONS.map((r) => (
              <button key={r} type="button" aria-pressed={query.ram === r} onClick={() => setParams({ ram: query.ram === r ? undefined : String(r) })}
                className={cn("rounded-md border px-3 py-1 text-sm focus-visible:ring-2 focus-visible:ring-ring", query.ram === r ? "border-primary bg-primary text-primary-foreground" : "hover:bg-accent")}>
                {r} GB
              </button>
            ))}
          </div>
        </fieldset>
        <fieldset>
          <legend className="mb-2 text-sm font-semibold">Rating</legend>
          <div className="space-y-1">
            <FilterRadio name="rating" label="Any" checked={!query.minRating} onChange={() => setParams({ minRating: undefined })} />
            {[4, 3, 2].map((r) => (
              <FilterRadio key={r} name="rating" label={`${r}★ & up`} checked={query.minRating === r} onChange={() => setParams({ minRating: String(r) })} />
            ))}
          </div>
        </fieldset>
        <label className="flex cursor-pointer items-center gap-2 text-sm font-medium">
          <input type="checkbox" className="h-4 w-4 accent-[hsl(var(--primary))]" checked={!!query.inStock} onChange={(e) => setParams({ inStock: e.target.checked ? "true" : undefined })} />
          In stock only
        </label>
      </aside>

      <section aria-label="Results">
        <div className="mb-4 flex flex-wrap items-center gap-3">
          <Button variant="outline" size="sm" className="lg:hidden" onClick={() => setShowFilters((s) => !s)} aria-expanded={showFilters}>
            <SlidersHorizontal className="h-4 w-4" /> Filters
          </Button>
          <p className="text-sm text-muted-foreground" aria-live="polite">
            {loading ? "Loading…" : `${data?.totalElements ?? 0} product${data?.totalElements === 1 ? "" : "s"}`}
          </p>
          <div className="ml-auto flex items-center gap-2">
            <label htmlFor="sort" className="text-sm">Sort by</label>
            <Select id="sort" className="h-9 w-auto" value={query.sort} onChange={(e) => setParams({ sort: e.target.value })}>
              {SORT_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
            </Select>
          </div>
        </div>

        {chips.length > 0 && (
          <ul className="mb-4 flex flex-wrap gap-2" aria-label="Active filters">
            {chips.map((c) => (
              <li key={c.key}>
                <button type="button" data-testid={`chip-${c.key}`} onClick={() => setParams(c.clear)} aria-label={`Remove filter ${c.label}`}
                  className="inline-flex items-center gap-1 rounded-full bg-accent px-3 py-1 text-sm font-medium text-accent-foreground hover:bg-accent/70 focus-visible:ring-2 focus-visible:ring-ring">
                  {c.label} <X className="h-3.5 w-3.5" />
                </button>
              </li>
            ))}
            <li><Button variant="link" size="sm" onClick={() => router.replace(path)}>Clear all</Button></li>
          </ul>
        )}

        {loading ? <ProductGridSkeleton count={8} /> : products.isError ? (
          <ErrorState error={products.error} onRetry={() => products.refetch()} />
        ) : data && data.content.length === 0 ? (
          <EmptyState title="No products found" description="Try removing a filter or searching for something else." action={<Button onClick={() => router.replace(path)}>Clear filters</Button>} />
        ) : (
          <>
            <div className={cn("grid grid-cols-2 gap-4 md:grid-cols-3 xl:grid-cols-4", products.isFetching && "opacity-60")}>
              {data?.content.map((p) => <ProductCard key={p.id} p={p} />)}
            </div>
            <Pagination page={data?.page ?? 0} totalPages={data?.totalPages ?? 0} onPage={(p) => setParams({ page: String(p) }, true)} />
          </>
        )}
      </section>
    </div>
  );
}

function FilterRadio({ name, label, checked, onChange }: { name: string; label: string; checked: boolean; onChange: () => void }) {
  return (
    <label className="flex cursor-pointer items-center gap-2 rounded px-1 py-0.5 text-sm hover:bg-accent">
      <input type="radio" name={name} checked={checked} onChange={onChange} className="h-4 w-4 accent-[hsl(var(--primary))]" />
      {label}
    </label>
  );
}
