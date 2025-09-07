module.exports = function (api) {
  api.cache(true);
  return {
    presets: ["babel-preset-expo"],
    // Expo SDK 50+ includes Router transforms in the preset.
    // Keep Reanimated plugin LAST.
    plugins: ["react-native-reanimated/plugin"],
  };
};
