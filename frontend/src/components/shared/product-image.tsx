"use client";
import * as React from "react";
import Image from "next/image";
import { Computer, Cpu, Laptop, Monitor, Mouse, Package } from "lucide-react";
import { fileUrl } from "@/lib/format";
import { cn } from "@/lib/utils";

const ICONS: Record<string, React.ComponentType<{ className?: string }>> = {
  laptop: Laptop, desktop: Computer, monitor: Monitor, component: Cpu, accessory: Mouse,
};
const GRADIENTS = [
  "from-orange-100 to-amber-200 dark:from-orange-950 dark:to-amber-900",
  "from-sky-100 to-indigo-200 dark:from-sky-950 dark:to-indigo-900",
  "from-emerald-100 to-teal-200 dark:from-emerald-950 dark:to-teal-900",
  "from-rose-100 to-pink-200 dark:from-rose-950 dark:to-pink-900",
];

export function ImageFallback({ category, brand, className }: { category?: string; brand?: string; className?: string }) {
  const key = (category ?? "").toLowerCase();
  const Icon = ICONS[key] ?? Package;
  const g = GRADIENTS[(brand ?? category ?? "").length % GRADIENTS.length];
  return (
    <div
      data-testid="image-fallback"
      role="img"
      aria-label={`${brand ?? ""} ${category ?? "product"}`.trim()}
      className={cn("flex h-full w-full flex-col items-center justify-center gap-2 bg-gradient-to-br", g, className)}
    >
      <Icon className="h-1/4 w-1/4 min-h-8 min-w-8 text-navy/60 dark:text-white/70" />
      {brand && <span className="text-sm font-semibold tracking-wide text-navy/70 dark:text-white/80">{brand}</span>}
    </div>
  );
}

/** Product image that falls back to gradient + category icon + brand name when missing or broken. */
export function ProductImage({
  src, alt, category, brand, className, priority, sizes = "(max-width: 768px) 100vw, 400px",
}: { src?: string; alt: string; category?: string; brand?: string; className?: string; priority?: boolean; sizes?: string }) {
  const [failed, setFailed] = React.useState(false);
  const url = fileUrl(src);
  React.useEffect(() => setFailed(false), [src]);
  return (
    <div className={cn("relative overflow-hidden bg-muted", className)}>
      {url && !failed ? (
        <Image src={url} alt={alt} fill unoptimized priority={priority} sizes={sizes} className="object-cover" onError={() => setFailed(true)} />
      ) : (
        <ImageFallback category={category} brand={brand} />
      )}
    </div>
  );
}
