#include "steam_inventory_poc_channel.h"

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

constexpr char kMethodChannel[] = "akasha/steam_inventory_poc";
constexpr char kEventChannel[] = "akasha/steam_inventory_poc/events";
constexpr uint32_t kAppId = 4677560;
constexpr DWORD kWaitTimeoutMs = 20000;

flutter::EncodableMap M(
    std::initializer_list<std::pair<const char*, flutter::EncodableValue>> xs) {
  flutter::EncodableMap m;
  for (const auto& x : xs) {
    m[flutter::EncodableValue(x.first)] = x.second;
  }
  return m;
}

std::string StatusOf(EResult r) {
  switch (r) {
    case k_EResultOK:
      return "success";
    case k_EResultPending:
      return "pending";
    case k_EResultFail:
      return "canceled";
    case k_EResultExpired:
      return "indeterminate";
    default:
      return "failed";
  }
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

}  // namespace

struct SteamInventoryPocChannel::Impl {
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> methods;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> events;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink;
  std::mutex mu;

  bool inited = false;
  bool online = false;
  CSteamID user{};
  int seq = 0;

  struct Pending {
    std::string kind;
    SteamInventoryResult_t handle = k_SteamInventoryResultInvalid;
    bool expect_orphan_result = false;  // StartPurchase
  };
  std::map<std::string, Pending> pending;
  std::map<SteamInventoryResult_t, std::string> by_handle;
  std::vector<flutter::EncodableMap> completed;

  CCallResult<Impl, SteamInventoryStartPurchaseResult_t> cr_purchase;
  CCallResult<Impl, SteamInventoryRequestPricesResult_t> cr_prices;
  std::string prices_corr;

  CCallback<Impl, SteamInventoryResultReady_t> cb_result_ready;
  CCallback<Impl, SteamInventoryFullUpdate_t> cb_full_update;

  Impl()
      : cb_result_ready(this, &Impl::OnResultReady),
        cb_full_update(this, &Impl::OnFullUpdate) {}

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
    std::string status = StatusOf(cb->m_result);
    if (cb->m_result == k_EResultOK && !id_ok) {
      status = "failed";
    }

    flutter::EncodableList items;
    if (cb->m_result == k_EResultOK && id_ok) {
      items = ReadItems(cb->m_handle);
    }

