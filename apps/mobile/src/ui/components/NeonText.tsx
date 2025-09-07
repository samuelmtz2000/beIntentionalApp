import React from "react";
import { Text, TextProps } from "react-native";
import { theme } from "../theme";

type Props = TextProps & { color?: string; size?: number; weight?: "400" | "600" | "700" };

export const NeonText: React.FC<Props> = ({ color = theme.colors.neonCyan, size = 18, weight = "700", style, children, ...rest }) => {
  return (
    <Text
      {...rest}
      style={[{
        color,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: 0.5,
        textShadowColor: color,
        textShadowOffset: { width: 0, height: 0 },
        textShadowRadius: 8,
      }, style]}
    >
      {children}
    </Text>
  );
};

