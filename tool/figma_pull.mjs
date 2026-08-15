#!/usr/bin/env node
/**
 * figma_pull.mjs — pull a single Figma frame down to something a human (or an
 * agent with a context budget) can actually read.
 *
 * Raw Figma node JSON for one screen is routinely several megabytes of vector
 * geometry, transform matrices and plugin data. This script keeps only what you
 * need to rebuild the screen in Flutter — geometry, fills, strokes, radii, auto
 * layout, text content and text styles — and throws the rest away.
 *
 * Usage:
 *   node tool/figma_pull.mjs "<figma url with ?node-id=...>" [--out <dir>] [--scale 2] [--no-image]
 *
 * Auth: reads FIGMA_TOKEN from the environment, or from a `.figma.env` file in
 * the project root containing `FIGMA_TOKEN=figd_...`. That file is gitignored.
 *
 * Outputs into <out> (default tool/figma_out/):
 *   <slug>.tree.json    pruned node tree, coordinates relative to the frame origin
 *   <slug>.tokens.json  every distinct colour / text style / radius / gap, with usage counts
 *   <slug>.png          rendered reference image of the frame
 */

import { writeFile, mkdir, readFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';

const API = 'https://api.figma.com/v1';
const ROOT = path.resolve(import.meta.dirname, '..');

/* ------------------------------------------------------------------ auth --- */

async function loadToken() {
  if (process.env.FIGMA_TOKEN) return process.env.FIGMA_TOKEN.trim();

  const envFile = path.join(ROOT, '.figma.env');
  if (existsSync(envFile)) {
    const text = await readFile(envFile, 'utf8');
    for (const line of text.split(/\r?\n/)) {
      const m = line.match(/^\s*FIGMA_TOKEN\s*=\s*(.+?)\s*$/);
      if (m) return m[1].replace(/^["']|["']$/g, '');
    }
  }
  die(
    'No Figma token found.\n' +
      '  Create one at figma.com -> Settings -> Security -> Personal access tokens\n' +
      '  (scope: File content, read-only), then put it in .figma.env as:\n' +
      '      FIGMA_TOKEN=figd_your_token_here',
  );
}

/* ------------------------------------------------------------------ args --- */

function parseArgs(argv) {
  const opts = {
    url: null,
    out: path.join(ROOT, 'tool', 'figma_out'),
    scale: 2,
    image: true,
    list: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--out') opts.out = path.resolve(argv[++i]);
    else if (a === '--scale') opts.scale = Number(argv[++i]);
    else if (a === '--no-image') opts.image = false;
    else if (a === '--list') opts.list = true;
    else if (!a.startsWith('--')) opts.url = a;
  }
  if (!opts.url) {
    die(
      'Pass a Figma URL, e.g.\n' +
        '  node tool/figma_pull.mjs "https://www.figma.com/design/ABC123/Job-Sensei?node-id=42-1337"\n\n' +
        'Add --list to enumerate every page and top-level frame instead:\n' +
        '  node tool/figma_pull.mjs --list "https://www.figma.com/design/ABC123/Job-Sensei"',
    );
  }
  return opts;
}

/**
 * Figma share URLs look like /design/<fileKey>/<name>?node-id=<a>-<b>.
 * The REST API wants the node id colon-separated, so `42-1337` -> `42:1337`.
 */
function parseFigmaUrl(raw, { requireNode = true } = {}) {
  let u;
  try {
    u = new URL(raw);
  } catch {
    die(`Not a URL: ${raw}`);
  }
  const key = u.pathname.match(/\/(?:file|design)\/([A-Za-z0-9]+)/)?.[1];
  if (!key) die(`Could not find a file key in that URL. Expected /design/<key>/...`);

  const nodeParam = u.searchParams.get('node-id');
  if (!nodeParam && requireNode) {
    die(
      'That URL has no ?node-id=. In Figma, right-click the frame you want and\n' +
        'choose "Copy link to selection" — that adds the node id.',
    );
  }
  return { key, nodeId: nodeParam ? nodeParam.replace(/-/g, ':') : null };
}

/**
 * Print every page and its top-level children so you can find the node id of
 * the frame you actually want. Uses depth=2 to keep the payload small.
 */
async function listFile(key, token) {
  const data = await figma(`/files/${key}?depth=2`, token);
  console.log(`\n${data.name}\n`);

  for (const page of data.document?.children ?? []) {
    const kids = page.children ?? [];
    console.log(`  PAGE  ${page.name}  (${kids.length} top-level)`);
    for (const child of kids) {
      const box = child.absoluteBoundingBox;
      const size = box ? `${Math.round(box.width)}x${Math.round(box.height)}` : '—';
      // The dash form is what a Figma URL uses, so it can be pasted directly.
      console.log(
        `        ${child.type.padEnd(9)} ${child.id.replace(':', '-').padEnd(10)} ${size.padEnd(11)} ${child.name}`,
      );
    }
    console.log('');
  }
  console.log('Re-run without --list using ?node-id=<the id you want>\n');
}

/* ------------------------------------------------------------- api calls --- */

async function figma(pathAndQuery, token) {
  const res = await fetch(`${API}${pathAndQuery}`, { headers: { 'X-Figma-Token': token } });
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    if (res.status === 403) die(`403 from Figma — token is invalid, expired, or lacks access to this file.`);
    if (res.status === 404) die(`404 from Figma — file or node not found. Check the URL.`);
    die(`Figma API ${res.status}: ${body.slice(0, 400)}`);
  }
  return res.json();
}

/* --------------------------------------------------------------- pruning --- */

const round = (n) => (typeof n === 'number' ? Math.round(n * 100) / 100 : n);

/** Figma stores channels as 0..1 floats. Emit Flutter-friendly #AARRGGBB. */
function toHex(color, opacity = 1) {
  if (!color) return null;
  const a = Math.round(255 * (color.a ?? 1) * opacity);
  const ch = (v) => Math.round(255 * v).toString(16).padStart(2, '0').toUpperCase();
  const rgb = `${ch(color.r)}${ch(color.g)}${ch(color.b)}`;
  return a === 255 ? `#FF${rgb}` : `#${a.toString(16).padStart(2, '0').toUpperCase()}${rgb}`;
}

function describePaint(paint) {
  if (!paint || paint.visible === false) return null;
  if (paint.type === 'SOLID') return toHex(paint.color, paint.opacity ?? 1);
  if (paint.type?.startsWith('GRADIENT')) {
    const stops = (paint.gradientStops ?? []).map((s) => `${toHex(s.color)}@${round(s.position)}`);
    return `${paint.type}(${stops.join(', ')})`;
  }
  if (paint.type === 'IMAGE') return `IMAGE(${paint.scaleMode})`;
  return paint.type ?? null;
}

/**
 * Icons are usually a small group of VECTOR/BOOLEAN_OPERATION nodes. Recursing
 * into them produces hundreds of meaningless path nodes, so we collapse them to
 * a single entry and record the id for a later SVG export.
 */
const VECTOR_TYPES = new Set(['VECTOR', 'BOOLEAN_OPERATION', 'STAR', 'LINE', 'ELLIPSE', 'REGULAR_POLYGON']);

function isIconContainer(node) {
  if (!node.children?.length) return false;
  const box = node.absoluteBoundingBox;
  const small = box && box.width <= 64 && box.height <= 64;
  return small && node.children.every((c) => VECTOR_TYPES.has(c.type) || isIconContainer(c));
}

function pruneNode(node, origin, tokens, iconIds, depth = 0) {
  const out = { name: node.name, type: node.type };

  // Geometry, relative to the frame's top-left so the numbers read like Flutter offsets.
  const box = node.absoluteBoundingBox;
  if (box) {
    out.x = round(box.x - origin.x);
    out.y = round(box.y - origin.y);
    out.w = round(box.width);
    out.h = round(box.height);
  }

  if (node.visible === false) out.hidden = true;
  if (node.opacity != null && node.opacity !== 1) out.opacity = round(node.opacity);

  // Fills / strokes.
  const fills = (node.fills ?? []).map(describePaint).filter(Boolean);
  if (fills.length) {
    out.fill = fills.length === 1 ? fills[0] : fills;
    for (const f of fills) if (f.startsWith('#')) bump(tokens.colors, f);
  }
  const strokes = (node.strokes ?? []).map(describePaint).filter(Boolean);
  if (strokes.length) {
    out.stroke = strokes.length === 1 ? strokes[0] : strokes;
    out.strokeWidth = round(node.strokeWeight);
    for (const s of strokes) if (s.startsWith('#')) bump(tokens.colors, s);
  }

  // Corner radius — Figma gives either a uniform value or per-corner array.
  if (node.cornerRadius != null) {
    out.radius = round(node.cornerRadius);
    bump(tokens.radii, out.radius);
  } else if (node.rectangleCornerRadii) {
    out.radius = node.rectangleCornerRadii.map(round);
    for (const r of out.radius) bump(tokens.radii, r);
  }

  // Auto layout maps almost 1:1 onto Row/Column + Padding in Flutter.
  if (node.layoutMode && node.layoutMode !== 'NONE') {
    out.layout = {
      direction: node.layoutMode === 'HORIZONTAL' ? 'row' : 'column',
      gap: round(node.itemSpacing),
      padding: [node.paddingTop, node.paddingRight, node.paddingBottom, node.paddingLeft].map(
        (v) => round(v ?? 0),
      ),
      mainAxis: node.primaryAxisAlignItems ?? 'MIN',
      crossAxis: node.counterAxisAlignItems ?? 'MIN',
    };
    if (node.itemSpacing) bump(tokens.gaps, round(node.itemSpacing));
    for (const p of out.layout.padding) if (p) bump(tokens.paddings, p);
  }

  // Shadows and blurs.
  const effects = (node.effects ?? [])
    .filter((e) => e.visible !== false)
    .map((e) =>
      e.type.includes('SHADOW')
        ? `${e.type} ${toHex(e.color)} x${round(e.offset?.x ?? 0)} y${round(e.offset?.y ?? 0)} blur${round(e.radius)} spread${round(e.spread ?? 0)}`
        : `${e.type} ${round(e.radius)}`,
    );
  if (effects.length) out.effects = effects;

  // Text.
  if (node.type === 'TEXT') {
    out.text = node.characters;
    const s = node.style ?? {};
    const style = {
      family: s.fontFamily,
      weight: s.fontWeight,
      size: round(s.fontSize),
      lineHeight: round(s.lineHeightPx),
      letterSpacing: round(s.letterSpacing),
      align: s.textAlignHorizontal,
      case: s.textCase,
    };
    for (const k of Object.keys(style)) if (style[k] == null) delete style[k];
    out.style = style;
    bump(tokens.textStyles, JSON.stringify(style));
  }

  // Collapse icons instead of recursing into their vector soup.
  if (isIconContainer(node)) {
    out.type = 'ICON';
    out.figmaId = node.id;
    iconIds.push({ id: node.id, name: node.name });
    return out;
  }
  if (VECTOR_TYPES.has(node.type)) {
    out.figmaId = node.id;
    iconIds.push({ id: node.id, name: node.name });
    return out;
  }

  if (node.children?.length) {
    out.children = node.children
      .filter((c) => c.visible !== false)
      .map((c) => pruneNode(c, origin, tokens, iconIds, depth + 1));
  }
  return out;
}

const bump = (map, key) => map.set(key, (map.get(key) ?? 0) + 1);

/** Sort a usage map into a descending [value, count] list — most-used first. */
const rank = (map, parse = (k) => k) =>
  [...map.entries()].sort((a, b) => b[1] - a[1]).map(([k, n]) => ({ value: parse(k), uses: n }));

/* ------------------------------------------------------------------ main --- */

/// Thrown by [die] so failures unwind to main() instead of calling
/// process.exit() mid-request, which trips a libuv assertion on Windows when a
/// keep-alive socket is still open.
class Fail extends Error {}

function die(msg) {
  throw new Fail(msg);
}

const slugify = (s) =>
  s.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '').slice(0, 60) || 'frame';

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  const token = await loadToken();
  const { key, nodeId } = parseFigmaUrl(opts.url, { requireNode: !opts.list });

  if (opts.list) return listFile(key, token);

  console.log(`file ${key}  node ${nodeId}`);

  const data = await figma(`/files/${key}/nodes?ids=${encodeURIComponent(nodeId)}`, token);
  const entry = data.nodes?.[nodeId];
  if (!entry?.document) die(`Figma returned no document for node ${nodeId}. Is it inside this file?`);

  const doc = entry.document;
  const origin = doc.absoluteBoundingBox ?? { x: 0, y: 0 };
  const tokens = {
    colors: new Map(),
    textStyles: new Map(),
    radii: new Map(),
    gaps: new Map(),
    paddings: new Map(),
  };
  const iconIds = [];

  const tree = pruneNode(doc, origin, tokens, iconIds);

  await mkdir(opts.out, { recursive: true });
  const slug = slugify(doc.name);

  const treePath = path.join(opts.out, `${slug}.tree.json`);
  await writeFile(treePath, JSON.stringify(tree, null, 2));

  const tokensPath = path.join(opts.out, `${slug}.tokens.json`);
  await writeFile(
    tokensPath,
    JSON.stringify(
      {
        frame: doc.name,
        size: { w: round(origin.width), h: round(origin.height) },
        colors: rank(tokens.colors),
        textStyles: rank(tokens.textStyles, JSON.parse),
        radii: rank(tokens.radii, Number),
        gaps: rank(tokens.gaps, Number),
        paddings: rank(tokens.paddings, Number),
        icons: iconIds,
      },
      null,
      2,
    ),
  );

  let imagePath = null;
  if (opts.image) {
    const img = await figma(
      `/images/${key}?ids=${encodeURIComponent(nodeId)}&format=png&scale=${opts.scale}`,
      token,
    );
    const url = img.images?.[nodeId];
    if (url) {
      const bytes = Buffer.from(await (await fetch(url)).arrayBuffer());
      imagePath = path.join(opts.out, `${slug}.png`);
      await writeFile(imagePath, bytes);
    } else {
      console.warn('! Figma did not return a render for this node (err: ' + (img.err ?? 'unknown') + ')');
    }
  }

  const rel = (p) => (p ? path.relative(ROOT, p).replace(/\\/g, '/') : null);
  console.log(`\n"${doc.name}"  ${round(origin.width)}x${round(origin.height)}`);
  console.log(`  ${tokens.colors.size} colours, ${tokens.textStyles.size} text styles, ${iconIds.length} icons/vectors`);
  console.log(`  tree   ${rel(treePath)}`);
  console.log(`  tokens ${rel(tokensPath)}`);
  if (imagePath) console.log(`  image  ${rel(imagePath)}`);
}

main().catch((e) => {
  console.error(`\n${e instanceof Fail ? e.message : (e.stack ?? String(e))}\n`);
  // Let the process wind down on its own rather than exiting hard.
  process.exitCode = 1;
});
