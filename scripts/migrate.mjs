#!/usr/bin/env node
import fs from 'node:fs/promises'
import { createHash } from 'node:crypto'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import sharp from 'sharp'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const ROOT = path.resolve(__dirname, '..')
const DOCS = path.join(ROOT, 'docs')
const PUBLIC = path.join(DOCS, 'public')
const SUMMARY = path.join(ROOT, 'SUMMARY.md')
const RASTER_IMAGE_EXTENSIONS = new Set(['.png', '.jpg', '.jpeg', '.webp'])

const CATEGORY_MAP = {
  CORE: { dir: 'guide', label: 'Flutter 完整开发实战详解' },
  UPDATE_FLUTTER: { dir: 'flutter-updates', label: 'Flutter SDK 更新集锦' },
  UPDATE_DART: { dir: 'dart-updates', label: 'Dart 更新集锦' },
  EXTRA: { dir: 'extra', label: '番外篇' },
  ENGINEERING: { dir: 'engineering', label: 'Flutter 工程化选择' },
  ROOT_FRONT: { dir: 'guide', label: '前言' }
}

function slugify(filename) {
  return filename
    .replace(/\.md$/i, '')
    .replace(/\s+/g, '-')
    .replace(/[^A-Za-z0-9._\-+]/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '')
}

async function exists(p) {
  try { await fs.access(p); return true } catch { return false }
}

async function readSourceFile(name) {
  const decoded = decodeURIComponent(name)
  const candidates = [decoded, name]
  const typoFixed = decoded.replace(/^Fluttter-/, 'Flutter-')
  if (typoFixed !== decoded) candidates.push(typoFixed)
  for (const c of candidates) {
    const p = path.join(ROOT, c)
    if (await exists(p)) return { src: p, content: await fs.readFile(p, 'utf8') }
  }
  return null
}

function parseSummary(text) {
  const lines = text.split(/\r?\n/)
  const linkRe = /\[(.+?)\]\((.+?\.md)\)/
  const subHeaderRe = /^\s*-\s*\*\*(.+?)\*\*\s*$/
  const items = []
  let currentTopGroup = null
  let currentSubGroup = null

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]
    if (!line.trim()) continue

    const sub = line.match(subHeaderRe)
    if (sub) {
      const name = sub[1].trim()
      if (name === 'Flutter') currentSubGroup = 'UPDATE_FLUTTER'
      else if (name === 'Dart') currentSubGroup = 'UPDATE_DART'
      else currentSubGroup = null
      continue
    }

    const m = line.match(linkRe)
    if (!m) continue

    const title = m[1].trim()
    const file = m[2].trim()

    const indent = line.match(/^(\s*)/)[1].length
    const isTopLevel = /^\*\s/.test(line.trimStart()) && indent === 0
    const isStarChild = /^\s+\*\s/.test(line)
    const isDashChild = /^\s+-\s/.test(line)

    let category
    if (file === 'README.md') {
      category = 'ROOT_FRONT'
      currentTopGroup = 'CORE'
      currentSubGroup = null
    } else if (file === 'UPDATE.md') {
      category = 'CORE'
      currentTopGroup = 'CORE'
      currentSubGroup = null
    } else if (isTopLevel) {
      currentSubGroup = null
      if (file === 'GCH.md') {
        currentTopGroup = 'ENGINEERING'
        category = 'ENGINEERING'
      } else if (file === 'FWREADME.md') {
        currentTopGroup = 'EXTRA'
        category = 'EXTRA'
      } else {
        currentTopGroup = 'CORE'
        category = 'CORE'
      }
    } else if (isDashChild) {
      category = currentSubGroup || 'CORE'
    } else if (isStarChild) {
      category = currentTopGroup === 'ENGINEERING' ? 'ENGINEERING'
        : currentTopGroup === 'EXTRA' ? 'EXTRA'
        : 'EXTRA'
    } else {
      category = 'EXTRA'
    }

    items.push({ title, file, category })
  }

  return items
}

