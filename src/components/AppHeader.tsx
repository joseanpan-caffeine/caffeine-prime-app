import { Pressable, StyleSheet, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { colors, space } from '@/theme';
import { Logo } from './Logo';

interface AppHeaderProps {
  onMenu?: () => void;
  onProfile?: () => void;
  /** Sem safe-area no topo (quando já há header nativo). */
  safeTop?: boolean;
}

/** Header branco do Figma: menu à esquerda, logo centralizada, ícone de perfil à direita. */
export function AppHeader({ onMenu, onProfile, safeTop = true }: AppHeaderProps) {
  const insets = useSafeAreaInsets();
  return (
    <View style={[styles.root, { paddingTop: safeTop ? insets.top + space(2) : space(2) }]}>
      <Pressable onPress={onMenu} hitSlop={10} accessibilityRole="button" accessibilityLabel="Menu" style={styles.side}>
        <Ionicons name="menu-outline" size={26} color={colors.text} />
      </Pressable>
      <Logo variant="dark" width={170} />
      <Pressable onPress={onProfile} hitSlop={10} accessibilityRole="button" accessibilityLabel="Perfil" style={[styles.side, styles.right]}>
        <Ionicons name="person-outline" size={22} color={colors.text} />
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: colors.surface,
    paddingHorizontal: space(4),
    paddingBottom: space(3),
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  side: { width: 40, height: 40, justifyContent: 'center' },
  right: { alignItems: 'flex-end' },
});
