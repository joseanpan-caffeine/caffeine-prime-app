/**
 * Design tokens do Caffeine Prime. Estética escura, "café premium".
 * Fontes: sistema por enquanto; troque `fonts.*` quando GT Pressura / Rund
 * forem carregadas com expo-font.
 */
import { Platform } from 'react-native';

export const colors = {
  background: '#0E0B09',
  surface: '#1A1512',
  surfaceElevated: '#241D18',
  border: '#2E2620',
  borderStrong: '#3D332B',
  text: '#F3EBDD',
  textMuted: '#B9AB97',
  textDim: '#7E7262',
  accent: '#E0A24A',
  accentDark: '#A8732B',
  accentSoft: 'rgba(224, 162, 74, 0.14)',
  onAccent: '#1A1208',
  success: '#5FB37A',
  successSoft: 'rgba(95, 179, 122, 0.16)',
  danger: '#E05A4A',
  dangerSoft: 'rgba(224, 90, 74, 0.16)',
  warning: '#E0A24A',
  warningSoft: 'rgba(224, 162, 74, 0.14)',
  info: '#8FB3D9',
  infoSoft: 'rgba(143, 179, 217, 0.16)',
  overlay: 'rgba(0, 0, 0, 0.6)',
  skeleton: '#2A221C',
} as const;

/** Escala de espaçamento base 4. `space(3)` = 12. */
export const space = (n: number): number => n * 4;

export const radius = {
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  pill: 999,
} as const;

export const fonts = {
  /** Títulos — futuro GT Pressura. */
  display: Platform.select({ ios: undefined, android: undefined, default: undefined }) as string | undefined,
  /** Corpo — futuro Rund. */
  body: undefined as string | undefined,
  /** Numéricos / códigos. */
  mono: Platform.select({ ios: 'Menlo', android: 'monospace', default: 'monospace' }) as string | undefined,
};

export const typography = {
  display: { fontFamily: fonts.display, fontSize: 32, lineHeight: 38, fontWeight: '700' as const, letterSpacing: -0.5 },
  title: { fontFamily: fonts.display, fontSize: 24, lineHeight: 30, fontWeight: '700' as const, letterSpacing: -0.3 },
  heading: { fontFamily: fonts.display, fontSize: 18, lineHeight: 24, fontWeight: '600' as const },
  body: { fontFamily: fonts.body, fontSize: 16, lineHeight: 22, fontWeight: '400' as const },
  bodyStrong: { fontFamily: fonts.body, fontSize: 16, lineHeight: 22, fontWeight: '600' as const },
  small: { fontFamily: fonts.body, fontSize: 14, lineHeight: 20, fontWeight: '400' as const },
  caption: { fontFamily: fonts.body, fontSize: 12, lineHeight: 16, fontWeight: '500' as const, letterSpacing: 0.3 },
  mono: { fontFamily: fonts.mono, fontSize: 13, lineHeight: 18 },
} as const;

export const shadows = {
  card: Platform.select({
    ios: { shadowColor: '#000', shadowOpacity: 0.35, shadowRadius: 12, shadowOffset: { width: 0, height: 6 } },
    android: { elevation: 4 },
    default: {},
  }),
} as const;

export const theme = { colors, space, radius, fonts, typography, shadows };
export type Theme = typeof theme;
