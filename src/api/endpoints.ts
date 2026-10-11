/** Funções tipadas por rota do BFF (ver ROUTES.md). */
import { http } from './client';
import type {
  AddCardRequest,
  AddressQuote,
  AddressQuoteRequest,
  AppConfig,
  AuthResponse,
  AuthTokens,
  Bill,
  CancelRequest,
  Catalog,
  Dashboard,
  Fulfillment,
  ItemRecurrence,
  LoginRequest,
  MagicLinkExchangeRequest,
  MagicLinkRequest,
  NotificationPreferences,
  PauseRequest,
  PaymentProfile,
  PayWithNewCardRequest,
  PricePreview,
  PreviewRequest,
  ReasonOption,
  RefreshRequest,
  RegisterDeviceRequest,
  RegisterRequest,
  ScheduledChange,
  SchedulingRequest,
  ShippingAddress,
  SocialLoginRequest,
  Subscription,
  UpdateAddressRequest,
  UpdateProfileRequest,
  UserProfile,
  VindiConfig,
} from './contracts';

/** Resposta de POST /auth/magic-link. `debugToken` é devolvido pelo BFF fake (suposição). */
export interface MagicLinkResponse {
  sent: boolean;
  debugToken?: string;
}

const noAuth = { auth: false } as const;

export const authApi = {
  login: (body: LoginRequest) => http.post<AuthResponse>('/auth/login', body, noAuth),
  google: (body: SocialLoginRequest) => http.post<AuthResponse>('/auth/google', body, noAuth),
  apple: (body: SocialLoginRequest) => http.post<AuthResponse>('/auth/apple', body, noAuth),
  magicLink: (body: MagicLinkRequest) => http.post<MagicLinkResponse>('/auth/magic-link', body, noAuth),
  magicLinkExchange: (body: MagicLinkExchangeRequest) =>
    http.post<AuthResponse>('/auth/magic-link/exchange', body, noAuth),
  register: (body: RegisterRequest) => http.post<AuthResponse>('/auth/register', body, noAuth),
  refresh: (body: RefreshRequest) => http.post<AuthTokens>('/auth/refresh', body, noAuth),
  logout: (body: RefreshRequest) => http.post<void>('/auth/logout', body),
};

export const meApi = {
  profile: () => http.get<UserProfile>('/me'),
  updateProfile: (body: UpdateProfileRequest) => http.patch<UserProfile>('/me/profile', body),
  dashboard: () => http.get<Dashboard>('/me/dashboard'),
  subscription: () => http.get<Subscription>('/me/subscription'),
  catalog: () => http.get<Catalog>('/me/catalog'),
  preview: (body: PreviewRequest, signal?: AbortSignal) =>
    http.post<PricePreview>('/me/subscription/preview', body, { signal, idempotent: false }),
  schedule: (body: SchedulingRequest) => http.post<ScheduledChange>('/me/subscription/scheduling', body),
  undoSchedule: () => http.delete<void>('/me/subscription/scheduling'),
  setItemRecurrence: (itemId: string, recurrence: ItemRecurrence) =>
    http.patch<Subscription>(`/me/subscription/items/${encodeURIComponent(itemId)}/recurrence`, { recurrence }),
  applyDiscount: (code: string) => http.patch<Subscription>('/me/subscription/discount', { code }),
  pause: (body: PauseRequest) => http.post<Subscription>('/me/subscription/pause', body),
  resume: () => http.post<Subscription>('/me/subscription/resume'),
  cancel: (body: CancelRequest) => http.post<Subscription>('/me/subscription/cancel', body),
  reactivate: () => http.post<Subscription>('/me/subscription/reactivate'),
  cancelReasons: () => http.get<ReasonOption[]>('/me/subscription/cancel-reasons'),
  pauseReasons: () => http.get<ReasonOption[]>('/me/subscription/pause-reasons'),
  savings: () => http.get<Dashboard['savings']>('/me/savings'),
  wallet: () => http.get<Dashboard['wallet']>('/me/wallet'),
  deleteRequest: (reason?: string) => http.post<void>('/me/delete-request', { reason }),
};

export const paymentsApi = {
  vindiConfig: () => http.get<VindiConfig>('/payments/vindi-config', noAuth),
  profiles: () => http.get<PaymentProfile[]>('/me/payment-profiles'),
  addCard: (body: AddCardRequest) => http.post<PaymentProfile>('/me/payment-profiles', body),
  removeCard: (id: string) => http.delete<void>(`/me/payment-profiles/${encodeURIComponent(id)}`),
  bills: () => http.get<Bill[]>('/me/bills'),
  bill: (billId: string) => http.get<Bill>(`/me/bills/${encodeURIComponent(billId)}`),
  payPix: (billId: string) => http.post<Bill>(`/me/bills/${encodeURIComponent(billId)}/pay/pix`),
  payCurrentCard: (billId: string) => http.post<Bill>(`/me/bills/${encodeURIComponent(billId)}/pay/current-card`),
  payNewCard: (billId: string, body: PayWithNewCardRequest) =>
    http.post<Bill>(`/me/bills/${encodeURIComponent(billId)}/pay/new-card`, body),
};

export const shippingApi = {
  address: () => http.get<ShippingAddress>('/me/shipping-address'),
  quote: (body: AddressQuoteRequest) => http.post<AddressQuote>('/me/shipping-address/quote', body, { idempotent: false }),
  update: (body: UpdateAddressRequest) => http.patch<ShippingAddress>('/me/shipping-address', body),
  tracking: () => http.get<Fulfillment>('/me/tracking'),
};

export const deviceApi = {
  register: (body: RegisterDeviceRequest) => http.post<{ id: string }>('/me/devices', body),
  remove: (id: string) => http.delete<void>(`/me/devices/${encodeURIComponent(id)}`),
  notificationPreferences: () => http.get<NotificationPreferences>('/me/notification-preferences'),
  updateNotificationPreferences: (body: Partial<NotificationPreferences>) =>
    http.patch<NotificationPreferences>('/me/notification-preferences', body),
  config: () => http.get<AppConfig>('/config', noAuth),
  health: () => http.get<{ status: 'ok' }>('/health', noAuth),
};
