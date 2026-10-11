import { useRef, useState, type ReactNode } from 'react';
import { Pressable, ScrollView, StyleSheet, View, type NativeScrollEvent, type NativeSyntheticEvent } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, space } from '@/theme';
import { type IoniconName } from './IconCircle';
import { Text } from './Text';

interface SectionHeaderProps {
  icon?: IoniconName;
  iconNode?: ReactNode;
  title: string;
  subtitle?: string;
  right?: ReactNode;
}

/** Título de seção com ícone dourado + subtítulo (ex.: "Minhas próximas caixas"). */
export function SectionHeader({ icon, iconNode, title, subtitle, right }: SectionHeaderProps) {
  return (
    <View style={styles.header}>
      <View style={styles.headerIcon}>{iconNode ?? (icon ? <Ionicons name={icon} size={22} color={colors.gold} /> : null)}</View>
      <View style={styles.headerText}>
        <Text variant="subheading">{title}</Text>
        {subtitle ? (
          <Text variant="small" tone="secondary">
            {subtitle}
          </Text>
        ) : null}
      </View>
      {right}
    </View>
  );
}

interface CarouselProps {
  children: ReactNode[];
  /** Largura de cada item + gap, usado para rolar com as setas. */
  itemWidth: number;
  gap?: number;
  title?: string;
  subtitle?: string;
  icon?: IoniconName;
  iconNode?: ReactNode;
  arrows?: boolean;
  /** Padding lateral do conteúdo (para alinhar com a margem da tela). */
  inset?: number;
}

/** Carrossel horizontal com cabeçalho e setas ‹ › (círculo cinza / círculo preto). */
export function Carousel({ children, itemWidth, gap = space(3), title, subtitle, icon, iconNode, arrows = true, inset = 0 }: CarouselProps) {
  const ref = useRef<ScrollView>(null);
  const [index, setIndex] = useState(0);
  const count = children.length;
  const step = itemWidth + gap;

  function go(next: number) {
    const i = Math.max(0, Math.min(count - 1, next));
    setIndex(i);
    ref.current?.scrollTo({ x: i * step, animated: true });
  }

  function onScrollEnd(e: NativeSyntheticEvent<NativeScrollEvent>) {
    const i = Math.round(e.nativeEvent.contentOffset.x / step);
    setIndex(Math.max(0, Math.min(count - 1, i)));
  }

  const canPrev = index > 0;
  const canNext = index < count - 1;

  const right =
    arrows && count > 1 ? (
      <View style={styles.arrows}>
        <Pressable onPress={() => go(index - 1)} disabled={!canPrev} accessibilityRole="button" accessibilityLabel="Anterior" style={[styles.arrow, canPrev ? styles.arrowOn : styles.arrowOff]}>
          <Ionicons name="arrow-back" size={18} color={canPrev ? '#FFFFFF' : colors.textMuted} />
        </Pressable>
        <Pressable onPress={() => go(index + 1)} disabled={!canNext} accessibilityRole="button" accessibilityLabel="Próximo" style={[styles.arrow, canNext ? styles.arrowOn : styles.arrowOff]}>
          <Ionicons name="arrow-forward" size={18} color={canNext ? '#FFFFFF' : colors.textMuted} />
        </Pressable>
      </View>
    ) : null;

  return (
    <View style={styles.root}>
      {title ? <SectionHeader icon={icon} iconNode={iconNode} title={title} subtitle={subtitle} right={right} /> : null}
      <ScrollView
        ref={ref}
        horizontal
        showsHorizontalScrollIndicator={false}
        snapToInterval={step}
        decelerationRate="fast"
        onMomentumScrollEnd={onScrollEnd}
        contentContainerStyle={[styles.content, { gap, paddingHorizontal: inset }]}
        style={inset ? { marginHorizontal: -inset } : undefined}
      >
        {children.map((child, i) => (
          <View key={i} style={{ width: itemWidth }}>
            {child}
          </View>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { marginBottom: space(3) },
  header: { flexDirection: 'row', alignItems: 'center', gap: space(2), marginBottom: space(3) },
  headerIcon: { width: 26, alignItems: 'center' },
  headerText: { flex: 1, gap: 2 },
  arrows: { flexDirection: 'row', gap: space(2) },
  arrow: { width: 36, height: 36, borderRadius: radius.pill, alignItems: 'center', justifyContent: 'center' },
  arrowOn: { backgroundColor: colors.text },
  arrowOff: { backgroundColor: colors.muted },
  content: { paddingBottom: 2 },
});
