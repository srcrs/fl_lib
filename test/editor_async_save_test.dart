import 'package:fl_lib/fl_lib.dart';
import 'package:fl_lib/generated/l10n/lib_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: LibLocalizations.localizationsDelegates,
  supportedLocales: LibLocalizations.supportedLocales,
  builder: (context, child) => ToastHost(child: child!),
  home: Builder(
    builder: (context) {
      context.setLibL10n();
      return Scaffold(body: child);
    },
  ),
);

void main() {
  tearDown(Toast.dismissAll);

  testWidgets('a failed later async save keeps the new draft dirty', (
    tester,
  ) async {
    var allowSave = true;
    await tester.pumpWidget(
      _app(
        EditorPage(
          args: EditorPageArgs(
            text: 'initial',
            onSave: (_) {},
            onSaveAsync: (_) async => allowSave,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    CodeLineEditingController editorController() =>
        tester.widget<CodeEditor>(find.byType(CodeEditor)).controller!;

    editorController().text = 'saved draft';
    await tester.pump();
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    allowSave = false;
    editorController().text = 'new unsaved draft';
    await tester.pump();
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text(libL10n.exitDirectly), findsOneWidget);
  });
}
