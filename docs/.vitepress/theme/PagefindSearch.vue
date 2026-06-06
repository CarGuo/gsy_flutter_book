<script setup lang="ts">
import { onMounted, onUnmounted, ref, watch, nextTick } from 'vue'
import { useRouter } from 'vitepress'

interface SubResult {
  url: string
  title: string
  excerpt: string
}
interface SearchResult {
  url: string
  title: string
  excerpt: string
  sub_results: SubResult[]
}

const open = ref(false)
const query = ref('')
const results = ref<SearchResult[]>([])
const loading = ref(false)
const error = ref('')
const activeIndex = ref(0)

const inputRef = ref<HTMLInputElement | null>(null)
const listRef = ref<HTMLElement | null>(null)
const router = useRouter()

let pagefind: any = null
let pagefindLoading: Promise<any> | null = null
let searchSeq = 0

async function loadPagefind() {
  if (pagefind) return pagefind
  if (pagefindLoading) return pagefindLoading
  pagefindLoading = (async () => {
    const base = (import.meta.env.BASE_URL || '/').replace(/\/$/, '')
    const id = 'pagefind-ui-css'
    if (typeof document !== 'undefined' && !document.getElementById(id)) {
      const link = document.createElement('link')
      link.id = id
      link.rel = 'stylesheet'
      link.href = `${base}/pagefind/pagefind-ui.css`
      document.head.appendChild(link)
    }
    const importPath = `${base}/pagefind/pagefind.js`
    const dynImport = new Function('p', 'return import(p)') as (p: string) => Promise<any>
    const mod = await dynImport(importPath)
    if (mod.options) {
      try { await mod.options({ excerptLength: 30 }) } catch (_) {}
    }
    pagefind = mod
    return mod
  })()
  return pagefindLoading
}

async function runSearch(q: string) {
  const mySeq = ++searchSeq
  if (!q.trim()) {
    results.value = []
    error.value = ''
    loading.value = false
    return
  }
  loading.value = true
  error.value = ''
  try {
    const pf = await loadPagefind()
    if (mySeq !== searchSeq) return
    const searchFn = typeof pf.debouncedSearch === 'function'
      ? pf.debouncedSearch.bind(pf)
      : pf.search.bind(pf)
    const search = await searchFn(q, 200)
    if (mySeq !== searchSeq) return
    if (!search) {
      results.value = []
      loading.value = false
      return
    }
    const top = search.results.slice(0, 20)
    if (top.length === 0) {
      results.value = []
      loading.value = false
      return
    }
    const FIRST_BATCH = Math.min(5, top.length)
    const firstData = await Promise.all(top.slice(0, FIRST_BATCH).map((r: any) => r.data()))
    if (mySeq !== searchSeq) return
    const mapItem = (d: any) => ({
      url: d.url,
      title: d.meta?.title || d.url,
      excerpt: d.excerpt,
      sub_results: (d.sub_results || []).slice(0, 3).map((s: any) => ({
        url: s.url,
        title: s.title,
        excerpt: s.excerpt
      }))
    })
    results.value = firstData.map(mapItem)
    activeIndex.value = 0
    loading.value = false
    if (top.length > FIRST_BATCH) {
      Promise.all(top.slice(FIRST_BATCH).map((r: any) => r.data())).then((rest: any[]) => {
        if (mySeq !== searchSeq) return
        results.value = [...results.value, ...rest.map(mapItem)]
      }).catch(() => { /* ignore tail errors */ })
    }
  } catch (e: any) {
    if (mySeq !== searchSeq) return
    error.value = '搜索初始化失败：请确认已执行 build（dev 模式无索引）。'
    console.warn('[Pagefind]', e)
    results.value = []
    loading.value = false
  }
}

watch(query, (q) => {
  runSearch(q)
})

function openModal() {
  open.value = true
  nextTick(() => {
    inputRef.value?.focus()
  })
}

function closeModal() {
  open.value = false
}

