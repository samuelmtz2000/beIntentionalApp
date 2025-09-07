import React from "react";
import { View, Text, ScrollView } from "react-native";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../src/api/client";
import { keys } from "../../src/api/keys";
import { theme } from "../../src/ui/theme";
import { Panel } from "../../src/ui/components/Panel";
import { NeonText } from "../../src/ui/components/NeonText";
import { NeonButton } from "../../src/ui/components/NeonButton";

export default function Store() {
  const qc = useQueryClient();
  const { data: cosmetics } = useQuery({ queryKey: keys.cosmetics, queryFn: async () => (await api.get("/store/cosmetics")).data });
  const buy = useMutation({
    mutationFn: async (id: string) => (await api.post(`/store/cosmetics/${id}/buy`)).data,
    onSuccess: () => qc.invalidateQueries({ queryKey: keys.profile }),
  });

  return (
    <ScrollView style={{ flex: 1, backgroundColor: theme.colors.bg }} contentContainerStyle={{ padding: 16 }}>
      <NeonText size={20} color={theme.colors.neonYellow}>STORE</NeonText>
      {cosmetics?.map((c: any) => (
        <Panel key={c.id} style={{ marginTop: 12 }}>
          <Text style={{ color: theme.colors.text, fontWeight: "700" }}>{c.category}:{c.key}</Text>
          <Text style={{ color: theme.colors.muted, marginVertical: 6 }}>{c.price} coins</Text>
          <NeonButton title="Buy" color={theme.colors.neonYellow} onPress={() => buy.mutate(c.id)} />
        </Panel>
      ))}
    </ScrollView>
  );
}
