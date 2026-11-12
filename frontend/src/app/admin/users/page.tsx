"use client";
import * as React from "react";
import { useQuery } from "@tanstack/react-query";
import { Search } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input, Select } from "@/components/ui/input";
import { Table, TBody, TD, TH, THead, TR } from "@/components/ui/table";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { EmptyState, ErrorState, ListSkeleton, PageHeader } from "@/components/shared/states";
import { Pagination } from "@/components/shared/pagination";
import { useAdminAction } from "@/hooks/use-admin-action";
import { useDebounced } from "@/hooks/use-debounced";
import { adminService } from "@/services/admin";
import { useAuthStore } from "@/store/authStore";
import { enumLabel, formatDate } from "@/lib/format";
import type { Role, User } from "@/types";

export default function UsersPage() {
  const me = useAuthStore((s) => s.user);
  const [kw, setKw] = React.useState("");
  const keyword = useDebounced(kw, 350);
  const [page, setPage] = React.useState(0);
  const [roleChange, setRoleChange] = React.useState<{ user: User; role: Role } | null>(null);
  const [toggle, setToggle] = React.useState<User | null>(null);
  const q = useQuery({ queryKey: ["admin-users", keyword, page], queryFn: () => adminService.users({ keyword, page, size: 20 }) });
  const setRole = useAdminAction((v: { user: User; role: Role }) => adminService.setUserRole(v.user.id, v.role), { success: (u) => `${u.fullName} is now ${enumLabel(u.role)}`, invalidate: ["admin-users"] });
  const setEnabled = useAdminAction((u: User) => adminService.setUserEnabled(u.id, !u.enabled), { success: (u) => (u.enabled ? "Account enabled" : "Account disabled"), invalidate: ["admin-users"] });
  return (
    <div>
      <PageHeader title="Users" />
      <div className="relative mb-4 max-w-sm"><Search className="pointer-events-none absolute left-3 top-2.5 h-4 w-4 text-muted-foreground" /><Input aria-label="Search users" className="pl-9" placeholder="Search name or email…" value={kw} onChange={(e) => { setKw(e.target.value); setPage(0); }} /></div>
      {q.isLoading ? <ListSkeleton rows={5} className="h-12" /> : q.isError ? <ErrorState error={q.error} onRetry={() => q.refetch()} /> : !q.data?.content.length ? <EmptyState title="No users found" /> : (
        <div className="rounded-lg border bg-card">
          <Table aria-label="Users">
            <THead><TR><TH>User</TH><TH>Role</TH><TH>Joined</TH><TH>Status</TH><TH className="text-right">Actions</TH></TR></THead>
            <TBody>{q.data.content.map((u) => {
              const self = u.id === me?.id;
              return (
                <TR key={u.id} data-testid="user-row">
                  <TD><p className="font-medium">{u.fullName}{self && <span className="ml-2 text-xs text-muted-foreground">(you)</span>}</p><p className="text-xs text-muted-foreground">{u.email}</p></TD>
                  <TD><Select aria-label={`Role for ${u.fullName}`} className="h-9 w-36" value={u.role} disabled={self} title={self ? "You cannot change your own role" : undefined} onChange={(e) => setRoleChange({ user: u, role: e.target.value as Role })}>
                    {(["ADMIN", "STAFF", "CUSTOMER"] as Role[]).map((r) => <option key={r} value={r}>{enumLabel(r)}</option>)}</Select></TD>
                  <TD className="whitespace-nowrap">{formatDate(u.createdAt)}</TD>
                  <TD><Badge tone={u.enabled ? "green" : "red"}>{u.enabled ? "Enabled" : "Disabled"}</Badge></TD>
                  <TD className="text-right"><Button size="sm" variant={u.enabled ? "outline" : "secondary"} disabled={self} title={self ? "You cannot disable your own account" : undefined} onClick={() => setToggle(u)}>{u.enabled ? "Disable" : "Enable"}</Button></TD>
                </TR>);
            })}</TBody>
          </Table>
        </div>
      )}
      <Pagination page={q.data?.page ?? 0} totalPages={q.data?.totalPages ?? 0} onPage={setPage} />
      <ConfirmDialog open={!!roleChange} onOpenChange={(o) => !o && setRoleChange(null)} title="Change role?" description={roleChange ? <>{roleChange.user.fullName} will become <strong>{enumLabel(roleChange.role)}</strong>.</> : undefined} confirmLabel="Change role" onConfirm={() => (roleChange ? setRole.mutateAsync(roleChange) : undefined)} />
      <ConfirmDialog open={!!toggle} onOpenChange={(o) => !o && setToggle(null)} title={toggle?.enabled ? "Disable account?" : "Enable account?"} description={toggle ? (toggle.enabled ? <>{toggle.fullName} will no longer be able to sign in.</> : <>{toggle.fullName} will be able to sign in again.</>) : undefined} confirmLabel={toggle?.enabled ? "Disable account" : "Enable account"} destructive={toggle?.enabled} onConfirm={() => (toggle ? setEnabled.mutateAsync(toggle) : undefined)} />
    </div>
  );
}
