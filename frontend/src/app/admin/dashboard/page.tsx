"use client";
import * as React from "react";
import { useQuery } from "@tanstack/react-query";
import { Area, AreaChart, CartesianGrid, Cell, Legend, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { AlertTriangle, DollarSign, ShoppingBag, Users } from "lucide-react";
import Link from "next/link";
import { Card, CardContent, CardHeader, CardTitle, Skeleton } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { ErrorState, PageHeader } from "@/components/shared/states";
import { adminService } from "@/services/admin";
import { enumLabel, formatDate, formatUSD, toDateParam } from "@/lib/format";
import { ORDER_STATUSES } from "@/lib/constants";

// validated default categorical order (light surface); fixed per status, never cycled
const STATUS_COLORS: Record<string, string> = {
  PENDING: "#eda100", CONFIRMED: "#2a78d6", PROCESSING: "#6250d6", SHIPPED: "#eb6834", DELIVERED: "#1baf7a", CANCELLED: "#e34948",
};

function Kpi({ icon, label, value, href, tone }: { icon: React.ReactNode; label: string; value: string; href?: string; tone?: string }) {
  const body = (
    <Card className="h-full"><CardContent className="flex items-center gap-4 p-5">
      <div className={`flex h-11 w-11 items-center justify-center rounded-lg ${tone ?? "bg-accent text-accent-foreground"}`}>{icon}</div>
      <div><p className="text-sm text-muted-foreground">{label}</p><p className="text-2xl font-extrabold" data-testid={`kpi-${label.toLowerCase().replace(/\s+/g, "-")}`}>{value}</p></div>
    </CardContent></Card>
  );
  return href ? <Link href={href} className="block focus-visible:ring-2 focus-visible:ring-ring rounded-lg">{body}</Link> : body;
}

export default function DashboardPage() {
  const today = new Date();
  const [to, setTo] = React.useState(toDateParam(today));
  const [from, setFrom] = React.useState(toDateParam(new Date(today.getTime() - 29 * 86400000)));
  const dash = useQuery({ queryKey: ["admin-dashboard"], queryFn: adminService.dashboard });
  const sales = useQuery({ queryKey: ["admin-sales", from, to], queryFn: () => adminService.sales(from, to), enabled: from <= to });

  if (dash.isError) return <ErrorState error={dash.error} onRetry={() => dash.refetch()} />;
  const d = dash.data;
  const pie = ORDER_STATUSES.map((s) => ({ name: enumLabel(s), key: s, value: d?.ordersByStatus?.[s] ?? 0 })).filter((x) => x.value > 0);
  const top = (d?.topProducts ?? []).slice(0, 5);
  const maxQty = Math.max(1, ...top.map((t) => t.quantitySold));

  return (
    <div className="space-y-6">
      <PageHeader title="Dashboard" description="Sales and operations overview" />
      {dash.isLoading ? (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">{Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-24" />)}</div>
      ) : d && (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <Kpi icon={<DollarSign className="h-5 w-5" />} label="Total sales" value={formatUSD(d.totalSales)} />
          <Kpi icon={<ShoppingBag className="h-5 w-5" />} label="Orders" value={String(d.totalOrders)} href="/admin/orders" />
          <Kpi icon={<Users className="h-5 w-5" />} label="Customers" value={String(d.totalCustomers)} href="/admin/users" />
          <Kpi icon={<AlertTriangle className="h-5 w-5" />} label="Low stock" value={String(d.lowStockCount)} href="/admin/inventory" tone={d.lowStockCount > 0 ? "bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-200" : undefined} />
        </div>
      )}

      <Card>
        <CardHeader className="flex-row flex-wrap items-center justify-between gap-3 space-y-0">
          <CardTitle>Sales</CardTitle>
          <div className="flex items-center gap-2 text-sm">
            <label htmlFor="from" className="sr-only">From</label><Input id="from" type="date" className="h-9 w-40" value={from} max={to} onChange={(e) => setFrom(e.target.value)} />
            <span>–</span>
            <label htmlFor="to" className="sr-only">To</label><Input id="to" type="date" className="h-9 w-40" value={to} min={from} onChange={(e) => setTo(e.target.value)} />
          </div>
        </CardHeader>
        <CardContent>
          {sales.isLoading ? <Skeleton className="h-64" /> : sales.isError ? <ErrorState error={sales.error} onRetry={() => sales.refetch()} /> : (
            <div className="h-64" role="img" aria-label={`Daily revenue from ${formatDate(from)} to ${formatDate(to)}`}>
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={sales.data} margin={{ left: 0, right: 8, top: 8 }}>
                  <defs><linearGradient id="rev" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#2a78d6" stopOpacity={0.25} /><stop offset="100%" stopColor="#2a78d6" stopOpacity={0} /></linearGradient></defs>
                  <CartesianGrid vertical={false} stroke="hsl(var(--border))" />
                  <XAxis dataKey="date" tickFormatter={(v: string) => v.slice(5)} tick={{ fontSize: 12, fill: "hsl(var(--muted-foreground))" }} tickLine={false} axisLine={false} minTickGap={24} />
                  <YAxis tickFormatter={(v: number) => `$${v}`} tick={{ fontSize: 12, fill: "hsl(var(--muted-foreground))" }} tickLine={false} axisLine={false} width={56} />
                  <Tooltip contentStyle={{ background: "hsl(var(--card))", border: "1px solid hsl(var(--border))", borderRadius: 8, color: "hsl(var(--foreground))" }}
                    formatter={(v) => [formatUSD(Number(v)), "Revenue"]} labelFormatter={(l) => formatDate(String(l))} />
                  <Area type="monotone" isAnimationActive={false} dataKey="revenue" stroke="#2a78d6" strokeWidth={2} fill="url(#rev)" dot={false} activeDot={{ r: 5, stroke: "hsl(var(--card))", strokeWidth: 2 }} />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          )}
        </CardContent>
      </Card>

      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader><CardTitle>Orders by status</CardTitle></CardHeader>
          <CardContent>
            {pie.length === 0 ? <p className="py-10 text-center text-muted-foreground">No orders yet</p> : (
              <div className="h-64" role="img" aria-label={`Orders by status: ${pie.map((p) => `${p.name} ${p.value}`).join(", ")}`}>
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie data={pie} isAnimationActive={false} dataKey="value" nameKey="name" innerRadius={50} outerRadius={85} paddingAngle={2} stroke="hsl(var(--card))" strokeWidth={2}>
                      {pie.map((p) => <Cell key={p.key} fill={STATUS_COLORS[p.key]} />)}
                    </Pie>
                    <Tooltip contentStyle={{ background: "hsl(var(--card))", border: "1px solid hsl(var(--border))", borderRadius: 8, color: "hsl(var(--foreground))" }} />
                    <Legend formatter={(v: string, e) => <span className="text-sm text-foreground">{v} · {(e.payload as { value?: number })?.value}</span>} />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            )}
          </CardContent>
        </Card>
        <Card>
          <CardHeader><CardTitle>Top 5 products</CardTitle></CardHeader>
          <CardContent>
            {top.length === 0 ? <p className="py-10 text-center text-muted-foreground">No sales yet</p> : (
              <ol className="space-y-3" aria-label="Top products by units sold">
                {top.map((t, i) => (
                  <li key={t.productId} data-testid="top-product">
                    <div className="flex justify-between text-sm"><span className="truncate pr-2">{i + 1}. {t.name}</span><span className="font-semibold">{t.quantitySold} sold</span></div>
                    <div className="mt-1 h-2 rounded-full bg-muted"><div className="h-2 rounded-full bg-[#2a78d6]" style={{ width: `${(t.quantitySold / maxQty) * 100}%` }} /></div>
                  </li>
                ))}
              </ol>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
