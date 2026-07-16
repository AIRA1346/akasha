#include "steam_inventory_poc_channel.h"

#include "steam_runtime.h"

#include <atomic>
#include <map>
#include <mutex>
#include <string>
#include <vector>

#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#pragma warning(push)
#pragma warning(disable : 4996)
#include "steam/steam_api.h"
#pragma warning(pop)

namespace {

constexpr char kMethodChannel[] = "akasha/steam_inventory";
constexpr char kEventChannel[] = "akasha/steam_inventory/events";
constexpr DWORD kWaitTimeoutMs = 20000;

flutter::EncodableMap M(
    std::initializer_list<std::pair<const char*, flutter::EncodableValue>> xs) {
  flutter::EncodableMap m;
  for (const auto& x : xs) {
    m[flutter::EncodableValue(x.first)] = x.second;
  }
  return m;
}

std::string EResultName(EResult r) {
  switch (r) {
    case k_EResultOK:
      return "k_EResultOK";
    case k_EResultFail:
      return "k_EResultFail";
    case k_EResultNoConnection:
      return "k_EResultNoConnection";
    case k_EResultInvalidPassword:
      return "k_EResultInvalidPassword";
    case k_EResultLoggedInElsewhere:
      return "k_EResultLoggedInElsewhere";
    case k_EResultInvalidProtocolVer:
      return "k_EResultInvalidProtocolVer";
    case k_EResultInvalidParam:
      return "k_EResultInvalidParam";
    case k_EResultFileNotFound:
      return "k_EResultFileNotFound";
    case k_EResultBusy:
      return "k_EResultBusy";
    case k_EResultInvalidState:
      return "k_EResultInvalidState";
    case k_EResultInvalidName:
      return "k_EResultInvalidName";
    case k_EResultInvalidEmail:
      return "k_EResultInvalidEmail";
    case k_EResultDuplicateName:
      return "k_EResultDuplicateName";
    case k_EResultAccessDenied:
      return "k_EResultAccessDenied";
    case k_EResultTimeout:
      return "k_EResultTimeout";
    case k_EResultBanned:
      return "k_EResultBanned";
    case k_EResultAccountNotFound:
      return "k_EResultAccountNotFound";
    case k_EResultInvalidSteamID:
      return "k_EResultInvalidSteamID";
    case k_EResultServiceUnavailable:
      return "k_EResultServiceUnavailable";
    case k_EResultNotLoggedOn:
      return "k_EResultNotLoggedOn";
    case k_EResultPending:
      return "k_EResultPending";
    case k_EResultEncryptionFailure:
      return "k_EResultEncryptionFailure";
    case k_EResultInsufficientPrivilege:
      return "k_EResultInsufficientPrivilege";
    case k_EResultLimitExceeded:
      return "k_EResultLimitExceeded";
    case k_EResultRevoked:
      return "k_EResultRevoked";
    case k_EResultExpired:
      return "k_EResultExpired";
    case k_EResultAlreadyRedeemed:
      return "k_EResultAlreadyRedeemed";
    case k_EResultDuplicateRequest:
      return "k_EResultDuplicateRequest";
    case k_EResultAlreadyOwned:
      return "k_EResultAlreadyOwned";
    case k_EResultIPNotFound:
      return "k_EResultIPNotFound";
    case k_EResultPersistFailed:
      return "k_EResultPersistFailed";
    case k_EResultLockingFailed:
      return "k_EResultLockingFailed";
    case k_EResultLogonSessionReplaced:
      return "k_EResultLogonSessionReplaced";
    case k_EResultConnectFailed:
      return "k_EResultConnectFailed";
    case k_EResultHandshakeFailed:
      return "k_EResultHandshakeFailed";
    case k_EResultIOFailure:
      return "k_EResultIOFailure";
    case k_EResultRemoteDisconnect:
      return "k_EResultRemoteDisconnect";
    case k_EResultShoppingCartNotFound:
      return "k_EResultShoppingCartNotFound";
    case k_EResultBlocked:
      return "k_EResultBlocked";
    case k_EResultIgnored:
      return "k_EResultIgnored";
    case k_EResultNoMatch:
      return "k_EResultNoMatch";
    case k_EResultAccountDisabled:
      return "k_EResultAccountDisabled";
    case k_EResultServiceReadOnly:
      return "k_EResultServiceReadOnly";
    case k_EResultAccountNotFeatured:
      return "k_EResultAccountNotFeatured";
    case k_EResultAdministratorOK:
      return "k_EResultAdministratorOK";
    case k_EResultContentVersion:
      return "k_EResultContentVersion";
    case k_EResultTryAnotherCM:
      return "k_EResultTryAnotherCM";
    case k_EResultPasswordRequiredToKickSession:
      return "k_EResultPasswordRequiredToKickSession";
    case k_EResultAlreadyLoggedInElsewhere:
      return "k_EResultAlreadyLoggedInElsewhere";
    case k_EResultSuspended:
      return "k_EResultSuspended";
    case k_EResultCancelled:
      return "k_EResultCancelled";
    case k_EResultDataCorruption:
      return "k_EResultDataCorruption";
    case k_EResultDiskFull:
      return "k_EResultDiskFull";
    case k_EResultRemoteCallFailed:
      return "k_EResultRemoteCallFailed";
    case k_EResultPasswordUnset:
      return "k_EResultPasswordUnset";
    case k_EResultExternalAccountUnlinked:
      return "k_EResultExternalAccountUnlinked";
    case k_EResultPSNTicketInvalid:
      return "k_EResultPSNTicketInvalid";
    case k_EResultExternalAccountAlreadyLinked:
      return "k_EResultExternalAccountAlreadyLinked";
    case k_EResultRemoteFileConflict:
      return "k_EResultRemoteFileConflict";
    case k_EResultIllegalPassword:
      return "k_EResultIllegalPassword";
    case k_EResultSameAsPreviousValue:
      return "k_EResultSameAsPreviousValue";
    case k_EResultAccountLogonDenied:
      return "k_EResultAccountLogonDenied";
    case k_EResultCannotUseOldPassword:
      return "k_EResultCannotUseOldPassword";
    case k_EResultInvalidLoginAuthCode:
      return "k_EResultInvalidLoginAuthCode";
    case k_EResultAccountLogonDeniedNoMail:
      return "k_EResultAccountLogonDeniedNoMail";
    case k_EResultHardwareNotCapableOfIPT:
      return "k_EResultHardwareNotCapableOfIPT";
    case k_EResultIPTInitError:
      return "k_EResultIPTInitError";
    case k_EResultParentalControlRestricted:
      return "k_EResultParentalControlRestricted";
    case k_EResultFacebookQueryError:
      return "k_EResultFacebookQueryError";
    case k_EResultExpiredLoginAuthCode:
      return "k_EResultExpiredLoginAuthCode";
    case k_EResultIPLoginRestrictionFailed:
      return "k_EResultIPLoginRestrictionFailed";
    case k_EResultAccountLockedDown:
      return "k_EResultAccountLockedDown";
    case k_EResultAccountLogonDeniedVerifiedEmailRequired:
      return "k_EResultAccountLogonDeniedVerifiedEmailRequired";
    case k_EResultNoMatchingURL:
      return "k_EResultNoMatchingURL";
    case k_EResultBadResponse:
      return "k_EResultBadResponse";
    case k_EResultRequirePasswordReEntry:
      return "k_EResultRequirePasswordReEntry";
    case k_EResultValueOutOfRange:
      return "k_EResultValueOutOfRange";
    case k_EResultUnexpectedError:
      return "k_EResultUnexpectedError";
    case k_EResultDisabled:
      return "k_EResultDisabled";
    case k_EResultInvalidCEGSubmission:
      return "k_EResultInvalidCEGSubmission";
    case k_EResultRestrictedDevice:
      return "k_EResultRestrictedDevice";
    case k_EResultRegionLocked:
      return "k_EResultRegionLocked";
    case k_EResultRateLimitExceeded:
      return "k_EResultRateLimitExceeded";
    case k_EResultAccountLoginDeniedNeedTwoFactor:
      return "k_EResultAccountLoginDeniedNeedTwoFactor";
    case k_EResultItemDeleted:
      return "k_EResultItemDeleted";
    case k_EResultAccountLoginDeniedThrottle:
      return "k_EResultAccountLoginDeniedThrottle";
    case k_EResultTwoFactorCodeMismatch:
      return "k_EResultTwoFactorCodeMismatch";
    case k_EResultTwoFactorActivationCodeMismatch:
      return "k_EResultTwoFactorActivationCodeMismatch";
    case k_EResultAccountAssociatedToMultiplePartners:
      return "k_EResultAccountAssociatedToMultiplePartners";
    case k_EResultNotModified:
      return "k_EResultNotModified";
    case k_EResultNoMobileDevice:
      return "k_EResultNoMobileDevice";
    case k_EResultTimeNotSynced:
      return "k_EResultTimeNotSynced";
    case k_EResultSmsCodeFailed:
      return "k_EResultSmsCodeFailed";
    case k_EResultAccountLimitExceeded:
      return "k_EResultAccountLimitExceeded";
    case k_EResultAccountActivityLimitExceeded:
      return "k_EResultAccountActivityLimitExceeded";
    case k_EResultPhoneActivityLimitExceeded:
      return "k_EResultPhoneActivityLimitExceeded";
    case k_EResultRefundToWallet:
      return "k_EResultRefundToWallet";
    case k_EResultEmailSendFailure:
      return "k_EResultEmailSendFailure";
    case k_EResultNotSettled:
      return "k_EResultNotSettled";
    case k_EResultNeedCaptcha:
      return "k_EResultNeedCaptcha";
    case k_EResultGSLTDenied:
      return "k_EResultGSLTDenied";
    case k_EResultGSOwnerDenied:
      return "k_EResultGSOwnerDenied";
    case k_EResultInvalidItemType:
      return "k_EResultInvalidItemType";
    case k_EResultIPBanned:
      return "k_EResultIPBanned";
    case k_EResultGSLTExpired:
      return "k_EResultGSLTExpired";
    case k_EResultInsufficientFunds:
      return "k_EResultInsufficientFunds";
    case k_EResultTooManyPending:
      return "k_EResultTooManyPending";
    default:
      return "unknown_" + std::to_string(static_cast<int>(r));
  }
}

std::string StatusOf(EResult r) {
  switch (r) {
    case k_EResultOK:
      return "success";
    case k_EResultPending:
      return "pending";
    case k_EResultExpired:
      return "indeterminate";
    case k_EResultCancelled:
      return "canceled";
    case k_EResultInvalidParam:
      return "invalid_param";
    case k_EResultServiceUnavailable:
      return "service_unavailable";
    case k_EResultLimitExceeded:
      return "limit_exceeded";
    case k_EResultFail:
      return "failed";
    default:
      return "failed";
  }
}

uint32_t ItemDefCount() {
  uint32 n = 0;
  if (!SteamInventory() || !SteamInventory()->GetItemDefinitionIDs(nullptr, &n)) {
    return 0;
  }
  return n;
}

flutter::EncodableMap BuildDiagnostics() {
  const bool init = SteamRuntime::Initialized();
  const bool logged_on = init && SteamUser() && SteamUser()->BLoggedOn();
  const bool subscribed =
      init && SteamApps() && SteamApps()->BIsSubscribedApp(SteamRuntime::kAppId);
  const bool overlay =
      init && SteamUtils() && SteamUtils()->IsOverlayEnabled();
  std::string steam_id;
  std::string persona;
  if (init && SteamUser()) {
    steam_id = std::to_string(SteamUser()->GetSteamID().ConvertToUint64());
  }
  if (init && SteamFriends()) {
    const char* name = SteamFriends()->GetPersonaName();
    if (name) persona = name;
  }
  return M({
      {"ok", flutter::EncodableValue(init)},
      {"initialized", flutter::EncodableValue(init)},
      {"initializationAttempted",
       flutter::EncodableValue(SteamRuntime::InitializationAttempted())},
      {"restartRequested",
       flutter::EncodableValue(SteamRuntime::RestartRequested())},
      {"shutdownPerformed",
       flutter::EncodableValue(SteamRuntime::ShutdownPerformed())},
      {"appId",
       flutter::EncodableValue(static_cast<int32_t>(SteamRuntime::kAppId))},
      {"steamId", flutter::EncodableValue(steam_id)},
      {"personaName", flutter::EncodableValue(persona)},
      {"loggedOn", flutter::EncodableValue(logged_on)},
      {"online", flutter::EncodableValue(logged_on)},
      {"subscribedApp", flutter::EncodableValue(subscribed)},
      {"subscribed", flutter::EncodableValue(subscribed)},
      {"overlayEnabled", flutter::EncodableValue(overlay)},
      {"overlayActive",
       flutter::EncodableValue(SteamRuntime::IsOverlayActive())},
      {"overlayNeedsPresent",
       flutter::EncodableValue(SteamRuntime::LastOverlayNeedsPresent())},
      {"steamTimerTickCount",
       flutter::EncodableValue(
           static_cast<int64_t>(SteamRuntime::SteamTimerTickCount()))},
      {"overlayNeedsPresentTrueCount",
       flutter::EncodableValue(static_cast<int64_t>(
           SteamRuntime::OverlayNeedsPresentTrueCount()))},
      {"overlayForceRedrawCount",
       flutter::EncodableValue(
           static_cast<int64_t>(SteamRuntime::OverlayForceRedrawCount()))},
      {"steamApiCallSource", flutter::EncodableValue("process_startup")},
      {"buildMode", flutter::EncodableValue(SteamRuntime::BuildMode())},
      {"executablePath",
       flutter::EncodableValue(SteamRuntime::ExecutablePath())},
      {"currentWorkingDirectory",
       flutter::EncodableValue(SteamRuntime::CurrentWorkingDirectory())},
      {"defCount",
       flutter::EncodableValue(static_cast<int32_t>(ItemDefCount()))},
  });
}

int32_t AsI32(const flutter::EncodableValue& v) {
  if (std::holds_alternative<int32_t>(v)) return std::get<int32_t>(v);
  if (std::holds_alternative<int64_t>(v)) {
    return static_cast<int32_t>(std::get<int64_t>(v));
  }
  return 0;
}

std::vector<int32_t> IntList(const flutter::EncodableMap& map, const char* key) {
  std::vector<int32_t> out;
  auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end() ||
      !std::holds_alternative<flutter::EncodableList>(it->second)) {
    return out;
  }
  for (const auto& v : std::get<flutter::EncodableList>(it->second)) {
    out.push_back(AsI32(v));
  }
  return out;
}

