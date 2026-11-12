"use client";
import * as React from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
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
import { homeFor, safeRedirect } from "@/lib/redirect";

export const loginSchema = z.object({
  email: z.string().min(1, "Email is required").email("Enter a valid email"),
  password: z.string().min(1, "Password is required"),
});
type LoginValues = z.infer<typeof loginSchema>;

export function LoginForm() {
  const router = useRouter();
  const params = useSearchParams();
  const setAuth = useAuthStore((s) => s.setAuth);
  const { register, handleSubmit, setError, formState: { errors, isSubmitting } } = useForm<LoginValues>({
    resolver: zodResolver(loginSchema),
  });

  const onSubmit = async (v: LoginValues) => {
    try {
      const res = await authService.login(v.email.trim(), v.password);
      queryClient.clear(); // never show the previous user's cached data
      setAuth(res.accessToken, res.user);
      toast.success(`Welcome back, ${res.user.fullName}`);
      const target = safeRedirect(params.get("redirect"));
      const isStaff = res.user.role !== "CUSTOMER";
      const dest = target && (!target.startsWith("/admin") || isStaff) ? target : homeFor(res.user.role);
      router.replace(dest);
      router.refresh();
    } catch (e) {
      if (e instanceof ApiError && e.errors) {
        Object.entries(e.errors).forEach(([k, m]) => k in v && setError(k as keyof LoginValues, { message: m }));
      }
      toast.error(errorMessage(e, "Login failed"));
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate className="space-y-4" aria-label="Log in">
      <Field label="Email" htmlFor="email" error={errors.email?.message}>
        <Input id="email" type="email" autoComplete="email" {...register("email")} aria-invalid={!!errors.email} />
      </Field>
      <Field label="Password" htmlFor="password" error={errors.password?.message}>
        <PasswordInput id="password" autoComplete="current-password" {...register("password")} aria-invalid={!!errors.password} />
      </Field>
      <Button type="submit" className="w-full" disabled={isSubmitting}>
        {isSubmitting ? "Signing in…" : "Log in"}
      </Button>
      <p className="text-center text-sm text-muted-foreground">
        New here? <Link className="font-medium text-primary hover:underline" href="/register">Create an account</Link>
      </p>
    </form>
  );
}
