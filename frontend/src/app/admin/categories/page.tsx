"use client";
import { NamedCrud } from "@/components/admin/named-crud";
import { useCategories } from "@/hooks/use-catalog";
import { adminService } from "@/services/admin";

export default function CategoriesPage() {
  const q = useCategories();
  return <NamedCrud singular="Category" plural="Categories" withDescription items={q.data} loading={q.isLoading} error={q.error} onRetry={() => q.refetch()} queryKey="categories"
    create={adminService.createCategory} update={adminService.updateCategory} remove={adminService.deleteCategory} />;
}
