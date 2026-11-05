import 'package:fl_lib/src/res/icons.dart';
import 'package:flutter/material.dart';

/// The app's back affordance, drawn with the shared Lucide family.
///
/// Material's [BackButton] hard-codes a Material arrow. Pages that need the
/// same navigation semantics should use this widget instead, so the whole app
/// keeps one icon language.
class FlBackButton extends StatelessWidget {
  const FlBackButton({super.key, this.onPressed, this.color});

  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      color: color,
      icon: const Icon(FlIcons.arrowBack),
    );
  }
}
