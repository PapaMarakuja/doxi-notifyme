import { db, TABLE, type RestockSubscription } from "./supabase";
import { getProduct, inStock, productName, variantImage } from "./nuvemshop";
import { cancelUrl, sendRestockEmail } from "./email";

/** Avisa todos os inscritos pendentes das variantes do produto que voltaram ao estoque. Retorna quantos e-mails saíram. */
export async function notifyProduct(productId: number): Promise<number> {
  const product = await getProduct(productId);
  if (!product || !product.published) return 0;

  const restocked = product.variants.filter(inStock);
  if (!restocked.length) return 0;

  // "Reserva" as linhas antes de enviar: webhooks duplicados/concorrentes não mandam e-mail duas vezes
  const { data, error } = await db()
    .from(TABLE)
    .update({ notified_at: new Date().toISOString() })
    .eq("product_id", productId)
    .in("variant_id", restocked.map((v) => v.id))
    .is("notified_at", null)
    .select();
  if (error) throw error;

  let sent = 0;
  for (const sub of (data ?? []) as RestockSubscription[]) {
    const variant = restocked.find((v) => v.id === sub.variant_id)!;
    try {
      await sendRestockEmail({
        to: sub.email,
        productName: productName(product),
        variantLabel: sub.variant_label,
        url: product.canonical_url,
        image: variantImage(product, variant),
        cancelUrl: cancelUrl(sub.id),
      });
      sent++;
    } catch (e) {
      console.error("restock email failed", sub.id, e);
      // devolve para a fila: o próximo webhook/cron tenta de novo
      await db().from(TABLE).update({ notified_at: null }).eq("id", sub.id);
    }
  }
  return sent;
}

export async function pendingProductIds(): Promise<number[]> {
  const { data, error } = await db().from(TABLE).select("product_id").is("notified_at", null);
  if (error) throw error;
  return [...new Set((data ?? []).map((r) => Number(r.product_id)))];
}

// LGPD: depois de avisado o e-mail já cumpriu a finalidade; guardamos só por 90 dias
export async function purgeNotified(days = 90): Promise<number> {
  const cutoff = new Date(Date.now() - days * 86_400_000).toISOString();
  const { data, error } = await db().from(TABLE).delete().lt("notified_at", cutoff).select("id");
  if (error) throw error;
  return data?.length ?? 0;
}
