import 'package:akasha_commerce_domain/akasha_commerce_domain.dart';

import 'auth/microtxn_authorization_callback.dart';
import 'auth/steam_ticket_authenticator.dart';
import 'secure_commerce_models.dart';
import 'secure_commerce_service.dart';
import 'steam/steam_publisher_credentials.dart';

/// Ticket-authenticated purchase facade for the deployable commerce backend.
///
/// Flutter may send auth tickets and order callbacks; this layer verifies
/// Steam identity before any ledger mutation. Client-claimed SteamID is never
/// used as the commerce account authority.
class CommercePurchaseGateway {
  CommercePurchaseGateway({
    required this.service,
    required this.authenticator,
    required this.credentials,
  });

  final SecureCommerceService service;
  final SteamTicketAuthenticator authenticator;
  final SteamPublisherCredentials credentials;

  Future<VerifiedSteamIdentity> _verifyTicket(String authTicketHex) {
    return authenticator.authenticateUserTicket(
      ticketHex: authTicketHex,
      expectedAppId: credentials.appId,
    );
  }

  /// Begin pack purchase using only the SteamID from AuthenticateUserTicket.
  Future<SecureCommerceOrder> beginPremiumPackPurchase({
    required String authTicketHex,
    required String productId,
    required String idempotencyKey,
  }) async {
    final identity = await _verifyTicket(authTicketHex);
    return service.beginPremiumPackPurchase(
      steamId: identity.steamId64,
      productId: productId,
      idempotencyKey: idempotencyKey,
    );
  }

  /// After overlay authorization: validate AppID/OrderID/SteamID correlation,
  /// then FinalizeTxn. Does not grant on authorization alone.
  Future<WalletProjection> completeAfterUserAuthorization({
    required String authTicketHex,
    required MicroTxnAuthorizationCallback callback,
    required String finalizeIdempotencyKey,
  }) async {
    final identity = await _verifyTicket(authTicketHex);

    if (callback.appId != credentials.appId) {
      throw CommerceRejected(
        'appid_mismatch',
        'Callback AppID ${callback.appId} != server ${credentials.appId}.',
      );
    }
    if (!callback.authorized) {
      throw const CommerceRejected(
        'user_denied',
        'MicroTxnAuthorizationResponse was not authorized.',
      );
    }

    final order = await service.getOrder(callback.orderId);
    if (order == null) {
      throw const CommerceNotFound('order_missing', 'Order not found.');
    }
    if (order.steamId != identity.steamId64) {
      throw const CommerceRejected(
        'steamid_mismatch',
        'Order SteamID does not match authenticated ticket identity.',
      );
    }

    return service.completePremiumPackPurchase(
      orderId: callback.orderId,
      finalizeIdempotencyKey: finalizeIdempotencyKey,
    );
  }

  Future<WalletProjection> walletForTicket(String authTicketHex) async {
    final identity = await _verifyTicket(authTicketHex);
    return service.wallet(identity.steamId64);
  }
}
