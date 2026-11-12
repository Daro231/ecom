import axios, { AxiosError } from "axios";
import type { ApiResponse } from "@/types";
import { API_URL } from "./constants";
import { ApiError } from "./api-error";
import { useAuthStore } from "@/store/authStore";
import { clearSession } from "./session";

export const api = axios.create({ baseURL: API_URL, timeout: 20000 });

api.interceptors.request.use((config) => {
  const token = useAuthStore.getState().token;
  if (token) config.headers.set("Authorization", `Bearer ${token}`);
  return config;
});

api.interceptors.response.use(
  (res) => res,
  (error: AxiosError<ApiResponse<unknown>>) => {
    const status = error.response?.status ?? 0;
    const url = error.config?.url ?? "";
    if (status === 401 && !url.includes("/auth/") && typeof window !== "undefined") {
      const hadToken = !!useAuthStore.getState().token;
      clearSession();
      if (hadToken && !window.location.pathname.startsWith("/login")) {
        const redirect = encodeURIComponent(window.location.pathname + window.location.search);
        window.location.href = `/login?redirect=${redirect}`;
      }
    }
    const body = error.response?.data;
    const message =
      body?.message ?? (error.code === "ECONNABORTED" ? "The request timed out" : error.message || "Network error");
    return Promise.reject(new ApiError(message, status, body?.errors));
  },
);

export async function get<T>(url: string, params?: object): Promise<T> {
  const res = await api.get<ApiResponse<T>>(url, { params });
  return res.data.data as T;
}
export async function post<T>(url: string, body?: unknown): Promise<T> {
  const res = await api.post<ApiResponse<T>>(url, body);
  return res.data.data as T;
}
export async function put<T>(url: string, body?: unknown): Promise<T> {
  const res = await api.put<ApiResponse<T>>(url, body);
  return res.data.data as T;
}
export async function patch<T>(url: string, body?: unknown, params?: object): Promise<T> {
  const res = await api.patch<ApiResponse<T>>(url, body, { params });
  return res.data.data as T;
}
export async function del<T = void>(url: string): Promise<T> {
  const res = await api.delete<ApiResponse<T>>(url);
  return res.data.data as T;
}

/** POST that also returns the server timestamp from the envelope (used for server-side clocks). */
export async function postWithTime<T>(url: string, body?: unknown): Promise<{ data: T; serverTime?: string }> {
  const res = await api.post<ApiResponse<T>>(url, body);
  return { data: res.data.data as T, serverTime: res.data.timestamp };
}
