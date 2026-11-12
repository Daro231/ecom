"use client";
import * as React from "react";
import { LogOut } from "lucide-react";
import { ConfirmDialog } from "./confirm-dialog";
import { Button } from "@/components/ui/button";
import { logout } from "@/lib/session";
import { cn } from "@/lib/utils";

export function LogoutButton({ className, variant = "ghost", label = "Log out" }: { className?: string; variant?: "ghost" | "outline" | "navy"; label?: string }) {
  const [open, setOpen] = React.useState(false);
  return (
    <>
      <Button variant={variant} className={cn("justify-start", className)} onClick={() => setOpen(true)}>
        <LogOut className="h-4 w-4" /> {label}
      </Button>
      <ConfirmDialog
        open={open}
        onOpenChange={setOpen}
        title="Log out?"
        description="You will need to sign in again to see your orders and account."
        confirmLabel="Log out"
        onConfirm={() => logout()}
      />
    </>
  );
}
