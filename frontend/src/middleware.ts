import { NextResponse, type NextRequest } from "next/server";

export function middleware(req: NextRequest) {
  const { pathname, search } = req.nextUrl;
  const token = req.cookies.get("ecom_token")?.value;
  const role = req.cookies.get("ecom_role")?.value;

  if (!token) {
    const url = req.nextUrl.clone();
    url.pathname = "/login";
    url.search = `?redirect=${encodeURIComponent(pathname + search)}`;
    const res = NextResponse.redirect(url);
    res.headers.set("Cache-Control", "no-store");
    return res;
  }
  if (pathname.startsWith("/admin") && role !== "ADMIN" && role !== "STAFF") {
    const url = req.nextUrl.clone();
    url.pathname = "/";
    url.search = "";
    return NextResponse.redirect(url);
  }
  const res = NextResponse.next();
  res.headers.set("Cache-Control", "no-store, must-revalidate");
  return res;
}

export const config = {
  matcher: [
    "/checkout/:path*",
    "/orders/:path*",
    "/profile/:path*",
    "/notifications/:path*",
    "/admin/:path*",
  ],
};
