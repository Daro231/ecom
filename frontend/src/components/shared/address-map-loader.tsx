"use client";
import dynamic from "next/dynamic";
import { Skeleton } from "@/components/ui/card";

const Loading = () => <Skeleton className="h-60 w-full" aria-label="Loading map" />;
export const AddressMap = dynamic(() => import("./address-map"), { ssr: false, loading: Loading });
export const StaticMap = dynamic(() => import("./static-map"), { ssr: false, loading: Loading });
