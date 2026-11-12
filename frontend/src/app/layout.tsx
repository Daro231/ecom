import type { Metadata } from "next";
import "./globals.css";
import "leaflet/dist/leaflet.css";
import { Providers } from "@/components/shared/providers";

export const metadata: Metadata = {
  title: { default: "ecom — Computers & accessories", template: "%s · ecom" },
  description: "Laptops, desktops, monitors, components and accessories.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className="min-h-screen font-sans">
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