std::vector<std::string> StrList(const flutter::EncodableMap& map,
                                 const char* key) {
  std::vector<std::string> out;
  auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end() ||
      !std::holds_alternative<flutter::EncodableList>(it->second)) {
    return out;
  }
  for (const auto& v : std::get<flutter::EncodableList>(it->second)) {
    if (std::holds_alternative<std::string>(v)) {
      out.push_back(std::get<std::string>(v));
    }
  }
  return out;
}

flutter::EncodableList IntListValue(const std::vector<int32_t>& xs) {
  flutter::EncodableList out;
  for (auto x : xs) {
    out.push_back(flutter::EncodableValue(x));
  }
  return out;
}

}  // namespace

struct SteamInventoryPocChannel::Impl {
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> methods;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> events;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink;
  std::mutex mu;

  bool bound = false;
  bool online = false;
  CSteamID user{};
  int seq = 0;

  struct Pending {
    std::string kind;
    SteamInventoryResult_t handle = k_SteamInventoryResultInvalid;
    bool expect_orphan_result = false;  // StartPurchase
    std::vector<int32_t> item_def_ids;
    std::vector<int32_t> quantities;
    uint64_t api_call = 0;
  };
  std::map<std::string, Pending> pending;
  std::map<SteamInventoryResult_t, std::string> by_handle;
  std::vector<flutter::EncodableMap> completed;

