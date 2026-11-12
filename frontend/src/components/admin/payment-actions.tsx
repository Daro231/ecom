"use client";
import * as React from "react";
import { RefreshCw, RotateCcw, Undo2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { useAdminAction } from "@/hooks/use-admin-action";
import { adminService } from "@/services/admin";
import { useAuthStore } from "@/store/authStore";
import { ApiError } from "@/lib/api-error";
import { formatUSD } from "@/lib/format";
import type { Payment } from "@/types";

const INVALIDATE = ["admin-payments", "admin-payments-late", "admin-order", "admin-orders", "admin-dashboard", "notifications", "unread"];
const RECHECK_KEY = "ecom-recheck-unavailable";
const recheckUnavailable = () => { try { return sessionStorage.getItem(RECHECK_KEY) === "1"; } catch { return false; } };

export const RESTORE_OUT_OF_STOCK = "Out of stock — please refund";

/** Refund / Restore / Recheck buttons for one payment, each behind a confirmation dialog. */
export function PaymentActions({ payment, orderNumber, size = "sm" }: { payment: Payment; orderNumber: string; size?: "sm" | "default" }) {
  const isAdmin = useAuthStore((s) => s.user?.role === "ADMIN");
  const [dlg, setDlg] = React.useState<"refund" | "restore" | "recheck" | null>(null);
  const [hideRecheck, setHideRecheck] = React.useState(recheckUnavailable);

  const refund = useAdminAction(() => adminService.refund(orderNumber), { success: "Payment refunded", invalidate: INVALIDATE });
  const restore = useAdminAction(() => adminService.restore(orderNumber), {
    success: "Order restored and confirmed", invalidate: INVALIDATE,
    onError: (e) => {
      if (e instanceof ApiError && e.status === 409) return RESTORE_OUT_OF_STOCK;
      if (e instanceof ApiError && e.status === 400) return "This order can't be restored — it is not cancelled with a late payment (already restored or refunded?).";
    },
  });
  const recheck = useAdminAction(() => adminService.recheck(orderNumber), {
    success: (p) => `Re-checked with Bakong: ${p.status}`, invalidate: INVALIDATE,
    onError: (e) => {
      if (e instanceof ApiError && e.status === 400) {
        try { sessionStorage.setItem(RECHECK_KEY, "1"); } catch { /* ignore */ }
        setHideRecheck(true);
        toast.info("Re-checking is only available when the server runs in Bakong mode.");
        return "Re-check is not available in mock mode";
      }
    },
  });

  const canRefund = isAdmin && (payment.status === "PAID" || payment.status === "PAID_AFTER_CANCEL");
  const canRestore = payment.status === "PAID_AFTER_CANCEL";
  const canRecheck = isAdmin && payment.method === "KHQR" && (payment.status === "PENDING" || payment.status === "FAILED") && !hideRecheck;
  if (!canRefund && !canRestore && !canRecheck) return null;
  return (
    <div className="flex flex-wrap justify-end gap-1">
      {canRestore && <Button size={size} onClick={() => setDlg("restore")}><RotateCcw className="h-4 w-4" /> Restore order</Button>}
      {canRefund && <Button size={size} variant="outline" onClick={() => setDlg("refund")}><Undo2 className="h-4 w-4" /> Refund</Button>}
      {canRecheck && <Button size={size} variant="outline" onClick={() => setDlg("recheck")}><RefreshCw className="h-4 w-4" /> Recheck with Bakong</Button>}

      <ConfirmDialog open={dlg === "refund"} onOpenChange={(o) => !o && setDlg(null)} title={`Refund ${formatUSD(payment.amount)}?`}
        description={<>Payment for order <strong>{orderNumber}</strong> will be marked as refunded. Make sure the money was returned to the customer.</>} confirmLabel="Refund payment" destructive onConfirm={() => refund.mutateAsync(undefined)} />
      <ConfirmDialog open={dlg === "restore"} onOpenChange={(o) => !o && setDlg(null)} title="Restore this order?"
        description={<>The customer paid {formatUSD(payment.amount)} after the order was cancelled. Stock is reserved again and order <strong>{orderNumber}</strong> becomes Confirmed. If an item is out of stock nothing changes and you should refund.</>} confirmLabel="Restore order" onConfirm={() => restore.mutateAsync(undefined)} />
      <ConfirmDialog open={dlg === "recheck"} onOpenChange={(o) => !o && setDlg(null)} title="Re-check with Bakong?"
        description="The server asks Bakong right now whether this QR was paid." confirmLabel="Recheck" onConfirm={() => recheck.mutateAsync(undefined)} />
    </div>
  );
}
