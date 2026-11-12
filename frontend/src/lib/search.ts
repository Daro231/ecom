import { CATEGORY_NAMES } from "./constants";
import type { Category } from "@/types";

/** If the keyword is exactly a category name (laptop, desktop …) return that category. */
export function categoryForKeyword(keyword: string | null | undefined, categories: Category[] | undefined): Category | undefined {
  const k = (keyword ?? "").trim().toLowerCase();
  if (!k || !categories) return undefined;
  const plain = k.endsWith("s") && CATEGORY_NAMES.includes(k.slice(0, -1)) ? k.slice(0, -1) : k;
  return categories.find((c) => c.name.toLowerCase() === k || c.name.toLowerCase() === plain);
}
