import { get, post, put } from "@/lib/api";
import type { AuthResult, User } from "@/types";

export const authService = {
  login: (email: string, password: string) => post<AuthResult>("/auth/login", { email, password }),
  register: (b: { fullName: string; email: string; password: string; phone?: string }) =>
    post<AuthResult>("/auth/register", b),
  me: () => get<User>("/users/me"),
  updateMe: (b: { fullName: string; phone?: string }) => put<User>("/users/me", b),
  changePassword: (b: { currentPassword: string; newPassword: string }) => put<void>("/users/me/password", b),
};
