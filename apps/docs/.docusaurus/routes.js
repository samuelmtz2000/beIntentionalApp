import React from 'react';
import ComponentCreator from '@docusaurus/ComponentCreator';

export default [
  {
    path: '/__docusaurus/debug',
    component: ComponentCreator('/__docusaurus/debug', '5ff'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/config',
    component: ComponentCreator('/__docusaurus/debug/config', '5ba'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/content',
    component: ComponentCreator('/__docusaurus/debug/content', 'a2b'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/globalData',
    component: ComponentCreator('/__docusaurus/debug/globalData', 'c3c'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/metadata',
    component: ComponentCreator('/__docusaurus/debug/metadata', '156'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/registry',
    component: ComponentCreator('/__docusaurus/debug/registry', '88c'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/routes',
    component: ComponentCreator('/__docusaurus/debug/routes', '000'),
    exact: true
  },
  {
    path: '/',
    component: ComponentCreator('/', 'efd'),
    routes: [
      {
        path: '/',
        component: ComponentCreator('/', 'dcc'),
        routes: [
          {
            path: '/',
            component: ComponentCreator('/', 'd4a'),
            routes: [
              {
                path: '/api/actions',
                component: ComponentCreator('/api/actions', 'e5e'),
                exact: true,
                sidebar: "docs"
              },
              {
                path: '/api/data-model',
                component: ComponentCreator('/api/data-model', '78a'),
                exact: true,
                sidebar: "docs"
              },
              {
                path: '/api/endpoints',
                component: ComponentCreator('/api/endpoints', '93e'),
                exact: true,
                sidebar: "docs"
              },
              {
                path: '/api/overview',
                component: ComponentCreator('/api/overview', 'd47'),
                exact: true,
                sidebar: "docs"
              },
              {
                path: '/api/quick-start',
                component: ComponentCreator('/api/quick-start', 'c21'),
                exact: true,
                sidebar: "docs"
              },
              {
                path: '/api/store',
                component: ComponentCreator('/api/store', '6bd'),
                exact: true,
                sidebar: "docs"
              },
              {
                path: '/intro',
                component: ComponentCreator('/intro', '32d'),
                exact: true,
                sidebar: "docs"
              }
            ]
          }
        ]
      }
    ]
  },
  {
    path: '*',
    component: ComponentCreator('*'),
  },
];
