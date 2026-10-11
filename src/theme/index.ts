/**
 * Design tokens do Caffeine Army Prime — tema CLARO, derivado do Figma
 * "Painel do assinante" (ver DESIGN.md).
 */
import { Platform } from 'react-native';
import { font, logoFont, textStyle, typeScale, type FontWeight, type TypeVariant } from './typography';

export const colors = {
  // Fundos
  background: '#F3F3F3',
  surface: '#FFFFFF',
  subtle: '#F8F9FA',
  muted: '#E9ECEF',
  border: '#E9ECEF',
  borderStrong: '#DEE2E6',

  // Marca
  brandDark: '#260F0F',
  brandDark2: '#331E1E',
  primary: '#F1D98A',
  primaryStrong: '#EBC969',
  gold: '#DBA73F',
  goldDeep: '#DDA41F',
  goldGradientStart: '#C28B14',
  goldGradientEnd: '#E4BD6F',
  goldSoft: '#FFF8E1',
  purple: '#7B44DA',
  purpleSoft: '#EAE1F9',

  // Semânticas
  success: '#82C91E',
  successDeep: '#74B816',
  successText: '#2B8A3E',
  successSoft: '#EEF6E2',
  successBadge: '#D8F0B3',
  warning: '#F59F00',
  warningText: '#F08C00',
  warningSoft: '#FFF3BF',
  warningCard: '#FBF1EA',
  danger: '#C92A2A',
  dangerSoft: '#FFE3E3',
  dangerCard: '#FFF5F5',
  info: '#006EBB',
  infoSoft: '#D9F2FC',

  // Texto
  text: '#212529',
  textSecondary: '#495057',
  textMuted: '#909296',
  textOnDark: '#FFFFFF',
  textOnDarkMuted: '#C9BDBD',
  textOnPrimary: '#260F0F',

  overlay: 'rgba(33, 37, 41, 0.45)',
  skeleton: '#E9ECEF',

  // Aliases de compatibilidade (código antigo)
  accent: '#DBA73F',
} as const;

/** Escala de espaçamento base 4. `space(3)` = 12. */
export const space = (n: number): number => n * 4;

export const radius = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  pill: 999,
} as const;

export const shadows = {
  card: Platform.select({
    ios: { shadowColor: '#000', shadowOpacity: 0.06, shadowRadius: 8, shadowOffset: { width: 0, height: 2 } },
    android: { elevation: 2 },
    default: { boxShadow: '0px 2px 8px rgba(0,0,0,0.06)' },
  }) as object,
  float: Platform.select({
    ios: { shadowColor: '#000', shadowOpacity: 0.12, shadowRadius: 16, shadowOffset: { width: 0, height: 6 } },
    android: { elevation: 6 },
    default: { boxShadow: '0px 6px 16px rgba(0,0,0,0.12)' },
  }) as object,
} as const;

export const fonts = { font, logoFont, textStyle };
export const typography = typeScale;
export { font, logoFont, textStyle, typeScale, setCustomFontsReady, areCustomFontsReady } from './typography';
export type { FontWeight, TypeVariant };

export const theme = { colors, space, radius, fonts, typography, shadows };
export type Theme = typeof theme;
