# doxi-notifyme

"Avise-me quando chegar" da Doxi na Nuvemshop.

**Fluxo:** variante sem estoque → botão na página do produto → modal (aviso LGPD, tamanhos sem estoque, e-mail, checkbox) → `POST /api/subscribe` → Supabase.
A Nuvemshop dispara o webhook `product/updated` → `/api/webhooks/nuvemshop` consulta o produto na API → variantes que voltaram ao estoque recebem e-mail (SMTP Hostinger, igual ao doxi-affiliates) → a linha fica marcada com `notified_at` (aviso único).
Um cron diário (`/api/cron/restock`) refaz a checagem caso algum webhook se perca.

## Setup

1. **Supabase:** rode `supabase/migrations/001_restock_subscriptions.sql` no SQL Editor.
2. **Env:** copie `.env.example` para `.env.local` (e configure as mesmas variáveis na Vercel). Os valores da Nuvemshop e do SMTP são os mesmos do doxi-affiliates; `NUVEMSHOP_CLIENT_SECRET` é o client secret do app no Portal de Parceiros.
3. **Deploy** na Vercel (o `vercel.json` já cria o cron). Defina `CRON_SECRET`.
4. **Registrar o webhook** (uma vez só):

```powershell
curl.exe -X POST "https://api.nuvemshop.com.br/v1/$env:NUVEMSHOP_USER_ID/webhooks" -H "Authentication: bearer $env:NUVEMSHOP_ACCESS_TOKEN" -H "Content-Type: application/json" -H "User-Agent: doxi-notifyme (suporte@doxi.com.br)" -d '{\"event\":\"product/updated\",\"url\":\"https://doxi-notifyme.vercel.app/api/webhooks/nuvemshop\"}'
```

5. **Tema:** copie `theme/snippets/product/product-notify-me.tpl` para o tema e inclua dentro de `.buy-button-container` em `snippets/product/product-form.tpl`, logo depois do botão de comprar:

```twig
{% include 'snippets/product/product-notify-me.tpl' %}
```

Ajuste a URL da API em `doxi_notify_api` no topo do snippet se o domínio do deploy for outro.

## Dev

```powershell
npm run dev
```

```powershell
npm test
```

`npm test` testa a lógica da modal (quais tamanhos aparecem). Em dev, coloque `http://localhost:XXXX` em `ALLOWED_ORIGINS` se for testar o formulário fora da loja.
