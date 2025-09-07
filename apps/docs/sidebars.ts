import type { SidebarsConfig } from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docs: [
    'intro',
    {
      type: 'category',
      label: 'API',
      collapsed: false,
      items: [
        'api/overview',
        'api/quick-start',
        'api/data-model',
        'api/endpoints',
        'api/actions',
        'api/store',
      ],
    },
  ],
};

export default sidebars;

