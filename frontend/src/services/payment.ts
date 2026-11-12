import { get, post, postWithTime } from "@/lib/api";
import type { KhqrData, Payment } from "@/types";

export const paymentService = {
  khqr: async (n: string): Promise<KhqrData> => {
    const { data, serverTime } = await postWithTime<KhqrData>(`/payments/${n}/khqr`);
    return { ...data, serverTime };
  },
  status: (n: string) => get<Payment>(`/payments/${n}/status`),
  /** MOCK mode only (404 in BAKONG mode). */
  simulate: (orderNumber: string, transactionRef: string) =>
    post<Payment>("/payments/callback", { transactionRef, orderNumber, status: "PAID" }),
};
