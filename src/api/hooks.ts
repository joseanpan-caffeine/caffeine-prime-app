/** Hooks react-query por rota, com invalidação de dashboard/subscription/bills nas mutações. */
import { useEffect, useState } from 'react';
import { useMutation, useQuery, useQueryClient, type QueryClient } from '@tanstack/react-query';
import { ApiError, isApiError } from './client';
import type {
  AddCardRequest,
  AddressQuoteRequest,
  Bill,
  CancelRequest,
  ItemRecurrence,
  NotificationPreferences,
  PauseRequest,
  PayWithNewCardRequest,
  PreviewRequest,
  SchedulingRequest,
  Subscription,
  UpdateAddressRequest,
  UpdateProfileRequest,
} from './contracts';
import { deviceApi, meApi, paymentsApi, shippingApi } from './endpoints';
import { useAuthStore } from '@/store/auth';

export const queryKeys = {
  me: ['me'] as const,
  dashboard: ['dashboard'] as const,
  subscription: ['subscription'] as const,
  catalog: ['catalog'] as const,
  bills: ['bills'] as const,
  bill: (id: string) => ['bills', id] as const,
  tracking: ['tracking'] as const,
  paymentProfiles: ['payment-profiles'] as const,
  shippingAddress: ['shipping-address'] as const,
  notificationPreferences: ['notification-preferences'] as const,
  config: ['config'] as const,
  vindiConfig: ['vindi-config'] as const,
  cancelReasons: ['reasons', 'cancel'] as const,
  pauseReasons: ['reasons', 'pause'] as const,
  preview: (req: PreviewRequest | null) => ['preview', req] as const,
};

export async function invalidateSubscriptionData(qc: QueryClient) {
  await Promise.all([
    qc.invalidateQueries({ queryKey: queryKeys.dashboard }),
    qc.invalidateQueries({ queryKey: queryKeys.subscription }),
    qc.invalidateQueries({ queryKey: queryKeys.bills }),
    qc.invalidateQueries({ queryKey: queryKeys.tracking }),
  ]);
}

/** 404 = "não há recurso" (assinatura/rastreio): devolve null em vez de erro. */
async function nullOn404<T>(p: Promise<T>): Promise<T | null> {
  try {
    return await p;
  } catch (e) {
    if (isApiError(e) && e.status === 404) return null;
    throw e;
  }
}

const shouldRetry = (failureCount: number, error: unknown) => {
  if (error instanceof ApiError && error.status > 0 && error.status < 500) return false;
  return failureCount < 2;
};

function useSignedIn() {
  return useAuthStore((s) => s.status === 'signedIn');
}

// ---------- Leitura ----------

export function useMe() {
  const enabled = useSignedIn();
  return useQuery({ queryKey: queryKeys.me, queryFn: meApi.profile, enabled, retry: shouldRetry });
}

export function useDashboard() {
  const enabled = useSignedIn();
  return useQuery({
    queryKey: queryKeys.dashboard,
    queryFn: meApi.dashboard,
    enabled,
    staleTime: 30_000,
    retry: shouldRetry,
  });
}

export function useSubscription() {
  const enabled = useSignedIn();
  return useQuery({
    queryKey: queryKeys.subscription,
    queryFn: () => nullOn404(meApi.subscription()),
    enabled,
    staleTime: 30_000,
    retry: shouldRetry,
  });
}

export function useCatalog() {
  const enabled = useSignedIn();
  return useQuery({ queryKey: queryKeys.catalog, queryFn: meApi.catalog, enabled, staleTime: 10 * 60_000, retry: shouldRetry });
}

export function useBills() {
  const enabled = useSignedIn();
  return useQuery({ queryKey: queryKeys.bills, queryFn: paymentsApi.bills, enabled, staleTime: 30_000, retry: shouldRetry });
}

export function useBill(billId: string | undefined) {
  const enabled = useSignedIn() && !!billId;
  const qc = useQueryClient();
  return useQuery({
    queryKey: queryKeys.bill(billId ?? ''),
    queryFn: () => paymentsApi.bill(billId as string),
    enabled,
    retry: shouldRetry,
    initialData: () => qc.getQueryData<Bill[]>(queryKeys.bills)?.find((b) => b.id === billId),
    initialDataUpdatedAt: () => qc.getQueryState(queryKeys.bills)?.dataUpdatedAt,
  });
}

export function useTracking() {
  const enabled = useSignedIn();
  return useQuery({
    queryKey: queryKeys.tracking,
    queryFn: () => nullOn404(shippingApi.tracking()),
    enabled,
    retry: shouldRetry,
  });
}

export function usePaymentProfiles() {
  const enabled = useSignedIn();
  return useQuery({ queryKey: queryKeys.paymentProfiles, queryFn: paymentsApi.profiles, enabled, retry: shouldRetry });
}

export function useShippingAddress() {
  const enabled = useSignedIn();
  return useQuery({
    queryKey: queryKeys.shippingAddress,
    queryFn: () => nullOn404(shippingApi.address()),
    enabled,
    retry: shouldRetry,
  });
}

export function useNotificationPreferences() {
  const enabled = useSignedIn();
  return useQuery({
    queryKey: queryKeys.notificationPreferences,
    queryFn: deviceApi.notificationPreferences,
    enabled,
    retry: shouldRetry,
  });
}

export function useAppConfig() {
  return useQuery({ queryKey: queryKeys.config, queryFn: deviceApi.config, staleTime: 60 * 60_000, retry: shouldRetry });
}

