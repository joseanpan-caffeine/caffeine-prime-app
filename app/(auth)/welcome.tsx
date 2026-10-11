import { useRouter } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import { Button, Screen, Text } from '@/components';
import { colors, radius, space } from '@/theme';

export default function Welcome() {
  const router = useRouter();
  return (
    <Screen scroll={false} safeTop>
      <View style={styles.hero}>
        <View style={styles.logo}>
          <Text variant="display" tone="accent">
            P
          </Text>
        </View>
        <Text variant="caption" tone="accent" style={styles.kicker}>
          CAFFEINE ARMY
        </Text>
        <Text variant="display">Prime</Text>
        <Text variant="body" tone="muted" center style={styles.lead}>
          Gerencie sua assinatura, sua caixa e seus pagamentos em um só lugar.
        </Text>
      </View>
      <View style={styles.actions}>
        <Button title="Entrar" onPress={() => router.push('/(auth)/login')} />
        <Button title="Criar conta" variant="secondary" onPress={() => router.push('/(auth)/register')} />
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  hero: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: space(2) },
  logo: {
    width: 88,
    height: 88,
    borderRadius: radius.xl,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.accentDark,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: space(4),
  },
  kicker: { letterSpacing: 3 },
  lead: { maxWidth: 300, marginTop: space(2) },
  actions: { gap: space(3) },
});
