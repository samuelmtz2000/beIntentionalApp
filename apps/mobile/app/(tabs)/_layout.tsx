import { Tabs } from "expo-router";
import React from "react";
import { theme } from "../../src/ui/theme";

export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{
        headerStyle: { backgroundColor: theme.colors.bg },
        headerTintColor: theme.colors.text,
        headerTitle: 'Habit Hero',
        tabBarStyle: { backgroundColor: theme.colors.panel, borderTopColor: "#222448" },
        tabBarActiveTintColor: theme.colors.neonCyan,
        tabBarInactiveTintColor: theme.colors.muted,
      }}
    />
  );
}
