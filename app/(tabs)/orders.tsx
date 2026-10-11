import { useRouter } from 'expo-router';
import { errorMessage } from '@/api/client';
import { useBills } from '@/api/hooks';
import { EmptyState, Screen, SkeletonCard } from '@/components';
import { BillCard } from '@/features/orders/BillCard';

export default function Orders() {
  const router = useRouter();
  const { data, isLoading, isError, error, refetch, isRefetching } = useBills();

  const bills = (data ?? []).slice().sort((a, b) => (a.issuedAt < b.issuedAt ? 1 : -1));

  return (
    <Screen safeTop title="Pedidos" subtitle="Histórico de faturas e entregas." onRefresh={refetch} refreshing={isRefetching}>
      {isLoading ? (
        <>
          <SkeletonCard lines={2} />
          <SkeletonCard lines={2} />
          <SkeletonCard lines={2} />
        </>
      ) : isError ? (
        <EmptyState icon="⚠️" title="Não deu para carregar" description={errorMessage(error)} actionLabel="Tentar de novo" onAction={() => refetch()} />
      ) : bills.length === 0 ? (
        <EmptyState icon="📦" title="Nenhum pedido ainda" description="Sua primeira fatura aparece aqui assim que a assinatura for cobrada." />
      ) : (
        bills.map((bill) => <BillCard key={bill.id} bill={bill} onPress={() => router.push({ pathname: '/orders/[billId]', params: { billId: bill.id } })} />)
      )}
    </Screen>
  );
}
