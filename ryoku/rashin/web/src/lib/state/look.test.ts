// @vitest-environment jsdom
// The Crate look is a cascade switch: app.css, kit.css and each component's
// own Crate rules apply only under <html data-look="crate">. These tests load
// the real stylesheets (the components compiled by Svelte, scoped as they ship)
// into jsdom, resolve the custom properties against the root, and read what a
// piece of the console would wear in each look.

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { compile } from "svelte/compiler";
import { afterEach, beforeAll, describe, expect, it } from "vitest";
import { needleColours, oklchHue, STOCK_NEEDLE } from "$lib/fx/needle";
import { applyLook, lookOf, rememberedLook } from "./theme.svelte";

const read = (rel: string) => readFileSync(fileURLToPath(new URL(rel, import.meta.url)), "utf8");

/** A component's shipped CSS and the scope class Svelte stamps on its elements
    (none for a kit part whose rules are all global). */
function component(rel: string): string {
  const { css } = compile(read(rel), { filename: rel, css: "external", generate: "client" });
  const code = css?.code ?? "";
  scopes[rel] = /\.(svelte-[a-z0-9]+)/.exec(code)?.[1] ?? "";
  return code;
}

const scopes: Record<string, string> = {};
const TOPBAR = "../app/TopBar.svelte";
const TRANSCRIPT = "../pages/chat/Transcript.svelte";
const LAMP = "../ui/Lamp.svelte";
const SEG = "../ui/Seg.svelte";
const MESSAGE = "../pages/chat/MessageItem.svelte";

// The Crate scheme's roles, as /api/theme hands them to applyRoles.
const CRATE_ROLES: Record<string, string> = {
  "--paper": "#0a0a0f",
  "--paper-lift": "#0f1016",
  "--ink": "#f1f5f9",
  "--ink-dim": "#999ca0",
  "--bone": "#67e8f9",
  "--ink-on-bone": "#0a0a0f",
  "--sun": "#06b6d4",
  "--sun-hi": "#67e8f9",
};

beforeAll(() => {
  const sheets = [read("../../app.css"), read("../ui/kit.css"), ...[TOPBAR, TRANSCRIPT, LAMP, SEG, MESSAGE].map(component)];
  for (const css of sheets) {
    const style = document.createElement("style");
    style.textContent = css;
    document.head.append(style);
  }
});

afterEach(() => {
  document.body.replaceChildren();
  wear("stock");
});

/** The Crate look with the Crate scheme's roles, or the stock look on the signature defaults. */
function wear(look: "crate" | "stock"): void {
  for (const [v, hex] of Object.entries(CRATE_ROLES)) {
    if (look === "crate") document.documentElement.style.setProperty(v, hex);
    else document.documentElement.style.removeProperty(v);
  }
  applyLook(look, document.documentElement);
}

/** Every var() resolved against the root, where the tokens live. */
function resolve(value: string): string {
  const root = getComputedStyle(document.documentElement);
  let out = value;
  for (let i = 0; i < 8 && out.includes("var("); i++) {
    out = out.replace(/var\((--[\w-]+)(?:,\s*([^()]*))?\)/g, (_, name: string, fallback?: string) => root.getPropertyValue(name).trim() || fallback || "");
  }
  return out.trim();
}

