"use client";
import L from "leaflet";
import { MapContainer, Marker, TileLayer } from "react-leaflet";
import { googleMapsUrl } from "@/lib/format";

const pin = L.divIcon({
  className: "",
  html: `<svg width="28" height="40" viewBox="0 0 32 44" xmlns="http://www.w3.org/2000/svg"><path d="M16 0C7.2 0 0 7 0 15.7 0 27.5 16 44 16 44s16-16.5 16-28.3C32 7 24.8 0 16 0z" fill="#FF7A1A" stroke="#0B1F3A" stroke-width="2"/><circle cx="16" cy="15.5" r="6" fill="#0B1F3A"/></svg>`,
  iconSize: [28, 40],
  iconAnchor: [14, 40],
});

/** Read-only map with the delivery pin. Clicking it opens Google Maps. */
export default function StaticMap({ lat, lng, height = 180 }: { lat: number; lng: number; height?: number }) {
  return (
    <div className="relative overflow-hidden rounded-md border" style={{ height }} data-testid="static-map">
      <MapContainer center={[lat, lng]} zoom={16} dragging={false} zoomControl={false} scrollWheelZoom={false} doubleClickZoom={false} touchZoom={false} keyboard={false} style={{ height: "100%", width: "100%" }}>
        <TileLayer attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>' url="https://tile.openstreetmap.org/{z}/{x}/{y}.png" />
        <Marker position={[lat, lng]} icon={pin} interactive={false} />
      </MapContainer>
      <a href={googleMapsUrl(lat, lng)} target="_blank" rel="noopener noreferrer" aria-label="Open delivery location in Google Maps" className="absolute inset-0 z-[500] cursor-pointer focus-visible:ring-2 focus-visible:ring-ring" />
    </div>
  );
}
