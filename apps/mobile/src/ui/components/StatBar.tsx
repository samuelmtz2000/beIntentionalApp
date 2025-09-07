import React from "react";
import { View, Text } from "react-native";
import { theme } from "../theme";

export const StatBar: React.FC<{ label: string; value: number; max: number; color?: string }>
  = ({ label, value, max, color = theme.colors.neonCyan }) => {
  const pct = Math.max(0, Math.min(1, max ? value / max : 0));
  return (
    <View style={{ marginVertical: 6 }}>
      <Text style={{ color: theme.colors.muted, marginBottom: 4 }}>{label}: {value}/{max}</Text>
      <View style={{ height: 10, backgroundColor: "#1a1c33", borderRadius: 8, overflow: "hidden" }}>
        <View style={{ width: `${pct * 100}%`, height: "100%", backgroundColor: color, shadowColor: color, shadowOpacity: 0.8, shadowRadius: 8 }} />
      </View>
    </View>
  );
};

