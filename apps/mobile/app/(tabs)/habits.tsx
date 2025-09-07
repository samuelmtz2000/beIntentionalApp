import React from "react";
import { View, Text, ScrollView } from "react-native";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../src/api/client";
import { keys } from "../../src/api/keys";
import { theme } from "../../src/ui/theme";
import { Panel } from "../../src/ui/components/Panel";
import { NeonText } from "../../src/ui/components/NeonText";
import { NeonButton } from "../../src/ui/components/NeonButton";

export default function Habits() {
  const qc = useQueryClient();
  const { data } = useQuery({ queryKey: keys.habits, queryFn: async () => (await api.get("/habits")).data });
  const complete = useMutation({
    mutationFn: async (id: string) => (await api.post(`/actions/habits/${id}/complete`)).data,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: keys.profile });
    },
  });

  return (
    <ScrollView style={{ flex: 1, backgroundColor: theme.colors.bg }} contentContainerStyle={{ padding: 16 }}>
      <NeonText size={20} color={theme.colors.neonCyan}>GOOD HABITS</NeonText>
      {data?.map((h: any) => (
        <Panel key={h.id} style={{ marginTop: 12 }}>
          <Text style={{ color: theme.colors.text, fontWeight: "700" }}>{h.name}</Text>
          <Text style={{ color: theme.colors.muted, marginVertical: 6 }}>+{h.xpReward} XP, +{h.coinReward} coins</Text>
          <NeonButton title="I did it" onPress={() => complete.mutate(h.id)} />
        </Panel>
      ))}
    </ScrollView>
  );
}
