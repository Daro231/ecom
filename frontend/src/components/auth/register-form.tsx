"use client";
import * as React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Field, Input } from "@/components/ui/input";
import { PasswordInput } from "./password-input";
import { authService } from "@/services/auth";
import { useAuthStore } from "@/store/authStore";
import { queryClient } from "@/lib/query-client";
import { ApiError, errorMessage } from "@/lib/api-error";

export const registerSchema = z
  .object({
    fullName: z.string().trim().min(2, "Enter your full name"),
    email: z.string().min(1, "Email is required").email("Enter a valid email"),
    phone: z.string().trim().regex(/^[0-9+\- ]{8,15}$/, "Enter a valid phone number").or(z.literal("")),
    password: z.string().min(8, "At least 8 characters").regex(/[A-Za-z]/, "Include a letter").regex(/[0-9]/, "Include a number"),
    confirm: z.string(),
  })
  .refine((v) => v.password === v.confirm, { path: ["confirm"], message: "Passwords do not match" });
type Values = z.infer<typeof registerSchema>;

export function RegisterForm() {
  const router = useRouter();
  const setAuth = useAuthStore((s) => s.setAuth);
  const { register, handleSubmit, setError, formState: { errors, isSubmitting } } = useForm<Values>({ resolver: zodResolver(registerSchema) });

  const onSubmit = async (v: Values) => {
    try {
      const res = await authService.register({ fullName: v.fullName, email: v.email.trim(), password: v.password, phone: v.phone || undefined });
      queryClient.clear();
      setAuth(res.accessToken, res.user);
      toast.success("Account created");
      router.replace("/");
      router.refresh();
    } catch (e) {
      if (e instanceof ApiError && e.errors) {
        Object.entries(e.errors).forEach(([k, m]) => k in v && setError(k as keyof Values, { message: m }));
      }
      toast.error(errorMessage(e, "Registration failed"));
    }
  };
  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate className="space-y-4" aria-label="Create account">
      <Field label="Full name" htmlFor="fullName" error={errors.fullName?.message}>
        <Input id="fullName" autoComplete="name" {...register("fullName")} />
      </Field>
      <Field label="Email" htmlFor="email" error={errors.email?.message}>
        <Input id="email" type="email" autoComplete="email" {...register("email")} />
      </Field>
      <Field label="Phone (optional)" htmlFor="phone" error={errors.phone?.message}>
        <Input id="phone" type="tel" autoComplete="tel" {...register("phone")} />
      </Field>
      <Field label="Password" htmlFor="password" error={errors.password?.message} hint="At least 8 characters with a letter and a number">
        <PasswordInput id="password" autoComplete="new-password" {...register("password")} />
      </Field>
      <Field label="Confirm password" htmlFor="confirm" error={errors.confirm?.message}>
        <PasswordInput id="confirm" autoComplete="new-password" {...register("confirm")} />
      </Field>
      <Button type="submit" className="w-full" disabled={isSubmitting}>{isSubmitting ? "Creating…" : "Create account"}</Button>
      <p className="text-center text-sm text-muted-foreground">
        Already registered? <Link className="font-medium text-primary hover:underline" href="/login">Log in</Link>
      </p>
    </form>
  );
}
