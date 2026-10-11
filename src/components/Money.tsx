import type { Money as MoneyValue } from '@/api/contracts';
import { formatMoney } from '@/lib/format';
import { Text, type TextProps } from './Text';

interface MoneyProps extends Omit<TextProps, 'children'> {
  value: MoneyValue | number | undefined | null;
  strike?: boolean;
}

export function Money({ value, strike, style, ...rest }: MoneyProps) {
  return (
    <Text {...rest} style={[strike && { textDecorationLine: 'line-through' }, style]}>
      {formatMoney(value)}
    </Text>
  );
}
