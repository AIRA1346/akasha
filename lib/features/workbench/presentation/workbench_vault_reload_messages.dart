/// Vault 디스크 reload 스낵 메시지.
abstract final class WorkbenchVaultReloadMessages {
  static const workSuccess = '디스크에서 파일을 다시 불러왔습니다.';
  static const entitySuccess = '디스크에서 journal을 다시 불러왔습니다.';

  static String workFailure(Object error) => '파일 다시 불러오기 실패: $error';
  static String entityFailure(Object error) => 'journal 다시 불러오기 실패: $error';
}