  CCallResult<Impl, SteamInventoryStartPurchaseResult_t> cr_purchase;
  CCallResult<Impl, SteamInventoryRequestPricesResult_t> cr_prices;
  std::string prices_corr;

  CCallback<Impl, SteamInventoryResultReady_t> cb_result_ready;
  CCallback<Impl, SteamInventoryFullUpdate_t> cb_full_update;
  CCallback<Impl, SteamInventoryDefinitionUpdate_t> cb_defs_update;
  CCallback<Impl, GameOverlayActivated_t> cb_overlay;
  bool defs_seen = false;

  Impl()
      : cb_result_ready(this, &Impl::OnResultReady),
        cb_full_update(this, &Impl::OnFullUpdate),
        cb_defs_update(this, &Impl::OnDefinitionUpdate),
        cb_overlay(this, &Impl::OnOverlayActivated) {}

  std::string Next(const char* p) { return std::string(p) + "_" + std::to_string(++seq); }

  void Emit(flutter::EncodableMap ev) {
    std::lock_guard<std::mutex> lock(mu);
    completed.push_back(ev);
    if (sink) {
      sink->Success(flutter::EncodableValue(ev));
    }
  }

  flutter::EncodableList ReadItems(SteamInventoryResult_t handle) {
    flutter::EncodableList items;
    uint32 n = 0;
    SteamInventory()->GetResultItems(handle, nullptr, &n);
    std::vector<SteamItemDetails_t> d(n);
    if (n == 0 || !SteamInventory()->GetResultItems(handle, d.data(), &n)) {
      return items;
    }
    for (uint32 i = 0; i < n; ++i) {
      items.push_back(flutter::EncodableValue(M({
          {"instanceId", flutter::EncodableValue(std::to_string(d[i].m_itemId))},
          {"itemDefId",
           flutter::EncodableValue(static_cast<int32_t>(d[i].m_iDefinition))},
          {"quantity",
           flutter::EncodableValue(static_cast<int32_t>(d[i].m_unQuantity))},
          {"flags",
           flutter::EncodableValue(static_cast<int32_t>(d[i].m_unFlags))},
      })));
    }
    return items;
  }

  std::string FindCorr(SteamInventoryResult_t handle) {
    std::lock_guard<std::mutex> lock(mu);
    auto it = by_handle.find(handle);
    if (it != by_handle.end()) return it->second;
    // StartPurchase: ResultReady handle was never registered.
    for (auto& e : pending) {
      if (e.second.expect_orphan_result) {
        e.second.expect_orphan_result = false;
        e.second.handle = handle;
        by_handle[handle] = e.first;
        return e.first;
      }
    }
    return Next("orphan");
  }

