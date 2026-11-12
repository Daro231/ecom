"use client";
import { useQuery } from "@tanstack/react-query";
import { ErrorState, ListSkeleton, PageHeader } from "@/components/shared/states";
import { ProductForm } from "@/components/admin/product-form";
import { adminService } from "@/services/admin";

export default function EditProductPage({ params }: { params: { id: string } }) {
  const q = useQuery({ queryKey: ["admin-product", params.id], queryFn: () => adminService.product(Number(params.id)) });
  return (
    <>
      <PageHeader title={q.data ? `Edit ${q.data.name}` : "Edit product"} />
      {q.isLoading ? <ListSkeleton rows={4} className="h-32" /> : q.isError || !q.data ? <ErrorState error={q.error} onRetry={() => q.refetch()} /> : <ProductForm product={q.data} />}
    </>
  );
}
