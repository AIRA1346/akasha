import 'package:akasha/screens/home/shell_layout_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShellLayoutSpec', () {
    test('resolves exact breakpoint boundaries', () {
      expect(ShellLayoutSpec.resolve(1440).layoutClass, ShellLayoutClass.wide);
      expect(
        ShellLayoutSpec.resolve(1439).layoutClass,
        ShellLayoutClass.standard,
      );
      expect(
        ShellLayoutSpec.resolve(1180).layoutClass,
        ShellLayoutClass.standard,
      );
      expect(
        ShellLayoutSpec.resolve(1179).layoutClass,
        ShellLayoutClass.compact,
      );
    });

    test('maps the UX verification viewports', () {
      const cases = [
        (width: 1600.0, expected: ShellLayoutClass.wide),
        (width: 1366.0, expected: ShellLayoutClass.standard),
        (width: 1024.0, expected: ShellLayoutClass.compact),
      ];

      for (final (:width, :expected) in cases) {
        expect(
          ShellLayoutSpec.resolve(width).layoutClass,
          expected,
          reason: 'viewport width $width',
        );
      }
    });

    test('wide keeps both rails inline with desktop geometry', () {
      const spec = ShellLayoutSpec.wide;

      expect(spec.sidebarPresentation, ShellSidebarPresentation.persistent);
      expect(spec.previewPresentation, ShellPreviewPresentation.inline);
      expect(spec.sidebarWidth, 256);
      expect(spec.previewWidth, 288);
      expect(spec.reservedSidebarWidth, 256);
      expect(spec.reservedPreviewWidth, 288);
      expect(spec.mainContentMinWidth, 800);
      expect(spec.appBarHeight, 64);
      expect(spec.dockHeight, 56);
      expect(spec.decorationDensity, ShellDecorationDensity.full);
    });

    test('standard overlays preview and reduces decoration', () {
      const spec = ShellLayoutSpec.standard;

      expect(spec.sidebarPresentation, ShellSidebarPresentation.persistent);
      expect(spec.previewPresentation, ShellPreviewPresentation.overlay);
      expect(spec.sidebarWidth, 232);
      expect(spec.previewWidth, 288);
      expect(spec.reservedSidebarWidth, 232);
      expect(spec.reservedPreviewWidth, 0);
      expect(spec.mainContentMinWidth, 800);
      expect(spec.appBarHeight, 64);
      expect(spec.dockHeight, 56);
      expect(spec.decorationDensity, ShellDecorationDensity.reduced);
    });

    test('compact uses drawer and sheet without a forced content minimum', () {
      const spec = ShellLayoutSpec.compact;

      expect(spec.sidebarPresentation, ShellSidebarPresentation.drawer);
      expect(spec.previewPresentation, ShellPreviewPresentation.sheet);
      expect(spec.reservedSidebarWidth, 0);
      expect(spec.reservedPreviewWidth, 0);
      expect(spec.mainContentMinWidth, 0);
      expect(spec.appBarHeight, 64);
      expect(spec.dockHeight, 56);
      expect(spec.decorationDensity, ShellDecorationDensity.minimal);
    });

    test('rejects invalid viewport widths', () {
      expect(() => ShellLayoutSpec.resolve(-1), throwsArgumentError);
      expect(
        () => ShellLayoutSpec.resolve(double.infinity),
        throwsArgumentError,
      );
    });
  });
}
