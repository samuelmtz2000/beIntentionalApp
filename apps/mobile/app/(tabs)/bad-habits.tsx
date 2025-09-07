import React from "react";
import { View, Text, ScrollView } from "react-native";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "../../src/api/client";
import { keys } from "../../src/api/keys";
import { theme } from "../../src/ui/theme";
import { Panel } from "../../src/ui/components/Panel";
import { NeonText } from "../../src/ui/components/NeonText";
import { NeonButton } from "../../src/ui/components/NeonButton";

export default function BadHabits() {
  const qc = useQueryClient();
  const { data } = useQuery({ queryKey: keys.badHabits, queryFn: async () => (await api.get("/bad-habits")).data });
  const record = useMutation({
    mutationFn: async ({ id, pay }: { id: string; pay?: boolean }) => (await api.post(`/actions/bad-habits/${id}/record`, { payWithCoins: pay })).data,
    onSuccess: () => qc.invalidateQueries({ queryKey: keys.profile }),
  });

  return (
    <ScrollView style={{ flex: 1, backgroundColor: theme.colors.bg }} contentContainerStyle={{ padding: 16 }}>
      <NeonText size={20} color={theme.colors.neonMagenta}>BAD HABITS</NeonText>
      {data?.map((b: any) => (
        <Panel key={b.id} style={{ marginTop: 12 }}>
          <Text style={{ color: theme.colors.text, fontWeight: "700" }}>{b.name}</Text>
          <Text style={{ color: theme.colors.muted, marginVertical: 6 }}>-{b.lifePenalty} life{b.controllable ? ` | cost ${b.coinCost}` : ""}</Text>
          {b.controllable ? (
            <View style={{ flexDirection: "row", gap: 8 }}>
              <NeonButton title={`Pay ${b.coinCost} coins`} color={theme.colors.neonYellow} onPress={() => record.mutate({ id: b.id, pay: true })} />
              <NeonButton title="I slipped (no pay)" onPress={() => record.mutate({ id: b.id })} />
            </View>
          ) : (
            <NeonButton title="I slipped" color={theme.colors.danger} onPress={() => record.mutate({ id: b.id })} />
          )}
        </Panel>
      ))}
    </ScrollView>
  );
}
