import React from "react";
import { View, Text } from "react-native";
import { useQuery } from "@tanstack/react-query";
import { api } from "../../api/client";
import { keys } from "../../api/keys";
import { theme } from "../theme";
import { Ionicons } from "@expo/vector-icons";

export const TopHUD: React.FC = () => {
  const { data } = useQuery({ queryKey: keys.profile, queryFn: async () => (await api.get("/me")).data });
  return (
    <View style={{ flexDirection: "row", alignItems: "center", gap: 16 }}>
      <View style={{ flexDirection: "row", alignItems: "center", gap: 6 }}>
        <Ionicons name="heart" size={18} color={theme.colors.danger} />
        <Text style={{ color: theme.colors.text, fontWeight: "700" }}>{data?.life ?? "-"}</Text>
      </View>
      <View style={{ flexDirection: "row", alignItems: "center", gap: 6 }}>
        <Ionicons name="cash" size={18} color={theme.colors.neonYellow} />
        <Text style={{ color: theme.colors.text, fontWeight: "700" }}>{data?.coins ?? "-"}</Text>
      </View>
    </View>
  );
};
