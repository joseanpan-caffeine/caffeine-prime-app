import { useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'expo-router';
import * as WebBrowser from 'expo-web-browser';
import { useAppConfig, useDashboard } from '@/api/hooks';
import { Button, EmptyState, Screen } from '@/components';
import { signOut } from '@/lib/session';

export default function UnderReview() {
  const router = useRouter();
  const qc = useQueryClient();
  const config = useAppConfig();
  const dashboard = useDashboard();

  async function check() {
    const res = await dashboard.refetch();
    if (res.data?.subscription && res.data.subscription.status !== 'fraud_review') router.replace('/(tabs)');
  }

  return (
    <Screen scroll={false} safeTop>
      <EmptyState
        icon="🔎"
        title="Assinatura em análise"
        description="Estamos revisando seus dados de pagamento. Isso costuma levar até 1 dia útil e você receberá um e-mail assim que concluir. Nenhuma ação é necessária por enquanto."
        actionLabel="Verificar novamente"
        onAction={check}
        secondaryLabel="Falar com o suporte"
        onSecondary={() => config.data?.links.support && WebBrowser.openBrowserAsync(config.data.links.support)}
      />
      <Button title="Sair da conta" variant="ghost" onPress={() => signOut(qc)} />
    </Screen>
  );
}
