"use client";
import * as React from "react";
import L from "leaflet";
import { Circle, MapContainer, Marker, TileLayer, useMap, useMapEvents } from "react-leaflet";
import { Crosshair, Loader2, MapPinOff } from "lucide-react";
import { Button } from "@/components/ui/button";
import { PHNOM_PENH } from "@/lib/constants";
import { accuracyWarning, geolocationErrorMessage } from "@/lib/geo";

export interface LatLng { lat: number; lng: number }
export type PinSource = "click" | "drag" | "geolocate" | "remove";
export interface AddressMapProps {
  value: LatLng | null;
  onChange: (pos: LatLng | null, source: PinSource) => void;
  height?: number;
}

const pinIcon = L.divIcon({
  className: "",
  html: `<svg width="32" height="44" viewBox="0 0 32 44" xmlns="http://www.w3.org/2000/svg"><path d="M16 0C7.2 0 0 7 0 15.7 0 27.5 16 44 16 44s16-16.5 16-28.3C32 7 24.8 0 16 0z" fill="#FF7A1A" stroke="#0B1F3A" stroke-width="2"/><circle cx="16" cy="15.5" r="6" fill="#0B1F3A"/></svg>`,
  iconSize: [32, 44],
  iconAnchor: [16, 44],
});

function ClickHandler({ onPick }: { onPick: (p: LatLng) => void }) {
  useMapEvents({ click: (e) => onPick({ lat: e.latlng.lat, lng: e.latlng.lng }) });
  return null;
}

function Viewport({ target }: { target: { center: LatLng; accuracy?: number; seq: number } | null }) {
  const map = useMap();
  React.useEffect(() => {
    if (!target) return;
    const c = L.latLng(target.center.lat, target.center.lng);
    if (target.accuracy && target.accuracy > 100) map.fitBounds(c.toBounds(target.accuracy * 2), { animate: true, maxZoom: 17 });
    else map.setView(c, Math.max(map.getZoom(), 17), { animate: true });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [target?.seq]);
  return null;
}

export default function AddressMap({ value, onChange, height = 240 }: AddressMapProps) {
  const [busy, setBusy] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);
  const [accuracy, setAccuracy] = React.useState<number | null>(null);
  const [target, setTarget] = React.useState<{ center: LatLng; accuracy?: number; seq: number } | null>(
    value ? { center: value, seq: 0 } : null,
  );
  const seq = React.useRef(1);

  const manual = (pos: LatLng, source: PinSource) => {
    setAccuracy(null); // moving the pin manually removes the circle and warning
    setError(null);
    onChange(pos, source);
  };

  const locate = () => {
    setError(null);
    if (typeof navigator === "undefined" || !navigator.geolocation) {
      setError("Your browser does not support location. Click the map to place the pin.");
      return;
    }
    setBusy(true);
    navigator.geolocation.getCurrentPosition(
      (p) => {
        setBusy(false);
        const pos = { lat: p.coords.latitude, lng: p.coords.longitude };
        setAccuracy(p.coords.accuracy);
        setTarget({ center: pos, accuracy: p.coords.accuracy, seq: seq.current++ });
        onChange(pos, "geolocate");
      },
      (err) => {
        setBusy(false);
        setError(geolocationErrorMessage(err.code));
      },
      { enableHighAccuracy: true, timeout: 10_000, maximumAge: 0 },
    );
  };

  const remove = () => {
    setAccuracy(null);
    setError(null);
    onChange(null, "remove");
  };

  const warning = accuracy !== null ? accuracyWarning(accuracy) : null;
  const center = value ?? { lat: PHNOM_PENH[0], lng: PHNOM_PENH[1] };

  return (
    <div className="space-y-2" data-testid="address-map">
      <div className="flex flex-wrap items-center gap-2">
        <Button type="button" variant="outline" size="sm" onClick={locate} disabled={busy}>
          {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : <Crosshair className="h-4 w-4" />}
          {busy ? "Locating…" : "Use my current location"}
        </Button>
        <Button type="button" variant="ghost" size="sm" onClick={remove} disabled={!value}>
          <MapPinOff className="h-4 w-4" /> Remove pin
        </Button>
        <span className="text-xs text-muted-foreground">
          {value ? `${value.lat.toFixed(6)}, ${value.lng.toFixed(6)}` : "Click the map to place a pin (optional)"}
        </span>
      </div>
      <div className="overflow-hidden rounded-md border" style={{ height }}>
        <MapContainer center={[center.lat, center.lng]} zoom={value ? 16 : 12} scrollWheelZoom style={{ height: "100%", width: "100%" }}>
          <TileLayer attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors' url="https://tile.openstreetmap.org/{z}/{x}/{y}.png" />
          <ClickHandler onPick={(p) => manual(p, "click")} />
          <Viewport target={target} />
          {value && accuracy !== null && <Circle center={[value.lat, value.lng]} radius={accuracy} pathOptions={{ color: "#2563eb", weight: 1, fillOpacity: 0.12 }} />}
          {value && (
            <Marker
              position={[value.lat, value.lng]}
              icon={pinIcon}
              draggable
              eventHandlers={{ dragend: (e) => { const ll = (e.target as L.Marker).getLatLng(); manual({ lat: ll.lat, lng: ll.lng }, "drag"); } }}
            />
          )}
        </MapContainer>
      </div>
      {warning && <p role="status" data-testid="accuracy-warning" className="rounded-md bg-amber-100 px-3 py-2 text-sm text-amber-900 dark:bg-amber-900/40 dark:text-amber-100">{warning}</p>}
      {error && <p role="alert" data-testid="geo-error" className="rounded-md bg-red-100 px-3 py-2 text-sm text-red-800 dark:bg-red-900/40 dark:text-red-100">{error}</p>}
    </div>
  );
}
