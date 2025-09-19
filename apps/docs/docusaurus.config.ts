import type { Config } from '@docusaurus/types';
import { themes as prismThemes } from 'prism-react-renderer';

const config: Config = {
  title: 'Habit Hero API',
  tagline: 'Gamified habit manager — API docs',
  url: 'http://localhost',
  baseUrl: '/',
  favicon: 'img/favicon.ico',
  organizationName: 'habit-hero',
  projectName: 'api-docs',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  i18n: { defaultLocale: 'en', locales: ['en'] },
  markdown: { mermaid: true },
  themes: ['@docusaurus/theme-mermaid'],

  presets: [
    [
      'classic',
      {
        docs: {
          routeBasePath: '/',
          sidebarPath: './sidebars.ts',
          editUrl: undefined,
        },
        blog: false,
        theme: { customCss: ['./src/css/custom.css'] },
      },
    ],
  ],

  themeConfig: {
    image: 'img/social-card.png',
    navbar: {
      title: 'Habit Hero API',
      items: [
        { to: '/', label: 'Docs', position: 'left' },
        { href: 'http://localhost:4000/docs', label: 'Swagger', position: 'right' },
        { href: 'http://localhost:4000/docs', label: 'API Docs', position: 'right' },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'API',
          items: [
            { label: 'Swagger UI', to: 'http://localhost:4000/docs' },
            { label: 'API Docs', to: 'http://localhost:4000/docs' },
          ],
        },
      ],
      copyright: `Habit Hero • ${new Date().getFullYear()}`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
  },
};

export default config;
