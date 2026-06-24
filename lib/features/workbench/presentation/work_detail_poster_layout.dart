/// 작품정보 패널 포스터 — 2:3 프레임을 max 안에 맞춤 (빈 세로 여백 최소화).
({double width, double height}) infoPosterDisplayBounds({
  required double maxWidth,
  required double maxHeight,
}) {
  if (maxWidth <= 0 || maxHeight <= 0) {
    return (width: 0, height: 0);
  }
  var width = maxWidth;
  var height = width * 3 / 2;
  if (height > maxHeight) {
    height = maxHeight;
    width = height * 2 / 3;
  }
  return (width: width, height: height);
}
