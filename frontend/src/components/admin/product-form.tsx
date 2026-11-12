"use client";
import * as React from "react";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { ImagePlus, Trash2, Upload } from "lucide-react";
import { toast } from "sonner";
import { useQueryClient } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Field, Input, Select, Textarea } from "@/components/ui/input";
import { ProductImage } from "@/components/shared/product-image";
import { useBrands, useCategories } from "@/hooks/use-catalog";
import { adminService } from "@/services/admin";
import { ApiError, errorMessage } from "@/lib/api-error";
import type { Product, ProductInput } from "@/types";

const optNum = (label: string, int = false) =>
  z.string().refine((v) => v.trim() === "" || (!Number.isNaN(Number(v)) && Number(v) >= 0 && (!int || Number.isInteger(Number(v)))), `${label} must be a ${int ? "whole " : ""}number ≥ 0`);

export const productSchema = z.object({
  sku: z.string().trim().min(2, "SKU is required"),
  name: z.string().trim().min(2, "Name is required"),
  description: z.string(),
  price: z.string().refine((v) => v.trim() !== "" && Number(v) > 0, "Price must be greater than 0"),
  categoryId: z.string().min(1, "Choose a category"),
  brandId: z.string().min(1, "Choose a brand"),
  cpu: z.string(), ram: optNum("RAM", true), storage: z.string(), gpu: z.string(), screenSize: optNum("Screen size"), os: z.string(),
  warrantyMonths: optNum("Warranty", true),
  stockQuantity: z.string().refine((v) => v.trim() !== "" && Number.isInteger(Number(v)) && Number(v) >= 0, "Stock must be a whole number ≥ 0"),
  lowStockThreshold: z.string().refine((v) => v.trim() !== "" && Number.isInteger(Number(v)) && Number(v) >= 0, "Threshold must be a whole number ≥ 0"),
  active: z.boolean(),
});
export type ProductValues = z.infer<typeof productSchema>;

const n = (s: string) => (s.trim() === "" ? undefined : Number(s));
const t = (s: string) => (s.trim() === "" ? undefined : s.trim());
export function toProductInput(v: ProductValues, imageUrls: string[]): ProductInput {
  return {
    sku: v.sku.trim(), name: v.name.trim(), description: t(v.description), price: Number(v.price),
    categoryId: Number(v.categoryId), brandId: Number(v.brandId),
    cpu: t(v.cpu), ram: n(v.ram), storage: t(v.storage), gpu: t(v.gpu), screenSize: n(v.screenSize), os: t(v.os), warrantyMonths: n(v.warrantyMonths),
    stockQuantity: Number(v.stockQuantity), lowStockThreshold: Number(v.lowStockThreshold), active: v.active, imageUrls,
  };
}
const str = (x?: number) => (x === undefined ? "" : String(x));

