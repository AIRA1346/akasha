part of 'file_service.dart';

mixin _AkashaFileServicePaths on _AkashaFileServiceBase {
  bool _shouldSkipPath(String filePath) {
    if (p.basename(filePath) == VaultReadmeWriter.readmeFileName) return true;
    final parts = p.split(filePath);
    return parts.any(
      (part) => part.startsWith('.') || AkashaFileService._skipDirNames.contains(part),
    );
  }
}
