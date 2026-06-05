import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/services/file_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 13 — Poster Image Registration & Copying Tests', () {
    late Directory tempVaultDir;
    late File tempSourceFile;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      
      // 임시 볼트 디렉토리 생성
      tempVaultDir = await Directory.systemTemp.createTemp('akasha_test_vault');
      
      // 임시 원본 이미지 파일 생성
      tempSourceFile = File(p.join(tempVaultDir.path, 'source_poster.jpg'));
      await tempSourceFile.writeAsString('fake_image_bytes');
    });

    tearDown(() async {
      // 청소
      if (tempVaultDir.existsSync()) {
        await tempVaultDir.delete(recursive: true);
      }
    });

    test('importPosterImage copies local image file to vault posters folder and returns relative path', () async {
      final fileService = AkashaFileService();
      
      // 볼트가 설정되지 않은 경우 null 반환
      expect(fileService.vaultPath, isNull);
      final nullResult = await fileService.importPosterImage(tempSourceFile.path);
      expect(nullResult, isNull);

      // 볼트 경로 설정
      await fileService.setVaultPath(tempVaultDir.path);
      expect(fileService.vaultPath, equals(tempVaultDir.path));

      // posters 폴더 자동 생성 확인
      final postersDir = Directory(p.join(tempVaultDir.path, 'posters'));
      expect(postersDir.existsSync(), isTrue);

      // 이미지 파일 가져오기 (이관)
      final relativePath = await fileService.importPosterImage(tempSourceFile.path);
      expect(relativePath, isNotNull);
      expect(relativePath!.startsWith('posters${p.separator}') || relativePath.startsWith('posters/'), isTrue);
      expect(relativePath.endsWith('source_poster.jpg'), isTrue);

      // 볼트 내부 복사본 존재 확인
      final copiedFile = File(p.join(tempVaultDir.path, relativePath));
      expect(copiedFile.existsSync(), isTrue);
      expect(copiedFile.readAsStringSync(), equals('fake_image_bytes'));
    });
  });
}
