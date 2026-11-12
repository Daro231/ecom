import Link from "next/link";

export function Footer() {
  return (
    <footer className="no-print mt-16 bg-navy text-slate-300">
      <div className="container grid gap-6 py-10 text-sm sm:grid-cols-3">
        <div>
          <p className="text-lg font-bold text-white">ecom</p>
          <p className="mt-2">Laptops, desktops, monitors, components and accessories — delivered across Cambodia.</p>
        </div>
        <div>
          <p className="font-semibold text-white">Shop</p>
          <ul className="mt-2 space-y-1">
            {["laptop", "desktop", "monitor", "component", "accessory"].map((c) => (
              <li key={c}><Link className="capitalize hover:text-white" href={`/products?keyword=${c}`}>{c}s</Link></li>
            ))}
          </ul>
        </div>
        <div>
          <p className="font-semibold text-white">Account</p>
          <ul className="mt-2 space-y-1">
            <li><Link className="hover:text-white" href="/orders">My orders</Link></li>
            <li><Link className="hover:text-white" href="/profile">Profile</Link></li>
            <li><Link className="hover:text-white" href="/cart">Cart</Link></li>
          </ul>
        </div>
      </div>
    </footer>
  );
}
