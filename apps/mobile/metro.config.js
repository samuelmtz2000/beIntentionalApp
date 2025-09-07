// Metro configuration for Expo in a PNPM monorepo
const { getDefaultConfig } = require('expo/metro-config');
const path = require('path');

const projectRoot = __dirname;
const workspaceRoot = path.resolve(projectRoot, '../..');

const config = getDefaultConfig(projectRoot);

// Allow Metro to follow symlinks (pnpm) and watch the workspace root
config.resolver.unstable_enableSymlinks = true;
config.watchFolders = [workspaceRoot];
config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, 'node_modules'),
  path.resolve(workspaceRoot, 'node_modules'),
];
// Some packages rely on package.json exports; disabling can help with pnpm edge cases
config.resolver.unstable_disablePackageJSONExports = true;

module.exports = config;

