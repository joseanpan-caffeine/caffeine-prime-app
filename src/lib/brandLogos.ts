/**
 * Logos de bandeiras de cartão e do PIX (assets/brand), resolvidas pelo nome
 * da bandeira que a API devolve em `paymentProfile.brand` (ex.: "Visa", "mastercard",
 * "American Express", "amex"). Sem correspondência → `undefined` (a UI mostra um badge de texto).
 */
import type { ImageSourcePropType } from 'react-native';

export type BrandLogo = ImageSourcePropType;

const LOGOS = {
  visa: require('../../assets/brand/logo-visa.svg') as BrandLogo,
  mastercard: require('../../assets/brand/logo-mastercard.svg') as BrandLogo,
  elo: require('../../assets/brand/logo-elo.svg') as BrandLogo,
  amex: require('../../assets/brand/logo-american_express.svg') as BrandLogo,
  hipercard: require('../../assets/brand/logo-hipercard.svg') as BrandLogo,
} as const;

export const PIX_LOGO: BrandLogo = require('../../assets/brand/pix.svg');

export type KnownCardBrand = keyof typeof LOGOS;

/** Normaliza o nome da bandeira para uma chave conhecida (ou `undefined`). */
export function normalizeCardBrand(brand?: string | null): KnownCardBrand | undefined {
  const b = (brand ?? '').toLowerCase().replace(/[\s_-]/g, '');
  if (!b) return undefined;
  if (b.includes('visa')) return 'visa';
  if (b.includes('master')) return 'mastercard';
  if (b === 'elo' || b.startsWith('elo')) return 'elo';
  if (b.includes('amex') || b.includes('americanexpress')) return 'amex';
  if (b.includes('hipercard') || b.includes('hiper')) return 'hipercard';
  return undefined;
}

/** Logo SVG da bandeira, ou `undefined` para bandeiras desconhecidas. */
export function getCardBrandLogo(brand?: string | null): BrandLogo | undefined {
  const key = normalizeCardBrand(brand);
  return key ? LOGOS[key] : undefined;
}
