/** Message shown when the browser position is imprecise (> 100 m), e.g. desktop PCs without GPS. */
export function accuracyWarning(accuracyMeters: number): string | null {
  if (!(accuracyMeters > 100)) return null;
  const m = Math.round(accuracyMeters);
  const spread = m >= 1000 ? `±${m.toLocaleString("en-US")} m / ±${(m / 1000).toFixed(1)} km` : `±${m} m`;
  return `Your location is approximate (${spread}). Please drag the pin to your exact location.`;
}

export function geolocationErrorMessage(code: number): string {
  switch (code) {
    case 1:
      return "Location permission was denied. Allow location access in your browser, or click the map to place the pin.";
    case 2:
      return "Your location is unavailable right now. Click the map to place the pin.";
    case 3:
      return "Finding your location took too long. Try again, or click the map to place the pin.";
    default:
      return "Could not get your location. Click the map to place the pin.";
  }
}
