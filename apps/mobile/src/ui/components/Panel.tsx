import React from "react";
import { View, ViewProps } from "react-native";
import { theme } from "../theme";

export const Panel: React.FC<ViewProps> = ({ style, children, ...rest }) => (
  <View
    {...rest}
    style={[{
      backgroundColor: theme.colors.panel,
      padding: 12,
      borderRadius: theme.radius,
      borderWidth: 1,
      borderColor: "#2a2b4a",
      shadowColor: "#000",
      shadowOpacity: 0.5,
      shadowRadius: 10,
      shadowOffset: { width: 0, height: 4 },
    }, style]}
  >
    {children}
  </View>
);

