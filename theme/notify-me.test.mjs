// Testa a lógica do snippet (roda o <script> do .tpl num window falso)
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const tpl = readFileSync(new URL("./snippets/product/product-notify-me.tpl", import.meta.url), "utf8");
const js = tpl.match(/<script>([\s\S]*?)<\/script>/)[1];
const window = {};
const document = { readyState: "complete", addEventListener() {}, querySelector: () => null };
new Function("window", "document", "setTimeout", js)(window, document, () => {});
const { outOfStock } = window.DoxiNotify;

const variants = [
  { id: 1, option0: "Rosa", option1: "P", available: false },
  { id: 2, option0: "Rosa", option1: "M", available: true },
  { id: 3, option0: "Rosa", option1: "G", available: false },
  { id: 4, option0: "Azul", option1: "P", available: false },
];

test("lista só tamanhos sem estoque da cor selecionada e marca o atual", () => {
  assert.deepEqual(outOfStock(variants, ["Rosa", "G"], 1), [
    { id: 1, label: "P", current: false },
    { id: 3, label: "G", current: true },
  ]);
});

test("produto sem variações", () => {
  assert.deepEqual(outOfStock([{ id: 9, option0: null, available: false }], [], 0), [{ id: 9, label: null, current: true }]);
});
