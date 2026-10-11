/**
 * Derivações de apresentação a partir dos contratos (sem regra de negócio nova —
 * só formatação e inferências visuais do painel Prime).
 */
import type { Capabilities, Frequency, Subscription, SubscriptionStatus } from '@/api/contracts';
import type { BadgeTone } from '@/components/Badge';
import { daysUntil, parseDate } from './format';

const MONTHS_LONG = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];

/** "17 de Julho" */
export function formatDayMonth(iso: string | undefined | null): string {
  const d = parseDate(iso);
  if (!d) return '—';
  return `${d.getDate()} de ${MONTHS_LONG[d.getMonth()]}`;
}

/** "14/07" */
export function formatShortDate(iso: string | undefined | null, withYear = false): string {
  const d = parseDate(iso);
  if (!d) return '—';
  const dd = String(d.getDate()).padStart(2, '0');
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  return withYear ? `${dd}/${mm}/${d.getFullYear()}` : `${dd}/${mm}`;
}

/** "PRIME ANUAL" */
export function planBadgeLabel(frequency: Frequency | undefined): string {
  return frequency ? `Prime ${frequency}` : 'Prime';
}

export const commitmentMonths: Record<Frequency, number> = { Mensal: 1, Trimestral: 3, Semestral: 6, Anual: 12 };

export function statusBadge(status: SubscriptionStatus | undefined, caps?: Capabilities): { label: string; tone: BadgeTone } {
  if (caps?.hasPendingBill) return { label: 'Pagamento pendente', tone: 'pending' };
  switch (status) {
    case 'active':
      return { label: 'Assinatura ativa', tone: 'active' };
    case 'future':
      return { label: 'Assinatura agendada', tone: 'scheduled' };
    case 'paused':
      return { label: 'Assinatura pausada', tone: 'paused' };
    case 'canceled':
      return { label: 'Assinatura cancelada', tone: 'canceled' };
    case 'fraud_review':
      return { label: 'Assinatura em análise', tone: 'review' };
    default:
      return { label: 'Sem assinatura', tone: 'canceled' };
  }
}

/** Data-limite de edição: `canEdit.until` do servidor ou 3 dias antes da cobrança. */
export function editUntilIso(sub: Pick<Subscription, 'nextBillingAt'>, caps?: Pick<Capabilities, 'canEdit'>): string | undefined {
  if (caps?.canEdit.until) return caps.canEdit.until;
  const d = parseDate(sub.nextBillingAt);
  if (!d) return undefined;
  d.setDate(d.getDate() - 3);
  return d.toISOString();
}

export function addMonths(iso: string, months: number): string | undefined {
  const d = parseDate(iso);
  if (!d) return undefined;
  const day = d.getDate();
  d.setDate(1);
  d.setMonth(d.getMonth() + months);
  const last = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
  d.setDate(Math.min(day, last));
  return d.toISOString();
}

/** Próximas datas de cobrança (a atual + `count` seguintes, cadência mensal). */
export function upcomingBillingDates(sub: Subscription, count = 2): string[] {
  const dates = [sub.nextBillingAt];
  for (let i = 1; i <= count; i++) {
    const next = addMonths(sub.nextBillingAt, i);
    if (next) dates.push(next);
  }
  return dates;
}

/** Fração 0–1 da vigência já cumprida. */
export function commitmentProgress(sub: Subscription, totalMonths?: number): number {
  const total = totalMonths ?? commitmentMonths[sub.frequency];
  if (!total || sub.remainingCommitmentMonths < 0) return 1;
  const remaining = Math.max(0, Math.min(total, sub.remainingCommitmentMonths));
  return (total - remaining) / total;
}

export function isEditWindowOpen(caps: Capabilities | undefined): boolean {
  return !!caps?.canEdit.allowed;
}

export function daysLabel(iso: string | undefined): string {
  const n = daysUntil(iso);
  if (n === null) return '';
  if (n <= 0) return 'hoje';
  return n === 1 ? 'amanhã' : `em ${n} dias`;
}
