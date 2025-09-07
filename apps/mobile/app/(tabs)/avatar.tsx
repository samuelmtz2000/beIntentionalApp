import React from "react";
import { View, Text, ScrollView } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { api } from "../../src/api/client";
import { keys } from "../../src/api/keys";
import { theme } from "../../src/ui/theme";
import { Panel } from "../../src/ui/components/Panel";
import { NeonText } from "../../src/ui/components/NeonText";

export default function Avatar() {
  const { data } = useQuery({ queryKey: keys.profile, queryFn: async () => (await api.get("/me")).data });
  return (
    <ScrollView style={{ flex: 1, backgroundColor: theme.colors.bg }} contentContainerStyle={{ padding: 16 }}>
      <NeonText size={20} color={theme.colors.success}>AVATAR</NeonText>
      <Panel style={{ marginTop: 12 }}>
        <Text style={{ color: theme.colors.muted, marginBottom: 8 }}>Owned cosmetics:</Text>
        {data?.cosmeticsOwned?.map((c: any) => (
          <Text key={c.id} style={{ color: theme.colors.text }}>- {c.category}:{c.key}</Text>
        ))}
        {!data?.cosmeticsOwned?.length && <Text style={{ color: theme.colors.muted }}>None yet — visit the Store.</Text>}
      </Panel>
    </ScrollView>
  );
}