export function useVindiConfig(enabled = true) {
  return useQuery({ queryKey: queryKeys.vindiConfig, queryFn: paymentsApi.vindiConfig, enabled, staleTime: 60 * 60_000 });
}

export function useCancelReasons() {
  return useQuery({ queryKey: queryKeys.cancelReasons, queryFn: meApi.cancelReasons, staleTime: 10 * 60_000 });
}

export function usePauseReasons() {
  return useQuery({ queryKey: queryKeys.pauseReasons, queryFn: meApi.pauseReasons, staleTime: 10 * 60_000 });
}

function useDebounced<T>(value: T, delay: number): T {
  const [debounced, setDebounced] = useState(value);
  const serialized = JSON.stringify(value);
  useEffect(() => {
    const t = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [serialized, delay]);
  return debounced;
}

/** Preview de preço com debounce (POST /me/subscription/preview). Passe null para desligar. */
export function usePreview(req: PreviewRequest | null, delay = 500) {
  const debounced = useDebounced(req, delay);
  const enabled = !!debounced && debounced.items.length > 0;
  return useQuery({
    queryKey: queryKeys.preview(debounced),
    queryFn: ({ signal }) => meApi.preview(debounced as PreviewRequest, signal),
    enabled,
    staleTime: 60_000,
    placeholderData: (prev) => prev,
    retry: false,
  });
}

// ---------- Mutações ----------

function useSubscriptionMutation<TVars, TData>(fn: (vars: TVars) => Promise<TData>) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: fn,
    onSuccess: async (data) => {
      if (data && typeof data === 'object' && 'status' in data && 'items' in data) {
        qc.setQueryData(queryKeys.subscription, data as unknown as Subscription);
      }
      await invalidateSubscriptionData(qc);
    },
  });
}

export const useScheduleChange = () => useSubscriptionMutation((body: SchedulingRequest) => meApi.schedule(body));
export const useUndoSchedule = () => useSubscriptionMutation(() => meApi.undoSchedule());
export const useSetItemRecurrence = () =>
  useSubscriptionMutation(({ itemId, recurrence }: { itemId: string; recurrence: ItemRecurrence }) =>
    meApi.setItemRecurrence(itemId, recurrence),
  );
export const useApplyDiscount = () => useSubscriptionMutation((code: string) => meApi.applyDiscount(code));
export const usePauseSubscription = () => useSubscriptionMutation((body: PauseRequest) => meApi.pause(body));
export const useResumeSubscription = () => useSubscriptionMutation(() => meApi.resume());
export const useCancelSubscription = () => useSubscriptionMutation((body: CancelRequest) => meApi.cancel(body));
export const useReactivateSubscription = () => useSubscriptionMutation(() => meApi.reactivate());

export function useUpdateProfile() {
  const qc = useQueryClient();
  const setUser = useAuthStore((s) => s.setUser);
  return useMutation({
    mutationFn: (body: UpdateProfileRequest) => meApi.updateProfile(body),
    onSuccess: async (user) => {
      setUser(user);
      qc.setQueryData(queryKeys.me, user);
      await qc.invalidateQueries({ queryKey: queryKeys.dashboard });
    },
  });
}

export function useAddCard() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (body: AddCardRequest) => paymentsApi.addCard(body),
    onSuccess: async () => {
      await qc.invalidateQueries({ queryKey: queryKeys.paymentProfiles });
      await invalidateSubscriptionData(qc);
    },
  });
}

export function useRemoveCard() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => paymentsApi.removeCard(id),
    onSuccess: async () => {
      await qc.invalidateQueries({ queryKey: queryKeys.paymentProfiles });
      await invalidateSubscriptionData(qc);
    },
  });
}

function useBillMutation<TVars>(fn: (vars: TVars) => Promise<Bill>) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: fn,
    onSuccess: async (bill) => {
      qc.setQueryData(queryKeys.bill(bill.id), bill);
      await invalidateSubscriptionData(qc);
    },
  });
}

export const usePayWithPix = () => useBillMutation((billId: string) => paymentsApi.payPix(billId));
export const usePayWithCurrentCard = () => useBillMutation((billId: string) => paymentsApi.payCurrentCard(billId));
export const usePayWithNewCard = () =>
  useBillMutation(({ billId, body }: { billId: string; body: PayWithNewCardRequest }) =>
    paymentsApi.payNewCard(billId, body),
  );

export function useQuoteAddress() {
  return useMutation({ mutationFn: (body: AddressQuoteRequest) => shippingApi.quote(body) });
}

export function useUpdateAddress() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (body: UpdateAddressRequest) => shippingApi.update(body),
    onSuccess: async (address) => {
      qc.setQueryData(queryKeys.shippingAddress, address);
      await invalidateSubscriptionData(qc);
    },
  });
}

export function useUpdateNotificationPreferences() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (body: Partial<NotificationPreferences>) => deviceApi.updateNotificationPreferences(body),
    onMutate: async (patch) => {
      await qc.cancelQueries({ queryKey: queryKeys.notificationPreferences });
      const previous = qc.getQueryData<NotificationPreferences>(queryKeys.notificationPreferences);
      if (previous) qc.setQueryData(queryKeys.notificationPreferences, { ...previous, ...patch });
      return { previous };
    },
    onError: (_e, _v, ctx) => {
      if (ctx?.previous) qc.setQueryData(queryKeys.notificationPreferences, ctx.previous);
    },
    onSuccess: (data) => qc.setQueryData(queryKeys.notificationPreferences, data),
  });
}

export function useDeleteAccountRequest() {
  return useMutation({ mutationFn: (reason?: string) => meApi.deleteRequest(reason) });
}
