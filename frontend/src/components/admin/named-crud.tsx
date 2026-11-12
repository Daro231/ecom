"use client";
import * as React from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Pencil, Plus, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Field, Input, Textarea } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Table, TBody, TD, TH, THead, TR } from "@/components/ui/table";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { EmptyState, ErrorState, ListSkeleton, PageHeader } from "@/components/shared/states";
import { useAdminAction } from "@/hooks/use-admin-action";
import { ApiError } from "@/lib/api-error";

export interface NamedItem { id: number; name: string; slug: string; description?: string }
const schema = z.object({ name: z.string().trim().min(2, "Name is required").max(100), description: z.string().max(500) });
type Values = z.infer<typeof schema>;

interface Props {
  singular: string; plural: string; withDescription?: boolean;
  items?: NamedItem[]; loading: boolean; error: unknown; onRetry: () => void; queryKey: string;
  create: (v: { name: string; description?: string }) => Promise<unknown>;
  update: (id: number, v: { name: string; description?: string }) => Promise<unknown>;
  remove: (id: number) => Promise<unknown>;
}

export function NamedCrud({ singular, plural, withDescription, items, loading, error, onRetry, queryKey, create, update, remove }: Props) {
  const [editing, setEditing] = React.useState<NamedItem | "new" | null>(null);
  const [del, setDel] = React.useState<NamedItem | null>(null);
  const { register, handleSubmit, reset, setError, formState: { errors } } = useForm<Values>({ resolver: zodResolver(schema), defaultValues: { name: "", description: "" } });
  React.useEffect(() => {
    if (editing) reset({ name: editing === "new" ? "" : editing.name, description: editing === "new" ? "" : editing.description ?? "" });
  }, [editing, reset]);

  const save = useAdminAction(
    async (v: Values) => {
      const body = withDescription ? { name: v.name, description: v.description.trim() || undefined } : { name: v.name };
      return editing === "new" ? create(body) : update((editing as NamedItem).id, body);
    },
    { success: `${singular} saved`, invalidate: [queryKey], onError: (e) => { if (e instanceof ApiError && e.status === 409) { setError("name", { message: "This name already exists" }); return "Name already exists"; } } },
  );
  const rm = useAdminAction((i: NamedItem) => remove(i.id), {
    success: `${singular} deleted`, invalidate: [queryKey],
    onError: (e) => (e instanceof ApiError && e.status === 409 ? `This ${singular.toLowerCase()} is used by products and cannot be deleted.` : undefined),
  });

  return (
    <div>
      <PageHeader title={plural} actions={<Button onClick={() => setEditing("new")}><Plus className="h-4 w-4" /> New {singular.toLowerCase()}</Button>} />
      {loading ? <ListSkeleton rows={5} className="h-12" /> : error ? <ErrorState error={error} onRetry={onRetry} /> : !items?.length ? <EmptyState title={`No ${plural.toLowerCase()} yet`} /> : (
        <div className="rounded-lg border bg-card">
          <Table aria-label={plural}>
            <THead><TR><TH>Name</TH><TH>Slug</TH>{withDescription && <TH>Description</TH>}<TH className="text-right">Actions</TH></TR></THead>
            <TBody>
              {items.map((i) => (
                <TR key={i.id} data-testid="crud-row">
                  <TD className="font-medium">{i.name}</TD><TD className="text-muted-foreground">{i.slug}</TD>
                  {withDescription && <TD className="max-w-xs truncate text-muted-foreground">{i.description ?? "—"}</TD>}
                  <TD><div className="flex justify-end gap-1">
                    <Button size="icon" variant="ghost" aria-label={`Edit ${i.name}`} onClick={() => setEditing(i)}><Pencil className="h-4 w-4" /></Button>
                    <Button size="icon" variant="ghost" className="text-destructive" aria-label={`Delete ${i.name}`} onClick={() => setDel(i)}><Trash2 className="h-4 w-4" /></Button>
                  </div></TD>
                </TR>
              ))}
            </TBody>
          </Table>
        </div>
      )}
      <Dialog open={editing !== null} onOpenChange={(o) => !o && setEditing(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>{editing === "new" ? `New ${singular.toLowerCase()}` : `Edit ${singular.toLowerCase()}`}</DialogTitle></DialogHeader>
          <form noValidate className="space-y-4" onSubmit={handleSubmit(async (v) => { try { await save.mutateAsync(v); setEditing(null); } catch { /* shown */ } })}>
            <Field label="Name" htmlFor="crud-name" error={errors.name?.message}><Input id="crud-name" {...register("name")} /></Field>
            {withDescription && <Field label="Description" htmlFor="crud-desc" error={errors.description?.message}><Textarea id="crud-desc" {...register("description")} /></Field>}
            <div className="flex justify-end gap-2"><Button variant="outline" onClick={() => setEditing(null)}>Cancel</Button><Button type="submit" disabled={save.isPending}>{save.isPending ? "Saving…" : "Save"}</Button></div>
          </form>
        </DialogContent>
      </Dialog>
      <ConfirmDialog open={!!del} onOpenChange={(o) => !o && setDel(null)} title={`Delete ${singular.toLowerCase()}?`} description={del ? <>“{del.name}” will be deleted. This cannot be undone.</> : undefined} confirmLabel="Delete" destructive onConfirm={() => (del ? rm.mutateAsync(del) : undefined)} />
    </div>
  );
}
