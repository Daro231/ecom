/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    remotePatterns: [
      { protocol: "http", hostname: "localhost", port: "8080", pathname: "/uploads/**" },
      { protocol: "https", hostname: "placehold.co" },
    ],
  },
};
export default nextConfig;
