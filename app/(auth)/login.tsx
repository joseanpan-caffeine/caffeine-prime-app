import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { useRouter } from 'expo-router';
import { useQueryClient } from '@tanstack/react-query';
import { Controller, useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { errorMessage } from '@/api/client';
import { authApi } from '@/api/endpoints';
import { Button, Input, Logo, Screen, Text, toast } from '@/components';
import { SocialButtons } from '@/features/auth/SocialButtons';
import { getDeviceName } from '@/lib/deviceName';
import { FAKE_AUTH } from '@/lib/env';
import { completeSignIn } from '@/lib/session';
import { colors, space } from '@/theme';

const schema = z.object({
  email: z.string().trim().email('Informe um e-mail válido'),
  password: z.string().min(6, 'Mínimo de 6 caracteres'),
});
type FormValues = z.infer<typeof schema>;

export default function Login() {
  const router = useRouter();
  const qc = useQueryClient();
  const [submitting, setSubmitting] = useState(false);
  const { control, handleSubmit, formState } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { email: FAKE_AUTH ? 'ativa@teste.com' : '', password: FAKE_AUTH ? 'prime123' : '' },
  });

  const onSubmit = handleSubmit(async (values) => {
    setSubmitting(true);
    try {
      const res = await authApi.login({ ...values, deviceName: getDeviceName() });
      await completeSignIn(res, qc);
    } catch (e) {
      toast.error(errorMessage(e, 'E-mail ou senha incorretos.'));
    } finally {
      setSubmitting(false);
    }
  });

  return (
    <Screen keyboard style={styles.root}>
      <Logo variant="dark" width={220} style={styles.logo} />
      <Text variant="title">Bem-vindo de volta</Text>
      <Text variant="body" tone="secondary" style={styles.subtitle}>
        Entre com a mesma conta da loja Caffeine Army.
      </Text>
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
            autoComplete="email"
            error={formState.errors.email?.message}
          />
        )}
      />
      <Controller
        control={control}
        name="password"
        render={({ field: { onChange, onBlur, value } }) => (
          <Input
            label="Senha"
            value={value}
            onChangeText={onChange}
            onBlur={onBlur}
            secureTextEntry
            textContentType="password"
            autoComplete="password"
            onSubmitEditing={onSubmit}
            returnKeyType="go"
            error={formState.errors.password?.message}
          />
        )}
      />
      <Button title="Entrar" onPress={onSubmit} loading={submitting} />
      <Button title="Entrar com link por e-mail" variant="ghost" onPress={() => router.push('/(auth)/magic-link')} />

      <View style={styles.divider}>
        <View style={styles.line} />
        <Text variant="caption" tone="dim">
          OU
        </Text>
        <View style={styles.line} />
      </View>

      <SocialButtons />

      <View style={styles.footer}>
        <Text variant="small" tone="muted">
          Ainda não tem conta?
        </Text>
        <Button title="Criar conta" variant="ghost" size="sm" full={false} onPress={() => router.push('/(auth)/register')} />
      </View>
      {FAKE_AUTH ? (
        <Text variant="caption" tone="dim" center style={styles.fake}>
          Modo fake ativo. Contas: ativa, janela, pausada, pendente, agendada, cancelada, analise, mensal, semassinatura
          @teste.com — senha prime123.
        </Text>
      ) : null}
    </Screen>
  );
}

const styles = StyleSheet.create({
  root: { backgroundColor: colors.surface },
  logo: { alignSelf: 'center', marginBottom: space(6) },
  subtitle: { marginBottom: space(5), marginTop: space(1) },
  divider: { flexDirection: 'row', alignItems: 'center', gap: space(3), marginVertical: space(5) },
  line: { flex: 1, height: 1, backgroundColor: colors.borderStrong },
  footer: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', marginTop: space(6), gap: space(1) },
  fake: { marginTop: space(4) },
});
