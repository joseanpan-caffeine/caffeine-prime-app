/** Deep link caffeineprime://auth/magic/:token → troca o token por sessão. */
import { useEffect, useRef, useState } from 'react';
import { ActivityIndicator, StyleSheet, View } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useQueryClient } from '@tanstack/react-query';
import { errorMessage } from '@/api/client';
import { authApi } from '@/api/endpoints';
import { Button, Screen, Text } from '@/components';
import { getDeviceName } from '@/lib/deviceName';
import { completeSignIn } from '@/lib/session';
import { colors, space } from '@/theme';

export default function MagicExchange() {
  const { token } = useLocalSearchParams<{ token: string }>();
  const router = useRouter();
  const qc = useQueryClient();
  const [error, setError] = useState<string | null>(null);
  const started = useRef(false);

  useEffect(() => {
    if (!token || started.current) return;
    started.current = true;
    authApi
      .magicLinkExchange({ token, deviceName: getDeviceName() })
      .then((res) => completeSignIn(res, qc))
      .then(() => router.replace('/'))
      .catch((e) => setError(errorMessage(e, 'Link inválido ou expirado.')));
  }, [token, qc, router]);

  return (
    <Screen scroll={false} safeTop>
      <View style={styles.center}>
        {error ? (
          <>
            <Text variant="heading" center>
              Não foi possível entrar
            </Text>
            <Text variant="small" tone="muted" center>
              {error}
            </Text>
            <Button title="Pedir um novo link" onPress={() => router.replace('/(auth)/magic-link')} style={styles.btn} />
          </>
        ) : (
          <>
            <ActivityIndicator color={colors.accent} />
            <Text variant="small" tone="muted">
              Validando seu link…
            </Text>
          </>
        )}
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: space(3) },
  btn: { marginTop: space(4), minWidth: 220 },
});
