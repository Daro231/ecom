"use client";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Field } from "@/components/ui/input";
import { PasswordInput } from "@/components/auth/password-input";
import { authService } from "@/services/auth";
import { ApiError, errorMessage } from "@/lib/api-error";

const schema = z.object({
  currentPassword: z.string().min(1, "Enter your current password"),
  newPassword: z.string().min(8, "At least 8 characters").regex(/[A-Za-z]/, "Include a letter").regex(/[0-9]/, "Include a number"),
  confirm: z.string(),
}).refine((v) => v.newPassword === v.confirm, { path: ["confirm"], message: "Passwords do not match" });
type Values = z.infer<typeof schema>;

export default function PasswordPage() {
  const { register, handleSubmit, reset, setError, formState: { errors, isSubmitting } } = useForm<Values>({ resolver: zodResolver(schema) });
  const onSubmit = async (v: Values) => {
    try {
      await authService.changePassword({ currentPassword: v.currentPassword, newPassword: v.newPassword });
      toast.success("Password changed");
      reset();
    } catch (e) {
      if (e instanceof ApiError && e.errors) Object.entries(e.errors).forEach(([k, m]) => k in v && setError(k as keyof Values, { message: m }));
      toast.error(errorMessage(e));
    }
  };
  return (
    <Card><CardContent className="p-6">
      <form onSubmit={handleSubmit(onSubmit)} noValidate className="max-w-md space-y-4" aria-label="Change password">
        <Field label="Current password" htmlFor="currentPassword" error={errors.currentPassword?.message}><PasswordInput id="currentPassword" autoComplete="current-password" {...register("currentPassword")} /></Field>
        <Field label="New password" htmlFor="newPassword" error={errors.newPassword?.message}><PasswordInput id="newPassword" autoComplete="new-password" {...register("newPassword")} /></Field>
        <Field label="Confirm new password" htmlFor="confirm" error={errors.confirm?.message}><PasswordInput id="confirm" autoComplete="new-password" {...register("confirm")} /></Field>
        <Button type="submit" disabled={isSubmitting}>{isSubmitting ? "Saving…" : "Change password"}</Button>
      </form>
    </CardContent></Card>
  );
}
