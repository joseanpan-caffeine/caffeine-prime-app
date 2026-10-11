/**
 * Botões Google / Apple. Com EXPO_PUBLIC_FAKE_AUTH=1 abre um sheet pedindo o
 * e-mail e envia idToken "fake:<email>" para POST /auth/google|apple.
 */
import { useEffect, useState } from 'react';
import { Platform, StyleSheet, View } from 'react-native';
import { useQueryClient } from '@tanstack/react-query';
import * as Google from 'expo-auth-session/providers/google';
import * as WebBrowser from 'expo-web-browser';
import type { AuthResponse, SocialLoginRequest } from '@/api/contracts';
import { errorMessage } from '@/api/client';
import { authApi } from '@/api/endpoints';
import { Button, Input, Sheet, Text, toast } from '@/components';
import { FAKE_AUTH, GOOGLE_ANDROID_CLIENT_ID, GOOGLE_IOS_CLIENT_ID, GOOGLE_WEB_CLIENT_ID } from '@/lib/env';
import { getDeviceName } from '@/lib/deviceName';
import { completeSignIn } from '@/lib/session';
import { appleSignInRequest, fakeSocialRequest, isAppleSignInAvailable, SocialCanceledError } from '@/lib/socialAuth';
import { space } from '@/theme';

WebBrowser.maybeCompleteAuthSession();

type Provider = 'google' | 'apple';

export function SocialButtons() {
  const qc = useQueryClient();
  const [busy, setBusy] = useState<Provider | null>(null);
  const [fakeFor, setFakeFor] = useState<Provider | null>(null);
  const [fakeEmail, setFakeEmail] = useState('');
  const [appleAvailable, setAppleAvailable] = useState(false);

  const googleConfigured = !!(GOOGLE_IOS_CLIENT_ID || GOOGLE_ANDROID_CLIENT_ID || GOOGLE_WEB_CLIENT_ID);
  const [googleRequest, , promptGoogle] = Google.useIdTokenAuthRequest({
    iosClientId: GOOGLE_IOS_CLIENT_ID,
    androidClientId: GOOGLE_ANDROID_CLIENT_ID,
    webClientId: GOOGLE_WEB_CLIENT_ID,
    clientId: GOOGLE_WEB_CLIENT_ID ?? 'unset.apps.googleusercontent.com',
  });

  useEffect(() => {
    isAppleSignInAvailable().then(setAppleAvailable);
  }, []);

  async function finish(provider: Provider, body: SocialLoginRequest) {
    setBusy(provider);
    try {
      const res: AuthResponse = provider === 'google' ? await authApi.google(body) : await authApi.apple(body);
      await completeSignIn(res, qc);
    } catch (e) {
      toast.error(errorMessage(e, 'Não foi possível entrar.'));
    } finally {
      setBusy(null);
    }
  }

  async function onGoogle() {
    if (FAKE_AUTH) return setFakeFor('google');
    if (!googleConfigured || !googleRequest) {
      toast.info('Login com Google ainda não configurado (veja README).');
      return;
    }
    const result = await promptGoogle();
    if (result.type === 'success') {
      const idToken = result.params.id_token;
      if (idToken) await finish('google', { idToken, deviceName: getDeviceName() });
      else toast.error('O Google não devolveu um token.');
    } else if (result.type === 'error') {
      toast.error('Falha no login com Google.');
    }
  }

  async function onApple() {
    if (FAKE_AUTH) return setFakeFor('apple');
    try {
      const body = await appleSignInRequest();
      await finish('apple', body);
    } catch (e) {
      if (!(e instanceof SocialCanceledError)) toast.error(errorMessage(e, 'Falha no login com Apple.'));
    }
  }

  function submitFake() {
    const provider = fakeFor;
    if (!provider) return;
    if (!/^\S+@\S+\.\S+$/.test(fakeEmail.trim())) {
      toast.error('Informe um e-mail válido.');
      return;
    }
    setFakeFor(null);
    void finish(provider, fakeSocialRequest(fakeEmail));
  }

  const showApple = appleAvailable || FAKE_AUTH || Platform.OS === 'ios';

  return (
    <View style={styles.root}>
      <Button
        title="Continuar com Google"
        variant="secondary"
        onPress={onGoogle}
        loading={busy === 'google'}
        disabled={busy !== null}
        icon={<Text variant="bodyStrong">G</Text>}
      />
      {showApple ? (
        <Button
          title="Continuar com Apple"
          variant="secondary"
          onPress={onApple}
          loading={busy === 'apple'}
          disabled={busy !== null}
          icon={<Text variant="bodyStrong"></Text>}
        />
      ) : null}

      <Sheet visible={fakeFor !== null} onClose={() => setFakeFor(null)} title="Modo fake">
        <Text variant="small" tone="muted" style={styles.fakeHint}>
          EXPO_PUBLIC_FAKE_AUTH=1: o app envia idToken &quot;fake:&lt;email&gt;&quot; para /auth/{fakeFor}. Use uma das
          contas de teste (ex.: ativa@teste.com).
        </Text>
        <Input
          label="E-mail"
          autoCapitalize="none"
          autoCorrect={false}
          keyboardType="email-address"
          placeholder="ativa@teste.com"
          value={fakeEmail}
          onChangeText={setFakeEmail}
          onSubmitEditing={submitFake}
          returnKeyType="go"
        />
        <Button title="Entrar" onPress={submitFake} />
      </Sheet>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { gap: space(3) },
  fakeHint: { marginBottom: space(3) },
});
