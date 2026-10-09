#!/usr/bin/env node
// Render audit — measure on the rendered page what can be measured, and hand a
// person a contact sheet for the rest.
//
// An agent does not know what "good" looks like, and reading a screenshot it
// misses what a person sees at a glance. But a large share of what people find
// by looking is not taste at all — it is geometry, and geometry can be measured:
//
//   tap-target   an interactive element smaller than the minimum at phone width
//                (44×44 by default: iOS HIG; Material uses 48; WCAG 2.5.8 AA is 24)
//   text-size    visible text below the minimum size
//   overflow     text that spills out of its box, or is cut off with no way to
//                read the rest (clipped, or ellipsis with no title/aria-label)
//   page-scroll  the page scrolls sideways at this width
//   overlap      two interactive elements whose boxes intersect
//
// Each page is drawn at phone and desktop width, screenshotted whole, and put on
// one contact sheet with its findings, so the person's job is a look, not a search.
// Render your stress fixture (longest names, 3-digit counts, zero items, deepest
// hierarchy — see docs/quality/README.md) and most layout breaks show up here.
//
// What it CANNOT see: taste, hierarchy, whether a control is recognisable as one,
// hit areas enlarged by pseudo-elements, anything behind an interaction it was
// not told to perform, content inside containers that scroll sideways on purpose,
// and overlap involving fixed or sticky bars (skipped: they cover content by design). A clean run is "nothing measurable", never "looks good".
//
//   node scripts/render-audit.mjs [--out DIR] [--report-only] [--min-target N]
//                                 [--min-text N] <url-or-file>...
//   make render-audit            pages from docs/quality/render-pages.txt
//
// Exit: 0 clean (or --report-only), 1 findings, 2 could not run.
import { mkdirSync, writeFileSync, existsSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { createRequire } from 'node:module';

const args = process.argv.slice(2);
const opt = { out: '', reportOnly: false, minTarget: 44, minText: 12 };
const pages = [];
for (let i = 0; i < args.length; i++) {
  const a = args[i];
  const value = () => {
    const v = args[++i];
    if (v === undefined || v.startsWith('--')) { console.error(`render-audit: ${a} needs a value`); process.exit(2); }
    return v;
  };
  const number = () => {
    const n = Number(value());
    if (!Number.isFinite(n) || n <= 0) { console.error(`render-audit: ${a} must be a positive number — a threshold that is not a number switches the check off`); process.exit(2); }
    return n;
  };
  if (a === '--out') opt.out = value();
  else if (a === '--report-only') opt.reportOnly = true;
  else if (a === '--min-target') opt.minTarget = number();
  else if (a === '--min-text') opt.minText = number();
  else if (a.startsWith('--')) { console.error(`unknown option ${a}`); process.exit(2); }
  else pages.push(a);
}
if (!pages.length) {
  console.error('render-audit: no pages given. List them in docs/quality/render-pages.txt, or pass URLs.');
  process.exit(2);
}
let chromium;
for (const m of ['playwright', '@playwright/test']) {
  try { ({ chromium } = await import(m)); break; } catch { /* try the next */ }
  // ESM import ignores NODE_PATH; require() honours it, so a global install works too.
  try { ({ chromium } = createRequire(join(process.cwd(), 'x.js'))(m)); break; } catch { /* try the next */ }
}
if (!chromium) {
  console.error('render-audit: Playwright is not installed. npm i -D playwright && npx playwright install chromium');
  process.exit(2);
}
const stamp = new Date().toISOString().replace(/[:.]/g, '-');
const out = resolve(opt.out || join('.agents', 'runs', 'render-audit', stamp));
mkdirSync(out, { recursive: true });
const VIEWPORTS = [
  { name: 'phone', width: 390, height: 844, mobile: true },
  { name: 'desktop', width: 1440, height: 900, mobile: false },
];
const toUrl = (p) => (/^[a-z]+:\/\//i.test(p) ? p : existsSync(p) ? pathToFileURL(resolve(p)).href : p);

// Runs inside the page. Returns findings; describes each element by a short selector.
function measure({ minTarget, minText, mobile, width }) {
  const INTERACTIVE = 'a[href],button,input:not([type=hidden]),select,textarea,summary,[role=button],[role=link],[role=checkbox],[role=radio],[role=tab],[role=switch],[role=menuitem],[onclick],[tabindex]:not([tabindex="-1"])';
  const out = [];
  // Screen-reader-only content (the clip / 1px pattern) is meant to be invisible
  // and untappable; measuring it produces failures on every accessible site.
  const srOnly = (el) => {
    const cs = getComputedStyle(el); const r = el.getBoundingClientRect();
    return (cs.clip && cs.clip !== 'auto') || /inset\(50%|inset\(100%/.test(cs.clipPath || '')
      || (cs.position === 'absolute' && r.width <= 1 && r.height <= 1);
  };
  // Hidden by itself OR by any ancestor: opacity, visibility, aria-hidden, inert.
  const visible = (el) => {
    const r = el.getBoundingClientRect();
    if (!(r.width > 0 && r.height > 0)) return false;
    for (let e = el; e && e !== document.documentElement; e = e.parentElement) {
      const cs = getComputedStyle(e);
      if (cs.display === 'none' || cs.visibility === 'hidden' || Number(cs.opacity) === 0) return false;
      if (e.getAttribute('aria-hidden') === 'true' || e.hasAttribute('inert')) return false;
      if (srOnly(e)) return false;
    }
    return true;
  };
  // Inside a container that scrolls sideways on purpose (a carousel, a wide table).
  const inScroller = (el) => {
    for (let e = el; e && e !== document.body; e = e.parentElement) {
      const o = getComputedStyle(e).overflowX;
      if ((o === 'auto' || o === 'scroll') && e.scrollWidth > e.clientWidth) return true;
    }
    return false;
  };
  const pinned = (el) => {
    for (let e = el; e && e !== document.body; e = e.parentElement) {
      const p = getComputedStyle(e).position;
      if (p === 'fixed' || p === 'sticky') return true;
    }
    return false;
  };
  const name = (el) => {
    let s = el.tagName.toLowerCase();
    if (el.id) s += '#' + el.id;
    else if (el.classList.length) s += '.' + [...el.classList].slice(0, 2).join('.');
    const t = (el.getAttribute('aria-label') || el.textContent || el.value || '').trim().replace(/\s+/g, ' ');
    return t ? `${s} "${t.slice(0, 40)}${t.length > 40 ? '…' : ''}"` : s;
  };
  // An inline link inside running text is exempt from target size (WCAG 2.5.8).
  const inlineInText = (el) => {
    if (el.tagName !== 'A' || getComputedStyle(el).display !== 'inline') return false;
    const p = el.parentElement; if (!p) return false;
    return [...p.childNodes].some((n) => n.nodeType === 3 && n.textContent.trim().length > 0);
  };
  const targets = [...document.querySelectorAll(INTERACTIVE)].filter(visible);
  if (mobile) {
    for (const el of targets) {
      if (inlineInText(el)) continue;
      const r = el.getBoundingClientRect();
      if (r.width < minTarget || r.height < minTarget) {
        const hard = r.width < 24 || r.height < 24;
        out.push({ check: 'tap-target', severity: hard ? 'fail' : 'warn', el: name(el),
          detail: `${Math.round(r.width)}×${Math.round(r.height)} — minimum ${minTarget}×${minTarget}${hard ? '; below WCAG 2.5.8 (24×24)' : ''}` });
      }
    }
  }
  // Text size: the element that directly holds visible text.
  const seen = new Set();
  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  while (walker.nextNode()) {
    const n = walker.currentNode; const el = n.parentElement;
    if (!el || seen.has(el) || !n.textContent.trim() || !visible(el)) continue;
    seen.add(el);
    const fs = parseFloat(getComputedStyle(el).fontSize);
    if (fs < minText) out.push({ check: 'text-size', severity: 'warn', el: name(el), detail: `${fs}px — minimum ${minText}px` });
  }
  // Overflow: spills, silent clips, and ellipsis with no way to read the rest.
  // Reported on the innermost box that overflows, so one long name is one finding.
  const overflowing = [...document.body.querySelectorAll('*')].filter((el) =>
    el.clientWidth > 0 && el.scrollWidth > el.clientWidth + 1 && el.textContent.trim() && visible(el) && !inScroller(el.parentElement || el)
    && !['auto', 'scroll'].includes(getComputedStyle(el).overflowX));
  for (const el of overflowing) {
    if (overflowing.some((o) => o !== el && el.contains(o))) continue;
    const cs = getComputedStyle(el);
    const readable = el.title || el.getAttribute('aria-label') || el.closest('[title]');
    if (cs.textOverflow === 'ellipsis') {
      if (!readable) out.push({ check: 'overflow', severity: 'warn', el: name(el), detail: 'truncated with an ellipsis and no title/aria-label — the full text cannot be read' });
    } else if (cs.overflowX === 'hidden' || cs.overflow === 'hidden' || cs.overflowX === 'clip') {
      out.push({ check: 'overflow', severity: 'fail', el: name(el), detail: `text clipped silently (${el.scrollWidth}px of content in ${el.clientWidth}px)` });
    } else if (cs.overflowX === 'visible') {
      out.push({ check: 'overflow', severity: 'fail', el: name(el), detail: `text spills out of its box (${el.scrollWidth}px in ${el.clientWidth}px)` });
    }
  }
  const se = document.scrollingElement;
  // Against the width asked for, not window.innerWidth: a mobile browser widens
  // its layout viewport to fit oversized content, which hides exactly this.
  if (se.scrollWidth > width + 1) {
    out.push({ check: 'page-scroll', severity: 'fail', el: 'page', detail: `page is ${se.scrollWidth}px wide at a ${width}px viewport` });
  }
  // Overlap between interactive elements that do not contain one another.
  for (let i = 0; i < targets.length; i++) {
    for (let j = i + 1; j < targets.length; j++) {
      const a = targets[i], b = targets[j];
      if (a.contains(b) || b.contains(a)) continue;
      // A fixed or sticky bar sits over content by design; what it covers moves.
      if (pinned(a) !== pinned(b)) continue;
      const ra = a.getBoundingClientRect(), rb = b.getBoundingClientRect();
      const w = Math.min(ra.right, rb.right) - Math.max(ra.left, rb.left);
      const h = Math.min(ra.bottom, rb.bottom) - Math.max(ra.top, rb.top);
      if (w > 2 && h > 2) out.push({ check: 'overlap', severity: 'fail', el: `${name(a)} × ${name(b)}`, detail: `boxes intersect by ${Math.round(w)}×${Math.round(h)}px` });
    }
  }
  return out;
}

const browser = await chromium.launch();
const results = [];
try {
  for (const p of pages) {
    for (const vp of VIEWPORTS) {
      const ctx = await browser.newContext({ viewport: { width: vp.width, height: vp.height }, isMobile: vp.mobile, hasTouch: vp.mobile, deviceScaleFactor: 1 });
      const page = await ctx.newPage();
      const entry = { page: p, viewport: vp.name, findings: [], shot: '' };
      try {
        await page.goto(toUrl(p), { waitUntil: 'load', timeout: 30000 });
        // Settle, but a page that long-polls never goes idle — that is not a failure.
        await page.waitForLoadState('networkidle', { timeout: 5000 }).catch(() => {});
        entry.findings = await page.evaluate(measure, { minTarget: opt.minTarget, minText: opt.minText, mobile: vp.mobile, width: vp.width });
        const file = `${results.length + 1}-${vp.name}.png`;
        await page.screenshot({ path: join(out, file), fullPage: true });
        entry.shot = file;
      } catch (e) {
        entry.error = String(e.message || e).split('\n')[0];
      }
      results.push(entry);
      await ctx.close();
    }
  }
} finally {
  await browser.close();
}

const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const rows = results.map((r) => `<section><h2>${esc(r.page)} · ${r.viewport}</h2>
${r.error ? `<p class="err">Could not render: ${esc(r.error)}</p>` : ''}
<ul>${r.findings.map((f) => `<li class="${f.severity}"><b>${f.check}</b> ${esc(f.el)} — ${esc(f.detail)}</li>`).join('') || '<li class="ok">nothing measurable — still look</li>'}</ul>
${r.shot ? `<a href="${r.shot}"><img src="${r.shot}" alt="${esc(r.page)} at ${r.viewport} width" loading="lazy"></a>` : ''}</section>`).join('\n');
writeFileSync(join(out, 'index.html'), `<!doctype html><meta charset="utf-8"><title>Render audit</title>
<style>body{font:14px system-ui;margin:24px;max-width:1600px}section{margin:0 0 32px}img{max-width:100%;max-height:900px;border:1px solid #ccc}
li.fail{color:#b00020}li.warn{color:#8a5a00}li.ok{color:#2e7d32}.err{color:#b00020}</style>
<h1>Render audit</h1><p>Measured: tap targets (phone), text size, overflow, sideways scroll, overlap. <b>Not</b> measured: taste, hierarchy, whether a control looks like one — that part is yours.</p>
${rows}`);
writeFileSync(join(out, 'findings.json'), JSON.stringify(results, null, 2));

const all = results.flatMap((r) => r.findings.map((f) => ({ ...f, page: r.page, viewport: r.viewport })));
const errors = results.filter((r) => r.error);
for (const r of errors) console.error(`✗ could not render ${r.page} at ${r.viewport}: ${r.error}`);
for (const f of all) console.log(`${f.severity === 'fail' ? '✗' : '!'} ${f.check.padEnd(11)} ${f.page} @${f.viewport}  ${f.el} — ${f.detail}`);
const n = (s) => all.filter((f) => f.severity === s).length;
console.log(`render audit: ${pages.length} page(s) × ${VIEWPORTS.length} widths — ${n('fail')} fail, ${n('warn')} warn. Contact sheet: ${join(out, 'index.html')}`);
if (errors.length) process.exit(2);
process.exit(all.length && !opt.reportOnly ? 1 : 0);
