import { createHmac, timingSafeEqual } from "node:crypto";

type I18n = Record<string, string>;

export type NsVariant = {
  id: number;
  stock: number | null; // null = estoque infinito
  stock_management: boolean;
  values: I18n[];
  image_id: number | null;
};

export type NsProduct = {
  id: number;
  name: I18n;
  canonical_url: string;
  published: boolean;
  variants: NsVariant[];
  images: { id: number; src: string }[];
};

const t = (v: I18n | undefined) => (v ? v.pt ?? Object.values(v)[0] ?? "" : "");

export async function getProduct(productId: number): Promise<NsProduct | null> {
  const base = process.env.NUVEMSHOP_API_URL ?? "https://api.nuvemshop.com.br/v1";
  const res = await fetch(`${base}/${process.env.NUVEMSHOP_USER_ID}/products/${productId}`, {
    headers: {
      Authentication: `bearer ${process.env.NUVEMSHOP_ACCESS_TOKEN}`,
      "User-Agent": "doxi-notifyme (hello@doxiwear.com)",
    },
    cache: "no-store",
  });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`Nuvemshop API ${res.status} ${res.statusText}`);
  return (await res.json()) as NsProduct;
}

export const productName = (p: NsProduct) => t(p.name);

export const variantLabel = (v: NsVariant) => v.values.map(t).filter(Boolean).join(" / ");

export const inStock = (v: NsVariant) => !v.stock_management || v.stock === null || v.stock > 0;

export function variantImage(p: NsProduct, v: NsVariant): string | null {
  return (p.images.find((i) => i.id === v.image_id) ?? p.images[0])?.src ?? null;
}

// Nuvemshop assina o corpo bruto com o client secret do app (HMAC-SHA256 hex)
export function validWebhookSignature(rawBody: string, signature: string | null): boolean {
  if (!signature || !process.env.NUVEMSHOP_CLIENT_SECRET) return false;
  const expected = createHmac("sha256", process.env.NUVEMSHOP_CLIENT_SECRET).update(rawBody).digest("hex");
  const a = Buffer.from(expected);
  const b = Buffer.from(signature);
  return a.length === b.length && timingSafeEqual(a, b);
}
