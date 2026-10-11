import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { colors, space } from '@/theme';
import { Text } from './Text';

interface CategoryTabsProps {
  tabs: { key: string; label: string }[];
  value: string;
  onChange: (key: string) => void;
}

/** Tabs de categoria: texto, ativa dourada com sublinhado dourado; linha base cinza. */
export function CategoryTabs({ tabs, value, onChange }: CategoryTabsProps) {
  return (
    <View style={styles.root}>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.content}>
        {tabs.map((t) => {
          const active = t.key === value;
          return (
            <Pressable key={t.key} onPress={() => onChange(t.key)} accessibilityRole="tab" accessibilityState={{ selected: active }} style={[styles.tab, active && styles.tabOn]}>
              <Text variant={active ? 'bodyStrong' : 'body'} tone={active ? 'gold' : 'dim'}>
                {t.label}
              </Text>
            </Pressable>
          );
        })}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { borderBottomWidth: 1, borderBottomColor: colors.borderStrong, marginBottom: space(3) },
  content: { gap: space(2), paddingRight: space(4) },
  tab: { paddingVertical: space(2.5), paddingHorizontal: space(2), borderBottomWidth: 2, borderBottomColor: 'transparent', marginBottom: -1 },
  tabOn: { borderBottomColor: colors.gold },
});
