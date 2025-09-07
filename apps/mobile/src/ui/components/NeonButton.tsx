import React from "react";
import { Pressable, View, Text, PressableProps } from "react-native";
import { theme } from "../theme";

type Props = PressableProps & { title: string; color?: string };

export const NeonButton: React.FC<Props> = ({ title, color = theme.colors.neonMagenta, style, ...rest }) => {
  return (
    <Pressable
      {...rest}
      style={({ pressed }) => [
        {
          paddingVertical: 10,
          paddingHorizontal: 14,
          borderRadius: 10,
          borderWidth: 2,
          borderColor: color,
          backgroundColor: pressed ? "rgba(255,255,255,0.06)" : "transparent",
          shadowColor: color,
          shadowOpacity: 0.6,
          shadowOffset: { width: 0, height: 0 },
          shadowRadius: 8,
        },
        style,
      ]}
    >
      <Text style={{ color: theme.colors.text, fontWeight: "700", letterSpacing: 0.5 }}>{title}</Text>
    </Pressable>
  );
};

