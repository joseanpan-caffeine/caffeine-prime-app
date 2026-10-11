/**
 * Cliente HTTP do BFF: base URL, bearer token, refresh automático em 401
 * (single-flight), Idempotency-Key em mutações e erros tipados (ApiError).
 */
import * as Crypto from 'expo-crypto';
import type { ApiError as ApiErrorBody, AuthTokens } from './contracts';
import { API_URL } from '@/lib/env';
import { useAuthStore } from '@/store/auth';

export class ApiError extends Error {
  readonly code: string;
  readonly status: number;
  readonly details?: unknown;

  constructor(status: number, body: Partial<ApiErrorBody> | null, fallback?: string) {
    super(body?.message ?? fallback ?? `Erro ${status}`);
    this.name = 'ApiError';
    this.status = status;
    this.code = body?.code ?? (status === 0 ? 'NETWORK_ERROR' : `HTTP_${status}`);
    this.details = body?.details;
  }

  get isNetwork(): boolean {
    return this.status === 0;
  }
}

export function isApiError(e: unknown): e is ApiError {
  return e instanceof ApiError;
}

export function errorMessage(e: unknown, fallback = 'Algo deu errado. Tente novamente.'): string {
  if (isApiError(e)) {
    if (e.isNetwork) return 'Sem conexão com o servidor. Verifique sua internet.';
    return e.message || fallback;
  }
  if (e instanceof Error && e.message) return e.message;
  return fallback;
}

type Method = 'GET' | 'POST' | 'PATCH' | 'PUT' | 'DELETE';

export interface RequestOptions {
  method?: Method;
  body?: unknown;
  /** Envia Authorization (padrão: true). */
  auth?: boolean;
  /** Gera Idempotency-Key (padrão: true para mutações). */
  idempotent?: boolean;
  headers?: Record<string, string>;
  signal?: AbortSignal;
  /** Uso interno: evita loop de refresh. */
  _retried?: boolean;
}

const JSON_HEADERS = { Accept: 'application/json', 'Content-Type': 'application/json' };

function uuid(): string {
  try {
    return Crypto.randomUUID();
  } catch {
    return `${Date.now().toString(16)}-${Math.random().toString(16).slice(2)}`;
  }
}

let refreshInFlight: Promise<AuthTokens | null> | null = null;

/** Troca o refresh token por novos tokens. Single-flight: chamadas concorrentes compartilham a mesma promessa. */
export function refreshSession(): Promise<AuthTokens | null> {
  if (refreshInFlight) return refreshInFlight;
  refreshInFlight = (async () => {
    const { refreshToken, setTokens, clear } = useAuthStore.getState();
    if (!refreshToken) {
      await clear();
      return null;
    }
    try {
      const res = await fetch(`${API_URL}/auth/refresh`, {
        method: 'POST',
        headers: JSON_HEADERS,
        body: JSON.stringify({ refreshToken }),
      });
      if (!res.ok) {
        await clear();
        return null;
      }
      const tokens = (await res.json()) as AuthTokens;
      await setTokens(tokens);
      return tokens;
    } catch {
      // Erro de rede: mantém a sessão para tentar depois.
      return null;
    } finally {
      refreshInFlight = null;
    }
  })();
  return refreshInFlight;
}

async function parseBody(res: Response): Promise<unknown> {
  if (res.status === 204) return undefined;
  const text = await res.text();
  if (!text) return undefined;
  try {
    return JSON.parse(text) as unknown;
  } catch {
    return text;
  }
}

export async function request<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const method: Method = options.method ?? 'GET';
  const auth = options.auth ?? true;
  const isMutation = method !== 'GET';
  const headers: Record<string, string> = { ...JSON_HEADERS, ...options.headers };

  if (auth) {
    const token = useAuthStore.getState().accessToken;
    if (token) headers.Authorization = `Bearer ${token}`;
  }
  if (isMutation && (options.idempotent ?? true) && !headers['Idempotency-Key']) {
    headers['Idempotency-Key'] = uuid();
  }

  let res: Response;
  try {
    res = await fetch(`${API_URL}${path}`, {
      method,
      headers,
      body: options.body === undefined ? undefined : JSON.stringify(options.body),
      signal: options.signal,
    });
  } catch (e) {
    throw new ApiError(0, null, e instanceof Error ? e.message : 'Falha de rede');
  }

  if (res.status === 401 && auth && !options._retried && !path.startsWith('/auth/')) {
    const tokens = await refreshSession();
    if (tokens) return request<T>(path, { ...options, _retried: true });
    const body = (await parseBody(res)) as Partial<ApiErrorBody> | null;
    throw new ApiError(401, typeof body === 'object' ? body : null, 'Sessão expirada');
  }

  const data = await parseBody(res);
  if (!res.ok) {
    const body = data && typeof data === 'object' ? (data as Partial<ApiErrorBody>) : null;
    throw new ApiError(res.status, body, typeof data === 'string' ? data : undefined);
  }
  return data as T;
}

export const http = {
  get: <T>(path: string, o?: RequestOptions) => request<T>(path, { ...o, method: 'GET' }),
  post: <T>(path: string, body?: unknown, o?: RequestOptions) => request<T>(path, { ...o, method: 'POST', body }),
  patch: <T>(path: string, body?: unknown, o?: RequestOptions) => request<T>(path, { ...o, method: 'PATCH', body }),
  delete: <T>(path: string, o?: RequestOptions) => request<T>(path, { ...o, method: 'DELETE' }),
};
