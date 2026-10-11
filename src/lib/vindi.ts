/**
 * Tokenização de cartão na API pública da Vindi. Só o gateway_token vai ao BFF.
 * Em FAKE_AUTH, devolve "fake-token-<últimos 4>" sem chamar a Vindi.
 */
import type { VindiConfig } from '@/api/contracts';
import { base64Ascii } from './base64';
import { FAKE_AUTH } from './env';
import { onlyDigits } from './format';

export interface CardInput {
  number: string;
  holderName: string;
  /** MM/AA ou MM/AAAA */
  expiry: string;
  cvv: string;
}

export interface TokenizedCard {
  gatewayToken: string;
  paymentCompanyCode?: string;
  lastFour: string;
}

export type CardBrand = 'visa' | 'mastercard' | 'elo' | 'american_express' | 'hipercard' | 'diners_club' | undefined;

export function detectBrand(number: string): CardBrand {
  const d = onlyDigits(number);
  if (/^(4011|4312|4389|4514|4573|5041|5066|5067|509|6277|6362|6363|650|6516|6550)/.test(d)) return 'elo';
  if (/^(606282|3841)/.test(d)) return 'hipercard';
  if (/^3[47]/.test(d)) return 'american_express';
  if (/^(36|38|30[0-5])/.test(d)) return 'diners_club';
  if (/^4/.test(d)) return 'visa';
  if (/^(5[1-5]|2[2-7])/.test(d)) return 'mastercard';
  return undefined;
}

export const brandLabel: Record<NonNullable<CardBrand>, string> = {
  visa: 'Visa',
  mastercard: 'Mastercard',
  elo: 'Elo',
  american_express: 'Amex',
  hipercard: 'Hipercard',
  diners_club: 'Diners',
};

function normalizeExpiry(expiry: string): string {
  const [mm = '', yy = ''] = expiry.split('/');
  const year = yy.length === 2 ? `20${yy}` : yy;
  return `${mm.padStart(2, '0')}/${year}`;
}

interface VindiProfileResponse {
  payment_profile?: { gateway_token?: string; payment_company?: { code?: string }; card_number_last_four?: string };
  errors?: { parameter?: string; message?: string }[];
}

export async function tokenizeCard(card: CardInput, config: VindiConfig | undefined): Promise<TokenizedCard> {
  const number = onlyDigits(card.number);
  const lastFour = number.slice(-4);
  const brand = detectBrand(number);

  if (FAKE_AUTH) {
    return { gatewayToken: `fake-token-${lastFour}`, paymentCompanyCode: brand, lastFour };
  }
  if (!config) throw new Error('Configuração de pagamento indisponível. Tente novamente.');

  const res = await fetch(`${config.apiUrl.replace(/\/$/, '')}/public/payment_profiles`, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      Authorization: `Basic ${base64Ascii(`${config.publicKey}:`)}`,
    },
    body: JSON.stringify({
      holder_name: card.holderName.trim(),
      card_expiration: normalizeExpiry(card.expiry),
      card_number: number,
      card_cvv: onlyDigits(card.cvv),
      payment_method_code: 'credit_card',
      ...(brand ? { payment_company_code: brand } : {}),
    }),
  });
  const data = (await res.json().catch(() => ({}))) as VindiProfileResponse;
  const token = data.payment_profile?.gateway_token;
  if (!res.ok || !token) {
    const msg = data.errors?.map((e) => e.message).filter(Boolean).join('; ');
    throw new Error(msg || 'Não foi possível validar o cartão. Confira os dados.');
  }
  return {
    gatewayToken: token,
    paymentCompanyCode: data.payment_profile?.payment_company?.code ?? brand,
    lastFour: data.payment_profile?.card_number_last_four ?? lastFour,
  };
}
