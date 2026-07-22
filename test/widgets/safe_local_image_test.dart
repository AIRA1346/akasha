import 'dart:convert';
import 'dart:io';

import 'package:akasha/widgets/safe_local_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'duplicate local posters share bytes and decode near target size',
    (tester) async {
      final directory = Directory.systemTemp.createTempSync(
        'akasha-safe-image-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final file = File('${directory.path}${Platform.pathSeparator}poster.png');
      file.writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(devicePixelRatio: 2),
            child: Row(
              children: [
                SafeLocalImage(file: file, width: 20, height: 30),
                SafeLocalImage(file: file, width: 20, height: 30),
              ],
            ),
          ),
        ),
      );
      // File IO completes outside the fake async clock. Pump only the resulting
      // widget frame; waiting for the platform image decoder to "settle" makes
      // this provider-contract test dependent on the host codec implementation.
      for (var attempt = 0; attempt < 10; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
        if (find.byType(Image).evaluate().length == 2) break;
      }

      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images, hasLength(2));
      final first = images[0].image as ResizeImage;
      final second = images[1].image as ResizeImage;
      expect(first.width, 40);
      expect(first.height, isNull);
      expect(
        identical(
          (first.imageProvider as MemoryImage).bytes,
          (second.imageProvider as MemoryImage).bytes,
        ),
        isTrue,
      );
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );
}
