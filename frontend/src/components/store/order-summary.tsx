import { Badge } from "@/components/ui/badge";
import { formatUSD } from "@/lib/format";
import type { Totals } from "@/lib/totals";

export function OrderSummary({ totals, shippingNote = "Calculated at checkout", shippingLabel = "Shipping" }: { totals: Totals; shippingNote?: string; shippingLabel?: string }) {
  return (
    <dl className="space-y-2 text-sm" aria-label="Order summary">
      <Row label="Subtotal" value={formatUSD(totals.subtotal)} testId="sum-subtotal" />
      {totals.discount > 0 && (
        <Row label={<span className="flex items-center gap-2">Discount {totals.couponCode && <Badge tone="green">{totals.couponCode}</Badge>}</span>} value={`−${formatUSD(totals.discount)}`} testId="sum-discount" />
      )}
      <Row label={shippingLabel} value={totals.shippingFee === null ? shippingNote : totals.shippingFee === 0 ? "Free" : formatUSD(totals.shippingFee)} testId="sum-shipping" />
      <div className="border-t pt-2">
        <Row label={<span className="text-base font-bold">Total</span>} value={<span className="text-lg font-extrabold">{totals.total === null ? "—" : formatUSD(totals.total)}</span>} testId="sum-total" />
      </div>
    </dl>
  );
}
function Row({ label, value, testId }: { label: React.ReactNode; value: React.ReactNode; testId: string }) {
  return (
    <div className="flex items-center justify-between gap-4">
      <dt className="text-muted-foreground">{label}</dt>
      <dd data-testid={testId} className="font-medium">{value}</dd>
    </div>
  );
}
