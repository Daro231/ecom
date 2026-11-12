"use client";
import * as React from "react";
import { useRouter } from "next/navigation";
import { useAuthStore } from "@/store/authStore";
import { homeFor } from "@/lib/redirect";

export default function AdminIndex() {
  const router = useRouter();
  const user = useAuthStore((s) => s.user);
  React.useEffect(() => { if (user) router.replace(homeFor(user.role)); }, [user, router]);
  return null;
}
