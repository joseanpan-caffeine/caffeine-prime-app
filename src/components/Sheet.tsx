import type { ReactNode } from 'react';
import { KeyboardAvoidingView, Modal, Platform, Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { colors, radius, space } from '@/theme';
import { Text } from './Text';

interface SheetProps {
  visible: boolean;
  onClose: () => void;
  title?: string;
  children: ReactNode;
  /** Altura máxima em fração da tela (padrão 0.85). */
  maxHeight?: number;
  /** Sem painel branco: os filhos desenham seus próprios grupos (menu de ação do Figma). */
  plain?: boolean;
}

/** Bottom sheet simples via Modal (sem dependências nativas). */
export function Sheet({ visible, onClose, title, children, maxHeight = 0.85, plain = false }: SheetProps) {
  const insets = useSafeAreaInsets();
  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose} statusBarTranslucent>
      <View style={styles.backdropWrap}>
        <Pressable style={styles.backdrop} onPress={onClose} accessibilityLabel="Fechar" />
        <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
          <View style={[plain ? styles.plain : styles.sheet, { paddingBottom: Math.max(insets.bottom, space(4)), maxHeight: `${maxHeight * 100}%` }]}>
            {!plain ? <View style={styles.handle} /> : null}
            {title ? (
              <View style={styles.header}>
                <Text variant="heading" tone={plain ? 'onDark' : 'default'}>
                  {title}
                </Text>
                {!plain ? (
                  <Pressable onPress={onClose} hitSlop={12} accessibilityRole="button" accessibilityLabel="Fechar">
                    <Ionicons name="close" size={22} color={colors.text} />
                  </Pressable>
                ) : null}
              </View>
            ) : null}
            <ScrollView keyboardShouldPersistTaps="handled" contentContainerStyle={styles.content}>
              {children}
            </ScrollView>
          </View>
        </KeyboardAvoidingView>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdropWrap: { flex: 1, justifyContent: 'flex-end', backgroundColor: colors.overlay },
  backdrop: { position: 'absolute', top: 0, left: 0, right: 0, bottom: 0 },
  sheet: {
    backgroundColor: colors.surface,
    borderTopLeftRadius: radius.lg,
    borderTopRightRadius: radius.lg,
    paddingHorizontal: space(4),
    paddingTop: space(2),
  },
  plain: { paddingHorizontal: space(3), paddingTop: space(2) },
  handle: { alignSelf: 'center', width: 40, height: 4, borderRadius: 2, backgroundColor: colors.borderStrong, marginBottom: space(3) },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: space(3) },
  content: { paddingBottom: space(2) },
});
