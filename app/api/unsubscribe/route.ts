import { db, TABLE, type RestockSubscription } from "@/lib/supabase";
import { esc } from "@/lib/email";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function page(title: string, body: string, status = 200) {
  const html = `<!DOCTYPE html>
<html lang="pt-BR"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex"><title>${title} · Doxi</title></head>
<body style="margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px;box-sizing:border-box;background:#f7f7f5;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:#222220">
  <main style="max-width:420px;width:100%;background:#fff;border:1px solid #e5e5e2;border-radius:16px;padding:28px 24px;text-align:center">
    <h1 style="margin:0 0 12px;font-size:20px">${title}</h1>
    ${body}
    <p style="margin:24px 0 0"><a href="https://doxiwear.com" style="color:#666663;font-size:13px">Voltar para a Doxi</a></p>
  </main>
</body></html>`;
  return new Response(html, { status, headers: { "Content-Type": "text/html; charset=utf-8" } });
}

async function find(id: string | null) {
  if (!id || !UUID_RE.test(id)) return null;
  const { data } = await db().from(TABLE).select("*").eq("id", id).maybeSingle();
  return data as RestockSubscription | null;
}

const gone = () => page("Aviso já cancelado", `<p style="margin:0;line-height:1.5">Não há mais nenhum aviso ativo para este link. Seu e-mail não está mais guardado.</p>`);

// GET só mostra a confirmação: leitores de e-mail abrem links sozinhos e não podem cancelar no lugar da pessoa
export async function GET(req: Request) {
  const id = new URL(req.url).searchParams.get("id");
  const sub = await find(id);
  if (!sub) return gone();
  return page(
    "Cancelar aviso?",
    `<p style="margin:0 0 20px;line-height:1.5">Vamos apagar seu e-mail e parar de te avisar sobre este produto.</p>
     <form method="post" action="/api/unsubscribe?id=${esc(sub.id)}">
       <button type="submit" style="width:100%;min-height:44px;border:0;border-radius:30px;background:#111;color:#fff;font-size:15px;font-weight:700;cursor:pointer">Cancelar aviso</button>
     </form>`
  );
}

export async function POST(req: Request) {
  const sub = await find(new URL(req.url).searchParams.get("id"));
  if (!sub) return gone();
  // Remove todas as inscrições desta pessoa para este produto (todos os tamanhos)
  const { error } = await db().from(TABLE).delete().eq("email", sub.email).eq("product_id", sub.product_id);
  if (error) {
    console.error("unsubscribe failed", sub.id, error);
    return page("Ops", `<p style="margin:0;line-height:1.5">Não conseguimos cancelar agora. Tente de novo em instantes.</p>`, 500);
  }
  return page("Aviso cancelado 🐾", `<p style="margin:0;line-height:1.5">Pronto! Apagamos seu e-mail e você não vai receber avisos deste produto.</p>`);
}
