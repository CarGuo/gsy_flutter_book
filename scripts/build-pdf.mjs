// scripts/build-pdf.mjs
// Build a full-site PDF from the freshly built VitePress dist.
// Strategy:
//   1. Read docs/.vitepress/sidebar.generated.mts to get the canonical reading order.
//   2. Spin up a static HTTP server on the dist/ directory.
//   3. Use Puppeteer to load each URL and print it to a per-page PDF buffer.
//   4. Merge all PDF buffers into one with pdf-lib.
//   5. Write to artifacts/gsy-flutter-book.pdf
//
// Designed to run inside GitHub Actions (ubuntu-latest) where chromium and
// fonts-noto-cjk are pre-installed by the workflow.
//
// Run: node scripts/build-pdf.mjs [--limit=N]

import { createServer } from 'node:http'
import { readFile, writeFile, stat, mkdir } from 'node:fs/promises'
import { extname, join, resolve, dirname } from 'node:path'
import { pathToFileURL } from 'node:url'
import puppeteer from 'puppeteer'
import { PDFDocument } from 'pdf-lib'

const DIST = resolve('docs/.vitepress/dist')
const OUT  = resolve('artifacts/gsy-flutter-book.pdf')
const PORT = 4173
const BASE = '/home/wx/'

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js':   'application/javascript',
  '.mjs':  'application/javascript',
  '.css':  'text/css',
  '.json': 'application/json',
  '.svg':  'image/svg+xml',
  '.png':  'image/png',
  '.jpg':  'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif':  'image/gif',
  '.webp': 'image/webp',
  '.ico':  'image/x-icon',
  '.woff': 'font/woff',
  '.woff2':'font/woff2',
  '.wasm': 'application/wasm',
}

function startServer() {
  const server = createServer(async (req, res) => {
    try {
      let urlPath = decodeURIComponent(req.url.split('?')[0])
      if (BASE !== '/' && urlPath.startsWith(BASE)) {
        urlPath = '/' + urlPath.slice(BASE.length)
      } else if (BASE !== '/' && urlPath === BASE.slice(0, -1)) {
        urlPath = '/'
      }
      if (urlPath.endsWith('/')) urlPath += 'index.html'
      let fp = join(DIST, urlPath)
      try {
        const s = await stat(fp)
        if (s.isDirectory()) fp = join(fp, 'index.html')
      } catch {
        const candidate = fp + '.html'
        try { await stat(candidate); fp = candidate } catch {}
      }
      const data = await readFile(fp)
      const ct = MIME[extname(fp).toLowerCase()] || 'application/octet-stream'
      res.writeHead(200, { 'Content-Type': ct })
      res.end(data)
    } catch (e) {
      res.writeHead(404).end('not found')
    }
  })
  return new Promise(r => server.listen(PORT, () => r(server)))
}

async function loadOrder() {
  const txt = await readFile('docs/.vitepress/sidebar.generated.mts', 'utf8')
  const links = []
  const re = /"link"\s*:\s*"([^"]+)"/g
  let m
  while ((m = re.exec(txt))) links.push(m[1])
  return [...new Set(links)]
}

// CSS injected before printing. Keeps VitePress doc layout intact, only hides
// site chrome that does not belong in a print artifact.
const PRINT_CSS = `
  @page { size: A4; margin: 16mm 14mm; }

  /* Hide site chrome only */
  .VPNav, .VPLocalNav, .VPSidebar, .VPDocFooter, .VPFooter,
  .VPDocAside, .VPDocAsideOutline, .VPBackdrop,
  .pf-launcher, .pf-search-trigger, [data-pagefind-ignore],
  .site-stats, [id^="busuanzi_container_"] { display: none !important; }

  html, body { background: #fff !important; }

  /* Force a CJK-capable font stack so Linux runners with fonts-noto-cjk render
     Chinese glyphs correctly even if VitePress theme variables resolve to a
     latin-only family. macOS / Windows fall back to their native CJK fonts. */
  html, body, .vp-doc, .VPHome, .VPHero, .VPFeatures, .VPFeature {
    font-family:
      -apple-system, BlinkMacSystemFont, "PingFang SC", "Hiragino Sans GB",
      "Microsoft YaHei", "Noto Sans CJK SC", "Noto Sans SC", "WenQuanYi Micro Hei",
      "Helvetica Neue", Arial, sans-serif !important;
  }
  .vp-doc code, .vp-doc pre, code {
    font-family:
      ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas,
      "Liberation Mono", "Noto Sans Mono CJK SC", "Noto Sans Mono", monospace !important;
  }

  /* Let the doc occupy the full printable width without VP's fixed sidebar offset */
  .VPContent { padding: 0 !important; }
  .VPDoc { padding: 0 !important; }
  .VPDoc .container, .VPDoc .content, .VPDoc .content-container { max-width: none !important; margin: 0 !important; padding: 0 !important; }
  .VPDoc .aside { display: none !important; }

  /* Typography tuned for A4 print, body 11pt */
  .vp-doc { font-size: 11pt; line-height: 1.7; color: #222; }
  .vp-doc h1 { font-size: 22pt; margin: 0 0 0.6em; page-break-before: auto; page-break-after: avoid; }
  .vp-doc h2 { font-size: 16pt; margin: 1.2em 0 0.5em; page-break-after: avoid; }
  .vp-doc h3 { font-size: 13pt; margin: 1em 0 0.4em; page-break-after: avoid; }
  .vp-doc p, .vp-doc li { orphans: 3; widows: 3; }
  .vp-doc pre { font-size: 9pt; line-height: 1.45; page-break-inside: avoid; white-space: pre-wrap; word-break: break-word; }
  .vp-doc code { font-size: 9.5pt; }
  .vp-doc img { max-width: 100% !important; height: auto !important; page-break-inside: avoid; }
  .vp-doc table { font-size: 10pt; page-break-inside: avoid; }
  .vp-doc blockquote { page-break-inside: avoid; }

  /* Home page (hero + features) kept as-is but bounded to printable area */
  .VPHome { padding: 0 !important; }
  .VPHero { padding: 12mm 0 8mm !important; }
  .VPHero .container { flex-direction: column !important; text-align: center !important; }
  .VPHero .main { order: 1; }
  .VPHero .image { order: 2; margin-top: 8mm; }
  .VPHero .image-container { width: 220px !important; height: 220px !important; }
  .VPHero .image-bg { width: 220px !important; height: 220px !important; }
  .VPHero .image-src { max-width: 220px !important; max-height: 220px !important; }

  /* Force 2-column grid for features regardless of viewport-class widths */
  .VPFeatures { padding: 0 !important; }
  .VPFeatures .container { max-width: none !important; padding: 0 !important; }
  .VPFeatures .items { display: grid !important; grid-template-columns: 1fr 1fr !important; gap: 6mm !important; margin: 0 !important; }
  .VPFeatures .items .item { width: 100% !important; padding: 0 !important; }
  .VPFeature { page-break-inside: avoid; height: 100% !important; }
`