  void OnResultReady(SteamInventoryResultReady_t* cb) {
    if (!cb) return;
    const std::string corr = FindCorr(cb->m_handle);
    std::string kind = "unknown";
    {
      std::lock_guard<std::mutex> lock(mu);
      auto it = pending.find(corr);
      if (it != pending.end()) kind = it->second.kind;
    }

    const bool id_ok = SteamInventory()->CheckResultSteamID(cb->m_handle, user);
    const int32_t code = static_cast<int32_t>(cb->m_result);
    const std::string name = EResultName(cb->m_result);
    std::string status = StatusOf(cb->m_result);
    if (cb->m_result == k_EResultOK && !id_ok) {
      status = "failed";
    }

    flutter::EncodableList items;
    flutter::EncodableList removed;
    flutter::EncodableList granted;
    if (cb->m_result == k_EResultOK && id_ok) {
      uint32 n = 0;
      SteamInventory()->GetResultItems(cb->m_handle, nullptr, &n);
      std::vector<SteamItemDetails_t> d(n);
      if (n > 0 && SteamInventory()->GetResultItems(cb->m_handle, d.data(), &n)) {
        for (uint32 i = 0; i < n; ++i) {
          const bool is_removed =
              (d[i].m_unFlags & k_ESteamItemRemoved) != 0 ||
              (d[i].m_unFlags & k_ESteamItemConsumed) != 0;
          flutter::EncodableMap row = M({
              {"instanceId",
               flutter::EncodableValue(std::to_string(d[i].m_itemId))},
              {"itemDefId",
               flutter::EncodableValue(static_cast<int32_t>(d[i].m_iDefinition))},
              {"quantity",
               flutter::EncodableValue(static_cast<int32_t>(d[i].m_unQuantity))},
              {"flags",
               flutter::EncodableValue(static_cast<int32_t>(d[i].m_unFlags))},
              {"removed", flutter::EncodableValue(is_removed)},
          });
          items.push_back(flutter::EncodableValue(row));
          if (is_removed) {
            removed.push_back(flutter::EncodableValue(row));
          } else {
            granted.push_back(flutter::EncodableValue(row));
          }
        }
      }
    }

    Emit(M({
        {"kind", flutter::EncodableValue(kind)},
        {"status", flutter::EncodableValue(status)},
        {"phase", flutter::EncodableValue("inventory_result_ready")},
        {"handle", flutter::EncodableValue(corr)},
        {"steamResult", flutter::EncodableValue(std::to_string(code))},
        {"steamResultCode", flutter::EncodableValue(code)},
        {"steamResultName", flutter::EncodableValue(name)},
        {"steamIdOk", flutter::EncodableValue(id_ok)},
        {"items", flutter::EncodableValue(items)},
        {"removedItems", flutter::EncodableValue(removed)},
        {"grantedItems", flutter::EncodableValue(granted)},
        {"detail",
         flutter::EncodableValue(
             !id_ok ? "steamid_mismatch"
             : (kind == "exchange"
                    ? std::string("exchange ResultReady ") + name +
                          " removed=" + std::to_string(removed.size()) +
                          " granted=" + std::to_string(granted.size())
             : (kind == "consume"
                    ? std::string("consume ResultReady ") + name +
                          " removed=" + std::to_string(removed.size()) +
                          " granted=" + std::to_string(granted.size())
                    : "result_ready — re-query inventory for authority")))},
    }));

    SteamInventory()->DestroyResult(cb->m_handle);
    std::lock_guard<std::mutex> lock(mu);
    by_handle.erase(cb->m_handle);
    pending.erase(corr);
  }

  void OnFullUpdate(SteamInventoryFullUpdate_t* cb) {
    // ResultReady still follows and owns DestroyResult.
    if (!cb) return;
    Emit(M({
        {"kind", flutter::EncodableValue("fullUpdate")},
        {"status", flutter::EncodableValue("pending")},
        {"handle", flutter::EncodableValue(std::to_string(cb->m_handle))},
        {"detail",
         flutter::EncodableValue(
             "SteamInventoryFullUpdate_t (ResultReady will follow)")},
    }));
  }

  void OnDefinitionUpdate(SteamInventoryDefinitionUpdate_t* /*cb*/) {
    defs_seen = true;
    Emit(M({
        {"kind", flutter::EncodableValue("definitions")},
        {"status", flutter::EncodableValue("success")},
        {"handle", flutter::EncodableValue(Next("defs"))},
        {"defCount",
         flutter::EncodableValue(static_cast<int32_t>(ItemDefCount()))},
        {"detail", flutter::EncodableValue("SteamInventoryDefinitionUpdate_t")},
    }));
  }

  void OnOverlayActivated(GameOverlayActivated_t* cb) {
    if (!cb) return;
    const bool active = cb->m_bActive != 0;
    SteamRuntime::SetOverlayActive(active);
    Emit(M({
        {"kind", flutter::EncodableValue("overlay")},
        {"status", flutter::EncodableValue("success")},
        {"handle", flutter::EncodableValue(Next("overlay"))},
        {"overlayActive", flutter::EncodableValue(active)},
        {"overlayEnabled",
         flutter::EncodableValue(SteamUtils() &&
                                 SteamUtils()->IsOverlayEnabled())},
        {"detail",
         flutter::EncodableValue(active ? "GameOverlayActivated_t active"
                                        : "GameOverlayActivated_t inactive")},
    }));
  }

  /// ItemDefs must be present before GetAllItems is reliable for a new app.
  bool WaitForItemDefinitions(DWORD timeout_ms) {
    if (ItemDefCount() > 0) {
      defs_seen = true;
      return true;
    }
    SteamInventory()->LoadItemDefinitions();
    const DWORD start = GetTickCount();
    while (GetTickCount() - start < timeout_ms) {
      SteamRuntime::Pump();
      if (ItemDefCount() > 0) {
        defs_seen = true;
        return true;
      }
      Sleep(25);
    }
    return ItemDefCount() > 0;
  }