/** (ids, classes + attributes + pseudo-classes, types), folded into one number. */
function specificity(selector: string): number {
  const bare = selector.replace(/\[[^\]]*\]/g, "[]");
  const ids = (bare.match(/#[\w-]+/g) ?? []).length;
  const classes = (bare.match(/\.[\w-]+|\[\]|:[\w-]+/g) ?? []).length;
  const types = (bare.replace(/[.#:][\w-]+|\[\]/g, "").match(/[a-z][\w-]*/gi) ?? []).length;
  return ids * 1e6 + classes * 1e3 + types;
}

/** The winning declaration among `props` for `el`: jsdom matches the selectors
    but cannot compute a colour written through var(), so the cascade (origin
    order and specificity) is folded here and the winner resolved. Media and
    container blocks are left out, as a desktop-width window would. */
function cascade(el: Element, ...props: string[]): string {
  let best: { spec: number; order: number; value: string } | null = null;
  let order = 0;
  for (const sheet of Array.from(document.styleSheets)) {
    for (const rule of Array.from(sheet.cssRules)) {
      if (!(rule instanceof CSSStyleRule)) continue;
      order++;
      const value = props.map((p) => rule.style.getPropertyValue(p)).find((v) => v !== "");
      if (!value) continue;
      for (const sel of rule.selectorText.split(",").map((x) => x.trim())) {
        if (sel.includes("::")) continue;
        let hit = false;
        try {
          hit = el.matches(sel);
        } catch {
          hit = false;
        }
        if (!hit) continue;
        const spec = specificity(sel);
        if (!best || spec > best.spec || (spec === best.spec && order >= best.order)) best = { spec, order, value };
      }
    }
  }
  return best ? resolve(best.value) : "";
}

/** Builds `<tag class="a b scope">` nested as given, returning the innermost. */
function mount(rel: string, ...chain: Array<[string, string]>): HTMLElement {
  let parent: HTMLElement = document.body;
  for (const [tag, cls] of chain) {
    const el = document.createElement(tag);
    el.className = `${cls} ${scopes[rel]}`;
    parent.append(el);
    parent = el;
  }
  return parent;
}

const families = (v: string) => v.split(",").map((f) => f.trim().replace(/^"|"$/g, ""));

describe("the look the daemon names", () => {
  it("is Crate only for an explicit crate", () => {
    expect(lookOf({ look: "crate" })).toBe("crate");
    for (const answer of [{ look: "stock" }, { look: "Crate" }, { look: 1 }, {}, null, undefined]) expect(lookOf(answer)).toBe("stock");
  });

  it("lands on the root and leaves it bare for the stock look", () => {
    const root = document.createElement("html");
    applyLook("crate", root);
    expect(root.dataset.look).toBe("crate");
    applyLook("stock", root);
    expect(root.hasAttribute("data-look")).toBe(false);
  });

  it("remembers the last look and survives a store that throws", () => {
    expect(rememberedLook({ getItem: () => "crate" })).toBe("crate");
    expect(rememberedLook({ getItem: () => null })).toBe("stock");
    expect(rememberedLook({ getItem: () => { throw new Error("blocked"); } })).toBe("stock");
    expect(rememberedLook(undefined)).toBe("stock");
  });
});

describe("the empty-state heading", () => {
  const heading = () => mount(TRANSCRIPT, ["section", "empty-chat"], ["p", ""]);

  it("is Crate's display face, bold, with no serif under Crate", () => {
    wear("crate");
    const face = families(cascade(heading(), "font-family"));
    expect(face[0]).toBe("Bricolage Grotesque");
    expect(face).not.toContain("serif");
    expect(face).not.toContain("Fraunces");
    expect(cascade(heading(), "font-weight")).toBe("700");
  });

  it("keeps the stock Fraunces at 400", () => {
    wear("stock");
    expect(families(cascade(heading(), "font-family"))).toEqual(["Fraunces", "Georgia", "serif"]);
    expect(cascade(heading(), "font-weight")).toBe("400");
  });
});

describe("the sheet tabs", () => {
  const current = () => mount(TOPBAR, ["nav", "island sheets"], ["a", "sheet on"]);
  const name = () => mount(TOPBAR, ["a", "sheet on"], ["span", "sheet-name"]);

  it("underline the current sheet in the mark under Crate, never fill it", () => {
    wear("crate");
    expect(cascade(current(), "background", "background-color")).toBe("transparent");
    expect(cascade(current(), "border-bottom-color", "border-bottom")).toBe("#67e8f9");
    expect(cascade(current(), "border-bottom")).toBe("2px solid transparent");
    expect(families(cascade(name(), "font-family"))[0]).toBe("JetBrains Mono");
    expect(cascade(name(), "text-transform")).toBe("uppercase");
  });

  it("keep the stock bone plate", () => {
    wear("stock");
    expect(cascade(current(), "background", "background-color")).toBe("#cdc4ba");
    expect(cascade(current(), "border-bottom", "border-bottom-color")).toBe("");
    expect(cascade(name(), "text-transform")).toBe("");
  });
});

describe("the console's edges", () => {
  const island = () => mount(TOPBAR, ["div", "island presence"]);

  it("are Crate's 10 % hairline with 6 px corners under Crate", () => {
    wear("crate");
    expect(cascade(island(), "border-color", "border")).toBe("color-mix(in srgb, #f1f5f9 10%, transparent)");
    expect(cascade(island(), "border-radius")).toBe("6px");
  });

  it("stay the stock soft line on the 12 px island", () => {
    wear("stock");
    expect(cascade(island(), "border", "border-color")).toBe("1px solid color-mix(in srgb, #cdc4ba 13%, transparent)");
    expect(cascade(island(), "border-radius")).toBe("12px");
  });
});

describe("the status dot", () => {
  const dot = () => mount(LAMP, ["span", "lamp ok"]);

  it("follows the accent under Crate", () => {
    wear("crate");
    expect(cascade(dot(), "background", "background-color")).toBe("#67e8f9");
  });

  it("stays bone in the stock look", () => {
    wear("stock");
    expect(cascade(dot(), "background", "background-color")).toBe("#cdc4ba");
  });
});

describe("the approval segments", () => {
  const picked = () => mount(SEG, ["button", "seg-item"]);

  it("fill the picked one with the mark, in mono caps, under Crate", () => {
    wear("crate");
    const el = picked();
    el.dataset.state = "on";
    expect(cascade(el, "background", "background-color")).toBe("#67e8f9");
    expect(cascade(el, "text-transform")).toBe("uppercase");
  });
});

describe("a sent prompt", () => {
  const plate = () => mount(MESSAGE, ["div", "user-plate"]);

  it("is a raised hairline card under Crate and the bone plate in stock", () => {
    wear("crate");
    expect(cascade(plate(), "background", "background-color")).toBe("#0f1016");
    wear("stock");
    expect(cascade(plate(), "background", "background-color")).toBe("#cdc4ba");
  });
});

describe("the Needle", () => {
  it("wears the accent itself, with paper eyes, under Crate", () => {
    const c = needleColours("crate", "#06b6d4", "#0a0a0f");
    expect(c.palette).toEqual({ head: "#06b6d4", eye: "#0a0a0f" });
    expect(c.hue).toBe(215);
  });

  it("keeps the stock vermillion swatch", () => {
    expect(needleColours("stock", "#06b6d4", "#0a0a0f")).toEqual(STOCK_NEEDLE);
    expect(STOCK_NEEDLE).toEqual({ hue: 29, tone: 0.7 });
    expect(Math.round(oklchHue("#e2342a")!)).toBe(29);
  });

  it("falls back to the stock face when the accent is not a colour", () => {
    expect(needleColours("crate", "cyan", "#0a0a0f")).toEqual(STOCK_NEEDLE);
  });
});
