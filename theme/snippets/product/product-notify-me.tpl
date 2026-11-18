{# Avise-me quando chegar (doxi-notifyme)
   - com notify_button: true -> so o botao (em snippets/product/product-variants.tpl, junto da calculadora)
   - sem parametro           -> modal + estilos + script (em snippets/product/product-form.tpl) #}
{% set doxi_notify_api = 'https://doxi-notifyme.vercel.app/api/subscribe' %}

{% if product.id and not quickshop %}
{% if notify_button %}
<div class="js-doxi-notify-wrap doxi-notify-wrap" aria-hidden="true">
	<div class="doxi-notify-wrap-inner">
		<button type="button" class="js-doxi-notify-open js-modal-open-private doxi-notify-open" data-target="#doxi-notify-modal" data-modal-url="doxi-notify-modal" data-product-id="{{ product.id }}" tabindex="-1">
			<svg class="doxi-notify-bell" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
				<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/>
				<path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/>
			</svg>
			<span>Avise-me quando chegar</span>
		</button>
	</div>
</div>
{% else %}

{% embed 'snippets/modals/modal.tpl' with {
	modal_id: 'doxi-notify-modal',
	position: { appear_from: 'bottom' },
	layout: { width_desktop: 'small' },
	title: 'Avise-me quando chegar',
	modal_classes: { modal: 'h-auto', close_icon: 'icon-inline' }
} %}
	{% block modal_body %}
		{# Sem <form>: o modal fica dentro do form do produto e forms aninhados nao sao validos #}
		<div class="js-doxi-notify-form doxi-notify" data-api="{{ doxi_notify_api }}">
			<p class="doxi-notify-lgpd">
				Em conformidade com a LGPD, usaremos o e-mail informado <strong>apenas</strong> para avisar quando
				<strong>{{ product.name }}</strong> voltar ao estoque no(s) tamanho(s) selecionado(s).
				Você não entrará em nenhuma lista de marketing, pode cancelar pelo link do e-mail de confirmação e apagamos seu e-mail 90 dias após o aviso.
			</p>

			<div class="form-group">
				<label class="js-doxi-notify-sizes-label form-label">Avisar quando chegar o tamanho:</label>
				<div class="js-doxi-notify-sizes doxi-notify-sizes"></div>
			</div>

			<div class="form-group">
				<label class="form-label" for="doxi-notify-email">Seu e-mail</label>
				<input type="email" id="doxi-notify-email" class="js-doxi-notify-email form-control" autocomplete="email" placeholder="voce@email.com" required>
			</div>

			<label class="checkbox-container doxi-notify-consent">
				<input type="checkbox" class="js-doxi-notify-consent" autocomplete="off">
				<span class="checkbox">
					<span class="checkbox-icon"></span>
					<span class="checkbox-text">Concordo em receber este aviso por e-mail.</span>
				</span>
			</label>

			<p class="js-doxi-notify-error doxi-notify-error" role="alert" style="display: none;"></p>

			<button type="button" class="js-doxi-notify-submit btn btn-primary btn-big btn-block">Confirmar</button>
		</div>
		<div class="js-doxi-notify-success doxi-notify-success" role="status" style="display: none;">
			<p><strong>Prontinho! 🐾</strong></p>
			<p>Vamos te avisar por e-mail assim que chegar. Enviamos uma confirmação com o link para cancelar, se mudar de ideia.</p>
		</div>
	{% endblock %}
{% endembed %}

<style>
	/* Botao junto da calculadora: abre/recolhe suave (mesma tecnica do aviso sob demanda) e vibra uma vez ao aparecer */
	.doxi-notify-wrap {
		flex: 1 1 100%;
		display: grid;
		grid-template-rows: 0fr;
		opacity: 0;
		margin-top: -12px; /* anula o gap do .product-size-actions enquanto escondido */
		pointer-events: none;
		transition: grid-template-rows 0.28s cubic-bezier(0.16, 1, 0.3, 1), opacity 0.22s ease, margin 0.28s cubic-bezier(0.16, 1, 0.3, 1);
	}
	.doxi-notify-wrap.is-visible {
		grid-template-rows: 1fr;
		opacity: 1;
		margin-top: 0;
		pointer-events: auto;
	}
	.doxi-notify-wrap-inner { overflow: hidden; padding: 2px; }
	.doxi-notify-open {
		display: flex;
		width: 100%;
		align-items: center;
		justify-content: center;
		gap: 8px;
		min-height: 44px;
		padding: 10px 16px;
		font-size: 14px;
		font-weight: 700;
		color: #fff;
		background: linear-gradient(135deg, #f5a3b0 0%, #e27d8d 100%);
		border: 0;
		border-radius: 30px;
		box-shadow: 0 4px 14px rgba(226, 125, 141, 0.35);
		cursor: pointer;
		transition: transform 0.15s ease, box-shadow 0.15s ease;
	}
	.doxi-notify-open:active { transform: scale(0.97); }
	.doxi-notify-wrap.is-buzzing .doxi-notify-open { animation: doxi-notify-buzz 0.6s ease-in-out 0.3s 1; }
	.doxi-notify-wrap.is-buzzing .doxi-notify-bell { animation: doxi-notify-ring 0.6s ease-in-out 0.3s 1; transform-origin: 50% 10%; }
	@keyframes doxi-notify-buzz {
		0%, 100% { transform: translateX(0); }
		15%, 45%, 75% { transform: translateX(-3px) rotate(-1deg); }
		30%, 60%, 90% { transform: translateX(3px) rotate(1deg); }
	}
	@keyframes doxi-notify-ring {
		0%, 100% { transform: rotate(0); }
		20%, 60% { transform: rotate(-18deg); }
		40%, 80% { transform: rotate(18deg); }
	}

	/* Barra fixa (celular): "Sem estoque" vira "Avise-me" com a mesma cor */
	.doxi-buy-bar-btn.is-notify {
		color: #fff;
		background: linear-gradient(135deg, #f5a3b0 0%, #e27d8d 100%);
		border-color: #e27d8d;
	}

	.doxi-notify-lgpd { font-size: 13px; line-height: 1.5; color: #555552; background: #f8f8f7; border: 1px solid #e5e5e2; border-radius: 12px; padding: 12px 14px; margin: 0 0 16px; }
	.doxi-notify-sizes { display: flex; flex-wrap: wrap; gap: 8px; }
	.doxi-notify-sizes .btn-variant { margin: 0; }
	.doxi-notify-consent { display: block; margin: 4px 0 16px; }
	.doxi-notify-error { color: #c0392b; font-size: 13px; margin: 0 0 12px; }
	.doxi-notify-success { text-align: center; padding: 16px 0; }
</style>

<script>
(function() {
	if (window.DoxiNotify) return;

	// Variantes sem estoque que combinam com as outras opcoes selecionadas (ex.: mesma cor), rotuladas pelo tamanho
	function outOfStock(variants, selected, sizeIdx) {
		return variants.filter(function(v) {
			if (v.available) return false;
			for (var i = 0; i < selected.length; i++) {
				if (i !== sizeIdx && String(v['option' + i]) !== String(selected[i])) return false;
			}
			return true;
		}).map(function(v) { return { id: v.id, label: v['option' + sizeIdx], current: !selected.length || String(v['option' + sizeIdx]) === String(selected[sizeIdx]) }; });
	}

	function state(container) {
		var variants = [];
		try { variants = JSON.parse(container.getAttribute('data-variants') || '[]'); } catch (e) {}
		var groups = container.querySelectorAll('.js-product-variants-group');
		var selected = [], sizeIdx = groups.length - 1;
		for (var i = 0; i < groups.length; i++) {
			var sel = groups[i].querySelector('select.js-variation-option');
			selected.push(sel ? sel.value : '');
			if (groups[i].classList.contains('js-size-variants-container')) sizeIdx = i;
		}
		if (!groups.length) { selected = []; sizeIdx = 0; }
		var current = variants.filter(function(v) {
			for (var i = 0; i < selected.length; i++) if (String(v['option' + i]) !== String(selected[i])) return false;
			return true;
		})[0];
		return { variants: variants, selected: selected, sizeIdx: sizeIdx, current: current };
	}

	var NOTIFY_LABEL = 'Avise-me';

	function refresh() {
		var btn = document.querySelector('.js-doxi-notify-open');
		var container = btn && btn.closest('.js-product-container');
		if (!container) return;
		var s = state(container);
		var show = !!(s.current && !s.current.available);
		var wrap = btn.closest('.js-doxi-notify-wrap');
		var was = wrap.classList.contains('is-visible');

		wrap.classList.toggle('is-visible', show);
		wrap.setAttribute('aria-hidden', String(!show));
		btn.tabIndex = show ? 0 : -1;
		if (show && !was) {
			wrap.classList.remove('is-buzzing');
			void wrap.offsetWidth; // reflow: a vibracao toca de novo a cada vez que o botao aparece
			wrap.classList.add('is-buzzing');
		}
		if (!show) wrap.classList.remove('is-buzzing');

		// Barra fixa do celular (store.js: initBuyBar espelha o botao Comprar; aqui sobrescrevemos quando sem estoque)
		var barBtn = document.querySelector('.js-buy-bar-btn');
		var mainBtn = document.querySelector('#product_form input[type="submit"].js-addtocart');
		if (!barBtn || !mainBtn) return;
		if (show) {
			barBtn.disabled = false;
			barBtn.textContent = NOTIFY_LABEL;
			barBtn.classList.add('is-notify');
		} else if (barBtn.classList.contains('is-notify')) {
			barBtn.classList.remove('is-notify');
			barBtn.disabled = mainBtn.disabled;
			barBtn.textContent = mainBtn.value;
		}
	}

	function fillModal(btn) {
		var s = state(btn.closest('.js-product-container'));
		var list = outOfStock(s.variants, s.selected, s.sizeIdx);
		var box = document.querySelector('.js-doxi-notify-sizes');
		document.querySelector('.js-doxi-notify-sizes-label').textContent =
			list.length > 1 ? 'Quais tamanhos você quer que a gente avise?' : 'Avisar quando chegar o tamanho:';
		box.innerHTML = '';
		list.forEach(function(o) {
			var a = document.createElement('button');
			a.type = 'button';
			a.className = 'btn btn-variant' + (o.current ? ' selected' : '');
			a.setAttribute('data-variant-id', o.id);
			a.setAttribute('aria-pressed', o.current ? 'true' : 'false');
			a.innerHTML = '<span class="btn-variant-content"></span>';
			a.firstChild.textContent = o.label || 'Único';
			box.appendChild(a);
		});
		document.querySelector('.js-doxi-notify-form').style.display = '';
		document.querySelector('.js-doxi-notify-success').style.display = 'none';
		showError('');
	}

	function showError(msg) {
		var el = document.querySelector('.js-doxi-notify-error');
		el.textContent = msg;
		el.style.display = msg ? '' : 'none';
	}

	function submit() {
		var form = document.querySelector('.js-doxi-notify-form');
		var btn = form.querySelector('.js-doxi-notify-submit');
		var email = form.querySelector('.js-doxi-notify-email').value.trim();
		var ids = Array.prototype.map.call(form.querySelectorAll('.js-doxi-notify-sizes .selected'), function(el) { return Number(el.getAttribute('data-variant-id')); });
		if (!ids.length) return showError('Selecione ao menos um tamanho.');
		if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email)) return showError('Informe um e-mail válido.');
		if (!form.querySelector('.js-doxi-notify-consent').checked) return showError('Marque a confirmação para receber o aviso.');
		showError('');
		btn.disabled = true;
		fetch(form.getAttribute('data-api'), {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				product_id: Number(document.querySelector('.js-doxi-notify-open').getAttribute('data-product-id')),
				variant_ids: ids, email: email, consent: true
			})
		}).then(function(r) {
			return r.json().catch(function() { return {}; }).then(function(d) {
				if (!r.ok) throw new Error(d.error || 'Não foi possível salvar agora. Tente novamente.');
				form.style.display = 'none';
				document.querySelector('.js-doxi-notify-success').style.display = '';
			});
		}).catch(function(e) {
			showError(e.message || 'Não foi possível salvar agora. Tente novamente.');
		}).then(function() { btn.disabled = false; });
	}

	function later() { setTimeout(refresh, 25); setTimeout(refresh, 150); setTimeout(refresh, 500); }

	function init() {
		document.addEventListener('click', function(e) {
			var open = e.target.closest('.js-doxi-notify-open');
			if (open) return fillModal(open);
			var bar = e.target.closest('.js-buy-bar-btn.is-notify');
			if (bar) {
				var trigger = document.querySelector('.js-doxi-notify-open');
				if (trigger) trigger.click(); // abre pelo mesmo caminho do botao (modal do tema + preenchimento)
				return;
			}
			var chip = e.target.closest('.js-doxi-notify-sizes .btn-variant');
			if (chip) {
				chip.classList.toggle('selected');
				chip.setAttribute('aria-pressed', chip.classList.contains('selected') ? 'true' : 'false');
				return;
			}
			if (e.target.closest('.js-doxi-notify-submit')) return submit();
			if (e.target.closest('.js-variant-button')) later();
		});
		document.addEventListener('change', function(e) {
			if (e.target.classList && e.target.classList.contains('js-variation-option')) later();
		});
		document.addEventListener('keydown', function(e) {
			// Enter no e-mail nao pode submeter o form do carrinho
			if (e.key === 'Enter' && e.target.classList && e.target.classList.contains('js-doxi-notify-email')) { e.preventDefault(); submit(); }
		});
		refresh();
		setTimeout(refresh, 500);
	}

	window.DoxiNotify = { outOfStock: outOfStock, refresh: refresh };
	if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
})();
</script>
{% endif %}
{% endif %}
