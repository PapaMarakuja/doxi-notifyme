import nodemailer from "nodemailer";

export const esc = (s: string) =>
  s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]!);

// Vercel preenche VERCEL_PROJECT_PRODUCTION_URL (sem protocolo) em todo deploy
const APP_URL = process.env.VERCEL_PROJECT_PRODUCTION_URL
  ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
  : "http://localhost:3001";

export const cancelUrl = (subscriptionId: string) => `${APP_URL}/api/unsubscribe?id=${subscriptionId}`;

function transporter() {
  const port = Number(process.env.SMTP_PORT || 465);
  if (!process.env.SMTP_USER || !process.env.SMTP_PASS) throw new Error("SMTP_USER/SMTP_PASS não definidos");
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST || "smtp.hostinger.com",
    port,
    secure: port === 465,
    auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
  });
}

function layout(opts: { image: string | null; alt: string; body: string; footer: string }) {
  return `<!DOCTYPE html>
<html lang="pt-BR"><head><meta charset="UTF-8"></head>
<body style="margin:0;padding:24px;background:#f7f7f5;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:#222220">
  <div style="max-width:520px;margin:0 auto;background:#fff;border:1px solid #e5e5e2;border-radius:16px;overflow:hidden">
    ${opts.image ? `<img src="${esc(opts.image)}" alt="${opts.alt}" style="display:block;width:100%;height:auto">` : ""}
    <div style="padding:28px 24px">${opts.body}</div>
    <div style="padding:16px 24px;background:#f8f8f7;font-size:12px;line-height:1.5;color:#666663;border-top:1px solid #e5e5e2">${opts.footer}</div>
  </div>
</body></html>`;
}

const link = (href: string, text: string) => `<a href="${esc(href)}" style="color:#666663">${text}</a>`;

export type RestockEmail = {
  to: string;
  productName: string;
  variantLabel: string;
  url: string;
  image: string | null;
  cancelUrl: string;
};

export async function sendRestockEmail(d: RestockEmail): Promise<void> {
  const name = esc(d.productName);
  const html = layout({
    image: d.image,
    alt: name,
    body: `<h1 style="margin:0 0 8px;font-size:22px">Chegou! 🐾</h1>
      <p style="margin:0 0 20px;font-size:15px;line-height:1.5">
        O <strong>${name}</strong> no tamanho <strong>${esc(d.variantLabel)}</strong> voltou ao estoque.
        Corre que as unidades são limitadas!
      </p>
      <a href="${esc(d.url)}" style="display:inline-block;background:#111;color:#fff;text-decoration:none;font-weight:700;padding:14px 24px;border-radius:8px">Comprar agora</a>`,
    footer: `Você recebeu este e-mail porque pediu para ser avisado(a) sobre este produto na Doxi.
      Este é um aviso único: seu e-mail não será usado para outra finalidade.<br>
      ${link(d.cancelUrl, "Não quero mais avisos deste produto")}`,
  });

  await transporter().sendMail({
    from: `"Doxi" <${process.env.SMTP_USER}>`,
    to: d.to,
    subject: `Chegou! ${d.productName} (${d.variantLabel}) voltou ao estoque`,
    html,
  });
}

export type ConfirmationEmail = {
  to: string;
  productName: string;
  variantLabels: string[];
  url: string;
  image: string | null;
  cancelUrl: string;
};

export async function sendConfirmationEmail(d: ConfirmationEmail): Promise<void> {
  const name = esc(d.productName);
  const sizes = d.variantLabels.map(esc).join(", ");
  const plural = d.variantLabels.length > 1;
  const html = layout({
    image: d.image,
    alt: name,
    body: `<h1 style="margin:0 0 8px;font-size:22px">Aviso confirmado 🐾</h1>
      <p style="margin:0 0 20px;font-size:15px;line-height:1.5">
        Assim que o <strong>${name}</strong> chegar no${plural ? "s tamanhos" : " tamanho"} <strong>${sizes}</strong>,
        a gente te avisa por aqui. É um aviso único.
      </p>
      <a href="${esc(d.url)}" style="display:inline-block;background:#111;color:#fff;text-decoration:none;font-weight:700;padding:14px 24px;border-radius:8px">Ver produto</a>`,
    footer: `Mudou de ideia? ${link(d.cancelUrl, "Cancelar este aviso")} e apagamos seu e-mail na hora.`,
  });

  await transporter().sendMail({
    from: `"Doxi" <${process.env.SMTP_USER}>`,
    to: d.to,
    subject: `Aviso confirmado: ${d.productName} (${d.variantLabels.join(", ")})`,
    html,
  });
}
