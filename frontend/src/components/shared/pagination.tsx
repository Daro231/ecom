"use client";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { Button } from "@/components/ui/button";

export function Pagination({ page, totalPages, onPage }: { page: number; totalPages: number; onPage: (p: number) => void }) {
  if (totalPages <= 1) return null;
  return (
    <nav aria-label="Pagination" className="mt-6 flex items-center justify-center gap-3">
      <Button variant="outline" size="sm" disabled={page <= 0} onClick={() => onPage(page - 1)}>
        <ChevronLeft className="h-4 w-4" /> Previous
      </Button>
      <span className="text-sm text-muted-foreground" aria-live="polite">
        Page {page + 1} of {totalPages}
      </span>
      <Button variant="outline" size="sm" disabled={page >= totalPages - 1} onClick={() => onPage(page + 1)}>
        Next <ChevronRight className="h-4 w-4" />
      </Button>
    </nav>
  );
}
