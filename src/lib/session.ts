import type { QueryClient } from '@tanstack/react-query';
import type { AuthResponse } from '@/api/contracts';
import { isApiError } from '@/api/client';
import { authApi, meApi } from '@/api/endpoints';
import { queryKeys } from '@/api/hooks';
import { useAuthStore } from '@/store/auth';
import { registerPushToken, unregisterPushToken } from './push';

/** Lê tokens, valida com GET /me e define o status da sessão. */
export async function bootstrapSession(): Promise<void> {
  const store = useAuthStore.getState();
  const { accessToken, refreshToken } = await store.hydrate();
  if (!accessToken && !refreshToken) {
    store.markSignedOut();
    return;
  }
  try {
    const user = await meApi.profile();
    store.setUser(user);
    void registerPushToken();
  } catch (e) {
    if (isApiError(e) && (e.status === 401 || e.status === 403)) {
      await store.clear();
    } else {
      // Rede fora: mantém os tokens e deixa o usuário entrar; as queries tentarão de novo.
      if (accessToken) store.setUser(store.user ?? { id: '', email: '', firstName: '', lastName: '', hasSubscription: true });
      else store.markSignedOut();
    }
  }
}

/** Aplica a resposta de qualquer rota /auth/* e registra o push. */
export async function completeSignIn(res: AuthResponse, qc?: QueryClient): Promise<void> {
  const { user, ...tokens } = res;
  await useAuthStore.getState().signIn(tokens, user);
  qc?.setQueryData(queryKeys.me, user);
  void registerPushToken();
}

export async function signOut(qc?: QueryClient): Promise<void> {
  const { refreshToken, clear } = useAuthStore.getState();
  try {
    await unregisterPushToken();
  } catch {
    // ignore
  }
  if (refreshToken) {
    try {
      await authApi.logout({ refreshToken });
    } catch {
      // revogação best-effort
    }
  }
  await clear();
  qc?.clear();
}
