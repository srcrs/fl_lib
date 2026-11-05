import 'package:fl_lib/src/view/widget/back_button.dart';
import 'package:flutter/material.dart';

/// An [AppBar] whose automatic leading control is the app's Lucide back
/// button instead of Material's hard-coded arrow.
///
/// A root page gets no leading control; a pushed page gets [FlBackButton].
/// Callers that pass [leading] keep full control.
class FlAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FlAppBar({
    super.key,
    this.title,
    this.actions,
    this.centerTitle,
    this.leading,
    this.leadingWidth,
    this.bottom,
    this.backgroundColor,
    this.titleTextStyle,
    this.elevation,
    this.scrolledUnderElevation,
    this.surfaceTintColor,
    this.shape,
  });

  final Widget? title;
  final List<Widget>? actions;
  final bool? centerTitle;
  final Widget? leading;
  final double? leadingWidth;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final TextStyle? titleTextStyle;
  final double? elevation;
  final double? scrolledUnderElevation;
  final Color? surfaceTintColor;
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return AppBar(
      automaticallyImplyLeading: false,
      leading: leading ?? (canPop ? const FlBackButton() : null),
      leadingWidth: leadingWidth,
      title: title,
      actions: actions,
      centerTitle: centerTitle,
      bottom: bottom,
      backgroundColor: backgroundColor,
      titleTextStyle: titleTextStyle,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
      surfaceTintColor: surfaceTintColor,
      shape: shape,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
