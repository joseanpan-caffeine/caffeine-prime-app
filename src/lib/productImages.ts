/**
 * Imagens de produto empacotadas no app (assets/products).
 *
 * Servem como fallback quando a API não devolve `imageUrl` (ou a URL falha):
 * primeiro tentamos pelo `handle` exato, depois por palavras-chave no handle/título.
 * Fonte oficial continua sendo o `imageUrl` da API — isto só evita tiles vazios.
 */
import type { ImageSourcePropType } from 'react-native';

export type LocalImage = ImageSourcePropType;

const IMAGES = {
  original380: require('../../assets/products/supercoffee-original-380.png') as LocalImage,
  chocolate380: require('../../assets/products/supercoffee-chocolate-380.png') as LocalImage,
  vanilla380: require('../../assets/products/supercoffee-vanilla-380.png') as LocalImage,
  choconilla380: require('../../assets/products/supercoffee-choconilla-380.png') as LocalImage,
  original220: require('../../assets/products/supercoffee-original-220.png') as LocalImage,
  chocolate220: require('../../assets/products/supercoffee-chocolate-220.png') as LocalImage,
  vanilla220: require('../../assets/products/supercoffee-vanilla-220.png') as LocalImage,
  toGo: require('../../assets/products/supercoffee-to-go.png') as LocalImage,
  toGoPacoca: require('../../assets/products/supercoffee-to-go-pacoca.png') as LocalImage,
  morningShot: require('../../assets/products/morning-shot.png') as LocalImage,
  whey: require('../../assets/products/whey.png') as LocalImage,
  economicPack: require('../../assets/products/economic-pack.png') as LocalImage,
} as const;

/** Handles conhecidos do catálogo (fake e loja) → imagem local. */
const BY_HANDLE: Record<string, LocalImage> = {
  'supercoffee-3-0-380g': IMAGES.original380,
  'supercoffee-3-0-original-380g': IMAGES.original380,
  'supercoffee-3-0-chocolate-380g': IMAGES.chocolate380,
  'supercoffee-3-0-vanilla-380g': IMAGES.vanilla380,
  'supercoffee-3-0-choconilla-380g': IMAGES.choconilla380,
  'supercoffee-3-0-paçoca-380g': IMAGES.original380,
  'supercoffee-3-0-pacoca-380g': IMAGES.original380,
  'supercoffee-3-0-economic': IMAGES.economicPack,
  'supercoffee-3-0-original-economic': IMAGES.original220,
  'supercoffee-3-0-chocolate-economic': IMAGES.chocolate220,
  'supercoffee-3-0-vanilla-economic': IMAGES.vanilla220,
  'supercoffee-to-go': IMAGES.toGo,
  'supercoffee-to-go-pacoca': IMAGES.toGoPacoca,
  'morning-shot': IMAGES.morningShot,
  'whey-isolado-900g': IMAGES.whey,
  'whey-isolado-chocolate-900g': IMAGES.whey,
  'whey-isolado-baunilha-900g': IMAGES.whey,
};

/** Remove acentos e normaliza para comparação por palavra-chave. */
function normalize(s: string): string {
  return s
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase();
}

/** Fallback por palavras-chave (handle + título) para produtos fora do mapa fixo. */
function byKeywords(text: string): LocalImage | undefined {
  const t = normalize(text);
  if (!t.trim()) return undefined;

  if (t.includes('whey')) return IMAGES.whey;
  if (t.includes('morning')) return IMAGES.morningShot;

  const isSupercoffee = t.includes('supercoffee') || t.includes('super coffee') || t.includes('supercofee');
  const isToGo = t.includes('to-go') || t.includes('to go') || t.includes('togo') || t.includes('sache');
  const isSmall = t.includes('220') || t.includes('economic') || t.includes('economico');
  const pacoca = t.includes('pacoca');

  if (isToGo) return pacoca ? IMAGES.toGoPacoca : IMAGES.toGo;

  // Sabores (choconilla antes de chocolate/vanilla porque contém ambos).
  if (t.includes('choconilla')) return IMAGES.choconilla380;
  if (t.includes('chocolate')) return isSmall ? IMAGES.chocolate220 : IMAGES.chocolate380;
  if (t.includes('vanilla') || t.includes('baunilha')) return isSmall ? IMAGES.vanilla220 : IMAGES.vanilla380;
  if (t.includes('original')) return isSmall ? IMAGES.original220 : IMAGES.original380;

  // Sem sabor identificável: economic → pack 2x220; qualquer Supercoffee → original 380.
  if (isSmall) return IMAGES.economicPack;
  if (isSupercoffee || pacoca) return IMAGES.original380;
  return undefined;
}

/**
 * Imagem local para um produto, por `handle` exato ou por palavras-chave no handle/título.
 * Devolve `undefined` quando não há correspondência (o `ProductImage` mostra o placeholder).
 */
export function getLocalProductImage(handle?: string, title?: string): LocalImage | undefined {
  if (handle && BY_HANDLE[handle]) return BY_HANDLE[handle];
  return byKeywords(`${handle ?? ''} ${title ?? ''}`);
}
