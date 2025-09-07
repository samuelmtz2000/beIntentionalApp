import { Slot } from "expo-router";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import React from "react";
import { theme } from "../src/ui/theme";
import { View } from "react-native";

const client = new QueryClient();

export default function Root() {
  return (
    <QueryClientProvider client={client}>
      <View style={{ flex: 1, backgroundColor: theme.colors.bg }}>
        <Slot />
      </View>
    </QueryClientProvider>
  );
}