const HEADER_TEMPLATE = `<div style="font-size:8pt;color:#888;width:100%;padding:0 14mm;display:flex;justify-content:space-between;">
  <span>GSY Flutter Book</span>
  <span class="title"></span>
</div>`

const FOOTER_TEMPLATE = `<div style="font-size:8pt;color:#888;width:100%;padding:0 14mm;text-align:center;">
  <span class="pageNumber"></span> / <span class="totalPages"></span>
</div>`

async function main() {
  const sidebarLinks = await loadOrder()
  // Always lead with the site home so PDF opens with the book cover.
  const links = ['/', ...sidebarLinks]

  const limitArg = process.argv.find(a => a.startsWith('--limit='))
  const limit = limitArg ? parseInt(limitArg.split('=')[1], 10) : links.length
  const onlyArg = process.argv.find(a => a.startsWith('--only='))
  const subset = onlyArg
    ? onlyArg.split('=')[1].split(',').map(s => s.trim()).filter(Boolean)
    : links.slice(0, limit)
  console.log(`[pdf] ${subset.length}/${links.length} pages to render`)

  const server = await startServer()
  console.log(`[pdf] static server up on :${PORT}`)

  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--font-render-hinting=none'],
  })
  const page = await browser.newPage()
  await page.emulateMediaType('print')
  await page.setViewport({ width: 1240, height: 1754, deviceScaleFactor: 1 })

  // Rewrite Qiniu-hosted images to use imageView2 server-side resize+recompress.
  // 2189 images on img.cdn.guoshuyu.cn average ~1MB each; with /2/w/1400/q/75/format/jpg
  // they come back ~50KB each, shrinking the merged PDF roughly 20x without any local
  // CPU work and without slowing down PDF generation.
  await page.setRequestInterception(true)
  const QINIU_HOST = /^https?:\/\/img\.cdn\.guoshuyu\.cn\//i
  const IMG_EXT = /\.(png|jpe?g|webp|gif)(\?|$)/i
  let rewriteCount = 0
  page.on('request', req => {
    const url = req.url()
    if (QINIU_HOST.test(url) && IMG_EXT.test(url) && !url.includes('imageView2')) {
      const sep = url.includes('?') ? '&' : '?'
      const rewritten = `${url}${sep}imageView2/2/w/1400/q/75/format/jpg`
      rewriteCount++
      req.continue({ url: rewritten })
    } else {
      req.continue()
    }
  })

  const merged = await PDFDocument.create()

  let i = 0
  for (const link of subset) {
    i++
    const cleanLink = link === '/' ? '/' : link
    const urlPath = (BASE !== '/' ? BASE.replace(/\/$/, '') : '') + cleanLink
    const url = `http://127.0.0.1:${PORT}${urlPath}`
    process.stdout.write(`[pdf] (${i}/${subset.length}) ${urlPath} ... `)
    try {
      await page.goto(url, { waitUntil: 'networkidle0', timeout: 60_000 })
      await page.addStyleTag({ content: PRINT_CSS })
      // Wait for webfonts to load so CJK glyphs render with the embedded font.
      await page.evaluate(() => document.fonts && document.fonts.ready)
      // Tiny settle delay for VitePress hydration after the style tag mutation.
      await new Promise(r => setTimeout(r, 250))

      const buf = await page.pdf({
        format: 'A4',
        margin: { top: '16mm', bottom: '16mm', left: '14mm', right: '14mm' },
        printBackground: true,
        preferCSSPageSize: true,
        displayHeaderFooter: true,
        headerTemplate: HEADER_TEMPLATE,
        footerTemplate: FOOTER_TEMPLATE,
      })
      const sub = await PDFDocument.load(buf)
      const copied = await merged.copyPages(sub, sub.getPageIndices())
      copied.forEach(p => merged.addPage(p))
      console.log('ok')
    } catch (e) {
      console.log('SKIP (' + e.message + ')')
    }
  }

  const out = await merged.save()
  await mkdir(dirname(OUT), { recursive: true })
  await writeFile(OUT, out)
  console.log(`[pdf] wrote ${OUT} (${(out.byteLength / 1024 / 1024).toFixed(2)} MB)`)
  console.log(`[pdf] rewrote ${rewriteCount} Qiniu image URLs via imageView2`)

  await browser.close()
  server.close()
}

main().catch(e => { console.error(e); process.exit(1) })
