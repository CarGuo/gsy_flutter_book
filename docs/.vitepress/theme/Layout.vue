<script setup lang="ts">
import { onMounted } from 'vue'
import DefaultTheme from 'vitepress/theme'
import PagefindSearch from './PagefindSearch.vue'

const { Layout } = DefaultTheme

function openSearch() {
  if (typeof window === 'undefined') return
  window.dispatchEvent(new CustomEvent('pagefind-open'))
}

onMounted(() => {
  if (typeof document === 'undefined') return
  if (document.getElementById('busuanzi-js')) return
  const s = document.createElement('script')
  s.id = 'busuanzi-js'
  s.async = true
  s.src = 'https://busuanzi.9420.ltd/js'
  document.head.appendChild(s)
})
</script>

<template>
  <Layout>
    <template #nav-bar-content-after>
      <button
        class="pf-launcher"
        type="button"
        aria-label="搜索文档"
        @click="openSearch"
      >
        <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <circle cx="11" cy="11" r="7" />
          <path d="m21 21-4.3-4.3" />
        </svg>
        <span class="pf-launcher-text">搜索文档</span>
        <span class="pf-launcher-kbd">
          <kbd>⌘</kbd><kbd>K</kbd>
        </span>
      </button>
    </template>
    <template #layout-bottom>
      <PagefindSearch />
      <div class="site-stats" aria-label="访问统计">
        <span class="site-stats-item">
          本站访客
          <span id="busuanzi_container_site_uv">
            <span id="busuanzi_value_site_uv">--</span>
          </span>
          人次
        </span>
        <span class="site-stats-sep">·</span>
        <span class="site-stats-item">
          总访问量
          <span id="busuanzi_container_site_pv">
            <span id="busuanzi_value_site_pv">--</span>
          </span>
          次
        </span>
      </div>
    </template>
  </Layout>
</template>

<style scoped>
.pf-launcher {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 32px;
  padding: 0 10px;
  margin-left: 12px;
  border: 1px solid var(--vp-c-divider, #e2e2e3);
  background: var(--vp-c-bg-soft, #f6f6f7);
  color: var(--vp-c-text-2, #5f6368);
  border-radius: 8px;
  font-size: 13px;
  cursor: pointer;
  transition: border-color 0.15s, color 0.15s;
}
.pf-launcher:hover {
  border-color: var(--vp-c-brand-1, #3eaf7c);
  color: var(--vp-c-text-1);
}
.pf-launcher-text {
  display: none;
}
.pf-launcher-kbd {
  display: none;
  gap: 2px;
}
.pf-launcher-kbd kbd {
  display: inline-block;
  padding: 1px 4px;
  border: 1px solid var(--vp-c-divider, #e2e2e3);
  border-radius: 3px;
  background: var(--vp-c-bg, #fff);
  font-size: 11px;
  line-height: 1;
}
@media (min-width: 768px) {
  .pf-launcher-text { display: inline; }
  .pf-launcher-kbd { display: inline-flex; }
}
.site-stats {
  display: flex;
  align-items: center;
  justify-content: center;
  flex-wrap: wrap;
  gap: 6px;
  padding: 10px 16px 18px;
  font-size: 12px;
  color: var(--vp-c-text-3, #888);
  border-top: 1px solid var(--vp-c-divider, #e2e2e3);
  background: var(--vp-c-bg, #fff);
}
.site-stats-item {
  white-space: nowrap;
}
.site-stats-sep {
  opacity: 0.6;
}
</style>
