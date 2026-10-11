import { Stack } from 'expo-router';
import { colors, fonts } from '@/theme';

export default function AuthLayout() {
  return (
    <Stack
      screenOptions={{
        headerStyle: { backgroundColor: colors.background },
        headerTintColor: colors.accent,
        headerTitleStyle: { color: colors.text, fontFamily: fonts.display, fontWeight: '600' },
        headerShadowVisible: false,
        headerBackButtonDisplayMode: 'minimal',
        contentStyle: { backgroundColor: colors.background },
      }}
    >
      <Stack.Screen name="welcome" options={{ headerShown: false }} />
      <Stack.Screen name="login" options={{ title: 'Entrar' }} />
      <Stack.Screen name="magic-link" options={{ title: 'Link por e-mail' }} />
      <Stack.Screen name="register" options={{ title: 'Criar conta' }} />
    </Stack>
  );
}
