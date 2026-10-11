import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { useQueryClient } from '@tanstack/react-query';
import { Controller, useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { errorMessage } from '@/api/client';
import { authApi, type MagicLinkResponse } from '@/api/endpoints';
import { Button, Card, EmptyState, Input, Screen, Text, toast } from '@/components';
import { getDeviceName } from '@/lib/deviceName';
import { FAKE_AUTH } from '@/lib/env';
import { completeSignIn } from '@/lib/session';
import { space, typography } from '@/theme';

const schema = z.object({ email: z.string().trim().email('Informe um e-mail válido') });
type FormValues = z.infer<typeof schema>;

export default function MagicLink() {
  const qc = useQueryClient();
  const [sending, setSending] = useState(false);
  const [sent, setSent] = useState<{ email: string; res: MagicLinkResponse } | null>(null);
  const [exchanging, setExchanging] = useState(false);
  const { control, handleSubmit, formState } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { email: FAKE_AUTH ? 'ativa@teste.com' : '' },
  });

  const onSubmit = handleSubmit(async ({ email }) => {
    setSending(true);
    try {
      const res = await authApi.magicLink({ email });
      setSent({ email, res });
    } catch (e) {
      toast.error(errorMessage(e, 'Não foi possível enviar o link.'));
    } finally {
      setSending(false);
    }
  });

  async function exchangeDebugToken(token: string) {
    setExchanging(true);
    try {
      const res = await authApi.magicLinkExchange({ token, deviceName: getDeviceName() });
      await completeSignIn(res, qc);
    } catch (e) {
      toast.error(errorMessage(e, 'Token inválido ou expirado.'));
    } finally {
      setExchanging(false);
    }
  }

  if (sent) {
    const debugToken = sent.res.debugToken;
    return (
      <Screen>
        <EmptyState
          icon="✉️"
          title="Verifique seu e-mail"
          description={`Enviamos um link de acesso para ${sent.email}. Abra pelo celular para entrar automaticamente. O link vale por alguns minutos.`}
          secondaryLabel="Enviar novamente"
          onSecondary={() => setSent(null)}
        />
        {FAKE_AUTH && debugToken ? (
          <Card title="Modo fake" subtitle="O BFF devolveu o token do link (debugToken).">
            <Text variant="mono" tone="accent" selectable style={styles.token}>
              {debugToken}
            </Text>
            <Button title="Usar este token" onPress={() => exchangeDebugToken(debugToken)} loading={exchanging} />
            <Text variant="caption" tone="dim" style={styles.deep}>
              Deep link equivalente: caffeineprime://auth/magic/{debugToken}
            </Text>
          </Card>
        ) : null}
      </Screen>
    );
  }

  return (
    <Screen keyboard title="Entrar sem senha" subtitle="Enviamos um link para o seu e-mail. Toque nele no celular e pronto.">
      <Controller
        control={control}
        name="email"
        render={({ field: { onChange, onBlur, value } }) => (
          <Input
            label="E-mail"
            value={value}
            onChangeText={onChange}
            onBlur={onBlur}
            autoCapitalize="none"
            autoCorrect={false}
            keyboardType="email-address"
            textContentType="emailAddress"
            onSubmitEditing={onSubmit}
            returnKeyType="send"
            error={formState.errors.email?.message}
          />
        )}
      />
      <View style={styles.actions}>
        <Button title="Enviar link" onPress={onSubmit} loading={sending} />
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  actions: { marginTop: space(2) },
  token: { ...typography.mono, marginBottom: space(3) },
  deep: { marginTop: space(2) },
});
