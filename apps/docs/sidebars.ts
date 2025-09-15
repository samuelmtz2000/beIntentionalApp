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
    {
      type: 'category',
      label: 'Frontend (iOS)',
      collapsed: false,
      items: [
        'frontend/overview',
        'frontend/architecture',
        'frontend/networking',
        'frontend/models',
'frontend/ui',
        'frontend/design-system',
        'frontend/state',
        'frontend/testing',
        'frontend/build-release',
        'frontend/configuration',
        'frontend/troubleshooting',
      ],
    },
  ],
};

export default sidebars;
