import nodemailer from "nodemailer";

const esc = (s: string) =>
  s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]!);

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

export type RestockEmail = { to: string; productName: string; variantLabel: string; url: string; image: string | null };

export async function sendRestockEmail(d: RestockEmail): Promise<void> {
  const name = esc(d.productName);
  const size = esc(d.variantLabel);
  const html = `<!DOCTYPE html>
<html lang="pt-BR"><head><meta charset="UTF-8"></head>
<body style="margin:0;padding:24px;background:#f7f7f5;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:#222220">
  <div style="max-width:520px;margin:0 auto;background:#fff;border:1px solid #e5e5e2;border-radius:16px;overflow:hidden">
    ${d.image ? `<img src="${esc(d.image)}" alt="${name}" style="display:block;width:100%;height:auto">` : ""}
    <div style="padding:28px 24px">
      <h1 style="margin:0 0 8px;font-size:22px">Chegou! 🐾</h1>
      <p style="margin:0 0 20px;font-size:15px;line-height:1.5">
        O <strong>${name}</strong> no tamanho <strong>${size}</strong> voltou ao estoque.
        Corre que as unidades são limitadas!
      </p>
      <a href="${esc(d.url)}" style="display:inline-block;background:#111;color:#fff;text-decoration:none;font-weight:700;padding:14px 24px;border-radius:8px">Comprar agora</a>
    </div>
    <div style="padding:16px 24px;background:#f8f8f7;font-size:12px;color:#666663;border-top:1px solid #e5e5e2">
      Você recebeu este e-mail porque pediu para ser avisado(a) sobre este produto na Doxi.
      Este é um aviso único: seu e-mail não será usado para outra finalidade.
    </div>
  </div>
</body></html>`;

  await transporter().sendMail({
    from: `"Doxi" <${process.env.SMTP_USER}>`,
    to: d.to,
    subject: `Chegou! ${d.productName} (${d.variantLabel}) voltou ao estoque`,
    html,
  });
}
