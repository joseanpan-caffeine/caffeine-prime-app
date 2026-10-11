import { useEffect, useState } from 'react';
import { StatusBar } from 'expo-status-bar';
import * as SplashScreen from 'expo-splash-screen';
import { DarkTheme, Stack, ThemeProvider, useRouter, useSegments } from 'expo-router';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ApiError } from '@/api/client';
import { ToastHost } from '@/components';
import { configureNotificationHandler } from '@/lib/push';
import { bootstrapSession } from '@/lib/session';
import { useAuthStore } from '@/store/auth';
import { colors, fonts } from '@/theme';

void SplashScreen.preventAutoHideAsync().catch(() => undefined);
configureNotificationHandler();

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: (count, error) => !(error instanceof ApiError && error.status > 0 && error.status < 500) && count < 2,
      staleTime: 15_000,
      refetchOnWindowFocus: false,
    },
  },
});

const navTheme = {
  ...DarkTheme,
  colors: {
    ...DarkTheme.colors,
    primary: colors.accent,
    background: colors.background,
    card: colors.background,
    text: colors.text,
    border: colors.border,
    notification: colors.accent,
  },
};

/** Redireciona entre (auth) e o app conforme o status da sessão. */
function useAuthGate() {
  const status = useAuthStore((s) => s.status);
  const segments = useSegments();
  const router = useRouter();

  useEffect(() => {
    if (status === 'booting') return;
    const first = segments[0] as string | undefined;
    const inAuthGroup = first === '(auth)';
    const isMagicLink = first === 'auth';
    if (status === 'signedOut' && !inAuthGroup && !isMagicLink) {
      router.replace('/(auth)/welcome');
    } else if (status === 'signedIn' && inAuthGroup) {
      router.replace('/');
    }
  }, [status, segments, router]);
}

function RootNavigator() {
  useAuthGate();
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
      <Stack.Screen name="index" options={{ headerShown: false }} />
      <Stack.Screen name="(auth)" options={{ headerShown: false }} />
      <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      <Stack.Screen name="auth/magic/[token]" options={{ headerShown: false }} />
      <Stack.Screen name="subscription/pause" options={{ title: 'Pausar assinatura' }} />
      <Stack.Screen name="subscription/paused" options={{ title: 'Assinatura pausada' }} />
      <Stack.Screen name="subscription/cancel" options={{ title: 'Cancelar assinatura' }} />
      <Stack.Screen name="subscription/canceled" options={{ title: 'Assinatura cancelada' }} />
      <Stack.Screen name="subscription/under-review" options={{ headerShown: false }} />
      <Stack.Screen name="subscription/none" options={{ headerShown: false }} />
      <Stack.Screen name="payments/cards" options={{ title: 'Cartões' }} />
      <Stack.Screen name="payments/pay/[billId]" options={{ title: 'Pagar fatura' }} />
      <Stack.Screen name="shipping/address" options={{ title: 'Endereço de entrega' }} />
      <Stack.Screen name="orders/[billId]" options={{ title: 'Detalhe do pedido' }} />
    </Stack>
  );
}

export default function RootLayout() {
  const status = useAuthStore((s) => s.status);
  const [booted, setBooted] = useState(false);

  useEffect(() => {
    bootstrapSession().finally(() => setBooted(true));
  }, []);

  useEffect(() => {
    if (booted && status !== 'booting') {
      SplashScreen.hideAsync().catch(() => undefined);
    }
  }, [booted, status]);

  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider value={navTheme}>
        <StatusBar style="light" />
        <RootNavigator />
        <ToastHost />
      </ThemeProvider>
    </QueryClientProvider>
  );
}
