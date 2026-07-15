#ifndef RUNNER_STEAM_INVENTORY_POC_CHANNEL_H_
#define RUNNER_STEAM_INVENTORY_POC_CHANNEL_H_

#include <memory>

#include <flutter/flutter_engine.h>

// MethodChannel akasha/steam_inventory (+ events stream).
// Links ISteamInventory when SteamAPI_Init succeeds; otherwise returns
// explicit failure codes (steam_not_running, offline, ...).
class SteamInventoryPocChannel {
 public:
  SteamInventoryPocChannel();
  ~SteamInventoryPocChannel();

  void Register(flutter::FlutterEngine* engine);

  // Call from the Windows message loop so Steam callbacks progress.
  static void PumpCallbacks();

  static bool IsSteamReady();

 private:
  struct Impl;
  std::unique_ptr<Impl> impl_;
};

#endif  // RUNNER_STEAM_INVENTORY_POC_CHANNEL_H_