  void OnPurchaseInit(SteamInventoryStartPurchaseResult_t* r, bool io_fail) {
    std::string corr;
    Pending snap;
    {
      std::lock_guard<std::mutex> lock(mu);
      for (auto& e : pending) {
        if (e.second.kind == "purchase" && e.second.expect_orphan_result) {
          corr = e.first;
          snap = e.second;
        }
      }
    }

    flutter::EncodableMap ev = M({
        {"kind", flutter::EncodableValue("purchase")},
        {"handle", flutter::EncodableValue(corr)},
        {"ioFailure", flutter::EncodableValue(io_fail)},
        {"itemDefIds", flutter::EncodableValue(IntListValue(snap.item_def_ids))},
        {"quantities", flutter::EncodableValue(IntListValue(snap.quantities))},
        {"apiCallHandle",
         flutter::EncodableValue(std::to_string(snap.api_call))},
    });

    if (io_fail || !r) {
      ev[flutter::EncodableValue("status")] = flutter::EncodableValue("failed");
      ev[flutter::EncodableValue("phase")] =
          flutter::EncodableValue("start_purchase_callback");
      ev[flutter::EncodableValue("steamResultCode")] =
          flutter::EncodableValue(static_cast<int32_t>(-1));
      ev[flutter::EncodableValue("steamResultName")] =
          flutter::EncodableValue("io_failure");
      ev[flutter::EncodableValue("detail")] =
          flutter::EncodableValue("SteamInventoryStartPurchaseResult_t io failure");
      Emit(ev);
      std::lock_guard<std::mutex> lock(mu);
      pending.erase(corr);
      return;
    }

    const int32_t code = static_cast<int32_t>(r->m_result);
    const std::string name = EResultName(r->m_result);
    ev[flutter::EncodableValue("steamResultCode")] =
        flutter::EncodableValue(code);
    ev[flutter::EncodableValue("steamResultName")] =
        flutter::EncodableValue(name);
    ev[flutter::EncodableValue("orderId")] =
        flutter::EncodableValue(std::to_string(r->m_ulOrderID));
    ev[flutter::EncodableValue("transactionId")] =
        flutter::EncodableValue(std::to_string(r->m_ulTransID));
    ev[flutter::EncodableValue("transId")] =
        flutter::EncodableValue(std::to_string(r->m_ulTransID));
    ev[flutter::EncodableValue("phase")] =
        flutter::EncodableValue("start_purchase_callback");

    if (r->m_result != k_EResultOK) {
      ev[flutter::EncodableValue("status")] =
          flutter::EncodableValue(StatusOf(r->m_result));
      ev[flutter::EncodableValue("detail")] = flutter::EncodableValue(
          std::string("SteamInventoryStartPurchaseResult_t rejected: ") + name +
          " (" + std::to_string(code) + ")");
      Emit(ev);
      std::lock_guard<std::mutex> lock(mu);
      pending.erase(corr);
      return;
    }

    ev[flutter::EncodableValue("status")] =
        flutter::EncodableValue("pending");
    ev[flutter::EncodableValue("detail")] = flutter::EncodableValue(
        "k_EResultOK — Overlay/user confirm pending; wait ResultReady; do not "
        "grant yet");
    Emit(ev);
  }

  void OnPrices(SteamInventoryRequestPricesResult_t* r, bool io_fail) {
    flutter::EncodableList prices;
    std::string status = "failed";
    std::string currency_code;
    if (!io_fail && r && r->m_result == k_EResultOK) {
      status = "success";
      currency_code = r->m_rgchCurrency;
      const uint32 n = SteamInventory()->GetNumItemsWithPrices();
      if (n > 0) {
        std::vector<SteamItemDef_t> defs(n);
        std::vector<uint64> cur(n), base(n);
        if (SteamInventory()->GetItemsWithPrices(defs.data(), cur.data(),
                                                 base.data(), n)) {
          for (uint32 i = 0; i < n; ++i) {
            prices.push_back(flutter::EncodableValue(M({
                {"itemDefId",
                 flutter::EncodableValue(static_cast<int32_t>(defs[i]))},
                {"priceAmount",
                 flutter::EncodableValue(static_cast<int64_t>(cur[i]))},
                {"basePriceAmount",
                 flutter::EncodableValue(static_cast<int64_t>(base[i]))},
                // Legacy POC key retained while production reads use the
                // unit-neutral priceAmount name.
                {"priceMicro",
                 flutter::EncodableValue(static_cast<int64_t>(cur[i]))},
            })));
          }
        }
      }
    }
    Emit(M({{"kind", flutter::EncodableValue("prices")},
            {"status", flutter::EncodableValue(status)},
            {"handle", flutter::EncodableValue(prices_corr)},
            {"currencyCode", flutter::EncodableValue(currency_code)},
            {"prices", flutter::EncodableValue(prices)}}));
  }

  bool WaitForCorr(const std::string& corr, flutter::EncodableMap* out,
                   DWORD timeout_ms) {
    const DWORD start = GetTickCount();
    while (GetTickCount() - start < timeout_ms) {
      SteamRuntime::Pump();
      {
        std::lock_guard<std::mutex> lock(mu);
        for (auto it = completed.rbegin(); it != completed.rend(); ++it) {
          auto h = it->find(flutter::EncodableValue("handle"));
          if (h != it->end() &&
              std::holds_alternative<std::string>(h->second) &&
              std::get<std::string>(h->second) == corr) {
            *out = *it;
            return true;
          }
        }
      }
      Sleep(10);
    }
    return false;
  }
};

namespace {

}  // namespace

SteamInventoryPocChannel::SteamInventoryPocChannel()
    : impl_(std::make_unique<Impl>()) {}

SteamInventoryPocChannel::~SteamInventoryPocChannel() {
  // SteamAPI_Shutdown is owned exclusively by SteamRuntime (main.cpp).
}

bool SteamInventoryPocChannel::IsSteamReady() {
  return SteamRuntime::Initialized();
}

void SteamInventoryPocChannel::PumpCallbacks() { SteamRuntime::Pump(); }