export function ProductForm({ product }: { product?: Product }) {
  const router = useRouter();
  const qc = useQueryClient();
  const cats = useCategories();
  const brands = useBrands();
  const [images, setImages] = React.useState<string[]>(product?.images ?? []);
  const [uploading, setUploading] = React.useState(false);
  const [url, setUrl] = React.useState("");
  const { register, handleSubmit, setError, formState: { errors, isSubmitting } } = useForm<ProductValues>({
    resolver: zodResolver(productSchema),
    defaultValues: {
      sku: product?.sku ?? "", name: product?.name ?? "", description: product?.description ?? "", price: str(product?.price),
      categoryId: product ? String(product.category.id) : "", brandId: product ? String(product.brand.id) : "",
      cpu: product?.cpu ?? "", ram: str(product?.ram), storage: product?.storage ?? "", gpu: product?.gpu ?? "",
      screenSize: str(product?.screenSize), os: product?.os ?? "", warrantyMonths: str(product?.warrantyMonths),
      stockQuantity: str(product?.stockQuantity ?? 0), lowStockThreshold: str(product?.lowStockThreshold ?? 5), active: product?.active ?? true,
    },
  });

  const onFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files ?? []);
    e.target.value = "";
    if (!files.length) return;
    setUploading(true);
    try {
      for (const f of files) {
        if (f.size > 5 * 1024 * 1024) { toast.error(`${f.name} is larger than 5 MB`); continue; }
        const r = await adminService.upload(f);
        setImages((cur) => [...cur, r.url]);
      }
    } catch (err) { toast.error(errorMessage(err)); } finally { setUploading(false); }
  };

  const onSubmit = async (v: ProductValues) => {
    try {
      const body = toProductInput(v, images);
      const saved = product ? await adminService.updateProduct(product.id, body) : await adminService.createProduct(body);
      ["admin-products", "admin-product", "products", "product"].forEach((k) => qc.invalidateQueries({ queryKey: [k] }));
      toast.success(product ? "Product updated" : "Product created");
      router.push(product ? "/admin/products" : `/admin/products/${saved.id}`);
    } catch (e) {
      if (e instanceof ApiError && e.errors) Object.entries(e.errors).forEach(([k, m]) => k in v && setError(k as keyof ProductValues, { message: m }));
      toast.error(errorMessage(e));
    }
  };
  const cat = cats.data?.find((c) => String(c.id) === String(product?.category.id));

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate className="mx-auto max-w-[900px] space-y-6" aria-label={product ? "Edit product" : "New product"}>
      <Card><CardContent className="grid gap-4 p-5 sm:grid-cols-2">
        <Field label="Name" htmlFor="name" error={errors.name?.message}><Input id="name" {...register("name")} /></Field>
        <Field label="SKU" htmlFor="sku" error={errors.sku?.message}><Input id="sku" {...register("sku")} /></Field>
        <Field label="Category" htmlFor="categoryId" error={errors.categoryId?.message}>
          <Select id="categoryId" {...register("categoryId")}><option value="">Select…</option>{cats.data?.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}</Select>
        </Field>
        <Field label="Brand" htmlFor="brandId" error={errors.brandId?.message}>
          <Select id="brandId" {...register("brandId")}><option value="">Select…</option>{brands.data?.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}</Select>
        </Field>
        <Field label="Price (USD)" htmlFor="price" error={errors.price?.message}><Input id="price" inputMode="decimal" {...register("price")} /></Field>
        <Field label="Warranty (months)" htmlFor="warrantyMonths" error={errors.warrantyMonths?.message}><Input id="warrantyMonths" inputMode="numeric" {...register("warrantyMonths")} /></Field>
        <div className="sm:col-span-2"><Field label="Description" htmlFor="description" error={errors.description?.message}><Textarea id="description" rows={3} {...register("description")} /></Field></div>
      </CardContent></Card>

      <Card><CardContent className="space-y-3 p-5">
        <h2 className="font-semibold">Specifications {cat && <span className="text-sm font-normal text-muted-foreground">(optional for {cat.name})</span>}</h2>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="CPU" htmlFor="cpu"><Input id="cpu" {...register("cpu")} /></Field>
          <Field label="RAM (GB)" htmlFor="ram" error={errors.ram?.message}><Input id="ram" inputMode="numeric" {...register("ram")} /></Field>
          <Field label="Storage" htmlFor="storage"><Input id="storage" {...register("storage")} /></Field>
          <Field label="GPU" htmlFor="gpu"><Input id="gpu" {...register("gpu")} /></Field>
          <Field label="Screen size (inch)" htmlFor="screenSize" error={errors.screenSize?.message}><Input id="screenSize" inputMode="decimal" {...register("screenSize")} /></Field>
          <Field label="Operating system" htmlFor="os"><Input id="os" {...register("os")} /></Field>
        </div>
      </CardContent></Card>

      <Card><CardContent className="grid gap-4 p-5 sm:grid-cols-3">
        <Field label="Stock quantity" htmlFor="stockQuantity" error={errors.stockQuantity?.message}><Input id="stockQuantity" inputMode="numeric" {...register("stockQuantity")} /></Field>
        <Field label="Low-stock threshold" htmlFor="lowStockThreshold" error={errors.lowStockThreshold?.message}><Input id="lowStockThreshold" inputMode="numeric" {...register("lowStockThreshold")} /></Field>
        <label className="flex items-end gap-2 pb-2 text-sm font-medium"><input type="checkbox" className="h-4 w-4 accent-[hsl(var(--primary))]" {...register("active")} /> Active (visible in the store)</label>
      </CardContent></Card>

      <Card><CardContent className="space-y-3 p-5">
        <h2 className="font-semibold">Images</h2>
        {images.length === 0 && <p className="text-sm text-muted-foreground">No images yet — the store shows a category placeholder.</p>}
        <ul className="flex flex-wrap gap-3" aria-label="Product images">
          {images.map((src, i) => (
            <li key={`${src}-${i}`} className="relative">
              <ProductImage src={src} alt={`Preview ${i + 1}`} className="h-24 w-32 rounded-md border" sizes="128px" />
              <button type="button" aria-label={`Remove image ${i + 1}`} onClick={() => setImages((c) => c.filter((_, j) => j !== i))} className="absolute -right-2 -top-2 rounded-full bg-destructive p-1 text-white shadow focus-visible:ring-2 focus-visible:ring-ring"><Trash2 className="h-3.5 w-3.5" /></button>
            </li>
          ))}
        </ul>
        <div className="flex flex-wrap items-center gap-2">
          <label className="inline-flex cursor-pointer items-center gap-2 rounded-md border px-3 py-2 text-sm font-medium hover:bg-accent focus-within:ring-2 focus-within:ring-ring">
            <Upload className="h-4 w-4" /> {uploading ? "Uploading…" : "Upload image"}
            <input type="file" accept="image/png,image/jpeg,image/webp,image/gif" multiple className="sr-only" onChange={onFile} disabled={uploading} data-testid="image-upload" />
          </label>
          <Input aria-label="Image URL" className="max-w-xs" placeholder="…or paste an image URL" value={url} onChange={(e) => setUrl(e.target.value)} />
          <Button variant="outline" disabled={!/^https?:\/\//.test(url.trim())} onClick={() => { setImages((c) => [...c, url.trim()]); setUrl(""); }}><ImagePlus className="h-4 w-4" /> Add</Button>
        </div>
      </CardContent></Card>

      <div className="flex justify-end gap-2">
        <Button variant="outline" onClick={() => router.push("/admin/products")}>Cancel</Button>
        <Button type="submit" disabled={isSubmitting || uploading}>{isSubmitting ? "Saving…" : product ? "Save changes" : "Create product"}</Button>
      </div>
    </form>
  );
}
