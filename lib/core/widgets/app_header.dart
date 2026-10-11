import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/tokens.dart';

/// Logo oficial "CAFFEINE ARMY PRIME" (SVG). `onDark` usa a versão branca.
class PrimeLogo extends StatelessWidget {
  const PrimeLogo({super.key, this.height = 20, this.onDark = false});

  final double height;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      onDark ? 'assets/brand/caffeine-prime-white.svg' : 'assets/brand/caffeine-prime.svg',
      height: height,
      fit: BoxFit.contain,
      semanticsLabel: 'Caffeine Army Prime',
    );
  }
}

/// Header branco: ação à esquerda, logo centralizada, ícone de perfil à direita.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key, this.onMenu, this.onProfile, this.leading});

  final VoidCallback? onMenu;
  final VoidCallback? onProfile;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bgSurface,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: leading ??
          (onMenu == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: onMenu,
                  tooltip: 'Menu',
                )),
      title: const PrimeLogo(height: 18),
      actions: <Widget>[
        if (onProfile != null)
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: onProfile,
            tooltip: 'Perfil',
          ),
      ],
    );
  }
}