void SteamInventoryPocChannel::Register(flutter::FlutterEngine* engine) {
  if (!engine || impl_->methods) return;

  impl_->methods =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          engine->messenger(), kMethodChannel,
          &flutter::StandardMethodCodec::GetInstance());
  impl_->events =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          engine->messenger(), kEventChannel,
          &flutter::StandardMethodCodec::GetInstance());

  impl_->events->SetStreamHandler(
      std::make_unique<
          flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
          [this](const flutter::EncodableValue*,
                 std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&&
                     s)
              -> std::unique_ptr<
                  flutter::StreamHandlerError<flutter::EncodableValue>> {
            std::lock_guard<std::mutex> lock(impl_->mu);
            impl_->sink = std::move(s);
            return nullptr;
          },
          [this](const flutter::EncodableValue*)
              -> std::unique_ptr<
                  flutter::StreamHandlerError<flutter::EncodableValue>> {
            std::lock_guard<std::mutex> lock(impl_->mu);
            impl_->sink.reset();
            return nullptr;
          }));

  impl_->methods->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        const auto& method = call.method_name();
        const auto* args = call.arguments();

        auto fail = [&](const char* code) {
          result->Success(flutter::EncodableValue(
              M({{"ok", flutter::EncodableValue(false)},
                 {"code", flutter::EncodableValue(code)},
                 {"status", flutter::EncodableValue("failed")},
                 {"online", flutter::EncodableValue(false)}})));
        };

        if (method == "initialize" || method == "init" ||
            method == "diagnostic" || method == "diagnostics") {
          // SteamAPI_Init already ran in SteamRuntime::Bootstrap (main).
          if (!SteamRuntime::Initialized()) {
            auto diag = BuildDiagnostics();
            diag[flutter::EncodableValue("ok")] = flutter::EncodableValue(false);
            diag[flutter::EncodableValue("code")] = flutter::EncodableValue(
                SteamRuntime::RestartRequested() ? "restart_via_steam"
                                                 : "steam_not_initialized");
            diag[flutter::EncodableValue("status")] =
                flutter::EncodableValue("failed");
            result->Success(flutter::EncodableValue(diag));
            return;
          }
          impl_->bound = true;
          impl_->user = SteamUser()->GetSteamID();
          impl_->online = SteamUser()->BLoggedOn();
          if (SteamInventory()) {
            SteamInventory()->LoadItemDefinitions();
          }
          auto diag = BuildDiagnostics();
          diag[flutter::EncodableValue("ok")] = flutter::EncodableValue(true);
          result->Success(flutter::EncodableValue(diag));
          return;
        }

        if (method == "shutdown") {
          // No-op: SteamAPI_Shutdown is process-owned (SteamRuntime).
          result->Success(flutter::EncodableValue(
              M({{"ok", flutter::EncodableValue(true)},
                 {"noop", flutter::EncodableValue(true)}})));
          return;
        }

        if (!SteamRuntime::Initialized() || !impl_->bound) {
          if (SteamRuntime::Initialized()) {
            impl_->bound = true;
            impl_->user = SteamUser()->GetSteamID();
            impl_->online = SteamUser()->BLoggedOn();
          } else {
            fail("not_initialized");
            return;
          }
        }

        if (method == "getInventory" || method == "getAllItems") {
          if (!SteamUser()->BLoggedOn()) {
            fail("offline");
            return;
          }
          if (!impl_->WaitForItemDefinitions(kWaitTimeoutMs)) {
            result->Success(flutter::EncodableValue(M({
                {"ok", flutter::EncodableValue(false)},
                {"code", flutter::EncodableValue("itemdefs_not_ready")},
                {"status", flutter::EncodableValue("failed")},
                {"defCount", flutter::EncodableValue(0)},
                {"detail",
                 flutter::EncodableValue(
                     "LoadItemDefinitions timed out — publish ItemDefs in "
                     "Steamworks Inventory Service")},
                {"online", flutter::EncodableValue(true)},
            })));
            return;
          }
          SteamInventoryResult_t handle = k_SteamInventoryResultInvalid;
          if (!SteamInventory()->GetAllItems(&handle)) {
            result->Success(flutter::EncodableValue(M({
                {"ok", flutter::EncodableValue(false)},
                {"code", flutter::EncodableValue("getAllItems_failed")},
                {"status", flutter::EncodableValue("failed")},
                {"defCount",
                 flutter::EncodableValue(
                     static_cast<int32_t>(ItemDefCount()))},
                {"online", flutter::EncodableValue(true)},
            })));
            return;
          }
          const std::string corr = impl_->Next("load");
          {
            std::lock_guard<std::mutex> lock(impl_->mu);
            Impl::Pending p;
            p.kind = "load";
            p.handle = handle;
            impl_->pending[corr] = p;
            impl_->by_handle[handle] = corr;
          }
          flutter::EncodableMap done;
          if (!impl_->WaitForCorr(corr, &done, kWaitTimeoutMs)) {
            result->Success(flutter::EncodableValue(M({
                {"ok", flutter::EncodableValue(false)},
                {"code", flutter::EncodableValue("inventory_timeout")},
                {"status", flutter::EncodableValue("failed")},
                {"defCount",
                 flutter::EncodableValue(
                     static_cast<int32_t>(ItemDefCount()))},
                {"online", flutter::EncodableValue(true)},
            })));
            return;
          }
          auto sit = done.find(flutter::EncodableValue("status"));
          auto iit = done.find(flutter::EncodableValue("items"));
          auto srit = done.find(flutter::EncodableValue("steamResult"));
          auto det = done.find(flutter::EncodableValue("detail"));
          const std::string status =
              sit != done.end() ? std::get<std::string>(sit->second) : "failed";
          flutter::EncodableList items;
          if (iit != done.end()) {
            items = std::get<flutter::EncodableList>(iit->second);
          }
          flutter::EncodableMap out = M({
              {"ok", flutter::EncodableValue(status == "success")},
              {"status", flutter::EncodableValue(status)},
              {"code",
               flutter::EncodableValue(status == "success" ? "ok" : status)},
              {"handle", flutter::EncodableValue(corr)},
              {"items", flutter::EncodableValue(items)},
              {"defCount",
               flutter::EncodableValue(static_cast<int32_t>(ItemDefCount()))},
              {"subscribed",
               flutter::EncodableValue(
                   SteamApps() &&
                   SteamApps()->BIsSubscribedApp(SteamRuntime::kAppId))},
              {"online", flutter::EncodableValue(true)},
          });
          if (srit != done.end()) {
            out[flutter::EncodableValue("steamResult")] = srit->second;
          }
          if (det != done.end()) {
            out[flutter::EncodableValue("detail")] = det->second;
          }
          result->Success(flutter::EncodableValue(out));
          return;
        }

        if (method == "requestPrices") {
          if (!SteamUser()->BLoggedOn()) {
            fail("offline");
            return;
          }
          impl_->prices_corr = impl_->Next("prices");
          SteamAPICall_t call = SteamInventory()->RequestPrices();
          if (call == k_uAPICallInvalid) {
            fail("requestPrices_invalid");
            return;
          }
          impl_->cr_prices.Set(call, impl_.get(), &Impl::OnPrices);
          flutter::EncodableMap done;
          if (!impl_->WaitForCorr(impl_->prices_corr, &done, kWaitTimeoutMs)) {
            fail("requestPrices_timeout");
            return;
          }
          auto sit = done.find(flutter::EncodableValue("status"));
          auto pit = done.find(flutter::EncodableValue("prices"));
          auto cit = done.find(flutter::EncodableValue("currencyCode"));
          const bool ok = sit != done.end() &&
                          std::get<std::string>(sit->second) == "success";
          flutter::EncodableList prices;
          if (pit != done.end()) {
            prices = std::get<flutter::EncodableList>(pit->second);
          }
          std::string currency_code;
          if (cit != done.end() &&
              std::holds_alternative<std::string>(cit->second)) {
            currency_code = std::get<std::string>(cit->second);
          }
          result->Success(flutter::EncodableValue(M({
              {"ok", flutter::EncodableValue(ok)},
              {"status", flutter::EncodableValue(ok ? "success" : "failed")},
              {"currencyCode", flutter::EncodableValue(currency_code)},
              {"prices", flutter::EncodableValue(prices)},
              {"handle", flutter::EncodableValue(impl_->prices_corr)},
          })));
          return;
        }

        if (method == "startPurchase") {
          if (!SteamUser()->BLoggedOn()) {
            fail("offline");
            return;
          }
          if (!args || !std::holds_alternative<flutter::EncodableMap>(*args)) {
            fail("invalid_args");
            return;
          }
          const auto& map = std::get<flutter::EncodableMap>(*args);
          auto defs = IntList(map, "itemDefIds");
          auto qtys = IntList(map, "quantities");
          if (defs.empty() || defs.size() != qtys.size()) {
            fail("invalid_args");
            return;
          }
          for (size_t i = 0; i < defs.size(); ++i) {
            if (defs[i] <= 0 || qtys[i] <= 0) {
              fail("invalid_purchase_item");
              return;
            }
          }
          std::vector<SteamItemDef_t> d(defs.begin(), defs.end());
          std::vector<uint32> q;
          for (auto x : qtys) q.push_back(static_cast<uint32>(x));
          const std::string corr = impl_->Next("purchase");
          SteamAPICall_t call = SteamInventory()->StartPurchase(
              d.data(), q.data(), static_cast<uint32>(d.size()));
          // Phase A: immediate API call failure.
          if (call == k_uAPICallInvalid) {
            result->Success(flutter::EncodableValue(M({
                {"ok", flutter::EncodableValue(false)},
                {"status", flutter::EncodableValue("failed")},
                {"phase", flutter::EncodableValue("start_purchase_api")},
                {"code", flutter::EncodableValue("k_uAPICallInvalid")},
                {"steamResultCode", flutter::EncodableValue(0)},
                {"steamResultName",
                 flutter::EncodableValue("k_uAPICallInvalid")},
                {"apiCallHandle", flutter::EncodableValue("0")},
                {"itemDefIds", flutter::EncodableValue(IntListValue(defs))},
                {"quantities", flutter::EncodableValue(IntListValue(qtys))},
                {"handle", flutter::EncodableValue(corr)},
                {"detail",
                 flutter::EncodableValue(
                     "StartPurchase returned k_uAPICallInvalid")},
            })));
            return;
          }
          {
            std::lock_guard<std::mutex> lock(impl_->mu);
            Impl::Pending p;
            p.kind = "purchase";
            p.expect_orphan_result = true;
            p.item_def_ids = defs;
            p.quantities = qtys;
            p.api_call = static_cast<uint64_t>(call);
            impl_->pending[corr] = p;
          }
          impl_->cr_purchase.Set(call, impl_.get(), &Impl::OnPurchaseInit);
          // Phase C pending: callback will report B (reject) or C (OK+ids).
          result->Success(flutter::EncodableValue(M({
              {"ok", flutter::EncodableValue(true)},
              {"status", flutter::EncodableValue("pending")},
              {"phase", flutter::EncodableValue("start_purchase_accepted")},
              {"handle", flutter::EncodableValue(corr)},
              {"apiCallHandle",
               flutter::EncodableValue(std::to_string(static_cast<uint64_t>(call)))},
              {"itemDefIds", flutter::EncodableValue(IntListValue(defs))},
              {"quantities", flutter::EncodableValue(IntListValue(qtys))},
              {"detail",
               flutter::EncodableValue(
                   "StartPurchase API accepted — await "
                   "SteamInventoryStartPurchaseResult_t; grant only after "
                   "ResultReady + re-query")},
          })));
          return;
        }

        if (method == "consumeItem") {
          if (!SteamUser()->BLoggedOn()) {
            fail("offline");
            return;
          }
          if (!args || !std::holds_alternative<flutter::EncodableMap>(*args)) {
            fail("invalid_args");
            return;
          }
          const auto& map = std::get<flutter::EncodableMap>(*args);
          auto iid = map.find(flutter::EncodableValue("instanceId"));
          auto qit = map.find(flutter::EncodableValue("quantity"));
          if (iid == map.end() ||
              !std::holds_alternative<std::string>(iid->second)) {
            fail("invalid_args");
            return;
          }
          const std::string instance_s = std::get<std::string>(iid->second);
          const int32_t qty = qit == map.end() ? 1 : AsI32(qit->second);
          if (qty != 1) {
            fail("invalid_consume_quantity");
            return;
          }
          SteamItemInstanceID_t item_id = 0;
          try {
            item_id = static_cast<SteamItemInstanceID_t>(std::stoull(instance_s));
          } catch (...) {
            fail("invalid_instance_id");
            return;
          }
          SteamInventoryResult_t handle = k_SteamInventoryResultInvalid;
          const bool accepted =
              SteamInventory()->ConsumeItem(&handle, item_id, 1);
          if (!accepted || handle == k_SteamInventoryResultInvalid) {
            result->Success(flutter::EncodableValue(M({
                {"ok", flutter::EncodableValue(false)},
                {"status", flutter::EncodableValue("failed")},
                {"phase", flutter::EncodableValue("consume_api")},
                {"code", flutter::EncodableValue("consume_failed")},
                {"consumeApiAccepted", flutter::EncodableValue(false)},
                {"instanceId", flutter::EncodableValue(instance_s)},
                {"quantity", flutter::EncodableValue(1)},
                {"detail",
                 flutter::EncodableValue(
                     "ConsumeItem returned false / invalid handle")},
            })));
            return;
          }
          const std::string corr = impl_->Next("consume");
          {
            std::lock_guard<std::mutex> lock(impl_->mu);
            Impl::Pending p;
            p.kind = "consume";
            p.handle = handle;
            impl_->pending[corr] = p;
            impl_->by_handle[handle] = corr;
          }
          result->Success(flutter::EncodableValue(M({
              {"ok", flutter::EncodableValue(true)},
              {"status", flutter::EncodableValue("pending")},
              {"phase", flutter::EncodableValue("consume_accepted")},
              {"consumeApiAccepted", flutter::EncodableValue(true)},
              {"handle", flutter::EncodableValue(corr)},
              {"instanceId", flutter::EncodableValue(instance_s)},
              {"quantity", flutter::EncodableValue(1)},
              {"detail",
               flutter::EncodableValue(
                   "ConsumeItem accepted — await ResultReady; re-query "
                   "GetAllItems for Theme/Astra authority")},
          })));
          return;
        }

        if (method == "exchangeItems") {
          if (!SteamUser()->BLoggedOn()) {
            fail("offline");
            return;
          }
          if (!args || !std::holds_alternative<flutter::EncodableMap>(*args)) {
            fail("invalid_args");
            return;
          }
          const auto& map = std::get<flutter::EncodableMap>(*args);
          auto git = map.find(flutter::EncodableValue("generateItemDefId"));
          auto gqit = map.find(flutter::EncodableValue("generateQuantity"));
          if (git == map.end()) {
            fail("invalid_args");
            return;
          }
          const int32_t gen = AsI32(git->second);
          const int32_t genq = gqit == map.end() ? 1 : AsI32(gqit->second);
          // Steam currently accepts one generated target with quantity one.
          if (gen <= 0 || genq != 1) {
            fail("invalid_generate_quantity");
            return;
          }
          auto ids = StrList(map, "destroyInstanceIds");
          auto qs = IntList(map, "destroyQuantities");
          if (ids.empty() || ids.size() != qs.size()) {
            fail("invalid_args");
            return;
          }
          SteamItemDef_t gen_def = gen;
          uint32 gen_qty = 1;
          std::vector<SteamItemInstanceID_t> destroy;
          std::vector<uint32> destroy_q;
          for (size_t i = 0; i < ids.size(); ++i) {
            if (qs[i] <= 0) {
              fail("invalid_destroy_quantity");
              return;
            }
            try {
              destroy.push_back(static_cast<SteamItemInstanceID_t>(
                  std::stoull(ids[i])));
            } catch (...) {
              fail("invalid_instance_id");
              return;
            }
            destroy_q.push_back(static_cast<uint32>(qs[i]));
          }
          SteamInventoryResult_t handle = k_SteamInventoryResultInvalid;
          const bool accepted = SteamInventory()->ExchangeItems(
              &handle, &gen_def, &gen_qty, 1, destroy.data(),
              destroy_q.data(), static_cast<uint32>(destroy.size()));
          if (!accepted || handle == k_SteamInventoryResultInvalid) {
            result->Success(flutter::EncodableValue(M({
                {"ok", flutter::EncodableValue(false)},
                {"status", flutter::EncodableValue("failed")},
                {"phase", flutter::EncodableValue("exchange_api")},
                {"code", flutter::EncodableValue("exchange_failed")},
                {"exchangeApiAccepted", flutter::EncodableValue(false)},
                {"generateItemDefId", flutter::EncodableValue(gen)},
                {"generateQuantity", flutter::EncodableValue(genq)},
                {"generateArrayLength", flutter::EncodableValue(1)},
                {"destroyCount",
                 flutter::EncodableValue(static_cast<int32_t>(destroy.size()))},
                {"detail",
                 flutter::EncodableValue(
                     "ExchangeItems returned false / invalid handle")},
            })));
            return;
          }
          const std::string corr = impl_->Next("exchange");
          {
            std::lock_guard<std::mutex> lock(impl_->mu);
            Impl::Pending p;
            p.kind = "exchange";
            p.handle = handle;
            impl_->pending[corr] = p;
            impl_->by_handle[handle] = corr;
          }
          result->Success(flutter::EncodableValue(M({
              {"ok", flutter::EncodableValue(true)},
              {"status", flutter::EncodableValue("pending")},
              {"phase", flutter::EncodableValue("exchange_accepted")},
              {"exchangeApiAccepted", flutter::EncodableValue(true)},
              {"handle", flutter::EncodableValue(corr)},
              {"generateItemDefId", flutter::EncodableValue(gen)},
              {"generateQuantity", flutter::EncodableValue(genq)},
              {"generateArrayLength", flutter::EncodableValue(1)},
              {"destroyCount",
               flutter::EncodableValue(static_cast<int32_t>(destroy.size()))},
              {"detail",
               flutter::EncodableValue(
                   "ExchangeItems accepted — await ResultReady; theme grant "
                   "authority is GetAllItems (20001), not this acceptance")},
          })));
          return;
        }

        if (method == "addPromoItem" || method == "triggerItemDrop") {
          if (!SteamUser()->BLoggedOn()) {
            fail("offline");
            return;
          }
          if (!args || !std::holds_alternative<flutter::EncodableMap>(*args)) {
            fail("invalid_args");
            return;
          }
          const auto& map = std::get<flutter::EncodableMap>(*args);
          const char* key =
              method == "addPromoItem" ? "itemDefId" : "generatorDefId";
          auto it = map.find(flutter::EncodableValue(key));
          if (it == map.end()) {
            fail("invalid_args");
            return;
          }
          const int32_t def = AsI32(it->second);
          SteamInventoryResult_t handle = k_SteamInventoryResultInvalid;
          const bool ok = method == "addPromoItem"
                              ? SteamInventory()->AddPromoItem(&handle, def)
                              : SteamInventory()->TriggerItemDrop(&handle, def);
          if (!ok) {
            fail(method == "addPromoItem" ? "promo_failed" : "drop_failed");
            return;
          }
          const std::string corr = impl_->Next(
              method == "addPromoItem" ? "promo" : "playtimeDrop");
          {
            std::lock_guard<std::mutex> lock(impl_->mu);
            Impl::Pending p;
            p.kind = method == "addPromoItem" ? "promo" : "playtimeDrop";
            p.handle = handle;
            impl_->pending[corr] = p;
            impl_->by_handle[handle] = corr;
          }
          result->Success(flutter::EncodableValue(M({
              {"ok", flutter::EncodableValue(true)},
              {"status", flutter::EncodableValue("pending")},
              {"handle", flutter::EncodableValue(corr)},
          })));
          return;
        }

        if (method == "poll") {
          std::lock_guard<std::mutex> lock(impl_->mu);
          flutter::EncodableList ops;
          for (const auto& op : impl_->completed) {
            ops.push_back(flutter::EncodableValue(op));
          }
          impl_->completed.clear();
          result->Success(flutter::EncodableValue(M({
              {"ok", flutter::EncodableValue(true)},
              {"ops", flutter::EncodableValue(ops)},
          })));
          return;
        }

        if (method == "destroyResult") {
          // Destroyed exactly once in OnResultReady.
          result->Success(flutter::EncodableValue(
              M({{"ok", flutter::EncodableValue(true)}})));
          return;
        }

        result->NotImplemented();
      });
}
