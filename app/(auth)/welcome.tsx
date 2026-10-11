import { useRouter } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Button, Logo, Screen, Text } from '@/components';
import { colors, radius, space } from '@/theme';

export default function Welcome() {
  const router = useRouter();
  return (
    <Screen scroll={false} safeTop style={styles.root}>
      <View style={styles.hero}>
        <View style={styles.mark}>
          <Ionicons name="cube-outline" size={34} color={colors.gold} />
        </View>
        <Logo size="lg" />
        <Text variant="body" tone="secondary" center style={styles.lead}>
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
  root: { backgroundColor: colors.surface },
  hero: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: space(3) },
  mark: {
    width: 88,
    height: 88,
    borderRadius: radius.xl,
    backgroundColor: colors.subtle,
    borderWidth: 1,
    borderColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: space(2),
  },
  lead: { maxWidth: 300, marginTop: space(2) },
  actions: { gap: space(3) },
});
