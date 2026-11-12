import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const badgeVariants = cva("inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold whitespace-nowrap", {
  variants: {
    tone: {
      gray: "bg-slate-200 text-slate-800 dark:bg-slate-700 dark:text-slate-100",
      blue: "bg-blue-100 text-blue-800 dark:bg-blue-900/60 dark:text-blue-200",
      amber: "bg-amber-100 text-amber-900 dark:bg-amber-900/60 dark:text-amber-200",
      green: "bg-green-100 text-green-800 dark:bg-green-900/60 dark:text-green-200",
      red: "bg-red-100 text-red-800 dark:bg-red-900/60 dark:text-red-200",
      redSolid: "bg-red-600 text-white",
      purple: "bg-purple-100 text-purple-800 dark:bg-purple-900/60 dark:text-purple-200",
      orange: "bg-orange-100 text-orange-900 dark:bg-orange-900/60 dark:text-orange-200",
    },
  },
  defaultVariants: { tone: "gray" },
});
export interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement>, VariantProps<typeof badgeVariants> {}
export const Badge = ({ className, tone, ...p }: BadgeProps) => (
  <span className={cn(badgeVariants({ tone }), className)} {...p} />
);
