import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

abstract final class FontUtils {
  /// Loads a font from a local file path.
  ///
  /// Derives the font name from the file name. Does nothing if the file or its
  /// name is unavailable.
  static Future<void> loadFrom(String localPath) async {
    final name = localPath.getFileName();
    if (name == null) return;
    final file = File(localPath);
    if (!await file.exists()) return;
    final fontLoader = FontLoader(name);
    fontLoader.addFont(file.readAsBytes().byteData);
    await fontLoader.load();
  }
}

/// Keeps a saved window position on a display that is still connected.
///
/// A laptop that was last used with an external monitor can otherwise reopen
/// the app at negative coordinates on a screen that is no longer there: the
/// process is healthy and the window exists, but nobody can see it. A position
/// is accepted when at least a strip of its title area overlaps a visible
/// work area; it is then nudged back inside that area. No overlap means the
/// caller should centre the window on the primary display instead.
Offset? clampWindowPosition({
  required Offset? position,
  required Size windowSize,
  required Iterable<Rect> visibleAreas,
}) {
  if (position == null) return null;
  const minVisibleWidth = 80.0;
  const minVisibleHeight = 44.0;
  for (final area in visibleAreas) {
    final probe = Rect.fromLTWH(
      position.dx,
      position.dy,
      windowSize.width,
      math.min(windowSize.height, minVisibleHeight),
    );
    if (!probe.overlaps(area)) continue;
    final maxX = math.max(
      area.left,
      area.right - math.min(windowSize.width, minVisibleWidth),
    );
    final maxY = math.max(
      area.top,
      area.bottom - math.min(windowSize.height, minVisibleHeight),
    );
    return Offset(
      position.dx.clamp(area.left, maxX).toDouble(),
      position.dy.clamp(area.top, maxY).toDouble(),
    );
  }
  return null;
}

/// Puts the window on the display the pointer is on.
///
/// A saved position is kept only when it is already on that display; one left
/// on a monitor that is switched off, mirrored away or no longer present is
/// discarded and the window is centred instead. The pointer is the useful
/// signal for "the display I am looking at" at launch time: the app is opened
/// from the Dock or a launcher on that display.
Offset? positionWindowOnDisplays({
  required Offset? savedPosition,
  required Size windowSize,
  required List<Rect> visibleAreas,
  required Offset? cursor,
}) {
  if (visibleAreas.isEmpty) return null;
  final preferred = cursor == null
      ? visibleAreas.first
      : visibleAreas.where((area) => area.contains(cursor)).firstOrNull ??
            visibleAreas.first;
  final clamped = clampWindowPosition(
    position: savedPosition,
    windowSize: windowSize,
    visibleAreas: [preferred],
  );
  if (clamped != null) return clamped;
  final x =
      preferred.left + math.max(0, (preferred.width - windowSize.width) / 2);
  final y =
      preferred.top + math.max(0, (preferred.height - windowSize.height) / 2);
  return Offset(x, y);
}

abstract final class SystemUIs {
  /// Enables edge-to-edge mode with a transparent navigation bar on Android.
  static void setTransparentNavigationBar(BuildContext context) {
    if (isAndroid) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ),
      );
    }
  }

  /// Shows or hides the system status bar.
  ///
  /// - [hide] if true, hides the status bar using immersive sticky mode.
  /// If false, shows the status bar using edge-to-edge mode.
  static void switchStatusBar({required bool hide}) {
    if (hide) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
    } else {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      );
    }
  }

  /// Initializes desktop window configuration.
  ///
  /// Only works on desktop platforms. On mobile platforms, this method does nothing.
  ///
  /// - [hideTitleBar] whether to hide the window title bar
  /// - [size] initial window size, if not provided uses default
  /// - [position] initial window position, if not provided centers the window
  /// - [listener] optional window event listener
  static Future<void> initDesktopWindow({
    required bool hideTitleBar,
    Size? size,
    Offset? position,
    Size minimumSize = const Size(300, 300),
    WindowListener? listener,
  }) async {
    if (!isDesktop) return;

    await windowManager.ensureInitialized();

    final windowSize = size ?? const Size(800, 600);
    final visibleAreas = await _visibleDisplayAreas();
    final visiblePosition = positionWindowOnDisplays(
      savedPosition: position,
      windowSize: windowSize,
      visibleAreas: visibleAreas,
      cursor: await _cursorPosition(),
    );

    final windowOptions = WindowOptions(
      center: visiblePosition == null,
      // Left alone on macOS, where the system title bar draws the window's
      // background: `window_manager` turns a transparent color into
      // `NSColor.clear`, and on macOS 27 a visible title bar with that
      // background is fully see-through (alpha 0 in a rendered frame, against
      // 1 with the default). The default, `windowBackgroundColor`, follows the
      // system appearance, as the title text drawn on it does. With the title
      // bar hidden the Flutter view covers that area, so nothing else shows it.
      backgroundColor: isMacOS ? null : Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: hideTitleBar ? TitleBarStyle.hidden : null,
      minimumSize: minimumSize,
      size: size,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (visiblePosition != null) {
        await windowManager.setPosition(visiblePosition);
      }
      await windowManager.show();
      // `waitUntilReadyToShow` applies the size before the window is shown.
      // On macOS a window restored from the storyboard can still come back at
      // its saved frame, so apply the requested size once more now that there
      // is a visible window to resize.
      await windowManager.setSize(windowSize);
      await windowManager.focus();
      if (listener != null) {
        windowManager.addListener(listener);
      }
    });
  }

  /// The work area of every connected display, in logical pixels.
  ///
  /// A failure here is not worth stopping the window over: an empty list makes
  /// [clampWindowPosition] return null, which centres the window on the
  /// primary display, exactly as a first launch does.
  static Future<List<Rect>> _visibleDisplayAreas() async {
    try {
      final displays = await screenRetriever.getAllDisplays();
      return [
        for (final display in displays)
          Rect.fromLTWH(
            (display.visiblePosition ?? Offset.zero).dx,
            (display.visiblePosition ?? Offset.zero).dy,
            (display.visibleSize ?? display.size).width,
            (display.visibleSize ?? display.size).height,
          ),
      ];
    } catch (e, s) {
      dprint('Could not read displays for the window position: $e\n$s');
      return const [];
    }
  }

  static Future<Offset?> _cursorPosition() async {
    try {
      return await screenRetriever.getCursorScreenPoint();
    } catch (e, s) {
      dprint('Could not read the pointer position: $e\n$s');
      return null;
    }
  }

  /// Updates the title bar style at runtime without restarting the app.
  ///
  /// Only works on desktop platforms.
  static Future<void> updateTitleBarStyle({required bool hideTitleBar}) async {
    if (!isDesktop) return;
    await windowManager.setTitleBarStyle(
      hideTitleBar ? TitleBarStyle.hidden : TitleBarStyle.normal,
    );
    WindowFrameConfig.setShowCaption(hideTitleBar);
  }
}

void withTextFieldController(
  Future<void> Function(TextEditingController) callback,
) async {
  final controller = TextEditingController();
  try {
    await callback(controller);
    // Wait a moment to ensure any UI updates are processed
    await Future.delayed(const Duration(seconds: 3));
  } finally {
    controller.dispose();
  }
}
