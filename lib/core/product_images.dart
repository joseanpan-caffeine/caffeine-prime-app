/// Mapeia handle/título de produto para uma imagem embutida, usada como
/// fallback quando `imageUrl` é nulo ou falha ao carregar.
///
/// Não é uma lista oficial de produtos (contexto-prime.md §12: nada fixo no app):
/// é só um conjunto de ilustrações genéricas por família/sabor/tamanho.
class ProductImages {
  ProductImages._();

  static const String base = 'assets/products/';

  static const String supercoffeeOriginal220 = '${base}supercoffee-original-220.png';
  static const String supercoffeeOriginal380 = '${base}supercoffee-original-380.png';
  static const String supercoffeeVanilla220 = '${base}supercoffee-vanilla-220.png';
  static const String supercoffeeVanilla380 = '${base}supercoffee-vanilla-380.png';
  static const String supercoffeeChocolate220 = '${base}supercoffee-chocolate-220.png';
  static const String supercoffeeChocolate380 = '${base}supercoffee-chocolate-380.png';
  static const String supercoffeeChoconilla380 = '${base}supercoffee-choconilla-380.png';
  static const String supercoffeeToGo = '${base}supercoffee-to-go.png';
  static const String supercoffeeToGoPacoca = '${base}supercoffee-to-go-pacoca.png';
  static const String morningShot = '${base}morning-shot.png';
  static const String whey = '${base}whey.png';
  static const String economicPack = '${base}economic-pack.png';

  /// Imagem genérica quando nada casa.
  static const String fallback = economicPack;

  static String _norm(String s) {
    return s
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('ã', 'a')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('_', '-');
  }

  /// Escolhe o asset mais provável a partir do handle e/ou título.
  static String forProduct({String? handle, String? title, String? flavor}) {
    final String h = _norm(handle ?? '');
    final String t = _norm('${title ?? ''} ${flavor ?? ''}');
    final String all = '$h $t';

    final bool isBig = all.contains('economic') || all.contains('380') || all.contains('economico');
    final bool isToGo = all.contains('to-go') || all.contains('to go') || all.contains('stick') || all.contains('sache');

    if (all.contains('morning') || all.contains('shot')) return morningShot;
    if (all.contains('whey') || all.contains('protein') || all.contains('proteina') || all.contains('creatin')) {
      return whey;
    }
    if (all.contains('koala')) return economicPack;

    if (all.contains('supercoffee') || all.contains('super coffee') || all.contains('coffee')) {
      if (isToGo) {
        if (all.contains('pacoca')) return supercoffeeToGoPacoca;
        return supercoffeeToGo;
      }
      if (all.contains('choconilla')) return supercoffeeChoconilla380;
      if (all.contains('chocolate') || all.contains('choco') || all.contains('cacau')) {
        return isBig ? supercoffeeChocolate380 : supercoffeeChocolate220;
      }
      if (all.contains('vanilla') || all.contains('baunilha')) {
        return isBig ? supercoffeeVanilla380 : supercoffeeVanilla220;
      }
      if (all.contains('original') || all.contains('tradicional')) {
        return isBig ? supercoffeeOriginal380 : supercoffeeOriginal220;
      }
      return isBig ? supercoffeeOriginal380 : supercoffeeOriginal220;
    }
    if (all.contains('pack') || all.contains('kit') || all.contains('combo')) return economicPack;
    return fallback;
  }
}
