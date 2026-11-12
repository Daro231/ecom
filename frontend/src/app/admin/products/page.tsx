"use client";
import * as React from "react";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { Pencil, Plus, Search, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input, Select } from "@/components/ui/input";
import { Table, TBody, TD, TH, THead, TR } from "@/components/ui/table";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { EmptyState, ErrorState, ListSkeleton, PageHeader } from "@/components/shared/states";
import { Pagination } from "@/components/shared/pagination";
import { ProductImage } from "@/components/shared/product-image";
import { useBrands, useCategories } from "@/hooks/use-catalog";
import { useAdminAction } from "@/hooks/use-admin-action";
import { useDebounced } from "@/hooks/use-debounced";
import { adminService } from "@/services/admin";
import { ApiError } from "@/lib/api-error";
import { formatUSD } from "@/lib/format";
import type { Product } from "@/types";

export default function AdminProductsPage() {
  const [kw, setKw] = React.useState("");
  const keyword = useDebounced(kw, 350);
  const [categoryId, setCat] = React.useState("");
  const [brandId, setBrand] = React.useState("");
  const [page, setPage] = React.useState(0);
  const [del, setDel] = React.useState<Product | null>(null);
  const cats = useCategories();
  const brands = useBrands();
  const q = useQuery({ queryKey: ["admin-products", keyword, categoryId, brandId, page], queryFn: () => adminService.products({ keyword, categoryId: categoryId || undefined, brandId: brandId || undefined, page, size: 15 }) });
  const toggle = useAdminAction((p: Product) => adminService.setProductActive(p.id, !p.active), { success: (p) => (p.active ? "Product activated" : "Product deactivated"), invalidate: ["admin-products", "products"] });
  const remove = useAdminAction((p: Product) => adminService.deleteProduct(p.id), {
    success: "Product deleted", invalidate: ["admin-products", "products"],
    onError: (e) => (e instanceof ApiError && e.status === 409 ? "This product is part of existing orders and cannot be deleted. Deactivate it instead." : undefined),
  });
  const reset = (fn: () => void) => { fn(); setPage(0); };

  return (
    <div>
      <PageHeader title="Products" actions={<Button asChild><Link href="/admin/products/new"><Plus className="h-4 w-4" /> New product</Link></Button>} />
      <div className="mb-4 flex flex-wrap gap-2">
        <div className="relative min-w-56 flex-1"><Search className="pointer-events-none absolute left-3 top-2.5 h-4 w-4 text-muted-foreground" /><Input aria-label="Search products" className="pl-9" placeholder="Search name, SKU…" value={kw} onChange={(e) => reset(() => setKw(e.target.value))} /></div>
        <Select aria-label="Category" className="w-40" value={categoryId} onChange={(e) => reset(() => setCat(e.target.value))}><option value="">All categories</option>{cats.data?.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}</Select>
        <Select aria-label="Brand" className="w-40" value={brandId} onChange={(e) => reset(() => setBrand(e.target.value))}><option value="">All brands</option>{brands.data?.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}</Select>
      </div>
      {q.isLoading ? <ListSkeleton rows={6} className="h-14" /> : q.isError ? <ErrorState error={q.error} onRetry={() => q.refetch()} /> : q.data && q.data.content.length === 0 ? <EmptyState title="No products found" /> : (
        <div className="rounded-lg border bg-card">
          <Table aria-label="Products">
            <THead><TR><TH>Product</TH><TH>Category</TH><TH>Price</TH><TH>Stock</TH><TH>Status</TH><TH className="text-right">Actions</TH></TR></THead>
            <TBody>
              {q.data?.content.map((p) => (
                <TR key={p.id} data-testid="product-row">
                  <TD><div className="flex items-center gap-3"><ProductImage src={p.images?.[0]} alt="" category={p.category.name} brand={p.brand.name} className="h-10 w-14 shrink-0 rounded" sizes="56px" /><div className="min-w-0"><p className="max-w-[260px] truncate font-medium">{p.name}</p><p className="text-xs text-muted-foreground">{p.sku} · {p.brand.name}</p></div></div></TD>
                  <TD>{p.category.name}</TD>
                  <TD>{formatUSD(p.price)}</TD>
                  <TD><span className={p.stockQuantity <= p.lowStockThreshold ? "font-semibold text-red-600" : ""}>{p.stockQuantity}</span></TD>
                  <TD><Badge tone={p.active ? "green" : "gray"}>{p.active ? "Active" : "Inactive"}</Badge></TD>
                  <TD><div className="flex justify-end gap-1">
                    <Button size="sm" variant="outline" onClick={() => toggle.mutate(p)} disabled={toggle.isPending}>{p.active ? "Deactivate" : "Activate"}</Button>
                    <Button size="icon" variant="ghost" asChild aria-label={`Edit ${p.name}`}><Link href={`/admin/products/${p.id}`}><Pencil className="h-4 w-4" /></Link></Button>
                    <Button size="icon" variant="ghost" className="text-destructive" aria-label={`Delete ${p.name}`} onClick={() => setDel(p)}><Trash2 className="h-4 w-4" /></Button>
                  </div></TD>
                </TR>
              ))}
            </TBody>
          </Table>
        </div>
      )}
      <Pagination page={q.data?.page ?? 0} totalPages={q.data?.totalPages ?? 0} onPage={setPage} />
      <ConfirmDialog open={!!del} onOpenChange={(o) => !o && setDel(null)} title="Delete product?" description={del ? <>“{del.name}” will be permanently deleted. This cannot be undone.</> : undefined} confirmLabel="Delete product" destructive onConfirm={() => (del ? remove.mutateAsync(del) : undefined)} />
    </div>
  );
}
