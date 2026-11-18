import { db, TABLE } from "@/lib/supabase";
import { getProduct, inStock, variantLabel } from "@/lib/nuvemshop";

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

function cors(req: Request): Record<string, string> {
  const origin = req.headers.get("origin") ?? "";
  const allowed = (process.env.ALLOWED_ORIGINS ?? "").split(",").map((s) => s.trim());
  if (!allowed.includes(origin)) return {};
  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    Vary: "Origin",
  };
}

const json = (req: Request, body: unknown, status = 200) => Response.json(body, { status, headers: cors(req) });

export function OPTIONS(req: Request) {
  return new Response(null, { status: 204, headers: cors(req) });
}

export async function POST(req: Request) {
  let body: { product_id?: unknown; variant_ids?: unknown; email?: unknown; consent?: unknown };
  try {
    body = await req.json();
  } catch {
    return json(req, { error: "JSON inválido" }, 400);
  }

  const productId = Number(body.product_id);
  const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
  const variantIds = Array.isArray(body.variant_ids) ? [...new Set(body.variant_ids.map(Number))] : [];

  if (!Number.isInteger(productId) || productId <= 0) return json(req, { error: "Produto inválido" }, 400);
  if (!EMAIL_RE.test(email) || email.length > 254) return json(req, { error: "E-mail inválido" }, 400);
  if (body.consent !== true) return json(req, { error: "É preciso aceitar o uso do e-mail" }, 400);
  if (!variantIds.length || variantIds.length > 30 || !variantIds.every((id) => Number.isInteger(id) && id > 0))
    return json(req, { error: "Selecione ao menos um tamanho" }, 400);

  try {
    // Fonte da verdade é a Nuvemshop: só aceita variantes deste produto que estão realmente sem estoque
    const product = await getProduct(productId);
    if (!product) return json(req, { error: "Produto não encontrado" }, 404);
    const variants = product.variants.filter((v) => variantIds.includes(v.id) && !inStock(v));
    if (!variants.length) return json(req, { error: "Esses tamanhos já estão disponíveis" }, 409);

    const consentAt = new Date().toISOString();
    for (const v of variants) {
      const { error } = await db().from(TABLE).insert({
        product_id: productId,
        variant_id: v.id,
        variant_label: variantLabel(v),
        email,
        consent_at: consentAt,
      });
      if (error && error.code !== "23505") throw error; // 23505 = já inscrito e pendente: tudo certo
    }
    return json(req, { ok: true });
  } catch (e) {
    console.error("subscribe failed", e);
    return json(req, { error: "Não foi possível salvar agora. Tente novamente." }, 500);
  }
}
