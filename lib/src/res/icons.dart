import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The shared library's Lucide glyph vocabulary.
///
/// The app and fl_lib widgets must draw one icon language. The app keeps its
/// product roles in `AppIcons`; these are the generic marks this package owns
/// (chevrons, save, search, status marks, editor actions). Both resolve through
/// the same Lucide collection:
/// <https://www.iconfont.cn/collections/detail?cid=54062>.
abstract final class FlIcons {
  static const add = LucideIcons.plus;
  static const arrowBack = LucideIcons.arrowLeft;
  static const arrowDownward = LucideIcons.arrowDown;
  static const arrowForward = LucideIcons.arrowRight;
  static const arrowUpward = LucideIcons.arrowUp;
  static const brokenImage = LucideIcons.imageOff;
  static const check = LucideIcons.check;
  static const checkCircleOutline = LucideIcons.circleCheck;
  static const checkCheck = LucideIcons.checkCheck;
  static const chevronLeft = LucideIcons.chevronLeft;
  static const chevronRight = LucideIcons.chevronRight;
  static const clear = LucideIcons.x;
  static const close = LucideIcons.x;
  static const colorize = LucideIcons.pipette;
  static const copy = LucideIcons.copy;
  static const delete = LucideIcons.trash2;
  static const dragHandle = LucideIcons.gripHorizontal;
  static const edit = LucideIcons.pencil;
  static const errorOutline = LucideIcons.circleAlert;
  static const expandMore = LucideIcons.chevronDown;
  static const flashlightOff = LucideIcons.flashlightOff;
  static const flashlightOn = LucideIcons.flashlight;
  static const helpOutline = LucideIcons.circleHelp;
  static const infoOutline = LucideIcons.info;
  static const insertDriveFile = LucideIcons.file;
  static const keyboardArrowDown = LucideIcons.chevronDown;
  static const keyboardArrowRight = LucideIcons.chevronRight;
  static const language = LucideIcons.languages;
  static const moreVert = LucideIcons.ellipsisVertical;
  static const network = LucideIcons.network;
  static const openInNew = LucideIcons.externalLink;
  static const refresh = LucideIcons.refreshCw;
  static const save = LucideIcons.save;
  static const search = LucideIcons.search;
  static const queueList = LucideIcons.listOrdered;
  static const share = LucideIcons.share2;
  static const sort = LucideIcons.arrowUpDown;
  static const visibility = LucideIcons.eye;
  static const visibilityOff = LucideIcons.eyeOff;
  static const warning = LucideIcons.triangleAlert;

  static const fingerprint = LucideIcons.fingerprint;
  static const hash = LucideIcons.hash;
  static const addCircle = LucideIcons.circlePlus;
  static const circleX = LucideIcons.circleX;
  static const clipboard = LucideIcons.clipboard;
  static const file = LucideIcons.file;
  static const paragraph = LucideIcons.pilcrow;
  static const question = LucideIcons.circleHelp;
  static const up = LucideIcons.chevronUp;
}
