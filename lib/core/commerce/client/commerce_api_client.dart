import 'package:akasha_commerce_domain/akasha_commerce_domain.dart';

/// Client-facing contract for the deployable commerce backend.
///
/// Payment authority (Publisher API key, Steam HTTP, ledger writes) lives
/// outside the Flutter app. This client only calls HTTP endpoints.
abstract class CommerceApiClient {
  Future<WalletProjection> getWallet({required String authTicketHex});

  Future<List<CommerceProduct>> listProducts({required String authTicketHex});

  /// Begin premium pack: backend verifies ticket → InitTxn.
  /// Does not grant Astra.
  Future<CommerceOrderDto> beginPremiumPackPurchase({
    required String authTicketHex,
    required String productId,
    required String idempotencyKey,
  });

  /// After Steam overlay MicroTxnAuthorizationResponse_t.
  Future<WalletProjection> completePremiumPackPurchase({
    required String authTicketHex,
    required int appId,
    required String orderId,
    required bool authorized,
    required String finalizeIdempotencyKey,
  });
}

/// Wire DTO for order state returned by the commerce backend API.
class CommerceOrderDto {
  const CommerceOrderDto({
    required this.orderId,
    required this.productId,
    required this.state,
    this.premiumGrantAmount,
  });

  final String orderId;
  final String productId;
  final String state;
  final int? premiumGrantAmount;
}

/// Port for Steam client ticket acquisition (game process only).
///
/// Implementation should call ISteamUser::GetAuthTicketForWebApi.
/// The resulting ticket is sent to the backend; SteamID is never trusted
/// from the client string alone.
abstract class SteamWebApiTicketProvider {
  Future<String> getAuthTicketForWebApi({required String identity});
}

/// Unwired stub — production base URL / HTTP not connected until sandbox E2E.
class UnwiredCommerceApiClient implements CommerceApiClient {
  const UnwiredCommerceApiClient();

  Never _notWired() => throw UnsupportedError(
    'Commerce backend HTTP is not wired. '
    'Commerce transaction acceptance is not yet sealed; '
    'an enabled IAP feature flag does not establish readiness.',
  );

  @override
  Future<WalletProjection> getWallet({required String authTicketHex}) async =>
      _notWired();

  @override
  Future<List<CommerceProduct>> listProducts({
    required String authTicketHex,
  }) async => _notWired();

  @override
  Future<CommerceOrderDto> beginPremiumPackPurchase({
    required String authTicketHex,
    required String productId,
    required String idempotencyKey,
  }) async => _notWired();

  @override
  Future<WalletProjection> completePremiumPackPurchase({
    required String authTicketHex,
    required int appId,
    required String orderId,
    required bool authorized,
    required String finalizeIdempotencyKey,
  }) async => _notWired();
}