function rewriteRelativeLinks(content, allFilesByName) {
  return content.replace(/\[([^\]]+)\]\(([^)\s]+\.md)([^)]*)\)/g, (full, text, link, anchor) => {
    if (/^https?:\/\//i.test(link)) return full
    const decoded = decodeURIComponent(link).replace(/^\.\//, '')
    const target = allFilesByName.get(decoded) || allFilesByName.get(link)
    if (!target) return full
    return `[${text}](${target}${anchor || ''})`
  })
}

function parseLocalImageSource(src) {
  const trimmed = src.trim()
  if (/^(?:https?:)?\/\//i.test(trimmed) || /^(?:data|blob):/i.test(trimmed)) return null
  if (trimmed.startsWith('/') && !/^\/[A-Za-z]\//.test(trimmed) && !/^\/Users\//i.test(trimmed)) return null

  const unwrapped = trimmed.startsWith('<') && trimmed.endsWith('>')
    ? trimmed.slice(1, -1)
    : trimmed
  const withoutSuffix = unwrapped.split(/[?#]/, 1)[0]
  try {
    return decodeURIComponent(withoutSuffix)
  } catch {
    return withoutSuffix
  }
}

function missingImageNotice(alt, src) {
  const normalizedSource = src.replace(/\\/g, '/')
  const label = (alt.trim() || path.posix.basename(normalizedSource) || '未命名图片')
    .replace(/[<>]/g, '')
  return `\n\n> 图片资源缺失：${label}\n\n`
}

async function publishArticleImage(buffer, localSource) {
  const sourceExt = path.extname(localSource).toLowerCase()
  const sourceHash = createHash('sha256').update(buffer).digest('hex').slice(0, 12)
  const rawBaseName = path.basename(localSource, sourceExt)
  const safeBaseName = rawBaseName.replace(/[^A-Za-z0-9._-]/g, '-') || 'image'
  const assetDir = path.join(PUBLIC, 'article-assets')
  await fs.mkdir(assetDir, { recursive: true })

  if (RASTER_IMAGE_EXTENSIONS.has(sourceExt)) {
    const image = sharp(buffer, { animated: true })
    const metadata = await image.metadata()
    if (!metadata.pages || metadata.pages === 1) {
      const assetName = `${sourceHash}-${safeBaseName}.webp`
      await image
        .rotate()
        .resize({ width: 1600, withoutEnlargement: true })
        .webp({ quality: 82 })
        .toFile(path.join(assetDir, assetName))
      return `/article-assets/${assetName}`
    }
  }

  const safeExt = sourceExt || '.bin'
  const assetName = `${sourceHash}-${safeBaseName}${safeExt}`
  await fs.writeFile(path.join(assetDir, assetName), buffer)
  return `/article-assets/${assetName}`
}

async function processLocalImages(content, sourcePath, warnings) {
  const imageRe = /!\[([^\]]*)\]\(([^)]+)\)/g
  const parts = []
  let cursor = 0

  for (const match of content.matchAll(imageRe)) {
    const [full, alt, src] = match
    const localSource = parseLocalImageSource(src)
    if (localSource === null) continue

    parts.push(content.slice(cursor, match.index))
    cursor = match.index + full.length

    const sourceDir = path.dirname(sourcePath)
    const absoluteSource = path.resolve(sourceDir, localSource)
    const relativeToRoot = path.relative(ROOT, absoluteSource)
    const isInsideRepository = relativeToRoot && relativeToRoot !== '..' && !relativeToRoot.startsWith(`..${path.sep}`) && !path.isAbsolute(relativeToRoot)

    if (!isInsideRepository || !(await exists(absoluteSource))) {
      warnings.push(`${path.relative(ROOT, sourcePath)} -> ${src.trim()}`)
      parts.push(missingImageNotice(alt, localSource))
      continue
    }

    const stat = await fs.stat(absoluteSource)
    if (!stat.isFile()) {
      warnings.push(`${path.relative(ROOT, sourcePath)} -> ${src.trim()}`)
      parts.push(missingImageNotice(alt, localSource))
      continue
    }

    const buffer = await fs.readFile(absoluteSource)
    const publishedPath = await publishArticleImage(buffer, localSource)
    parts.push(`![${alt}](${publishedPath})`)
  }

  if (cursor === 0) return content
  parts.push(content.slice(cursor))
  return parts.join('')
}

async function copyRootImages() {
  await fs.mkdir(PUBLIC, { recursive: true })
  const exts = new Set(['.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp', '.ico'])
  const entries = await fs.readdir(ROOT, { withFileTypes: true })
  const published = new Map()
  for (const e of entries) {
    if (!e.isFile()) continue
    const ext = path.extname(e.name).toLowerCase()
    if (!exts.has(ext)) continue
    const src = path.join(ROOT, e.name)

    // Keep the source artwork intact while publishing right-sized variants for the site shell.
    if (e.name === 'logo.png') {
      await fs.rm(path.join(PUBLIC, e.name), { force: true })
      await sharp(src)
        .resize({ width: 640, withoutEnlargement: true })
        .webp({ quality: 82 })
        .toFile(path.join(PUBLIC, 'logo.webp'))
      await sharp(src)
        .resize({ width: 96, withoutEnlargement: true })
        .png({ compressionLevel: 9, palette: true })
        .toFile(path.join(PUBLIC, 'logo-icon.png'))
      published.set(e.name, '/logo.webp')
      continue
    }

    const dst = path.join(PUBLIC, e.name)
    await fs.copyFile(src, dst)
    published.set(e.name, `/${e.name}`)
  }
  return published
}

function rewriteRootImageRefs(content, rootImages) {
  if (!rootImages.size) return content
  return content.replace(
    /!\[([^\]]*)\]\(([^)]+)\)/g,
    (full, alt, src) => {
      const trimmed = src.trim().replace(/^\.\//, '')
      if (rootImages.has(trimmed)) return `![${alt}](${rootImages.get(trimmed)})`
      return full
    }
  )
}

function ensureFrontmatter(content, title) {
  if (/^---\n[\s\S]*?\n---/.test(content)) return content
  const safeTitle = title.replace(/"/g, '\\"')
  return `---\ntitle: "${safeTitle}"\n---\n\n${content}`
}

async function main() {
  console.log('Reading SUMMARY.md...')
  const summaryRaw = await fs.readFile(SUMMARY, 'utf8')
  const items = parseSummary(summaryRaw)
  console.log(`Parsed ${items.length} entries from SUMMARY.md`)

  for (const key of Object.keys(CATEGORY_MAP)) {
    const dir = CATEGORY_MAP[key].dir
    if (dir !== '.') await fs.mkdir(path.join(DOCS, dir), { recursive: true })
  }

  const rootImages = await copyRootImages()
  console.log(`Published ${rootImages.size} root images to docs/public/`)

  const targetMap = new Map()
  for (const item of items) {
    const cat = CATEGORY_MAP[item.category]
    const slug = slugify(item.file)
    const targetRel = cat.dir === '.' ? `/${slug}` : `/${cat.dir}/${slug}`
    targetMap.set(item.file, targetRel)
    targetMap.set(decodeURIComponent(item.file), targetRel)
  }

  const skipped = []
  const written = []
  const imageWarnings = []

  for (const item of items) {
    const cat = CATEGORY_MAP[item.category]
    const src = await readSourceFile(item.file)
    if (!src) {
      skipped.push(item.file)
      continue
    }
    let content = src.content
    content = rewriteRelativeLinks(content, targetMap)
    content = rewriteRootImageRefs(content, rootImages)
    content = await processLocalImages(content, src.src, imageWarnings)
    content = ensureFrontmatter(content, item.title)

    const slug = slugify(item.file)
    const outDir = cat.dir === '.' ? DOCS : path.join(DOCS, cat.dir)
    const outPath = path.join(outDir, `${slug}.md`)
    await fs.mkdir(path.dirname(outPath), { recursive: true })
    await fs.writeFile(outPath, content, 'utf8')
    written.push({ ...item, outPath, slug, link: cat.dir === '.' ? `/${slug}` : `/${cat.dir}/${slug}` })
  }

  console.log(`Migrated: ${written.length}, Skipped: ${skipped.length}`)
  if (skipped.length) console.log('  skipped:', skipped.slice(0, 10), skipped.length > 10 ? '...' : '')
  if (imageWarnings.length) {
    // Missing article media is reported but must not block publishing unrelated content.
    console.warn(`Missing local images: ${imageWarnings.length}`)
    for (const warning of imageWarnings) console.warn(`  ${warning}`)
  }

  const groups = {
    CORE: [],
    UPDATE_FLUTTER: [],
    UPDATE_DART: [],
    EXTRA: [],
    ENGINEERING: [],
    ROOT_FRONT: []
  }
  for (const w of written) groups[w.category].push(w)

  const guideIndexLines = ['---', 'title: 全部文章', '---', '', '# 全部文章', '']
  const sidebarItems = []

  if (groups.ROOT_FRONT.length) {
    sidebarItems.push({
      text: CATEGORY_MAP.ROOT_FRONT.label,
      items: groups.ROOT_FRONT.map(w => ({ text: w.title, link: w.link }))
    })
  }
  if (groups.CORE.length) {
    sidebarItems.push({
      text: CATEGORY_MAP.CORE.label,
      collapsed: false,
      items: groups.CORE.map(w => ({ text: w.title, link: w.link }))
    })
    guideIndexLines.push(`## ${CATEGORY_MAP.CORE.label}`, '')
    for (const w of groups.CORE) guideIndexLines.push(`- [${w.title}](${w.link})`)
    guideIndexLines.push('')
  }
  if (groups.UPDATE_FLUTTER.length) {
    sidebarItems.push({
      text: CATEGORY_MAP.UPDATE_FLUTTER.label,
      collapsed: true,
      items: groups.UPDATE_FLUTTER.map(w => ({ text: w.title, link: w.link }))
    })
    guideIndexLines.push(`## ${CATEGORY_MAP.UPDATE_FLUTTER.label}`, '')
    for (const w of groups.UPDATE_FLUTTER) guideIndexLines.push(`- [${w.title}](${w.link})`)
    guideIndexLines.push('')
  }
  if (groups.UPDATE_DART.length) {
    sidebarItems.push({
      text: CATEGORY_MAP.UPDATE_DART.label,
      collapsed: true,
      items: groups.UPDATE_DART.map(w => ({ text: w.title, link: w.link }))
    })
    guideIndexLines.push(`## ${CATEGORY_MAP.UPDATE_DART.label}`, '')
    for (const w of groups.UPDATE_DART) guideIndexLines.push(`- [${w.title}](${w.link})`)
    guideIndexLines.push('')
  }
  if (groups.EXTRA.length) {
    sidebarItems.push({
      text: CATEGORY_MAP.EXTRA.label,
      collapsed: true,
      items: groups.EXTRA.map(w => ({ text: w.title, link: w.link }))
    })
    guideIndexLines.push(`## ${CATEGORY_MAP.EXTRA.label}`, '')
    for (const w of groups.EXTRA) guideIndexLines.push(`- [${w.title}](${w.link})`)
    guideIndexLines.push('')
  }
  if (groups.ENGINEERING.length) {
    sidebarItems.push({
      text: CATEGORY_MAP.ENGINEERING.label,
      collapsed: true,
      items: groups.ENGINEERING.map(w => ({ text: w.title, link: w.link }))
    })
    guideIndexLines.push(`## ${CATEGORY_MAP.ENGINEERING.label}`, '')
    for (const w of groups.ENGINEERING) guideIndexLines.push(`- [${w.title}](${w.link})`)
    guideIndexLines.push('')
  }

  const sidebarCode = `import type { DefaultTheme } from 'vitepress'

export const sidebar: DefaultTheme.Sidebar = ${JSON.stringify(sidebarItems, null, 2)}
`
  await fs.writeFile(path.join(DOCS, '.vitepress', 'sidebar.generated.mts'), sidebarCode, 'utf8')
  console.log('Wrote docs/.vitepress/sidebar.generated.mts')

  await fs.mkdir(path.join(DOCS, 'guide'), { recursive: true })
  await fs.writeFile(path.join(DOCS, 'guide', 'index.md'), guideIndexLines.join('\n'), 'utf8')
  console.log('Wrote docs/guide/index.md')

  console.log('\n✓ Migration complete.')
}

main().catch(err => { console.error(err); process.exit(1) })
