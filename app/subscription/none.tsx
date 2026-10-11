import { useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'expo-router';
import * as WebBrowser from 'expo-web-browser';
import { useAppConfig, useDashboard } from '@/api/hooks';
import { Button, EmptyState, Logo, Screen, toast } from '@/components';
import { signOut } from '@/lib/session';
import { useAuthStore } from '@/store/auth';

export default function NoSubscription() {
  const router = useRouter();
  const qc = useQueryClient();
  const config = useAppConfig();
  const dashboard = useDashboard();
  const user = useAuthStore((s) => s.user);

  async function subscribe() {
    const url = config.data?.links.subscribeUrl;
    if (!url) {
      toast.info('Link de assinatura indisponível no momento.');
      return;
    }
    await WebBrowser.openBrowserAsync(url);
  }

  async function refresh() {
    const res = await dashboard.refetch();
    if (res.data?.subscription && res.data.subscription.status !== 'fraud_review') {
      useAuthStore.getState().setUser({ ...res.data.user, hasSubscription: true });
      router.replace('/(tabs)');
    } else {
      toast.info('Ainda não encontramos uma assinatura nesta conta.');
    }
  }

  return (
    <Screen scroll={false} safeTop>
      <Logo style={{ alignSelf: 'center', marginTop: 8 }} />
      <EmptyState
        icon="☕"
        title={`Olá${user?.firstName ? `, ${user.firstName}` : ''}! Você ainda não é Prime.`}
        description="Assine no site e volte aqui para gerenciar sua caixa, pagamentos e entregas pelo app."
        actionLabel="Assinar o Caffeine Prime"
        onAction={subscribe}
        secondaryLabel="Já assinei, atualizar"
        onSecondary={refresh}
      />
      <Button title="Sair da conta" variant="ghost" onPress={() => signOut(qc)} />
    </Screen>
  );
}
