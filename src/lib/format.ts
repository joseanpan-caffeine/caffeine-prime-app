import type { Money } from '@/api/contracts';

const brl = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });

export function formatMoney(value: Money | number | undefined | null): string {
  if (value === undefined || value === null) return '—';
  const amount = typeof value === 'number' ? value : value.amount;
  try {
    return brl.format(amount);
  } catch {
    return `R$ ${amount.toFixed(2).replace('.', ',')}`;
  }
}

const MONTHS_SHORT = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

export function parseDate(iso: string | undefined | null): Date | null {
  if (!iso) return null;
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? null : d;
}

export function formatDate(iso: string | undefined | null, opts: { withYear?: boolean } = {}): string {
  const d = parseDate(iso);
  if (!d) return '—';
  const day = String(d.getDate()).padStart(2, '0');
  const month = MONTHS_SHORT[d.getMonth()] ?? '';
  return opts.withYear === false ? `${day} ${month}` : `${day} ${month} ${d.getFullYear()}`;
}

export function formatDateTime(iso: string | undefined | null): string {
  const d = parseDate(iso);
  if (!d) return '—';
  const hh = String(d.getHours()).padStart(2, '0');
  const mm = String(d.getMinutes()).padStart(2, '0');
  return `${formatDate(iso)} às ${hh}:${mm}`;
}

/** Dias inteiros até a data (0 = hoje, negativo = passado). */
export function daysUntil(iso: string | undefined | null, from: Date = new Date()): number | null {
  const d = parseDate(iso);
  if (!d) return null;
  const start = new Date(from.getFullYear(), from.getMonth(), from.getDate());
  const target = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  return Math.round((target.getTime() - start.getTime()) / 86_400_000);
}

export function describeDaysUntil(iso: string | undefined | null): string {
  const days = daysUntil(iso);
  if (days === null) return '—';
  if (days < 0) return `há ${Math.abs(days)} dia${Math.abs(days) === 1 ? '' : 's'}`;
  if (days === 0) return 'hoje';
  if (days === 1) return 'amanhã';
  return `em ${days} dias`;
}

export function formatCountdown(ms: number): string {
  if (ms <= 0) return '00:00';
  const total = Math.floor(ms / 1000);
  const h = Math.floor(total / 3600);
  const m = Math.floor((total % 3600) / 60);
  const s = total % 60;
  const mm = String(m).padStart(2, '0');
  const ss = String(s).padStart(2, '0');
  return h > 0 ? `${h}:${mm}:${ss}` : `${mm}:${ss}`;
}

export const onlyDigits = (s: string): string => s.replace(/\D/g, '');

export function maskCpf(s: string): string {
  const d = onlyDigits(s).slice(0, 11);
  return d
    .replace(/(\d{3})(\d)/, '$1.$2')
    .replace(/(\d{3})(\d)/, '$1.$2')
    .replace(/(\d{3})(\d{1,2})$/, '$1-$2');
}

export function maskPhone(s: string): string {
  const d = onlyDigits(s).slice(0, 11);
  if (d.length <= 10) return d.replace(/(\d{2})(\d)/, '($1) $2').replace(/(\d{4})(\d)/, '$1-$2');
  return d.replace(/(\d{2})(\d)/, '($1) $2').replace(/(\d{5})(\d)/, '$1-$2');
}

export function maskCep(s: string): string {
  const d = onlyDigits(s).slice(0, 8);
  return d.replace(/(\d{5})(\d)/, '$1-$2');
}

export function maskDateBR(s: string): string {
  const d = onlyDigits(s).slice(0, 8);
  return d.replace(/(\d{2})(\d)/, '$1/$2').replace(/(\d{2})(\d)/, '$1/$2');
}

/** "DD/MM/AAAA" → "AAAA-MM-DD" (ou null se inválida). */
export function brDateToIso(s: string): string | null {
  const m = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(s);
  if (!m) return null;
  const [, dd, mm, yyyy] = m;
  const d = new Date(Number(yyyy), Number(mm) - 1, Number(dd));
  if (d.getFullYear() !== Number(yyyy) || d.getMonth() !== Number(mm) - 1 || d.getDate() !== Number(dd)) return null;
  return `${yyyy}-${mm}-${dd}`;
}

export function maskCardNumber(s: string): string {
  const d = onlyDigits(s).slice(0, 19);
  return d.replace(/(\d{4})(?=\d)/g, '$1 ');
}

export function maskExpiry(s: string): string {
  const d = onlyDigits(s).slice(0, 6);
  return d.replace(/(\d{2})(\d)/, '$1/$2');
}

export function isValidCpf(value: string): boolean {
  const d = onlyDigits(value);
  if (d.length !== 11 || /^(\d)\1{10}$/.test(d)) return false;
  const calc = (len: number) => {
    let sum = 0;
    for (let i = 0; i < len; i++) sum += Number(d[i]) * (len + 1 - i);
    const r = (sum * 10) % 11;
    return r === 10 ? 0 : r;
  };
  return calc(9) === Number(d[9]) && calc(10) === Number(d[10]);
}

export function luhn(value: string): boolean {
  const d = onlyDigits(value);
  if (d.length < 13) return false;
  let sum = 0;
  let dbl = false;
  for (let i = d.length - 1; i >= 0; i--) {
    let n = Number(d[i]);
    if (dbl) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    dbl = !dbl;
  }
  return sum % 10 === 0;
}
