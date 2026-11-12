"use client";
import { NamedCrud } from "@/components/admin/named-crud";
import { useBrands } from "@/hooks/use-catalog";
import { adminService } from "@/services/admin";

export default function BrandsPage() {
  const q = useBrands();
  return <NamedCrud singular="Brand" plural="Brands" items={q.data} loading={q.isLoading} error={q.error} onRetry={() => q.refetch()} queryKey="brands"
    create={adminService.createBrand} update={adminService.updateBrand} remove={adminService.deleteBrand} />;
}
