// Render the existing square Lumière master into Chip's opaque iOS app icon.
import fs from 'node:fs/promises'
import { chromium } from 'playwright'

const output = new URL('../apple/iOS/Assets.xcassets/AppIcon.appiconset/', import.meta.url)
await fs.mkdir(output, { recursive: true })
const svg = await fs.readFile(new URL('masters/lumiere-square.svg', import.meta.url), 'utf8')
const browser = await chromium.launch({ executablePath: process.env.CHROMIUM_PATH || undefined })
try {
  const page = await browser.newPage({ viewport: { width: 1024, height: 1024 }, deviceScaleFactor: 1 })
  await page.setContent(`<style>html,body{margin:0;background:#0f0f0f}svg{display:block}</style>${svg}`)
  await page.screenshot({ path: new URL('AppIcon.png', output).pathname, omitBackground: false })
  await fs.writeFile(new URL('Contents.json', output), JSON.stringify({
    images: [{ filename: 'AppIcon.png', idiom: 'universal', platform: 'ios', size: '1024x1024' }],
    info: { author: 'xcode', version: 1 },
  }, null, 2) + '\n')
} finally {
  await browser.close()
}