function normalizeUrl(u: string) {
  if (!u) return '/'
  let url = u
  url = url.replace(/\.html$/, '')
  if (url.endsWith('/index')) url = url.slice(0, -'/index'.length) || '/'
  return url
}

function goto(url: string) {
  const target = normalizeUrl(url)
  closeModal()
  router.go(target)
}

function onKeyDown(e: KeyboardEvent) {
  if ((e.metaKey || e.ctrlKey) && (e.key === 'k' || e.key === 'K')) {
    e.preventDefault()
    open.value ? closeModal() : openModal()
    return
  }
  if (!open.value) return
  if (e.key === 'Escape') {
    e.preventDefault()
    closeModal()
  } else if (e.key === 'ArrowDown') {
    e.preventDefault()
    activeIndex.value = Math.min(activeIndex.value + 1, Math.max(results.value.length - 1, 0))
    scrollActiveIntoView()
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    activeIndex.value = Math.max(activeIndex.value - 1, 0)
    scrollActiveIntoView()
  } else if (e.key === 'Enter') {
    const r = results.value[activeIndex.value]
    if (r) {
      e.preventDefault()
      goto(r.url)
    }
  }
}

function scrollActiveIntoView() {
  nextTick(() => {
    const el = listRef.value?.querySelector('[data-active="true"]') as HTMLElement | null
    el?.scrollIntoView({ block: 'nearest' })
  })
}

function onLauncherEvent() {
  openModal()
}

onMounted(() => {
  window.addEventListener('keydown', onKeyDown)
  window.addEventListener('pagefind-open', onLauncherEvent as EventListener)
})

onUnmounted(() => {
  window.removeEventListener('keydown', onKeyDown)
  window.removeEventListener('pagefind-open', onLauncherEvent as EventListener)
  searchSeq++
})
</script>

<template>
  <Teleport to="body">
    <div v-if="open" class="pf-mask" @click.self="closeModal" role="dialog" aria-modal="true" aria-label="搜索文档">
      <div class="pf-modal">
        <div class="pf-input-row">
          <span class="pf-icon" aria-hidden="true">
            <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <circle cx="11" cy="11" r="7" />
              <path d="m21 21-4.3-4.3" />
            </svg>
          </span>
          <input
            ref="inputRef"
            v-model="query"
            type="search"
            placeholder="搜索文档…"
            autocomplete="off"
            spellcheck="false"
            class="pf-input"
          />
          <button class="pf-close" @click="closeModal" aria-label="关闭">Esc</button>
        </div>

        <div class="pf-body" ref="listRef">
          <div v-if="loading" class="pf-status">搜索中…</div>
          <div v-else-if="error" class="pf-status pf-error">{{ error }}</div>
          <div v-else-if="!query.trim()" class="pf-status pf-tip">
            输入关键字开始搜索。<br />
            支持 ↑ ↓ 切换结果，<kbd>Enter</kbd> 打开，<kbd>Esc</kbd> 关闭。
          </div>
          <div v-else-if="results.length === 0" class="pf-status">没有匹配的结果</div>
          <ul v-else class="pf-list">
            <li
              v-for="(r, i) in results"
              :key="r.url"
              class="pf-item"
              :data-active="i === activeIndex"
              @click="goto(r.url)"
              @mouseenter="activeIndex = i"
            >
              <div class="pf-item-title" v-html="r.title" />
              <div class="pf-item-excerpt" v-html="r.excerpt" />
              <ul v-if="r.sub_results.length" class="pf-sub">
                <li
                  v-for="s in r.sub_results"
                  :key="s.url"
                  class="pf-sub-item"
                  @click.stop="goto(s.url)"
                >
                  <div class="pf-sub-title" v-html="s.title" />
                  <div class="pf-sub-excerpt" v-html="s.excerpt" />
                </li>
              </ul>
            </li>
          </ul>
        </div>

        <div class="pf-footer">
          <span><kbd>↑</kbd><kbd>↓</kbd> 选择</span>
          <span><kbd>↵</kbd> 打开</span>
          <span><kbd>Esc</kbd> 关闭</span>
          <span class="pf-brand">由 Pagefind 提供搜索</span>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
