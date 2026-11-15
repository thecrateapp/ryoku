// The Needle's colours. The stock look locks the creature's hue to the
// vermillion accent and lets blobatar pick the swatch and the eyes; the Crate
// look draws it in the theme's accent outright, with paper eyes, so the
// character stays Rashin's while it wears Crate's cyan.

import type { Look } from "$lib/state/theme.svelte";

export interface NeedleColours {
  hue: number;
  tone: number;
  palette?: { head: string; eye: string };
}

// Hue 29 is --sun (#e2342a) in OKLCh and tone 0.7 lands the body on that
// vermillion swatch rather than its pastel tint.
export const STOCK_NEEDLE: NeedleColours = { hue: 29, tone: 0.7 };

const HEX = /^#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})/i;

/** The OKLCh hue of an sRGB hex, so blobatar's own tints lean the accent's way. */
export function oklchHue(hex: string): number | null {
  const m = HEX.exec(hex);
  if (!m) return null;
  const [r, g, b] = m.slice(1).map((h) => {
    const c = parseInt(h, 16) / 255;
    return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
  }) as [number, number, number];
  const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  const mm = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  const a = 1.9779984951 * l - 2.428592205 * mm + 0.4505937099 * s;
  const bb = 0.0259040371 * l + 0.7827717662 * mm - 0.808675766 * s;
  return ((Math.atan2(bb, a) * 180) / Math.PI + 360) % 360;
}

export function needleColours(look: Look, accent: string, paper: string): NeedleColours {
  const hue = look === "crate" ? oklchHue(accent) : null;
  if (hue === null || !HEX.test(paper)) return STOCK_NEEDLE;
  return { hue: Math.round(hue), tone: STOCK_NEEDLE.tone, palette: { head: accent, eye: paper } };
}
