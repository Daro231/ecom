import { Header } from "@/components/store/header";
import { Footer } from "@/components/store/footer";

export default function StoreLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen flex-col">
      <Header />
      <main className="container flex-1 py-6">{children}</main>
      <Footer />
    </div>
  );
}
