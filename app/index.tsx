import { Redirect } from 'expo-router';
import { ActivityIndicator, StyleSheet, View } from 'react-native';
import { useAuthStore } from '@/store/auth';
import { colors } from '@/theme';

export default function Index() {
  const status = useAuthStore((s) => s.status);
  if (status === 'booting') {
    return (
      <View style={styles.root}>
        <ActivityIndicator color={colors.gold} />
      </View>
    );
  }
  return <Redirect href={status === 'signedIn' ? '/(tabs)' : '/(auth)/welcome'} />;
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.background, alignItems: 'center', justifyContent: 'center' },
});
