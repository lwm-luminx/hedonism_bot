// Rasterises the Lumière masters with Chromium (they use an SVG grain filter and blend modes,
// which most SVG renderers drop) and copies them to where the app and the Mac uploader use them.
// Usage: node brand/render.mjs   (needs `playwright`; set CHROMIUM_PATH to use an installed Chromium)
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { chromium } from 'playwright'

const brand = path.dirname(fileURLToPath(import.meta.url))
const root = path.dirname(brand)
const master = (v) => fs.readFileSync(path.join(brand, 'masters', `lumiere-${v}.svg`), 'utf8')

const browser = await chromium.launch({ executablePath: process.env.CHROMIUM_PATH || undefined })
const page = await browser.newPage()

async function png(svg, px, out, { inset = 0, shadow = false } = {}) {
  const size = px - 2 * inset
  await page.setViewportSize({ width: px, height: px })
  await page.setContent(`<style>html,body{margin:0;background:transparent}
    div{width:${px}px;height:${px}px;display:grid;place-items:center}
    svg{display:block;width:${size}px;height:${size}px;${shadow ? `filter:drop-shadow(0 ${px * .01}px ${px * .012}px rgba(0,0,0,.35))` : ''}}</style><div>${svg}</div>`)
  await page.screenshot({ path: path.join(root, out), omitBackground: true })
  console.log('wrote', out)
}

await png(master('mark'), 32, 'public/favicon-32.png')
await png(master('mark'), 64, 'public/favicon-64.png')
await png(master('square'), 180, 'public/apple-touch-icon.png')
// macOS app icons sit inside the canvas (824px of 1024) with a soft drop shadow.
await png(master('rounded'), 1024, 'mac/HedonismUploader/Resources/AppIcon-1024.png', { inset: 100, shadow: true })
await browser.close()

fs.copyFileSync(path.join(brand, 'masters', 'lumiere-mark.svg'), path.join(root, 'public/lumiere-mark.svg'))
console.log('wrote public/lumiere-mark.svg')
