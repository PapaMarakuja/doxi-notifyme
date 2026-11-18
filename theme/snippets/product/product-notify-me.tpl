{# Avise-me quando chegar (doxi-notifyme). Incluir dentro de .buy-button-container em snippets/product/product-form.tpl #}
{% set doxi_notify_api = 'https://doxi-notifyme.vercel.app/api/subscribe' %}

{% if product.id and not quickshop %}
<button type="button" class="js-doxi-notify-open js-modal-open-private btn btn-secondary btn-big btn-block doxi-notify-open" data-target="#doxi-notify-modal" data-modal-url="doxi-notify-modal" data-product-id="{{ product.id }}" style="display: none;">
	Avise-me quando chegar
</button>

{% embed 'snippets/modals/modal.tpl' with {
	modal_id: 'doxi-notify-modal',
	position: { appear_from: 'bottom' },
	layout: { width_desktop: 'small' },
	title: 'Avise-me quando chegar',
	modal_classes: { modal: 'h-auto', close_icon: 'icon-inline' }
} %}
	{% block modal_body %}
		{# Sem <form>: o modal fica dentro do form do produto e forms aninhados não são válidos #}
		<div class="js-doxi-notify-form doxi-notify" data-api="{{ doxi_notify_api }}">
			<p class="doxi-notify-lgpd">
				Em conformidade com a LGPD, usaremos o e-mail informado <strong>apenas</strong> para avisar quando
				<strong>{{ product.name }}</strong> voltar ao estoque no(s) tamanho(s) selecionado(s).
				É um aviso único e você não entrará em nenhuma lista de marketing.
			</p>

			<div class="form-group">
				<label class="form-label">Tamanhos sem estoque</label>
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
			<p>Vamos te avisar por e-mail assim que chegar.</p>
		</div>
	{% endblock %}
{% endembed %}

<style>
	.doxi-notify-open { margin-top: 10px; }
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

	// Variantes sem estoque que combinam com as outras opções selecionadas (ex.: mesma cor), rotuladas pelo tamanho
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

	function refresh() {
		var btn = document.querySelector('.js-doxi-notify-open');
		var container = btn && btn.closest('.js-product-container');
		if (!container) return;
		var s = state(container);
		btn.style.display = s.current && !s.current.available ? '' : 'none';
	}

	function fillModal(btn) {
		var s = state(btn.closest('.js-product-container'));
		var list = outOfStock(s.variants, s.selected, s.sizeIdx);
		var box = document.querySelector('.js-doxi-notify-sizes');
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
			// Enter no e-mail não pode submeter o form do carrinho
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
