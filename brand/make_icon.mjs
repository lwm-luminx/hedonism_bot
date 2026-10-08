// Draws the Lumière Archive mark: a seven-blade aperture in brushed gold, with warm light pouring through the opening.
// Colours come from the app's theme (ink #0f0f0f, gold #c9a96e).
// Writes three SVG masters into brand/masters:
//   lumiere-rounded.svg  app-icon tile with rounded corners
//   lumiere-square.svg   full-bleed tile (touch icons, which the OS rounds itself)
//   lumiere-mark.svg     the aperture alone on transparent (favicon, page headers)
// The masters use SVG grain and blend modes, so rasterise them in a browser: `node brand/render.mjs`.
// Usage: node brand/make_icon.mjs
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const OUT = path.join(path.dirname(fileURLToPath(import.meta.url)), 'masters')
fs.mkdirSync(OUT, { recursive: true })

const INK = '#0f0f0f', INK2 = '#1b1712'
const GOLD = { hi: '#fbeec6', lt: '#e6cc8f', mid: '#c9a96e', dk: '#8a6a34', deep: '#4a3818' }
const N = 7, CX = 512, CY = 512, R = 360, R0 = 150, ROT = -Math.PI / 2 + .3

function iris(variant) {
  const mark = variant === 'mark'
  const defs = [
    `<clipPath id="tile">${mark ? `<circle cx="${CX}" cy="${CY}" r="${R + 11}"/>` : `<rect width="1024" height="1024" rx="${variant === 'rounded' ? 228 : 0}"/>`}</clipPath>`,
    '<filter id="grain" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency=".75" numOctaves="2" seed="7" stitchTiles="stitch"/><feColorMatrix type="saturate" values="0"/></filter>',
    '<filter id="brush" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency=".004 .35" numOctaves="2" seed="3"/><feColorMatrix type="saturate" values="0"/></filter>',
    `<radialGradient id="bg" cx=".5" cy=".42" r=".75"><stop offset="0" stop-color="${INK2}"/><stop offset="1" stop-color="${INK}"/></radialGradient>`,
    `<radialGradient id="light"><stop offset="0" stop-color="#ffffff"/><stop offset=".35" stop-color="${GOLD.hi}"/><stop offset=".7" stop-color="#ffb35c"/><stop offset="1" stop-color="#ff7a3d"/></radialGradient>`,
    `<radialGradient id="halo"><stop offset="0" stop-color="${GOLD.lt}" stop-opacity=".35"/><stop offset=".6" stop-color="${GOLD.mid}" stop-opacity=".08"/><stop offset="1" stop-color="${GOLD.mid}" stop-opacity="0"/></radialGradient>`,
    `<linearGradient id="rim" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${GOLD.dk}"/><stop offset=".22" stop-color="${GOLD.lt}"/><stop offset=".38" stop-color="${GOLD.hi}"/><stop offset=".55" stop-color="${GOLD.mid}"/><stop offset=".78" stop-color="${GOLD.dk}"/><stop offset="1" stop-color="${GOLD.lt}"/></linearGradient>`,
    `<clipPath id="ring"><circle cx="${CX}" cy="${CY}" r="${R}"/></clipPath>`,
  ]
  const body = mark ? [] : [`<rect width="1024" height="1024" fill="url(#bg)"/>`, `<circle cx="${CX}" cy="${CY}" r="${R + 110}" fill="url(#halo)"/>`]
  body.push(`<circle cx="${CX}" cy="${CY}" r="${R}" fill="url(#light)"/>`)

  const P = i => [CX + R0 * Math.cos(ROT + i * 2 * Math.PI / N), CY + R0 * Math.sin(ROT + i * 2 * Math.PI / N)]
  const blades = []
  for (let i = 0; i < N; i++) {
    const a = P(i), b = P(i + 1)
    // Each blade runs from one edge of the opening out to the rim.
    const ang = ROT + (i + 1) * 2 * Math.PI / N + .95
    const ang2 = ang - 2 * Math.PI / N - .15
    const o1 = [CX + (R + 40) * Math.cos(ang), CY + (R + 40) * Math.sin(ang)]
    const o2 = [CX + (R + 40) * Math.cos(ang2), CY + (R + 40) * Math.sin(ang2)]
    const shade = i % 2 ? [GOLD.mid, GOLD.deep] : [GOLD.lt, GOLD.dk]
    const mid = ROT + (i + .5) * 2 * Math.PI / N
    const gx = .5 + .5 * Math.cos(mid), gy = .5 + .5 * Math.sin(mid)
    defs.push(`<linearGradient id="b${i}" x1="${1 - gx}" y1="${1 - gy}" x2="${gx}" y2="${gy}"><stop offset="0" stop-color="${shade[0]}"/><stop offset=".55" stop-color="${shade[1]}"/><stop offset="1" stop-color="${GOLD.deep}"/></linearGradient>`)
    blades.push(`<path d="M${a[0].toFixed(1)} ${a[1].toFixed(1)} L${b[0].toFixed(1)} ${b[1].toFixed(1)} L${o1[0].toFixed(1)} ${o1[1].toFixed(1)} A${R + 40} ${R + 40} 0 0 0 ${o2[0].toFixed(1)} ${o2[1].toFixed(1)} Z" fill="url(#b${i})" stroke="${GOLD.deep}" stroke-width="5" stroke-linejoin="round"/>`)
  }
  body.push(`<g clip-path="url(#ring)">${blades.join('')}</g>`)
  // Brushed-metal sheen across the blades, then the gold rim.
  body.push(`<g clip-path="url(#ring)"><rect width="1024" height="1024" filter="url(#brush)" opacity=".22" style="mix-blend-mode:soft-light"/></g>`)
  body.push(`<circle cx="${CX}" cy="${CY}" r="${R}" fill="none" stroke="url(#rim)" stroke-width="22"/>`)

  const box = mark ? `${CX - R - 11} ${CY - R - 11} ${2 * R + 22} ${2 * R + 22}` : '0 0 1024 1024'
  const px = mark ? 2 * R + 22 : 1024
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${box}" width="${px}" height="${px}">` +
    `<defs>${defs.join('')}</defs><g clip-path="url(#tile)">${body.join('')}` +
    `<rect width="1024" height="1024" filter="url(#grain)" opacity=".16" style="mix-blend-mode:overlay"/></g></svg>\n`
}

for (const v of ['rounded', 'square', 'mark']) fs.writeFileSync(path.join(OUT, `lumiere-${v}.svg`), iris(v))
console.log(`wrote ${OUT}/lumiere-{rounded,square,mark}.svg`)
