/**
 * Estado local de edição da caixa. Suposição (ver README): BoxItemInput.handle é o
 * handle do sabor quando o produto tem `flavors`, senão o handle do produto.
 */
import { useCallback, useMemo, useState } from 'react';
import type { Catalog, CatalogProduct, Frequency, ItemRecurrence, PreviewRequest, SchedulingRequest, Subscription } from '@/api/contracts';

export interface EditorItem {
  /** handle do produto no catálogo */
  productHandle: string;
  /** handle enviado ao BFF (sabor ou produto) */
  handle: string;
  quantity: number;
  recurrence: ItemRecurrence;
  /** id do item na assinatura atual (quando já existe) */
  subscriptionItemId?: string;
}

export interface EditorState {
  frequency: Frequency;
  items: EditorItem[];
  giftHandles: string[];
  nextCycleOnly: boolean;
}

export function findProduct(catalog: Catalog, handle: string): CatalogProduct | undefined {
  return catalog.products.find((p) => p.handle === handle || p.flavors?.some((f) => f.handle === handle));
}

function buildInitial(subscription: Subscription, catalog: Catalog): EditorState {
  const items: EditorItem[] = [];
  const giftHandles: string[] = [];
  for (const it of subscription.items) {
    if (it.isGift) {
      giftHandles.push(it.handle);
      continue;
    }
    const product = findProduct(catalog, it.handle);
    items.push({
      productHandle: product?.handle ?? it.handle,
      handle: it.handle,
      quantity: it.quantity,
      recurrence: it.recurrence,
      subscriptionItemId: it.id,
    });
  }
  return { frequency: subscription.frequency, items, giftHandles, nextCycleOnly: false };
}

function serialize(s: EditorState): string {
  return JSON.stringify({
    f: s.frequency,
    i: [...s.items].filter((i) => i.quantity > 0).sort((a, b) => a.handle.localeCompare(b.handle)).map((i) => [i.handle, i.quantity, i.recurrence]),
    g: [...s.giftHandles].sort(),
  });
}

export function useBoxEditor(subscription: Subscription, catalog: Catalog) {
  const initial = useMemo(() => buildInitial(subscription, catalog), [subscription, catalog]);
  const [state, setState] = useState<EditorState>(initial);
  const [baseline, setBaseline] = useState(() => serialize(initial));

  // Resincroniza quando a assinatura muda no servidor (ex.: PATCH recurrence).
  const initialKey = serialize(initial);
  if (initialKey !== baseline) {
    setBaseline(initialKey);
    setState(initial);
  }

  const dirty = serialize(state) !== baseline;

  const setQuantity = useCallback((productHandle: string, quantity: number, product?: CatalogProduct) => {
    setState((s) => {
      const existing = s.items.find((i) => i.productHandle === productHandle);
      if (existing) {
        return { ...s, items: s.items.map((i) => (i.productHandle === productHandle ? { ...i, quantity } : i)) };
      }
      if (!product || quantity <= 0) return s;
      const firstFlavor = product.flavors?.find((f) => f.inStock) ?? product.flavors?.[0];
      return {
        ...s,
        items: [...s.items, { productHandle, handle: firstFlavor?.handle ?? product.handle, quantity, recurrence: null }],
      };
    });
  }, []);

  const setFlavor = useCallback((productHandle: string, flavorHandle: string) => {
    setState((s) => ({ ...s, items: s.items.map((i) => (i.productHandle === productHandle ? { ...i, handle: flavorHandle } : i)) }));
  }, []);

  const setRecurrence = useCallback((productHandle: string, recurrence: ItemRecurrence) => {
    setState((s) => ({ ...s, items: s.items.map((i) => (i.productHandle === productHandle ? { ...i, recurrence } : i)) }));
  }, []);

  const setFrequency = useCallback((frequency: Frequency) => setState((s) => ({ ...s, frequency })), []);
  const setNextCycleOnly = useCallback((nextCycleOnly: boolean) => setState((s) => ({ ...s, nextCycleOnly })), []);
  const toggleGift = useCallback((handle: string) => {
    setState((s) => ({
      ...s,
      giftHandles: s.giftHandles.includes(handle) ? s.giftHandles.filter((g) => g !== handle) : [...s.giftHandles, handle],
    }));
  }, []);
  const reset = useCallback(() => setState(initial), [initial]);

  const activeItems = state.items.filter((i) => i.quantity > 0);
  const totalUnits = activeItems.reduce((n, i) => n + i.quantity, 0);
  const allRecurring = activeItems.length > 0 && activeItems.every((i) => i.recurrence !== null);

  const previewRequest: PreviewRequest | null =
    activeItems.length > 0
      ? { frequency: state.frequency, items: activeItems.map(({ handle, quantity, recurrence }) => ({ handle, quantity, recurrence })) }
      : null;

  const schedulingRequest: SchedulingRequest | null = previewRequest
    ? { ...previewRequest, giftHandles: state.giftHandles, nextCycleOnly: state.nextCycleOnly }
    : null;

  return {
    state,
    dirty,
    activeItems,
    totalUnits,
    allRecurring,
    previewRequest,
    schedulingRequest,
    setQuantity,
    setFlavor,
    setRecurrence,
    setFrequency,
    setNextCycleOnly,
    toggleGift,
    reset,
  };
}
