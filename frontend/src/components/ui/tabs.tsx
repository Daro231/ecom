"use client";
import { cn } from "@/lib/utils";

export interface TabItem { value: string; label: string; count?: number }
export function Tabs({
  items, value, onChange, className, ariaLabel = "Tabs",
}: { items: TabItem[]; value: string; onChange: (v: string) => void; className?: string; ariaLabel?: string }) {
  return (
    <div role="tablist" aria-label={ariaLabel} className={cn("flex gap-1 overflow-x-auto border-b", className)}>
      {items.map((t) => (
        <button
          key={t.value}
          role="tab"
          type="button"
          aria-selected={value === t.value}
          onClick={() => onChange(t.value)}
          className={cn(
            "-mb-px flex items-center gap-1.5 whitespace-nowrap border-b-2 px-4 py-2 text-sm font-medium focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
            value === t.value ? "border-primary text-primary" : "border-transparent text-muted-foreground hover:text-foreground",
          )}
        >
          {t.label}
          {t.count !== undefined && (
            <span className={cn("rounded-full px-1.5 text-xs", t.value === "PAID_AFTER_CANCEL" && t.count > 0 ? "bg-red-600 text-white" : "bg-muted")}>
              {t.count}
            </span>
          )}
        </button>
      ))}
    </div>
  );
}
