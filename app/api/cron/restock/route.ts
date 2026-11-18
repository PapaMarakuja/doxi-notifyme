import { notifyProduct, pendingProductIds, purgeNotified } from "@/lib/restock";

// Rede de segurança para webhooks perdidos: varre os produtos com inscrições pendentes
export async function GET(req: Request) {
  if (!process.env.CRON_SECRET || req.headers.get("authorization") !== `Bearer ${process.env.CRON_SECRET}`)
    return new Response("unauthorized", { status: 401 });

  let sent = 0;
  for (const id of await pendingProductIds()) {
    try {
      sent += await notifyProduct(id);
    } catch (e) {
      console.error("cron notify failed", id, e);
    }
  }
  const purged = await purgeNotified(90);
  return Response.json({ sent, purged });
}
