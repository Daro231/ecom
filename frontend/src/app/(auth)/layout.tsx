import Link from "next/link";
import { ThemeToggle } from "@/components/shared/theme-toggle";

export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen flex-col bg-gradient-to-br from-navy to-navy-light">
      <div className="container flex h-16 items-center justify-between text-white">
        <Link href="/" className="flex items-center gap-2 text-xl font-extrabold">
          <span className="flex h-8 w-8 items-center justify-center rounded-md bg-brand text-navy">e</span> ecom
        </Link>
        <ThemeToggle className="text-white hover:bg-white/10" />
      </div>
      <main className="flex flex-1 items-center justify-center px-4 pb-16">{children}</main>
    </div>
  );
}
