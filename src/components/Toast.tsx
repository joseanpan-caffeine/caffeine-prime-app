import { useEffect, useState } from 'react';
import { Animated, Pressable, StyleSheet, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { create } from 'zustand';
import { colors, radius, shadows, space } from '@/theme';
import { Text } from './Text';

export type ToastKind = 'info' | 'success' | 'error';
interface ToastItem {
  id: number;
  message: string;
  kind: ToastKind;
  title?: string;
}

interface ToastState {
  current: ToastItem | null;
  show: (message: string, kind?: ToastKind, title?: string) => void;
  hide: () => void;
}

let seq = 0;
export const useToastStore = create<ToastState>((set) => ({
  current: null,
  show: (message, kind = 'info', title) => set({ current: { id: ++seq, message, kind, title } }),
  hide: () => set({ current: null }),
}));

export const toast = {
  info: (m: string) => useToastStore.getState().show(m, 'info'),
  success: (m: string) => useToastStore.getState().show(m, 'success'),
  error: (m: string) => useToastStore.getState().show(m, 'error', 'Algo deu errado.'),
};

/** Toast do Figma: branco com sombra, ícone verde (ok) ou vermelho (erro) + título bold + texto. */
export function ToastHost() {
  const current = useToastStore((s) => s.current);
  const hide = useToastStore((s) => s.hide);
  const insets = useSafeAreaInsets();
  const [anim] = useState(() => new Animated.Value(0));

  useEffect(() => {
    if (!current) return;
    anim.setValue(0);
    Animated.spring(anim, { toValue: 1, useNativeDriver: true, speed: 20, bounciness: 6 }).start();
    const t = setTimeout(() => {
      Animated.timing(anim, { toValue: 0, duration: 200, useNativeDriver: true }).start(() => hide());
    }, current.kind === 'error' ? 4500 : 3000);
    return () => clearTimeout(t);
  }, [current, anim, hide]);

  if (!current) return null;
  const isError = current.kind === 'error';
  const iconBg = isError ? colors.danger : current.kind === 'success' ? colors.success : colors.gold;
  const iconName = isError ? 'close' : current.kind === 'success' ? 'checkmark' : 'information';
  return (
    <Animated.View
      pointerEvents="box-none"
      style={[
        styles.wrap,
        { top: insets.top + space(2), opacity: anim, transform: [{ translateY: anim.interpolate({ inputRange: [0, 1], outputRange: [-20, 0] }) }] },
      ]}
    >
      <Pressable onPress={hide} style={[styles.toast, shadows.float, isError && styles.toastError]} accessibilityRole="alert">
        <View style={[styles.icon, { backgroundColor: iconBg }]}>
          <Ionicons name={iconName} size={14} color="#FFFFFF" />
        </View>
        <View style={styles.text}>
          {current.title ? (
            <Text variant="bodyStrong" tone={isError ? 'danger' : 'default'}>
              {current.title}
            </Text>
          ) : null}
          <Text variant="body">{current.message}</Text>
        </View>
      </Pressable>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  wrap: { position: 'absolute', left: space(4), right: space(4), zIndex: 100, alignItems: 'center' },
  toast: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: space(3),
    backgroundColor: colors.surface,
    borderRadius: radius.sm,
    paddingVertical: space(3),
    paddingHorizontal: space(4),
    alignSelf: 'stretch',
  },
  toastError: { backgroundColor: colors.dangerCard },
  icon: { width: 22, height: 22, borderRadius: 11, alignItems: 'center', justifyContent: 'center', marginTop: 1 },
  text: { flex: 1, gap: 2 },
});
