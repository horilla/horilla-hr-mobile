/// Renders the README screenshots from the preview's sample data.
///
///     flutter test tool/readme_screenshots.dart
///
/// Writes PNGs to ../docs/screenshots/. A widget test rather than a simulator
/// run so it needs no device, no server and no sign-in, and produces the same
/// pictures every time. Lives outside test/ so `flutter test` never runs it.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:horilla_mobile/app.dart';
import 'package:horilla_mobile/main_preview.dart';

const _shots = {
  'home': '/home',
  'attendance': '/time',
  'leave': '/time/leave',
  'leave-apply': '/time/leave/apply',
  'approvals': '/team/approvals',
  'team': '/team',
  'announcements': '/home/announcements',
  'announcement': '/home/announcements/1',
  'notifications': '/home/notifications',
  'me': '/me',
};

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(
        File(f).readAsBytes().then((b) => ByteData.view(b.buffer)),
      );
    }
    await loader.load();
  }

  const fonts = 'Assets/fonts';
  await family('PlusJakartaSans', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'])
      '$fonts/PlusJakartaSans-$w.ttf',
  ]);
  await family('JetBrainsMono', [
    for (final w in ['Regular', 'Medium', 'Bold'])
      '$fonts/JetBrainsMono-$w.ttf',
  ]);
  final sdk = File(Platform.resolvedExecutable).parent.parent.parent.parent;
  await family('MaterialIcons', [
    '${sdk.path}/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}

void main() {
  testWidgets('README screenshots', (tester) async {
    await tester.runAsync(_loadFonts);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    // iPhone 15-class logical size, rendered at 3x.
    tester.view
      ..physicalSize = const Size(1179, 2556)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: ProviderScope(
          overrides: previewOverrides,
          child: const HorillaApp(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    final out = Directory('../docs/screenshots')..createSync(recursive: true);
    for (final MapEntry(key: name, value: path) in _shots.entries) {
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
      // The punch clock ticks forever, so settle by time, not pumpAndSettle.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // Asset images decode asynchronously; a test frame won't wait for them.
      await tester.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await tester.pump();
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 3);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '${out.path}/$name.png',
        ).writeAsBytesSync(png!.buffer.asUint8List());
      });
    }
    debugDefaultTargetPlatformOverride = null;
  });
}
