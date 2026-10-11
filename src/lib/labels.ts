import type { Bill, BillStatus, CapabilityReason, Frequency, Fulfillment, SubscriptionStatus } from '@/api/contracts';
import { formatDate } from './format';

export const subscriptionStatusLabel: Record<SubscriptionStatus, string> = {
  active: 'Ativa',
  future: 'Começa em breve',
  paused: 'Pausada',
  canceled: 'Cancelada',
  fraud_review: 'Em análise',
};

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
    case 'PENDING_BILL':
      return 'Há uma fatura pendente. Pague para liberar as alterações.';
    case 'NOT_PAUSED':
      return 'Sua assinatura não está pausada.';
    case 'NOT_CANCELED':
      return 'Sua assinatura não está cancelada.';
    case 'CANCELLATION_BLOCKED':
      return 'O cancelamento não está disponível no momento. Fale com o suporte.';
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
