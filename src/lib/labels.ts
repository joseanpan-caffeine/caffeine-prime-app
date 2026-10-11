import type { Bill, BillStatus, CapabilityReason, Frequency, Fulfillment, Subscription, SubscriptionStatus } from '@/api/contracts';
import { formatDate } from './format';

export const subscriptionStatusLabel: Record<SubscriptionStatus, string> = {
  active: 'Ativa',
  future: 'Começa em breve',
  paused: 'Pausada',
  canceled: 'Cancelada',
  fraud_review: 'Em análise',
};

/**
 * Status desconhecido: a Prime API guarda `status` como string livre e o BFF devolve o valor
 * original em `rawStatus` (docs/contexto-prime.md §8 item 5). Mostramos um texto genérico neutro
 * e seguimos navegando; nunca quebrar a tela.
 */
export function describeSubscriptionStatus(sub: Pick<Subscription, 'status' | 'rawStatus'> | null | undefined): string {
  if (!sub) return 'Sem assinatura';
  if (sub.rawStatus) return `Status: ${sub.rawStatus}`;
  return subscriptionStatusLabel[sub.status] ?? `Status: ${String(sub.status)}`;
}

/** Fatura de ciclo pausado (R$ 0,00 durante a pausa): esperada, não é erro (§5.3). */
export function isPausedCycleBill(bill: Pick<Bill, 'pausedCycle' | 'amount' | 'status'>, subscriptionPaused = false): boolean {
  if (bill.pausedCycle) return true;
  return subscriptionPaused && bill.status === 'paid' && bill.amount.amount === 0;
}

export const billStatusLabel: Record<BillStatus, string> = {
  pending: 'Pendente',
  paid: 'Paga',
  canceled: 'Cancelada',
  review: 'Em análise',
};

export const fulfillmentLabel: Record<Fulfillment['status'], string> = {
  pending: 'Aguardando envio',
  processing: 'Preparando pedido',
  shipped: 'Enviado',
  in_transit: 'Em trânsito',
  out_for_delivery: 'Saiu para entrega',
  delivered: 'Entregue',
  failed: 'Falha na entrega',
};

export const frequencyLabel: Record<Frequency, string> = {
  Mensal: 'Mensal',
  Trimestral: 'Trimestral',
  Semestral: 'Semestral',
  Anual: 'Anual',
};

/**
 * Texto pt-BR para cada razão de bloqueio devolvida pelo BFF (regras oficiais em
 * docs/contexto-prime.md §6.1; o app não recalcula nenhuma delas). `until` é o instante em que a
 * ação reabre, já no fuso de São Paulo.
 */
export function capabilityReasonLabel(reason: CapabilityReason | undefined, until?: string): string {
  switch (reason) {
    case 'EDIT_WINDOW_CLOSED':
      return until
        ? `A janela de edição está fechada até ${formatDate(until)}. Sua próxima caixa já está sendo preparada.`
        : 'A janela de edição está fechada. Sua próxima caixa já está sendo preparada.';
    case 'SUBSCRIPTION_NOT_ACTIVE':
      return 'Sua assinatura não está ativa.';
    case 'FREQUENCY_NOT_ELIGIBLE':
      return 'Seu plano não permite esta ação. Planos Semestral e Anual têm direito a pausa.';
    case 'NO_PAUSE_CREDITS':
      return 'Você já usou todos os créditos de pausa deste plano.';
    case 'MIN_PAID_CYCLES':
      return 'Disponível a partir da 4ª cobrança paga.';
    case 'PAUSE_WINDOW_CLOSED':
      return until ? `Pedido de pausa só até 3 dias antes da cobrança. Volta a ficar disponível em ${formatDate(until)}.` : 'Pedido de pausa só até 3 dias antes da cobrança.';
    case 'RESUME_WINDOW_CLOSED':
      return until
        ? `Só é possível desfazer a pausa até 5 dias antes da cobrança. A próxima cobrança é em ${formatDate(until)}.`
        : 'Só é possível desfazer a pausa até 5 dias antes da cobrança.';
    case 'PENDING_BILL':
      return 'Há uma fatura pendente. Pague para liberar as alterações.';
    case 'NOT_PAUSED':
      return 'Sua assinatura não está pausada.';
    case 'NOT_CANCELED':
      return 'Sua assinatura não está cancelada.';
    case 'CANCELLATION_BLOCKED':
      return 'O cancelamento não está disponível no momento. Fale com o suporte.';
    case 'COMMITMENT_ACTIVE':
      return until
        ? `Sua fidelidade termina em ${formatDate(until)}; o cancelamento fica disponível depois do último pagamento.`
        : 'Sua fidelidade ainda está em vigor; o cancelamento fica disponível depois do último pagamento.';
    case 'CANCEL_WINDOW_CLOSED':
      return until
        ? `A janela de cancelamento fechou: a cobrança deste ciclo acontece em ${formatDate(until)}. Sem cancelar, a assinatura renova; você poderá cancelar no próximo ciclo.`
        : 'A janela de cancelamento fechou para este ciclo. Sem cancelar, a assinatura renova.';
    case 'UNDER_REVIEW':
      return 'Sua assinatura está em análise. Aguarde o contato da nossa equipe.';
    default:
      return 'Esta ação não está disponível no momento.';
  }
}

export function paymentMethodLabel(bill: Bill): string {
  if (bill.paymentMethod === 'pix') return 'PIX';
  if (bill.paymentMethod === 'credit_card') {
    const pp = bill.paymentProfile;
    return pp ? `${pp.brand} •••• ${pp.lastFour}` : 'Cartão de crédito';
  }
  return '—';
}
