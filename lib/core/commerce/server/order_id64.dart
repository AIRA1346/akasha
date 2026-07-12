/// Opaque 64-bit Steam-compatible order id (unsigned range as BigInt/int).
///
/// Steam requires a unique 64-bit OrderID per transaction, stored server-side.
class OrderId64 {
  const OrderId64(this.value);

  /// Unsigned 64-bit value stored in a signed Dart [int] bit pattern when
  /// within 63 bits, otherwise as a clamped positive generator output.
  final int value;

  @override
  String toString() => value.toString();

  @override
  bool operator ==(Object other) =>
      other is OrderId64 && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Generates unique positive 64-bit-ish order ids for the server.
abstract class OrderId64Generator {
  OrderId64 next();
}

/// Monotonic generator suitable for tests and single-process fakes.
class MonotonicOrderId64Generator implements OrderId64Generator {
  MonotonicOrderId64Generator({int start = 1 << 32}) : _next = start;

  int _next;

  @override
  OrderId64 next() {
    final id = _next;
    _next++;
    return OrderId64(id);
  }
}
