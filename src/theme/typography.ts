/**
 * Tipografia do Caffeine Army Prime.
 *
 * A marca usa Acumin Pro (Adobe Fonts). Como não é embutível sem licença, usamos
 * Archivo (Google Fonts) como substituto. Para trocar para Acumin Pro depois:
 *  1. adicione os .otf em assets/fonts e carregue-os em app/_layout.tsx (useFonts);
 *  2. troque os nomes em `fontFamilies` abaixo — nada mais precisa mudar.
 *
 * Em React Native cada peso é uma família distinta, por isso mapeamos peso → família.
 */
import type { TextStyle } from 'react-native';

export type FontWeight = '400' | '500' | '600' | '700' | '800';

/** Slots de fonte. `heading`/`display` podem apontar para outra família (ex.: Acumin Pro Condensed). */
export const fontFamilies = {
  body: {
    '400': 'Archivo_400Regular',
    '500': 'Archivo_500Medium',
    '600': 'Archivo_600SemiBold',
    '700': 'Archivo_700Bold',
    '800': 'Archivo_800ExtraBold',
  },
  heading: {
    '400': 'Archivo_400Regular',
    '500': 'Archivo_500Medium',
    '600': 'Archivo_600SemiBold',
    '700': 'Archivo_700Bold',
    '800': 'Archivo_800ExtraBold',
  },
  display: {
    '400': 'Archivo_400Regular',
    '500': 'Archivo_500Medium',
    '600': 'Archivo_600SemiBold',
    '700': 'Archivo_700Bold',
    '800': 'Archivo_800ExtraBold',
  },
  /** Logo "PRIME": itálico pesado. */
  logo: 'Archivo_800ExtraBold_Italic',
} as const;

export type FontSlot = 'body' | 'heading' | 'display';

let customFontsReady = false;

/** Chamado pelo layout raiz depois de carregar (ou falhar ao carregar) as fontes. */
export function setCustomFontsReady(ready: boolean) {
  customFontsReady = ready;
}

export function areCustomFontsReady() {
  return customFontsReady;
}

/**
 * Resolve `{ fontFamily }` para um slot + peso. Se as fontes customizadas não
 * carregaram, devolve `{ fontWeight }` para a fonte do sistema.
 */
export function font(slot: FontSlot, weight: FontWeight = '400'): Pick<TextStyle, 'fontFamily' | 'fontWeight'> {
  if (customFontsReady) return { fontFamily: fontFamilies[slot][weight] };
  return { fontWeight: weight };
}

export function logoFont(): Pick<TextStyle, 'fontFamily' | 'fontWeight' | 'fontStyle'> {
  if (customFontsReady) return { fontFamily: fontFamilies.logo };
  return { fontWeight: '800', fontStyle: 'italic' };
}

interface TypeSpec {
  slot: FontSlot;
  weight: FontWeight;
  fontSize: number;
  lineHeight: number;
  letterSpacing?: number;
}

/** Escala: display 28, h1 22, h2 18, h3 16, body 14, small 12, caption 11. Line-height ≈ 1.3. */
export const typeScale = {
  display: { slot: 'display', weight: '700', fontSize: 28, lineHeight: 34, letterSpacing: -0.4 },
  title: { slot: 'heading', weight: '700', fontSize: 22, lineHeight: 28, letterSpacing: -0.3 },
  heading: { slot: 'heading', weight: '700', fontSize: 18, lineHeight: 24, letterSpacing: -0.3 },
  subheading: { slot: 'heading', weight: '700', fontSize: 16, lineHeight: 21, letterSpacing: -0.2 },
  body: { slot: 'body', weight: '400', fontSize: 14, lineHeight: 19 },
  bodyMedium: { slot: 'body', weight: '600', fontSize: 14, lineHeight: 19 },
  bodyStrong: { slot: 'body', weight: '700', fontSize: 14, lineHeight: 19 },
  small: { slot: 'body', weight: '400', fontSize: 12, lineHeight: 16 },
  smallMedium: { slot: 'body', weight: '600', fontSize: 12, lineHeight: 16 },
  smallStrong: { slot: 'body', weight: '700', fontSize: 12, lineHeight: 16 },
  caption: { slot: 'body', weight: '500', fontSize: 11, lineHeight: 14 },
  captionStrong: { slot: 'body', weight: '700', fontSize: 11, lineHeight: 14 },
  mono: { slot: 'body', weight: '400', fontSize: 12, lineHeight: 16 },
} as const satisfies Record<string, TypeSpec>;

export type TypeVariant = keyof typeof typeScale;

/** Estilo completo (família resolvida) de uma variante. */
export function textStyle(variant: TypeVariant): TextStyle {
  const spec: TypeSpec = typeScale[variant];
  return {
    ...font(spec.slot, spec.weight),
    fontSize: spec.fontSize,
    lineHeight: spec.lineHeight,
    letterSpacing: spec.letterSpacing,
  };
}
