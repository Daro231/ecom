import { NOMINATIM_CONTACT } from "./constants";

export interface NominatimResult {
  display_name?: string;
  address?: Record<string, string | undefined>;
}
export interface MappedAddress {
  line1: string;
  city: string;
}

/**
 * Map a Nominatim reverse result to our address fields.
 * In Cambodia Nominatim stores the khan in `town` and the city/province in `state`.
 */
export function mapNominatim(r: NominatimResult): MappedAddress {
  const a = r.address ?? {};
  const city = (a.city ?? a.state ?? a.province ?? "").trim();
  const parts: string[] = [];
  const road = [a.house_number, a.road].filter(Boolean).join(" ").trim();
  const candidates = [
    road,
    a.hamlet,
    a.village,
    a.neighbourhood,
    a.suburb,
    a.quarter,
    a.town,
    a.county,
    a.city_district,
    a.district,
  ];
  const seen = new Set<string>([city.toLowerCase()]);
  for (const c of candidates) {
    const v = c?.trim();
    if (!v) continue;
    const k = v.toLowerCase();
    if (seen.has(k)) continue;
    seen.add(k);
    parts.push(v);
  }
  return { line1: parts.join(", "), city };
}

let lastCall = 0;
/** Reverse geocode with Nominatim, never more than one request per second. */
export async function reverseGeocode(lat: number, lng: number, signal?: AbortSignal): Promise<MappedAddress> {
  const wait = lastCall + 1000 - Date.now();
  if (wait > 0) await new Promise((r) => setTimeout(r, wait));
  lastCall = Date.now();
  const params = new URLSearchParams({
    format: "jsonv2",
    lat: String(lat),
    lon: String(lng),
    "accept-language": "en",
  });
  if (NOMINATIM_CONTACT) params.set("email", NOMINATIM_CONTACT);
  const res = await fetch(`https://nominatim.openstreetmap.org/reverse?${params}`, { signal });
  if (!res.ok) throw new Error(`Nominatim ${res.status}`);
  const json = (await res.json()) as NominatimResult;
  const mapped = mapNominatim(json);
  if (!mapped.line1 && !mapped.city) throw new Error("No address found");
  return mapped;
}
