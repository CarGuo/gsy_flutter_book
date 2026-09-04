import type { DefaultTheme } from 'vitepress'
import { sidebar } from './sidebar.generated.mts'

export default {
  title: 'GSY Flutter Book',
  description: 'GSY Flutter / Dart 系列文章合集 — 由 VitePress + Pagefind 驱动',
  lang: 'zh-CN',
  base: '/home/wx/',
  cleanUrls: true,
  lastUpdated: true,
  ignoreDeadLinks: true,

  head: [
    ['link', { rel: 'icon', type: 'image/png', href: '/home/wx/logo-icon.png' }],
    ['meta', { name: 'theme-color', content: '#3eaf7c' }]
  ],

  themeConfig: {
    logo: '/logo-icon.png',
    siteTitle: 'GSY Flutter Book',

    nav: [
      { text: '首页', link: '/' },
      { text: '全部文章', link: '/guide/' },
      {
        text: '相关项目',
        items: [
          { text: 'GSYGithubAppFlutter', link: 'https://github.com/CarGuo/gsy_github_app_flutter' },
          { text: 'GSYGithubAppCompose', link: 'https://github.com/CarGuo/GSYGithubAppCompose' },
          { text: 'GSYGithubAppKotlin', link: 'https://github.com/CarGuo/GSYGithubAppKotlin' },
          { text: 'GSYGithubApp (RN)', link: 'https://github.com/CarGuo/GSYGithubApp' }
        ]
      },
      { text: '掘金博客', link: 'https://juejin.cn/user/582aca2ba22b9d006b59ae68/posts' }
    ],

    sidebar: sidebar as DefaultTheme.Sidebar,

    socialLinks: [
      { icon: 'github', link: 'https://github.com/CarGuo' }
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2018-present 恋猫de小郭 (CarGuo)'
    },

    outline: { level: [2, 3], label: '本页目录' },
    docFooter: { prev: '上一篇', next: '下一篇' },
    lastUpdatedText: '最后更新',
    returnToTopLabel: '回到顶部',
    sidebarMenuLabel: '菜单',
    darkModeSwitchLabel: '主题',
    lightModeSwitchTitle: '切换到浅色模式',
    darkModeSwitchTitle: '切换到深色模式'
  },

  vite: {
    server: { host: '0.0.0.0' },
    optimizeDeps: { exclude: ['vitepress'] }
  },

  transformHtml(code, id) {
    if (id.endsWith('index.html') && (id.endsWith('/dist/index.html') || id === 'index.html')) {
      return code
    }
    return code.replace(
      /<div class="VPDoc/,
      '<div data-pagefind-body class="VPDoc'
    )
  }
}
