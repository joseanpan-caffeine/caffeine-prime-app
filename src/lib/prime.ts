/**
 * Derivações de apresentação a partir dos contratos (sem regra de negócio nova —
 * só formatação e inferências visuais do painel Prime).
 */
import type { Capabilities, Capability, Frequency, Subscription } from '@/api/contracts';
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

/**
 * Badge de status do painel. Status fora do enum conhecido (string livre na Prime API) vem com
 * `rawStatus` e vira um badge neutro "Status: {raw}" — a navegação continua normal.
 */
export function statusBadge(sub: Pick<Subscription, 'status' | 'rawStatus'> | null | undefined, caps?: Capabilities): { label: string; tone: BadgeTone } {
  if (caps?.hasPendingBill) return { label: 'Pagamento pendente', tone: 'pending' };
  if (sub?.rawStatus) return { label: `Status: ${sub.rawStatus}`, tone: 'neutral' };
  switch (sub?.status) {
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

/**
 * Data-limite de edição, sempre vinda do servidor (`canEdit.closesAt` quando aberta; `until`
 * quando fechada). O app não calcula D-3 no aparelho: a regra é do BFF, em America/Sao_Paulo.
 */
export function editUntilIso(_sub: Pick<Subscription, 'nextBillingAt'>, caps?: Pick<Capabilities, 'canEdit'>): string | undefined {
  return capabilityDeadline(caps?.canEdit);
}

/** Prazo exibível de uma capability: `closesAt` (aberta) ou `until` (fechada). */
export function capabilityDeadline(cap: Capability | undefined): string | undefined {
  return cap?.closesAt ?? cap?.until ?? undefined;
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

export interface UpcomingBilling {
  date: string;
  /** `true` só para a primeira: é o `nextBillingAt` real da API. As demais são previsão. */
  confirmed: boolean;
}

/**
 * Próximas cobranças: a primeira é a data real (`nextBillingAt`); as seguintes são PREVISÃO.
 * O ciclo do Prime é de 30 dias, não um dia fixo do mês (docs/contexto-prime.md §6.3), então
 * nunca derivar "todo dia X" nem tratar as datas estimadas como confirmadas.
 */
export function upcomingBillings(sub: Pick<Subscription, 'nextBillingAt'>, count = 2): UpcomingBilling[] {
  const list: UpcomingBilling[] = [{ date: sub.nextBillingAt, confirmed: true }];
  const base = parseDate(sub.nextBillingAt);
  if (!base) return list;
  for (let i = 1; i <= count; i++) {
    list.push({ date: new Date(base.getTime() + i * 30 * 86_400_000).toISOString(), confirmed: false });
  }
  return list;
}

/**
 * Fração 0–1 da vigência já cumprida. `totalMonths` vem do plano no catálogo da API; sem ele,
 * estima pelo que a assinatura informa (ciclos pagos + meses restantes). Nada fixo por plano.
 */
export function commitmentProgress(sub: Pick<Subscription, 'remainingCommitmentMonths' | 'paidCycles'>, totalMonths?: number): number {
  if (sub.remainingCommitmentMonths < 0) return 1;
  const total = totalMonths && totalMonths > 0 ? totalMonths : sub.paidCycles + sub.remainingCommitmentMonths;
  if (!total) return 1;
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
