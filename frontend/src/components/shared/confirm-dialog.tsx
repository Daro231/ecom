"use client";
import * as React from "react";
import * as AD from "@radix-ui/react-alert-dialog";
import { Button } from "@/components/ui/button";

export interface ConfirmDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  description?: React.ReactNode;
  confirmLabel?: string;
  cancelLabel?: string;
  destructive?: boolean;
  confirmDisabled?: boolean;
  onConfirm: () => void | Promise<unknown>;
  children?: React.ReactNode;
}

/** Confirmation dialog: confirm runs the action then closes; cancel/Escape only closes. */
export function ConfirmDialog({
  open, onOpenChange, title, description, confirmLabel = "Confirm", cancelLabel = "Cancel",
  destructive, confirmDisabled, onConfirm, children,
}: ConfirmDialogProps) {
  const [busy, setBusy] = React.useState(false);
  const run = async () => {
    setBusy(true);
    try {
      await onConfirm();
    } catch {
      /* the caller reports errors (toast); the dialog still closes */
    } finally {
      setBusy(false);
      onOpenChange(false);
    }
  };
  return (
    <AD.Root open={open} onOpenChange={onOpenChange}>
      <AD.Portal>
        <AD.Overlay className="fixed inset-0 z-[60] bg-black/60" />
        <AD.Content className="fixed left-1/2 top-1/2 z-[60] grid w-[calc(100%-2rem)] max-w-md -translate-x-1/2 -translate-y-1/2 gap-4 rounded-lg border bg-card p-6 shadow-lg">
          <div className="space-y-2">
            <AD.Title className="text-lg font-semibold">{title}</AD.Title>
            <AD.Description asChild>
              <div className="text-sm text-muted-foreground">{description ?? "Are you sure?"}</div>
            </AD.Description>
          </div>
          {children}
          <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
            <AD.Cancel asChild>
              <Button variant="outline" disabled={busy}>
                {cancelLabel}
              </Button>
            </AD.Cancel>
            <Button variant={destructive ? "destructive" : "default"} onClick={run} disabled={busy || confirmDisabled}>
              {busy ? "Working…" : confirmLabel}
            </Button>
          </div>
        </AD.Content>
      </AD.Portal>
    </AD.Root>
  );
}
