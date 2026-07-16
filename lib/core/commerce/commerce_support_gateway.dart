/// Optional provider capability for producing a sanitized support report.
///
/// Implementations must not include credentials, publisher keys, Vault
/// content, persona names, Steam IDs, or absolute user paths.
abstract interface class CommerceSupportGateway {
  String buildSupportReport();
}
