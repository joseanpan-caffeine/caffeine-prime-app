import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../product_images.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Miniatura de produto: usa `imageUrl` quando houver e cai para o asset
/// embutido (ProductImages) quando nula ou falhar.
class ProductThumb extends StatelessWidget {
  const ProductThumb({
    super.key,
    this.imageUrl,
    this.handle,
    this.title,
    this.flavor,
    this.size = 72,
    this.quantity,
    this.radius = 8,
    this.background = AppColors.bgSubtle,
    this.showEditPencil = false,
  });

  final String? imageUrl;
  final String? handle;
  final String? title;
  final String? flavor;
  final double size;

  /// Badge de quantidade no canto (preto).
  final int? quantity;
  final double radius;
  final Color background;
  final bool showEditPencil;

  @override
  Widget build(BuildContext context) {
    final String fallback = ProductImages.forProduct(handle: handle, title: title, flavor: flavor);
    final Widget fallbackImage = Image.asset(fallback, fit: BoxFit.contain);

    Widget image;
    final String? url = imageUrl;
    if (url != null && url.isNotEmpty) {
      image = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        placeholder: (BuildContext c, String u) => fallbackImage,
        errorWidget: (BuildContext c, String u, Object e) => fallbackImage,
      );
    } else {
      image = fallbackImage;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius)),
              padding: EdgeInsets.all(size * 0.08),
              child: image,
            ),
          ),
          if (quantity != null)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.textPrimary, borderRadius: BorderRadius.circular(999)),
                child: Text('${quantity}x', style: AppTypography.badge.copyWith(color: Colors.white)),
              ),
            ),
          if (showEditPencil)
            const Positioned(
              right: -4,
              bottom: -4,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: AppColors.brandGold,
                child: Icon(Icons.edit, size: 11, color: AppColors.brandDark),
              ),
            ),
        ],
      ),
    );
  }
}
