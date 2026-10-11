import { useEffect, useMemo, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import * as Clipboard from 'expo-clipboard';
import * as WebBrowser from 'expo-web-browser';
import type { Bill, PixCharge } from '@/api/contracts';
import { errorMessage } from '@/api/client';
import { useAppConfig, useBill, useDashboard, usePayWithCurrentCard, usePayWithNewCard, usePayWithPix } from '@/api/hooks';
import { Button, Card, EmptyState, Money, PaymentFailedCard, PixPaymentCard, Row, Screen, SkeletonCard, Text, toast, type PaymentOption } from '@/components';
import { CardForm } from '@/features/payments/CardForm';
import { formatCountdown, formatDate } from '@/lib/format';
import { formatShortDate } from '@/lib/prime';
import type { TokenizedCard } from '@/lib/vindi';
import { space } from '@/theme';

export default function PayBill() {
  const { billId, method: initialMethod } = useLocalSearchParams<{ billId: string; method?: string }>();
  const router = useRouter();
  const { data: bill, isLoading, isError, error, refetch } = useBill(billId);
  const { data: dashboard } = useDashboard();
  const config = useAppConfig();
  const payCard = usePayWithCurrentCard();
  const payPix = usePayWithPix();
  const [chosen, setMethod] = useState<PaymentOption | null>(initialMethod === 'card' ? 'card' : initialMethod === 'pix' ? 'pix' : null);
  const [showNewCard, setShowNewCard] = useState(false);
  const [pixRequested, setPixRequested] = useState(initialMethod === 'pix');

  const currentCard = dashboard?.subscription?.paymentProfile ?? bill?.paymentProfile;
  const pixAvailable = dashboard?.capabilities.pendingBill?.id === bill?.id ? dashboard?.capabilities.pendingBill?.pixAvailable !== false : true;

  // Opção padrão derivada: cartão atual → PIX → novo cartão.
  const method: PaymentOption = chosen && (chosen !== 'card' || currentCard) ? chosen : currentCard ? 'card' : pixAvailable ? 'pix' : 'new-card';

  // Gera o PIX automaticamente quando o usuário escolheu PIX (deep link ou botão) e ainda não há cobrança.
  useEffect(() => {
    if (method === 'pix' && pixRequested && bill && !bill.pix && !payPix.data && !payPix.isPending && !payPix.isError) {
      payPix.mutate(bill.id, { onError: (e) => toast.error(errorMessage(e, 'Não foi possível gerar o PIX.')) });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [method, pixRequested, bill?.id]);

  if (isLoading) {
    return (
      <Screen>
        <SkeletonCard lines={2} />
        <SkeletonCard lines={4} />
      </Screen>
    );
  }
  if (isError || !bill) {
    return (
      <Screen>
        <EmptyState icon="⚠️" title="Fatura não encontrada" description={errorMessage(error)} actionLabel="Tentar de novo" onAction={() => refetch()} />
      </Screen>
    );
  }
  if (bill.status === 'paid') {
    return (
      <Screen>
        <EmptyState icon="✅" title="Fatura paga" description={`Pagamento confirmado${bill.paidAt ? ` em ${formatDate(bill.paidAt)}` : ''}. Obrigado!`} actionLabel="Voltar ao início" onAction={() => router.replace('/(tabs)')} />
      </Screen>
    );
  }

  const options: { key: PaymentOption; label: string; hint: string; enabled: boolean }[] = [
    { key: 'card', label: 'Realizar cobrança no cartão atual', hint: 'Este e próximos meses', enabled: !!currentCard },
    { key: 'pix', label: 'Pagar com PIX', hint: 'Apenas este mês', enabled: pixAvailable },
    { key: 'new-card', label: 'Alterar cartão de cobrança', hint: 'Este e próximos meses', enabled: true },
  ];

  function onPrimary() {
    if (method === 'card') {
      payCard.mutate(bill!.id, {
        onSuccess: (b) => {
          if (b.status === 'paid') {
            toast.success('Pagamento aprovado!');
            router.replace('/(tabs)');
          } else {
            toast.info('Pagamento enviado. Aguardando confirmação da operadora.');
          }
        },
        onError: (e) => toast.error(errorMessage(e, 'Pagamento recusado. Tente outro cartão.')),
      });
    } else if (method === 'pix') {
      setPixRequested(true);
      if (payPix.isError) payPix.mutate(bill!.id, { onError: (e) => toast.error(errorMessage(e, 'Não foi possível gerar o PIX.')) });
    } else {
      setShowNewCard(true);
    }
  }

  async function support() {
    const url = config.data?.links.support;
    if (!url) {
      toast.info('Canal de suporte indisponível no momento.');
      return;
    }
    try {
      await WebBrowser.openBrowserAsync(url);
    } catch {
      toast.error('Não foi possível abrir o link.');
    }
  }

  return (
    <Screen keyboard>
      <Card>
        <Row>
          <View>
            <Text variant="small" tone="secondary">
              Fatura · ciclo {bill.cycle}
            </Text>
            <Text variant="small" tone="secondary">
              Vencimento {formatShortDate(bill.dueAt, true)}
            </Text>
          </View>
          <Money value={bill.amount} variant="title" />
        </Row>
      </Card>

      <PaymentFailedCard
        title={bill.status === 'review' ? 'Seu pagamento está em análise' : 'Não foi possível processar seu pagamento'}
        card={currentCard ? { brand: currentCard.brand, lastFour: currentCard.lastFour } : null}
        options={options}
        value={method}
        onChange={(v) => {
          setMethod(v);
          if (v !== 'new-card') setShowNewCard(false);
        }}
        primaryLabel={method === 'card' ? `Regularizar assinatura · ${bill.amount.amount.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })}` : method === 'pix' ? 'Gerar PIX' : 'Alterar cartão de cobrança'}
        onPrimary={onPrimary}
        primaryLoading={payCard.isPending || (method === 'pix' && payPix.isPending)}
        onSupport={support}
      />

      {method === 'pix' && (pixRequested || bill.pix) ? <PixPanel bill={bill} pixData={payPix.data?.pix} regenerate={() => payPix.mutate(bill.id)} regenerating={payPix.isPending} error={payPix.isError ? errorMessage(payPix.error, 'Não foi possível gerar o PIX.') : null} /> : null}

      {method === 'new-card' && showNewCard ? <NewCardPanel bill={bill} /> : null}
    </Screen>
  );
}

function PixPanel({ bill, pixData, regenerate, regenerating, error }: { bill: Bill; pixData?: PixCharge; regenerate: () => void; regenerating: boolean; error: string | null }) {
  const router = useRouter();
  const pix: PixCharge | undefined = pixData ?? bill.pix;

  if (!pix) {
    return (
      <Card>
        {error ? (
          <>
            <Text variant="small" tone="danger">
              {error}
            </Text>
            <Button title="Tentar de novo" variant="secondary" size="sm" style={styles.mt3} onPress={regenerate} loading={regenerating} />
          </>
        ) : (
          <SkeletonCard lines={4} />
        )}
      </Card>
    );
  }
  return <PixDetails pix={pix} dueAt={bill.dueAt} onRegenerate={regenerate} regenerating={regenerating} onPaid={() => router.replace('/(tabs)')} />;
}

function PixDetails({ pix, dueAt, onRegenerate, regenerating, onPaid }: { pix: PixCharge; dueAt: string; onRegenerate: () => void; regenerating: boolean; onPaid: () => void }) {
  const expiresAt = useMemo(() => new Date(pix.expiresAt).getTime(), [pix.expiresAt]);
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    const t = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(t);
  }, []);
  const remaining = expiresAt - now;
  const expired = Number.isFinite(expiresAt) && remaining <= 0;

  async function copy() {
    await Clipboard.setStringAsync(pix.qrCodeText);
    toast.success('Código PIX copiado. Cole no app do seu banco.');
  }

  return (
    <PixPaymentCard
      qrCodeImageUrl={pix.qrCodeImageUrl}
      qrCodeText={pix.qrCodeText}
      dueLabel={formatShortDate(dueAt, true)}
      onCopy={copy}
      expired={expired}
      onRegenerate={onRegenerate}
      regenerating={regenerating}
      footer={
        <View style={styles.pixFooter}>
          <Text variant="caption" tone="dim" center>
            {expired ? 'QR Code expirado.' : `Este QR Code expira em ${formatCountdown(remaining)}.`} A confirmação é automática em até alguns minutos. Se o PIX vencer, a cobrança vai para o cartão à meia-noite.
          </Text>
          <Button title="Já paguei" variant="ghost" size="sm" onPress={onPaid} />
        </View>
      }
    />
  );
}

function NewCardPanel({ bill }: { bill: Bill }) {
  const router = useRouter();
  const pay = usePayWithNewCard();

  async function onTokenized(card: TokenizedCard) {
    await pay
      .mutateAsync(
        { billId: bill.id, body: { gatewayToken: card.gatewayToken, paymentCompanyCode: card.paymentCompanyCode } },
        {
          onSuccess: (b) => {
            toast.success(b.status === 'paid' ? 'Pagamento aprovado!' : 'Pagamento enviado.');
            router.replace('/(tabs)');
          },
          onError: (e) => toast.error(errorMessage(e, 'Pagamento recusado.')),
        },
      )
      .catch(() => undefined);
  }

  return (
    <Card title="Novo cartão de crédito" subtitle="O novo cartão passa a ser o padrão da assinatura.">
      <CardForm submitLabel="Pagar com este cartão" onTokenized={onTokenized} busy={pay.isPending} />
    </Card>
  );
}

const styles = StyleSheet.create({
  mt3: { marginTop: space(3) },
  pixFooter: { gap: space(1) },
});
