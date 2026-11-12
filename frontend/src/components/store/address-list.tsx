"use client";
import * as React from "react";
import { MapPin, Pencil, Plus, Star, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { EmptyState, ErrorState, ListSkeleton } from "@/components/shared/states";
import { StaticMap } from "@/components/shared/address-map-loader";
import { AddressForm } from "./address-form";
import { useAddressMutations, useAddresses } from "@/hooks/use-account";
import { useAuthStore } from "@/store/authStore";
import type { Address } from "@/types";

export function AddressList() {
  const q = useAddresses();
  const user = useAuthStore((s) => s.user);
  const m = useAddressMutations();
  const [editing, setEditing] = React.useState<Address | "new" | null>(null);
  const [deleting, setDeleting] = React.useState<Address | null>(null);
  const [defaulting, setDefaulting] = React.useState<Address | null>(null);

  if (q.isLoading) return <ListSkeleton rows={2} className="h-28" />;
  if (q.isError) return <ErrorState error={q.error} onRetry={() => q.refetch()} />;
  const list = q.data ?? [];
  return (
    <div className="space-y-4">
      <div className="flex justify-end"><Button onClick={() => setEditing("new")}><Plus className="h-4 w-4" /> Add address</Button></div>
      {list.length === 0 ? (
        <EmptyState icon={<MapPin className="h-10 w-10" />} title="No saved addresses" description="Add an address to check out faster." />
      ) : (
        <ul className="grid gap-4 sm:grid-cols-2">
          {list.map((a) => (
            <li key={a.id}>
              <Card data-testid="address-card"><CardContent className="space-y-3 p-4">
                <div className="flex items-start justify-between gap-2">
                  <div className="text-sm"><p className="font-semibold">{a.receiverName}</p><p className="text-muted-foreground">{a.phone}</p><p>{a.line1}, {a.city}</p></div>
                  {a.isDefault && <Badge tone="orange">Default</Badge>}
                </div>
                {a.latitude !== undefined && a.longitude !== undefined ? <StaticMap lat={a.latitude} lng={a.longitude} height={140} /> : <p className="text-xs text-muted-foreground">No map pin saved</p>}
                <div className="flex flex-wrap gap-2">
                  <Button size="sm" variant="outline" onClick={() => setEditing(a)}><Pencil className="h-4 w-4" /> Edit</Button>
                  {!a.isDefault && <Button size="sm" variant="outline" onClick={() => setDefaulting(a)}><Star className="h-4 w-4" /> Set default</Button>}
                  <Button size="sm" variant="ghost" className="text-destructive" onClick={() => setDeleting(a)}><Trash2 className="h-4 w-4" /> Delete</Button>
                </div>
              </CardContent></Card>
            </li>
          ))}
        </ul>
      )}

      <Dialog open={editing !== null} onOpenChange={(o) => !o && setEditing(null)}>
        <DialogContent className="max-w-xl">
          <DialogHeader><DialogTitle>{editing === "new" ? "Add address" : "Edit address"}</DialogTitle></DialogHeader>
          {editing !== null && (
            <AddressForm
              key={editing === "new" ? "new" : editing.id}
              initial={editing === "new" ? undefined : editing}
              defaults={{ receiverName: user?.fullName, phone: user?.phone }}
              onCancel={() => setEditing(null)}
              onSubmit={async (input) => {
                if (editing === "new") await m.create.mutateAsync(input);
                else await m.update.mutateAsync({ id: editing.id, body: input });
                setEditing(null);
              }}
            />
          )}
        </DialogContent>
      </Dialog>

      <ConfirmDialog open={!!deleting} onOpenChange={(o) => !o && setDeleting(null)} title="Delete this address?" description={deleting ? `${deleting.line1}, ${deleting.city} will be removed from your account.` : undefined} confirmLabel="Delete" destructive onConfirm={() => (deleting ? m.remove.mutateAsync(deleting.id) : undefined)} />
      <ConfirmDialog open={!!defaulting} onOpenChange={(o) => !o && setDefaulting(null)} title="Make this your default address?" description={defaulting ? `${defaulting.line1}, ${defaulting.city}` : undefined} confirmLabel="Set as default" onConfirm={() => (defaulting ? m.setDefault.mutateAsync(defaulting.id) : undefined)} />
    </div>
  );
}