.pf-mask {
  position: fixed;
  inset: 0;
  z-index: 100;
  background: rgba(0, 0, 0, 0.45);
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding: 8vh 16px 16px;
  backdrop-filter: blur(4px);
}
.pf-modal {
  width: 100%;
  max-width: 720px;
  background: var(--vp-c-bg, #fff);
  color: var(--vp-c-text-1, #213547);
  border: 1px solid var(--vp-c-divider, #e2e2e3);
  border-radius: 12px;
  box-shadow: 0 24px 48px rgba(0, 0, 0, 0.25);
  display: flex;
  flex-direction: column;
  max-height: 80vh;
  overflow: hidden;
}
.pf-input-row {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 14px;
  border-bottom: 1px solid var(--vp-c-divider, #e2e2e3);
}
.pf-icon {
  color: var(--vp-c-text-2, #5f6368);
  display: inline-flex;
}
.pf-input {
  flex: 1;
  border: none;
  outline: none;
  font-size: 16px;
  background: transparent;
  color: inherit;
  padding: 6px 0;
}
.pf-close {
  border: 1px solid var(--vp-c-divider, #e2e2e3);
  background: var(--vp-c-bg-soft, #f6f6f7);
  color: var(--vp-c-text-2, #5f6368);
  border-radius: 6px;
  padding: 2px 8px;
  font-size: 12px;
  cursor: pointer;
}
.pf-body {
  overflow-y: auto;
  flex: 1;
  padding: 8px 0;
}
.pf-status {
  padding: 24px 16px;
  text-align: center;
  color: var(--vp-c-text-2, #5f6368);
  font-size: 14px;
  line-height: 1.6;
}
.pf-error { color: var(--vp-c-danger-1, #e44); }
.pf-tip kbd { margin: 0 2px; }
.pf-list {
  list-style: none;
  margin: 0;
  padding: 0;
}
.pf-item {
  padding: 10px 16px;
  border-left: 3px solid transparent;
  cursor: pointer;
}
.pf-item[data-active="true"] {
  background: var(--vp-c-bg-soft, #f6f6f7);
  border-left-color: var(--vp-c-brand-1, #3eaf7c);
}
.pf-item-title {
  font-weight: 600;
  font-size: 15px;
  color: var(--vp-c-text-1);
  margin-bottom: 4px;
}
.pf-item-excerpt {
  font-size: 13px;
  color: var(--vp-c-text-2);
  line-height: 1.5;
}
.pf-item-excerpt :deep(mark),
.pf-item-title :deep(mark),
.pf-sub-title :deep(mark),
.pf-sub-excerpt :deep(mark) {
  background: transparent;
  color: var(--vp-c-brand-1, #3eaf7c);
  font-weight: 600;
}
.pf-sub {
  list-style: none;
  margin: 8px 0 0 0;
  padding: 0 0 0 12px;
  border-left: 2px solid var(--vp-c-divider, #e2e2e3);
}
.pf-sub-item {
  padding: 4px 0;
  cursor: pointer;
}
.pf-sub-item:hover .pf-sub-title { color: var(--vp-c-brand-1, #3eaf7c); }
.pf-sub-title {
  font-size: 13px;
  color: var(--vp-c-text-1);
}
.pf-sub-excerpt {
  font-size: 12px;
  color: var(--vp-c-text-3);
  margin-top: 2px;
  line-height: 1.4;
}
.pf-footer {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 8px 14px;
  border-top: 1px solid var(--vp-c-divider, #e2e2e3);
  font-size: 12px;
  color: var(--vp-c-text-3, #888);
  background: var(--vp-c-bg-soft, #f6f6f7);
}
.pf-brand { margin-left: auto; }
.pf-footer kbd {
  display: inline-block;
  padding: 1px 6px;
  border: 1px solid var(--vp-c-divider, #e2e2e3);
  border-radius: 4px;
  background: var(--vp-c-bg, #fff);
  font-size: 11px;
  margin-right: 4px;
}
</style>
