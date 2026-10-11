import { useEffect, useState } from 'react';
import { StatusBar } from 'expo-status-bar';
import * as SplashScreen from 'expo-splash-screen';
import { DefaultTheme, Stack, ThemeProvider, useRouter, useSegments } from 'expo-router';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import {
  Archivo_400Regular,
  Archivo_500Medium,
  Archivo_600SemiBold,
  Archivo_700Bold,
  Archivo_800ExtraBold,
  Archivo_800ExtraBold_Italic,
  useFonts,
} from '@expo-google-fonts/archivo';
import { ApiError } from '@/api/client';
import { ToastHost } from '@/components';
import { configureNotificationHandler } from '@/lib/push';
import { bootstrapSession } from '@/lib/session';
import { useAuthStore } from '@/store/auth';
import { colors, font, setCustomFontsReady } from '@/theme';

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
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    primary: colors.gold,
    background: colors.background,
    card: colors.surface,
    text: colors.text,
    border: colors.border,
    notification: colors.gold,
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
        headerStyle: { backgroundColor: colors.surface },
        headerTintColor: colors.text,
        headerTitleStyle: { color: colors.text, fontSize: 16, ...font('heading', '700') },
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
  // Fontes Archivo (substituto de Acumin Pro). Se falhar, seguimos com a fonte do sistema.
  const [fontsLoaded, fontsError] = useFonts({
    Archivo_400Regular,
    Archivo_500Medium,
    Archivo_600SemiBold,
    Archivo_700Bold,
    Archivo_800ExtraBold,
    Archivo_800ExtraBold_Italic,
  });
  const fontsSettled = fontsLoaded || !!fontsError;
  if (fontsSettled) setCustomFontsReady(fontsLoaded && !fontsError);

  useEffect(() => {
    bootstrapSession().finally(() => setBooted(true));
  }, []);

  useEffect(() => {
    if (booted && fontsSettled && status !== 'booting') {
      SplashScreen.hideAsync().catch(() => undefined);
    }
  }, [booted, fontsSettled, status]);

  if (!fontsSettled) return null;

  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider value={navTheme}>
        <StatusBar style="dark" />
        <RootNavigator />
        <ToastHost />
      </ThemeProvider>
    </QueryClientProvider>
  );
}
