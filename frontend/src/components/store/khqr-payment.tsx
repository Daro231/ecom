"use client";
import * as React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { QRCodeCanvas } from "qrcode.react";
import { AlertTriangle, Download, RefreshCw, Timer, XCircle } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/card";
import { ErrorState } from "@/components/shared/states";
import { paymentService } from "@/services/payment";
import { orderService } from "@/services/order";
import { ApiError, errorMessage } from "@/lib/api-error";
import { formatCountdown, merchantName, QR_EXPIRED_REASON, remainingFromServer } from "@/lib/khqr";
import { formatMoney } from "@/lib/format";
import { KHQR_POLL_MS } from "@/lib/constants";
import type { KhqrData, Payment } from "@/types";

type Phase = "loading" | "ready" | "expired" | "failed" | "cancelled" | "late" | "error";

export function KhqrPayment({ orderNumber }: { orderNumber: string }) {
  const router = useRouter();
  const qc = useQueryClient();
  const [qr, setQr] = React.useState<KhqrData | null>(null);
  const [phase, setPhase] = React.useState<Phase>("loading");
  const [failure, setFailure] = React.useState<string | null>(null);
  const [fatal, setFatal] = React.useState<unknown>(null);
  const [providerWarning, setProviderWarning] = React.useState(false);
  const [remaining, setRemaining] = React.useState(0);
  const [simulating, setSimulating] = React.useState(false);
  const deadline = React.useRef(0);
  const phaseRef = React.useRef<Phase>("loading");
  phaseRef.current = phase;
  const canvasWrap = React.useRef<HTMLDivElement>(null);

  const order = useQuery({ queryKey: ["order", orderNumber], queryFn: () => orderService.get(orderNumber) });

  const goSuccess = React.useCallback(() => {
    qc.invalidateQueries({ queryKey: ["orders"] });
    qc.invalidateQueries({ queryKey: ["order", orderNumber] });
    router.replace(`/checkout/success/${orderNumber}`);
  }, [qc, router, orderNumber]);

  const generate = React.useCallback(async () => {
    setPhase("loading");
    setFailure(null);
    try {
      const data = await paymentService.khqr(orderNumber);
      deadline.current = Date.now() + remainingFromServer(data.expiresAt, data.serverTime);
      setQr(data);
      setRemaining(deadline.current - Date.now());
      setPhase(deadline.current - Date.now() <= 0 ? "expired" : "ready");
    } catch (e) {
      if (e instanceof ApiError && e.status === 400) {
        // order cancelled / already paid: look at the order to decide what to show
        try {
          const o = await orderService.get(orderNumber);
          if (o.payment?.status === "PAID") return goSuccess();
          setPhase(o.payment?.status === "PAID_AFTER_CANCEL" ? "late" : "cancelled");
          return;
        } catch {
          /* fall through */
        }
      }
      setFatal(e);
      setPhase("error");
    }
  }, [orderNumber, goSuccess]);

  const started = React.useRef<string | null>(null);
  React.useEffect(() => {
    if (started.current === orderNumber) return; // StrictMode runs effects twice in dev
    started.current = orderNumber;
    void generate();
  }, [generate, orderNumber]);

  // countdown on the local monotonic clock, anchored to the server expiry
  React.useEffect(() => {
    if (phase !== "ready") return;
    const id = setInterval(() => {
      const left = deadline.current - Date.now();
      setRemaining(left);
      if (left <= 0) setPhase("expired");
    }, 500);
    return () => clearInterval(id);
  }, [phase, qr]);

  const handleStatus = React.useCallback(
    (p: Payment) => {
      setProviderWarning(false);
      if (p.status === "PAID") return goSuccess();
      if (p.status === "PAID_AFTER_CANCEL") return setPhase("late");
      if (p.status === "REFUNDED") return setPhase("cancelled");
      if (p.status === "FAILED") {
        if (p.failureReason === QR_EXPIRED_REASON) return setPhase((cur) => (cur === "ready" ? "expired" : cur));
        setFailure(p.failureReason ?? "The payment failed.");
        setPhase("failed");
        void orderService.get(orderNumber).then((o) => o.status === "CANCELLED" && setPhase("cancelled")).catch(() => undefined);
      }
    },
    [goSuccess, orderNumber],
  );

  const check = React.useCallback(async () => {
    try {
      handleStatus(await paymentService.status(orderNumber));
    } catch (e) {
      // 502 (provider unusable) and 504 (timeout) are NOT payment failures: keep polling
      if (e instanceof ApiError && (e.status === 502 || e.status === 504 || e.status === 0)) setProviderWarning(true);
      else if (e instanceof ApiError && e.status === 404) {
        setFatal(e);
        setPhase("error");
      } else setProviderWarning(true);
    }
  }, [handleStatus, orderNumber]);

  // poll every 3 s while visible; check immediately when the tab becomes visible again
  React.useEffect(() => {
    if (phase !== "ready" && phase !== "expired") return;
    let timer: ReturnType<typeof setTimeout>;
    let stopped = false;
    const loop = async () => {
      if (stopped) return;
      if (!document.hidden) await check();
      if (!stopped) timer = setTimeout(loop, KHQR_POLL_MS);
    };
    timer = setTimeout(loop, KHQR_POLL_MS);
    const onVis = () => {
      if (!document.hidden) {
        clearTimeout(timer);
        void loop();
      }
    };
    document.addEventListener("visibilitychange", onVis);
    window.addEventListener("focus", onVis);
    return () => {
      stopped = true;
      clearTimeout(timer);
      document.removeEventListener("visibilitychange", onVis);
      window.removeEventListener("focus", onVis);
    };
  }, [phase, check]);

  const download = () => {
    const canvas = canvasWrap.current?.querySelector("canvas");
    if (!canvas) return;
    const a = document.createElement("a");
    a.href = canvas.toDataURL("image/png");
    a.download = `khqr-${orderNumber}.png`;
    a.click();
  };

  const simulate = async () => {
    setSimulating(true);
    try {
      await paymentService.simulate(orderNumber, `MOCK-${Date.now()}`);
      await check();
    } catch (e) {
      toast.error(errorMessage(e));
    } finally {
      setSimulating(false);
    }
  };

  if (phase === "error") return <ErrorState error={fatal} onRetry={() => void generate()} title="Could not load the payment" />;
  if (phase === "cancelled" || phase === "late") {
    const o = order.data;
    return (
      <div role="status" className="mx-auto max-w-md rounded-lg border bg-card p-6 text-center">
        <XCircle className="mx-auto h-12 w-12 text-destructive" />
        <h2 className="mt-3 text-xl font-bold">{phase === "late" ? "Payment received after cancellation" : "This order was cancelled"}</h2>
        <p className="mt-2 text-sm text-muted-foreground">
          {phase === "late"
            ? "We received your payment after the order was cancelled. Our team will restore your order or refund you."
            : o?.cancelledReason ? `Reason: ${o.cancelledReason}. No QR code is available for cancelled orders.` : "No QR code is available for cancelled orders."}
        </p>
        <Button asChild className="mt-4"><Link href={`/orders/${orderNumber}`}>View order</Link></Button>
      </div>
    );
  }

  const expired = phase === "expired";
  return (
    <div className="mx-auto w-full max-w-md" data-testid="khqr-page" data-phase={phase}>
      {providerWarning && (
        <div role="status" data-testid="provider-warning" className="mb-3 flex items-start gap-2 rounded-md bg-amber-100 px-3 py-2 text-sm text-amber-900 dark:bg-amber-900/40 dark:text-amber-100">
          <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" />
          <span>We can&apos;t reach the payment provider right now. Don&apos;t worry — we&apos;ll keep checking automatically.</span>
        </div>
      )}
      <div className="overflow-hidden rounded-xl border bg-card shadow-md">
        <div className="bg-khqr px-5 py-3 text-center text-white">
          <p className="text-2xl font-black tracking-[0.25em]">KHQR</p>
        </div>
        <div className="space-y-4 p-6 text-center">
          {!qr ? (
            <Skeleton className="mx-auto h-[300px] w-[300px]" aria-label="Generating QR code" />
          ) : (
            <>
              <div>
                <p className="text-sm text-muted-foreground">{merchantName(qr.qrString)}</p>
                <p className="text-3xl font-extrabold" data-testid="khqr-amount">{formatMoney(qr.amount, qr.currency)}</p>
                <p className="text-xs text-muted-foreground">{qr.currency} · Order {qr.orderNumber}</p>
              </div>
              <div ref={canvasWrap} className="relative mx-auto w-fit rounded-lg border bg-white p-1">
                <QRCodeCanvas value={qr.qrString} size={280} marginSize={4} bgColor="#ffffff" fgColor="#000000" level="M" className={expired ? "opacity-20" : ""} aria-label="KHQR payment code" />
                {expired && (
                  <div className="absolute inset-0 flex flex-col items-center justify-center gap-3 bg-white/70">
                    <p className="text-lg font-bold text-black" data-testid="qr-expired">QR expired</p>
                    <Button onClick={() => void generate()}><RefreshCw className="h-4 w-4" /> Generate new QR</Button>
                  </div>
                )}
              </div>
              {!expired && (
                <p className="flex items-center justify-center gap-1.5 text-sm" aria-live="off">
                  <Timer className="h-4 w-4" /> Expires in <strong data-testid="khqr-countdown" className="font-mono">{formatCountdown(remaining)}</strong>
                </p>
              )}
            </>
          )}

          {phase === "failed" && (
            <div role="alert" data-testid="khqr-failed" className="rounded-md bg-red-100 px-3 py-2 text-left text-sm text-red-800 dark:bg-red-900/40 dark:text-red-100">
              <p className="font-semibold">Payment failed</p>
              <p>{failure}</p>
              <Button size="sm" variant="destructive" className="mt-2" onClick={() => void generate()}><RefreshCw className="h-4 w-4" /> Try again</Button>
            </div>
          )}

          <div className="flex flex-col gap-2">
            {qr && !expired && (
              <Button variant="outline" onClick={download}><Download className="h-4 w-4" /> Download QR</Button>
            )}
            {qr?.mode === "MOCK" && (
              <Button variant="secondary" onClick={simulate} disabled={simulating || expired}>{simulating ? "Processing…" : "Simulate payment"}</Button>
            )}
            <Button asChild variant="link"><Link href={`/orders/${orderNumber}`}>Pay later – view order</Link></Button>
          </div>
          <p className="text-xs text-muted-foreground">Open your banking app, tap Scan, and scan this code. This page updates automatically.</p>
        </div>
      </div>
    </div>
  );
}
