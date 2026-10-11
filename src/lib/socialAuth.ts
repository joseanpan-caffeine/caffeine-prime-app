/**
 * Login social. Em FAKE_AUTH os botões enviam idToken "fake:<email>" (ver ROUTES.md).
 */
import { Platform } from 'react-native';
import * as AppleAuthentication from 'expo-apple-authentication';
import type { SocialLoginRequest } from '@/api/contracts';
import { getDeviceName } from './deviceName';
import { FAKE_AUTH } from './env';

export function fakeSocialRequest(email: string): SocialLoginRequest {
  return { idToken: `fake:${email.trim().toLowerCase()}`, deviceName: getDeviceName() };
}

export async function isAppleSignInAvailable(): Promise<boolean> {
  if (FAKE_AUTH) return true;
  if (Platform.OS !== 'ios') return false;
  try {
    return await AppleAuthentication.isAvailableAsync();
  } catch {
    return false;
  }
}

export class SocialCanceledError extends Error {
  constructor() {
    super('canceled');
    this.name = 'SocialCanceledError';
  }
}

/** Fluxo Apple real: devolve o corpo pronto para POST /auth/apple. */
export async function appleSignInRequest(): Promise<SocialLoginRequest> {
  try {
    const credential = await AppleAuthentication.signInAsync({
      requestedScopes: [
        AppleAuthentication.AppleAuthenticationScope.FULL_NAME,
        AppleAuthentication.AppleAuthenticationScope.EMAIL,
      ],
    });
    if (!credential.identityToken) throw new Error('A Apple não devolveu um token.');
    const name = [credential.fullName?.givenName, credential.fullName?.familyName].filter(Boolean).join(' ');
    return { idToken: credential.identityToken, fullName: name || undefined, deviceName: getDeviceName() };
  } catch (e) {
    if (e && typeof e === 'object' && 'code' in e && (e as { code?: string }).code === 'ERR_REQUEST_CANCELED') {
      throw new SocialCanceledError();
    }
    throw e;
  }
}
