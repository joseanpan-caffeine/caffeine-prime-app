import type { ReactNode, RefObject } from 'react';
import {
  KeyboardAvoidingView,
  Platform,
  RefreshControl,
  ScrollView,
  StyleSheet,
  View,
  type ViewStyle,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { colors, space } from '@/theme';
import { Text } from './Text';

interface ScreenProps {
  children: ReactNode;
  /** Rola o conteúdo (padrão: true). */
  scroll?: boolean;
  title?: string;
  subtitle?: string;
  /** Conteúdo fixo acima do conteúdo rolável (ex.: cabeçalho). */
  header?: ReactNode;
  /** Barra fixa no rodapé (ex.: CTA). */
  footer?: ReactNode;
  refreshing?: boolean;
  onRefresh?: () => void;
  padded?: boolean;
  style?: ViewStyle;
  contentStyle?: ViewStyle;
  /** Considera a safe area no topo (use em telas sem header nativo). */
  safeTop?: boolean;
  keyboard?: boolean;
  /** Ref do ScrollView (para rolar até âncoras). */
  scrollRef?: RefObject<ScrollView | null>;
}

export function Screen({
  children,
  scroll = true,
  title,
  subtitle,
  header,
  footer,
  refreshing,
  onRefresh,
  padded = true,
  style,
  contentStyle,
  safeTop = false,
  keyboard = false,
  scrollRef,
}: ScreenProps) {
  const insets = useSafeAreaInsets();
  const paddingTop = safeTop ? insets.top + space(3) : space(3);
  const paddingBottom = (footer ? space(3) : insets.bottom + space(6)) + space(2);

  const heading = (title || subtitle) && (
    <View style={styles.heading}>
      {title ? <Text variant="title">{title}</Text> : null}
      {subtitle ? (
        <Text variant="small" tone="muted" style={styles.subtitle}>
          {subtitle}
        </Text>
      ) : null}
    </View>
  );

  const body = scroll ? (
    <ScrollView
      ref={scrollRef}
      style={styles.flex}
      contentContainerStyle={[
        padded && styles.padded,
        { paddingTop, paddingBottom },
        contentStyle,
      ]}
      keyboardShouldPersistTaps="handled"
      refreshControl={
        onRefresh ? (
          <RefreshControl refreshing={!!refreshing} onRefresh={onRefresh} tintColor={colors.gold} colors={[colors.gold]} />
        ) : undefined
      }
    >
      {heading}
      {children}
    </ScrollView>
  ) : (
    <View style={[styles.flex, padded && styles.padded, { paddingTop, paddingBottom }, contentStyle]}>
      {heading}
      {children}
    </View>
  );

  const content = keyboard ? (
    <KeyboardAvoidingView style={styles.flex} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
      {body}
    </KeyboardAvoidingView>
  ) : (
    body
  );

  return (
    <View style={[styles.root, style]}>
      {header}
      {content}
      {footer ? (
        <View style={[styles.footer, { paddingBottom: Math.max(insets.bottom, space(3)) }]}>{footer}</View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.background },
  flex: { flex: 1 },
  padded: { paddingHorizontal: space(4) },
  heading: { marginBottom: space(4), gap: space(1) },
  subtitle: {},
  footer: {
    paddingHorizontal: space(4),
    paddingTop: space(3),
    borderTopWidth: 1,
    borderTopColor: colors.border,
    backgroundColor: colors.surface,
  },
});
