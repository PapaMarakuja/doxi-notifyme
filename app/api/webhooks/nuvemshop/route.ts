import { after } from "next/server";
import { validWebhookSignature } from "@/lib/nuvemshop";
import { notifyProduct } from "@/lib/restock";

// Registrado para o evento product/updated. Payload: { store_id, event, id }
export async function POST(req: Request) {
  const raw = await req.text();
  if (!validWebhookSignature(raw, req.headers.get("x-linkedstore-hmac-sha256")))
    return new Response("invalid signature", { status: 401 });

  const { id, event } = JSON.parse(raw) as { id: number; event: string };
  if (event !== "product/updated" || !id) return new Response("ignored");

  // Responde já (a Nuvemshop exige resposta rápida) e envia os e-mails depois
  after(async () => {
    try {
      const sent = await notifyProduct(Number(id));
      if (sent) console.log(`product ${id}: ${sent} restock emails`);
    } catch (e) {
      console.error("webhook notify failed", id, e);
    }
  });
  return new Response("ok");
}
