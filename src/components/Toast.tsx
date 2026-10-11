import { useEffect, useState } from 'react';
import { Animated, Pressable, StyleSheet } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { create } from 'zustand';
import { colors, radius, space } from '@/theme';
import { Text } from './Text';

export type ToastKind = 'info' | 'success' | 'error';
interface ToastItem {
  id: number;
  message: string;
  kind: ToastKind;
}

interface ToastState {
  current: ToastItem | null;
  show: (message: string, kind?: ToastKind) => void;
  hide: () => void;
}

let seq = 0;
export const useToastStore = create<ToastState>((set) => ({
  current: null,
  show: (message, kind = 'info') => set({ current: { id: ++seq, message, kind } }),
  hide: () => set({ current: null }),
}));

export const toast = {
  info: (m: string) => useToastStore.getState().show(m, 'info'),
  success: (m: string) => useToastStore.getState().show(m, 'success'),
  error: (m: string) => useToastStore.getState().show(m, 'error'),
};

const border: Record<ToastKind, string> = { info: colors.accent, success: colors.success, error: colors.danger };

/** Renderize uma vez no layout raiz. */
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
  return (
    <Animated.View
      pointerEvents="box-none"
      style={[
        styles.wrap,
        { top: insets.top + space(2), opacity: anim, transform: [{ translateY: anim.interpolate({ inputRange: [0, 1], outputRange: [-20, 0] }) }] },
      ]}
    >
      <Pressable onPress={hide} style={[styles.toast, { borderLeftColor: border[current.kind] }]} accessibilityRole="alert">
        <Text variant="small">{current.message}</Text>
      </Pressable>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  wrap: { position: 'absolute', left: space(4), right: space(4), zIndex: 100, alignItems: 'center' },
  toast: {
    backgroundColor: colors.surfaceElevated,
    borderRadius: radius.md,
    borderLeftWidth: 4,
    paddingVertical: space(3),
    paddingHorizontal: space(4),
    borderWidth: 1,
    borderColor: colors.borderStrong,
    alignSelf: 'stretch',
  },
});
