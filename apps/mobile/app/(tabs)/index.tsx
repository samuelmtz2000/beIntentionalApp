import React from "react";
import { View, Text, ScrollView } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { api } from "../../src/api/client";
import { keys } from "../../src/api/keys";
import { theme } from "../../src/ui/theme";
import { Panel } from "../../src/ui/components/Panel";
import { NeonText } from "../../src/ui/components/NeonText";
import { StatBar } from "../../src/ui/components/StatBar";

export default function Dashboard() {
  const { data } = useQuery({ queryKey: keys.profile, queryFn: async () => (await api.get("/me")).data });

  return (
    <ScrollView style={{ flex: 1, backgroundColor: theme.colors.bg }} contentContainerStyle={{ padding: 16 }}>
      <NeonText color={theme.colors.neonYellow} size={26}>HABIT HERO</NeonText>
      <Text style={{ color: theme.colors.muted, marginBottom: 12 }}>Level up your life like an arcade run.</Text>

      <Panel>
        <NeonText size={18}>Areas</NeonText>
        {data?.areas?.map((a: any) => (
          <View key={a.areaId} style={{ marginTop: 8 }}>
            <Text style={{ color: theme.colors.text, fontWeight: "600" }}>{a.name} — L{a.level}</Text>
            <StatBar label="Progress" value={a.xp} max={a.xpPerLevel} color={theme.colors.neonCyan} />
          </View>
        ))}
      </Panel>
    </ScrollView>
  );
}
