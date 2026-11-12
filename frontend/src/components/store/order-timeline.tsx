import { Check, X } from "lucide-react";
import { buildTimeline } from "@/lib/timeline";
import { formatDateTime } from "@/lib/format";
import { cn } from "@/lib/utils";
import type { Order } from "@/types";

export function OrderTimeline({ order }: { order: Order }) {
  const steps = buildTimeline(order);
  return (
    <ol className="relative space-y-5" aria-label="Order timeline">
      {steps.map((s, i) => (
        <li key={s.key} className="relative flex gap-3" aria-current={s.state === "current" ? "step" : undefined}>
          {i < steps.length - 1 && <span className={cn("absolute left-[13px] top-7 h-[calc(100%-4px)] w-0.5", s.state === "done" ? "bg-green-600" : "bg-border")} aria-hidden />}
          <span className={cn("z-10 flex h-7 w-7 shrink-0 items-center justify-center rounded-full border-2 text-xs",
            s.state === "done" && "border-green-600 bg-green-600 text-white",
            s.state === "current" && "border-primary bg-primary text-primary-foreground",
            s.state === "cancelled" && "border-red-600 bg-red-600 text-white",
            s.state === "pending" && "border-border bg-background text-muted-foreground")}>
            {s.state === "done" ? <Check className="h-4 w-4" /> : s.state === "cancelled" ? <X className="h-4 w-4" /> : i + 1}
          </span>
          <div className="pt-0.5">
            <p className={cn("text-sm font-medium", s.state === "pending" && "text-muted-foreground")}>{s.label}</p>
            {s.at && <p className="text-xs text-muted-foreground">{formatDateTime(s.at)}</p>}
            {s.note && <p className="text-xs text-muted-foreground">Reason: {s.note}</p>}
          </div>
        </li>
      ))}
    </ol>
  );
}
