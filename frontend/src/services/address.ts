import { del, get, patch, post, put } from "@/lib/api";
import type { Address, AddressInput } from "@/types";

export const addressService = {
  list: () => get<Address[]>("/users/me/addresses"),
  create: (b: AddressInput) => post<Address>("/users/me/addresses", b),
  update: (id: number, b: AddressInput) => put<Address>(`/users/me/addresses/${id}`, b),
  remove: (id: number) => del(`/users/me/addresses/${id}`),
  setDefault: (id: number) => patch<Address>(`/users/me/addresses/${id}/default`),
};
