sealed class CommerceException implements Exception {
  const CommerceException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => 'CommerceException($code): $message';
}

class CommerceConflict extends CommerceException {
  const CommerceConflict(super.code, super.message);
}

class CommerceRejected extends CommerceException {
  const CommerceRejected(super.code, super.message);
}

class CommerceNotFound extends CommerceException {
  const CommerceNotFound(super.code, super.message);
}
