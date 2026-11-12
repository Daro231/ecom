"use client";
import * as React from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Button } from "@/components/ui/button";
import { Field, Input } from "@/components/ui/input";
import { AddressMap } from "@/components/shared/address-map-loader";
import type { LatLng, PinSource } from "@/components/shared/address-map";
import { reverseGeocode } from "@/lib/geocoder";
import { ApiError } from "@/lib/api-error";
import type { Address, AddressInput } from "@/types";

export const addressSchema = z.object({
  receiverName: z.string().trim().min(2, "Enter the receiver's name"),
  phone: z.string().trim().regex(/^[0-9+\- ]{8,15}$/, "Enter a valid phone number"),
  line1: z.string().trim().min(3, "Enter the street address"),
  city: z.string().trim().min(2, "Enter the city"),
  isDefault: z.boolean(),
});
export type AddressValues = z.infer<typeof addressSchema>;

const round6 = (n: number) => Math.round(n * 1e6) / 1e6;

/** Build the request body. Coordinates are always sent while a pin exists (PUT replaces all fields). */
export function buildAddressInput(v: AddressValues, pin: LatLng | null): AddressInput {
  const base: AddressInput = { receiverName: v.receiverName.trim(), phone: v.phone.trim(), line1: v.line1.trim(), city: v.city.trim(), isDefault: v.isDefault };
  if (pin) {
    base.latitude = round6(pin.lat);
    base.longitude = round6(pin.lng);
  }
  return base;
}

interface Props {
  initial?: Address;
  defaults?: { receiverName?: string; phone?: string };
  submitLabel?: string;
  onSubmit: (input: AddressInput) => Promise<unknown> | void;
  onCancel?: () => void;
  hideDefaultToggle?: boolean;
}

export function AddressForm({ initial, defaults, submitLabel = "Save address", onSubmit, onCancel, hideDefaultToggle }: Props) {
  const { register, handleSubmit, setValue, setError, formState: { errors, isSubmitting } } = useForm<AddressValues>({
    resolver: zodResolver(addressSchema),
    defaultValues: {
      receiverName: initial?.receiverName ?? defaults?.receiverName ?? "",
      phone: initial?.phone ?? defaults?.phone ?? "",
      line1: initial?.line1 ?? "",
      city: initial?.city ?? "",
      isDefault: initial?.isDefault ?? false,
    },
  });
  const [pin, setPin] = React.useState<LatLng | null>(
    initial?.latitude !== undefined && initial?.longitude !== undefined ? { lat: initial.latitude, lng: initial.longitude } : null,
  );
  // fields the user typed in (or that already had saved text) are never overwritten by the geocoder
  const typed = React.useRef({ line1: !!initial?.line1, city: !!initial?.city });
  const [geoNote, setGeoNote] = React.useState<string | null>(null);
  const [geoBusy, setGeoBusy] = React.useState(false);
  const timer = React.useRef<ReturnType<typeof setTimeout>>();
  const abort = React.useRef<AbortController>();
  const line1Reg = register("line1");
  const cityReg = register("city");

  React.useEffect(() => () => { clearTimeout(timer.current); abort.current?.abort(); }, []);

  const onPin = (pos: LatLng | null, source: PinSource) => {
    setPin(pos);
    setGeoNote(null);
    clearTimeout(timer.current);
    abort.current?.abort();
    if (!pos || source === "remove") return;
    timer.current = setTimeout(async () => {
      const ctl = new AbortController();
      abort.current = ctl;
      setGeoBusy(true);
      try {
        const r = await reverseGeocode(pos.lat, pos.lng, ctl.signal);
        if (r.line1 && !typed.current.line1) setValue("line1", r.line1, { shouldValidate: true });
        if (r.city && !typed.current.city) setValue("city", r.city, { shouldValidate: true });
      } catch (e) {
        if ((e as Error).name !== "AbortError") setGeoNote("We could not look up the address for this pin. Please type the address and city.");
      } finally {
        setGeoBusy(false);
      }
    }, 1000);
  };

  const submit = handleSubmit(async (v) => {
    try {
      await onSubmit(buildAddressInput(v, pin));
    } catch (e) {
      if (e instanceof ApiError && e.errors) {
        Object.entries(e.errors).forEach(([k, m]) => {
          if (k in v) setError(k as keyof AddressValues, { message: m });
        });
      }
    }
  });

  return (
    <form onSubmit={submit} noValidate className="space-y-4" aria-label={initial ? "Edit address" : "New address"}>
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Receiver name" htmlFor="receiverName" error={errors.receiverName?.message}>
          <Input id="receiverName" autoComplete="name" {...register("receiverName")} />
        </Field>
        <Field label="Phone" htmlFor="phone" error={errors.phone?.message}>
          <Input id="phone" type="tel" autoComplete="tel" {...register("phone")} />
        </Field>
      </div>
      <Field label="Address" htmlFor="line1" error={errors.line1?.message} hint={geoBusy ? "Looking up the address…" : undefined}>
        <Input id="line1" autoComplete="street-address" {...line1Reg} onChange={(e) => { typed.current.line1 = e.target.value.trim() !== ""; line1Reg.onChange(e); }} />
      </Field>
      <Field label="City" htmlFor="city" error={errors.city?.message}>
        <Input id="city" autoComplete="address-level2" {...cityReg} onChange={(e) => { typed.current.city = e.target.value.trim() !== ""; cityReg.onChange(e); }} />
      </Field>
      <div>
        <p className="mb-2 text-sm font-medium">Delivery location (optional)</p>
        <AddressMap value={pin} onChange={onPin} height={240} />
        {geoNote && <p role="status" className="mt-2 text-sm text-amber-700 dark:text-amber-300">{geoNote}</p>}
      </div>
      {!hideDefaultToggle && (
        <label className="flex cursor-pointer items-center gap-2 text-sm">
          <input type="checkbox" className="h-4 w-4 accent-[hsl(var(--primary))]" {...register("isDefault")} /> Set as my default address
        </label>
      )}
      <div className="flex justify-end gap-2">
        {onCancel && <Button variant="outline" onClick={onCancel}>Cancel</Button>}
        <Button type="submit" disabled={isSubmitting}>{isSubmitting ? "Saving…" : submitLabel}</Button>
      </div>
    </form>
  );
}