    Emit(M({
        {"kind", flutter::EncodableValue(kind)},
        {"status", flutter::EncodableValue(status)},
        {"handle", flutter::EncodableValue(corr)},
        {"steamResult",
         flutter::EncodableValue(std::to_string(static_cast<int>(cb->m_result)))},
        {"steamIdOk", flutter::EncodableValue(id_ok)},
        {"items", flutter::EncodableValue(items)},
        {"detail",
         flutter::EncodableValue(
             id_ok ? "result_ready ? re-query inventory for authority"
                   : "steamid_mismatch")},
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

  void OnPurchaseInit(SteamInventoryStartPurchaseResult_t* r, bool io_fail) {
    std::string corr;
    {
      std::lock_guard<std::mutex> lock(mu);
      for (auto& e : pending) {
        if (e.second.kind == "purchase" && e.second.expect_orphan_result) {
          corr = e.first;
        }
      }
    }
    if (io_fail || !r) {
      Emit(M({{"kind", flutter::EncodableValue("purchase")},
              {"status", flutter::EncodableValue("failed")},
              {"handle", flutter::EncodableValue(corr)},
              {"detail", flutter::EncodableValue("start_purchase_io_failure")}}));
      return;
    }
    if (r->m_result != k_EResultOK) {
      Emit(M({{"kind", flutter::EncodableValue("purchase")},
              {"status", flutter::EncodableValue(StatusOf(r->m_result))},
              {"handle", flutter::EncodableValue(corr)},
              {"orderId",
               flutter::EncodableValue(std::to_string(r->m_ulOrderID))},
              {"detail", flutter::EncodableValue("purchase_not_authorized")}}));
      std::lock_guard<std::mutex> lock(mu);
      pending.erase(corr);
      return;
    }
    Emit(M({{"kind", flutter::EncodableValue("purchase")},
            {"status", flutter::EncodableValue("pending")},
            {"handle", flutter::EncodableValue(corr)},
            {"orderId",
             flutter::EncodableValue(std::to_string(r->m_ulOrderID))},
            {"transId",
             flutter::EncodableValue(std::to_string(r->m_ulTransID))},
            {"detail",
             flutter::EncodableValue(
                 "overlay/init ok ? wait ResultReady; do not grant yet")}}));
  }

  void OnPrices(SteamInventoryRequestPricesResult_t* r, bool io_fail) {
    flutter::EncodableList prices;
    std::string status = "failed";
    if (!io_fail && r && r->m_result == k_EResultOK) {
      status = "success";
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
            {"prices", flutter::EncodableValue(prices)}}));
  }

  bool WaitForCorr(const std::string& corr, flutter::EncodableMap* out,
                   DWORD timeout_ms) {
    const DWORD start = GetTickCount();
    while (GetTickCount() - start < timeout_ms) {
      SteamAPI_RunCallbacks();
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
std::atomic<bool> g_ready{false};
}  // namespace

SteamInventoryPocChannel::SteamInventoryPocChannel()
    : impl_(std::make_unique<Impl>()) {}

SteamInventoryPocChannel::~SteamInventoryPocChannel() {
  if (impl_->inited) {
    SteamAPI_Shutdown();
    impl_->inited = false;
    g_ready = false;
  }
}

bool SteamInventoryPocChannel::IsSteamReady() { return g_ready.load(); }

void SteamInventoryPocChannel::PumpCallbacks() {
  if (g_ready.load()) SteamAPI_RunCallbacks();
}

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

        if (method == "initialize" || method == "init") {
          if (impl_->inited) {
            result->Success(flutter::EncodableValue(M({
                {"ok", flutter::EncodableValue(true)},
                {"online", flutter::EncodableValue(impl_->online)},
                {"appId", flutter::EncodableValue(static_cast<int32_t>(kAppId))},
            })));
            return;
          }
          if (SteamAPI_RestartAppIfNecessary(kAppId)) {
            fail("restart_via_steam");
            return;
          }
          if (!SteamAPI_Init()) {
            fail("steam_not_running");
            return;
          }
          impl_->inited = true;
          g_ready = true;
          impl_->user = SteamUser()->GetSteamID();
          impl_->online = SteamUser()->BLoggedOn();
          SteamInventory()->LoadItemDefinitions();
          result->Success(flutter::EncodableValue(M({
              {"ok", flutter::EncodableValue(true)},
              {"online", flutter::EncodableValue(impl_->online)},
              {"appId", flutter::EncodableValue(static_cast<int32_t>(kAppId))},
              {"steamId",
               flutter::EncodableValue(
                   std::to_string(impl_->user.ConvertToUint64()))},
          })));
          return;
        }

        if (method == "shutdown") {
          if (impl_->inited) {
            SteamAPI_Shutdown();
            impl_->inited = false;
            impl_->online = false;
            g_ready = false;
          }
          result->Success(flutter::EncodableValue(
              M({{"ok", flutter::EncodableValue(true)}})));
          return;
        }

        if (!impl_->inited) {
          fail("not_initialized");
          return;
        }

        if (method == "getInventory" || method == "getAllItems") {
          if (!SteamUser()->BLoggedOn()) {
            fail("offline");
            return;
          }
          SteamInventoryResult_t handle = k_SteamInventoryResultInvalid;
          if (!SteamInventory()->GetAllItems(&handle)) {
            fail("getAllItems_failed");
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
            fail("inventory_timeout");
            return;
          }
          auto sit = done.find(flutter::EncodableValue("status"));
          auto iit = done.find(flutter::EncodableValue("items"));
          const std::string status =
              sit != done.end() ? std::get<std::string>(sit->second) : "failed";
          flutter::EncodableList items;
          if (iit != done.end()) {
            items = std::get<flutter::EncodableList>(iit->second);
          }
          result->Success(flutter::EncodableValue(M({
              {"ok", flutter::EncodableValue(status == "success")},
              {"status", flutter::EncodableValue(status)},
              {"handle", flutter::EncodableValue(corr)},
              {"items", flutter::EncodableValue(items)},
          })));
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
          const bool ok = sit != done.end() &&
                          std::get<std::string>(sit->second) == "success";
          flutter::EncodableList prices;
          if (pit != done.end()) {
            prices = std::get<flutter::EncodableList>(pit->second);
          }
          result->Success(flutter::EncodableValue(M({
              {"ok", flutter::EncodableValue(ok)},
              {"status", flutter::EncodableValue(ok ? "success" : "failed")},
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
          std::vector<SteamItemDef_t> d(defs.begin(), defs.end());
          std::vector<uint32> q;
          for (auto x : qtys) q.push_back(static_cast<uint32>(x));
          const std::string corr = impl_->Next("purchase");
          {
            std::lock_guard<std::mutex> lock(impl_->mu);
            Impl::Pending p;
            p.kind = "purchase";
            p.expect_orphan_result = true;
            impl_->pending[corr] = p;
          }
          SteamAPICall_t call = SteamInventory()->StartPurchase(
              d.data(), q.data(), static_cast<uint32>(d.size()));
          if (call == k_uAPICallInvalid) {
            fail("startPurchase_invalid");
            return;
          }
          impl_->cr_purchase.Set(call, impl_.get(), &Impl::OnPurchaseInit);
          result->Success(flutter::EncodableValue(M({
              {"ok", flutter::EncodableValue(true)},
              {"status", flutter::EncodableValue("pending")},
              {"handle", flutter::EncodableValue(corr)},
              {"detail",
               flutter::EncodableValue(
                   "StartPurchase accepted ? not granted until ResultReady + "
                   "re-query")},
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
          auto ids = StrList(map, "destroyInstanceIds");
          auto qs = IntList(map, "destroyQuantities");
          if (ids.empty() || ids.size() != qs.size()) {
            fail("invalid_args");
            return;
          }
          SteamItemDef_t gen_def = gen;
          uint32 gen_qty = static_cast<uint32>(genq);
          std::vector<SteamItemInstanceID_t> destroy;
          std::vector<uint32> destroy_q;
          for (size_t i = 0; i < ids.size(); ++i) {
            destroy.push_back(static_cast<SteamItemInstanceID_t>(
                std::stoull(ids[i])));
            destroy_q.push_back(static_cast<uint32>(qs[i]));
          }
          SteamInventoryResult_t handle = k_SteamInventoryResultInvalid;
          if (!SteamInventory()->ExchangeItems(
                  &handle, &gen_def, &gen_qty, 1, destroy.data(),
                  destroy_q.data(), static_cast<uint32>(destroy.size()))) {
            fail("exchange_failed");
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
              {"handle", flutter::EncodableValue(corr)},
              {"detail",
               flutter::EncodableValue(
                   "ExchangeItems accepted ? unlock only after ResultReady + "
                   "re-query")},
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
