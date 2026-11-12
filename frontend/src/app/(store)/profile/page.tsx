"use client";
import * as React from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Field, Input } from "@/components/ui/input";
import { authService } from "@/services/auth";
import { useAuthStore } from "@/store/authStore";
import { ApiError, errorMessage } from "@/lib/api-error";
import { formatDate } from "@/lib/format";

const schema = z.object({
  fullName: z.string().trim().min(2, "Enter your full name"),
  phone: z.string().trim().regex(/^[0-9+\- ]{8,15}$/, "Enter a valid phone number").or(z.literal("")),
});
type Values = z.infer<typeof schema>;

export default function ProfilePage() {
  const user = useAuthStore((s) => s.user);
  const setUser = useAuthStore((s) => s.setUser);
  const { register, handleSubmit, reset, setError, formState: { errors, isSubmitting, isDirty } } = useForm<Values>({ resolver: zodResolver(schema), values: { fullName: user?.fullName ?? "", phone: user?.phone ?? "" } });
  const onSubmit = async (v: Values) => {
    try {
      const u = await authService.updateMe({ fullName: v.fullName, phone: v.phone || undefined });
      setUser(u);
      reset({ fullName: u.fullName, phone: u.phone ?? "" });
      toast.success("Profile updated");
    } catch (e) {
      if (e instanceof ApiError && e.errors) Object.entries(e.errors).forEach(([k, m]) => k in v && setError(k as keyof Values, { message: m }));
      toast.error(errorMessage(e));
    }
  };
  return (
    <Card><CardContent className="p-6">
      <form onSubmit={handleSubmit(onSubmit)} noValidate className="max-w-md space-y-4" aria-label="Edit profile">
        <Field label="Email" htmlFor="email"><Input id="email" value={user?.email ?? ""} readOnly disabled /></Field>
        <Field label="Full name" htmlFor="fullName" error={errors.fullName?.message}><Input id="fullName" {...register("fullName")} /></Field>
        <Field label="Phone" htmlFor="phone" error={errors.phone?.message}><Input id="phone" type="tel" {...register("phone")} /></Field>
        <p className="text-xs text-muted-foreground">Member since {formatDate(user?.createdAt)}</p>
        <Button type="submit" disabled={isSubmitting || !isDirty}>{isSubmitting ? "Saving…" : "Save changes"}</Button>
      </form>
    </CardContent></Card>
  );
}
