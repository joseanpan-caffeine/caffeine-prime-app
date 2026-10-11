import { useEffect } from 'react';
import type { ColorValue } from 'react-native';
import { Tabs, useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useDashboard } from '@/api/hooks';
import { useAuthStore } from '@/store/auth';
import { colors, fonts } from '@/theme';

type IconName = keyof typeof Ionicons.glyphMap;

function icon(active: IconName, inactive: IconName) {
  function TabIcon({ color, focused, size }: { color: ColorValue; focused: boolean; size: number }) {
    return <Ionicons name={focused ? active : inactive} color={color} size={size} />;
  }
  return TabIcon;
}

/** Redireciona para telas de estado quando não há assinatura ou ela está em análise. */
function useSubscriptionGate() {
  const router = useRouter();
  const user = useAuthStore((s) => s.user);
  const { data } = useDashboard();

  useEffect(() => {
    if (user && user.hasSubscription === false && user.id) {
      router.replace('/subscription/none');
      return;
    }
    if (!data) return;
    if (data.subscription === null) {
      router.replace('/subscription/none');
    } else if (data.subscription.status === 'fraud_review') {
      router.replace('/subscription/under-review');
    }
  }, [data, user, router]);
}

export default function TabsLayout() {
  useSubscriptionGate();
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: colors.accent,
        tabBarInactiveTintColor: colors.textDim,
        tabBarStyle: { backgroundColor: colors.background, borderTopColor: colors.border },
        tabBarLabelStyle: { fontFamily: fonts.body, fontSize: 11, fontWeight: '600' },
        sceneStyle: { backgroundColor: colors.background },
      }}
    >
      <Tabs.Screen name="index" options={{ title: 'Início', tabBarIcon: icon('home', 'home-outline') }} />
      <Tabs.Screen name="box" options={{ title: 'Minha caixa', tabBarIcon: icon('cube', 'cube-outline') }} />
      <Tabs.Screen name="orders" options={{ title: 'Pedidos', tabBarIcon: icon('receipt', 'receipt-outline') }} />
      <Tabs.Screen name="profile" options={{ title: 'Perfil', tabBarIcon: icon('person', 'person-outline') }} />
    </Tabs>
  );
}
