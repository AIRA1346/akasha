#include "steam_runtime.h"

#include <atomic>
#include <string>

#include <windows.h>

#pragma warning(push)
#pragma warning(disable : 4996)
#include "steam/steam_api.h"
#pragma warning(pop)

namespace SteamRuntime {
namespace {

std::atomic<bool> g_attempted{false};
std::atomic<bool> g_initialized{false};
std::atomic<bool> g_restart{false};
std::atomic<bool> g_shutdown{false};
std::atomic<bool> g_overlay_active{false};
std::atomic<bool> g_overlay_enabled{false};
std::atomic<bool> g_overlay_first_sample_recorded{false};
std::atomic<bool> g_overlay_first_sample_enabled{false};
std::atomic<bool> g_last_needs_present{false};
std::atomic<uint64_t> g_process_start_tick_ms{0};
std::atomic<uint64_t> g_last_overlay_sample_tick_ms{0};
std::atomic<uint64_t> g_timer_ticks{0};
std::atomic<uint64_t> g_needs_present_true{0};
std::atomic<uint64_t> g_force_redraws{0};
std::atomic<uint64_t> g_overlay_enabled_samples{0};
std::atomic<uint64_t> g_overlay_enabled_transitions{0};
std::atomic<uint64_t> g_overlay_activated_callbacks{0};
std::atomic<uint64_t> g_overlay_deactivated_callbacks{0};
std::atomic<int64_t> g_overlay_first_sample_elapsed_ms{-1};
std::atomic<int64_t> g_overlay_first_true_elapsed_ms{-1};
std::atomic<int64_t> g_overlay_last_callback_elapsed_ms{-1};

constexpr uint64_t kOverlaySampleIntervalMs = 1000;

}  // namespace

bool Bootstrap() {
  if (g_attempted.exchange(true)) {
    return !g_restart.load();
  }
  g_process_start_tick_ms = GetTickCount64();

  if (SteamAPI_RestartAppIfNecessary(kAppId)) {
    g_restart = true;
    OutputDebugStringW(
        L"[SteamRuntime] RestartAppIfNecessary=true - exit for Steam relaunch\n");
    return false;
  }

  if (!SteamAPI_Init()) {
    OutputDebugStringW(
        L"[SteamRuntime] SteamAPI_Init failed - continuing without Steam\n");
    return true;
  }

  g_initialized = true;
  if (SteamInventory()) {
    SteamInventory()->LoadItemDefinitions();
  }
  ObserveOverlayEnabled();
  OutputDebugStringW(L"[SteamRuntime] SteamAPI_Init ok (before Flutter/D3D)\n");
  return true;
}

void Pump() {
  if (g_initialized.load() && !g_shutdown.load()) {
    SteamAPI_RunCallbacks();
    ObserveOverlayEnabled();
  }
}

void Shutdown() {
  if (g_shutdown.exchange(true)) {
    return;
  }
  if (g_initialized.exchange(false)) {
    SteamAPI_Shutdown();
    OutputDebugStringW(L"[SteamRuntime] SteamAPI_Shutdown\n");
  }
}

bool InitializationAttempted() { return g_attempted.load(); }
bool Initialized() { return g_initialized.load(); }
bool RestartRequested() { return g_restart.load(); }
bool ShutdownPerformed() { return g_shutdown.load(); }

bool OverlayNeedsPresent() {
  if (!g_initialized.load() || g_shutdown.load() || !SteamUtils()) {
    g_last_needs_present = false;
    return false;
  }
  const bool needs = SteamUtils()->BOverlayNeedsPresent();
  const bool prev = g_last_needs_present.exchange(needs);
  if (needs) {
    g_needs_present_true.fetch_add(1);
  }
  if (prev != needs) {
    OutputDebugStringW(needs ? L"[SteamRuntime] BOverlayNeedsPresent true\n"
                             : L"[SteamRuntime] BOverlayNeedsPresent false\n");
  }
  return needs;
}

void ObserveOverlayEnabled() {
  if (!g_initialized.load() || g_shutdown.load() || !SteamUtils()) {
    return;
  }

  const uint64_t now = GetTickCount64();
  const uint64_t previous_sample = g_last_overlay_sample_tick_ms.load();
  if (previous_sample != 0 &&
      now - previous_sample < kOverlaySampleIntervalMs) {
    return;
  }
  g_last_overlay_sample_tick_ms = now;

  const bool enabled = SteamUtils()->IsOverlayEnabled();
  const int64_t elapsed = static_cast<int64_t>(ProcessUptimeMs());
  g_overlay_enabled_samples.fetch_add(1);
  if (!g_overlay_first_sample_recorded.exchange(true)) {
    g_overlay_first_sample_enabled = enabled;
    g_overlay_first_sample_elapsed_ms = elapsed;
    g_overlay_enabled = enabled;
    if (enabled) {
      g_overlay_first_true_elapsed_ms = elapsed;
    }
    OutputDebugStringW(
        enabled ? L"[SteamRuntime] Overlay initial sample enabled\n"
                : L"[SteamRuntime] Overlay initial sample disabled\n");
    return;
  }

  const bool previous = g_overlay_enabled.exchange(enabled);
  if (previous != enabled) {
    g_overlay_enabled_transitions.fetch_add(1);
    if (enabled && g_overlay_first_true_elapsed_ms.load() < 0) {
      g_overlay_first_true_elapsed_ms = elapsed;
    }
    OutputDebugStringW(enabled ? L"[SteamRuntime] Overlay enabled transition\n"
                               : L"[SteamRuntime] Overlay disabled transition\n");
  }
}

bool IsOverlayEnabled() { return g_overlay_enabled.load(); }
bool OverlayFirstSampleEnabled() {
  return g_overlay_first_sample_enabled.load();
}
int64_t OverlayFirstSampleElapsedMs() {
  return g_overlay_first_sample_elapsed_ms.load();
}
int64_t OverlayFirstTrueElapsedMs() {
  return g_overlay_first_true_elapsed_ms.load();
}
uint64_t OverlayEnabledSampleCount() {
  return g_overlay_enabled_samples.load();
}
uint64_t OverlayEnabledTransitionCount() {
  return g_overlay_enabled_transitions.load();
}

void SetOverlayActive(bool active) {
  g_overlay_active = active;
  g_overlay_last_callback_elapsed_ms =
      static_cast<int64_t>(ProcessUptimeMs());
  if (active) {
    g_overlay_activated_callbacks.fetch_add(1);
    OutputDebugStringW(L"[SteamRuntime] GameOverlayActivated_t active\n");
  } else {
    g_overlay_deactivated_callbacks.fetch_add(1);
    OutputDebugStringW(L"[SteamRuntime] GameOverlayActivated_t inactive\n");
  }
}
bool IsOverlayActive() { return g_overlay_active.load(); }
uint64_t OverlayActivatedCallbackCount() {
  return g_overlay_activated_callbacks.load();
}
uint64_t OverlayDeactivatedCallbackCount() {
  return g_overlay_deactivated_callbacks.load();
}
int64_t OverlayLastCallbackElapsedMs() {
  return g_overlay_last_callback_elapsed_ms.load();
}

uint64_t ProcessUptimeMs() {
  const uint64_t start = g_process_start_tick_ms.load();
  if (start == 0) return 0;
  return GetTickCount64() - start;
}

void NoteSteamTimerTick() { g_timer_ticks.fetch_add(1); }
void NoteOverlayForceRedraw() { g_force_redraws.fetch_add(1); }
uint64_t SteamTimerTickCount() { return g_timer_ticks.load(); }
uint64_t OverlayNeedsPresentTrueCount() { return g_needs_present_true.load(); }
uint64_t OverlayForceRedrawCount() { return g_force_redraws.load(); }
bool LastOverlayNeedsPresent() { return g_last_needs_present.load(); }

std::string ExecutablePath() {
  wchar_t buf[MAX_PATH] = {};
  const DWORD n = GetModuleFileNameW(nullptr, buf, MAX_PATH);
  if (n == 0 || n >= MAX_PATH) return {};
  int bytes =
      WideCharToMultiByte(CP_UTF8, 0, buf, -1, nullptr, 0, nullptr, nullptr);
  if (bytes <= 1) return {};
  std::string out(static_cast<size_t>(bytes - 1), '\0');
  WideCharToMultiByte(CP_UTF8, 0, buf, -1, out.data(), bytes, nullptr, nullptr);
  return out;
}

std::string CurrentWorkingDirectory() {
  wchar_t buf[MAX_PATH] = {};
  const DWORD n = GetCurrentDirectoryW(MAX_PATH, buf);
  if (n == 0 || n >= MAX_PATH) return {};
  int bytes =
      WideCharToMultiByte(CP_UTF8, 0, buf, -1, nullptr, 0, nullptr, nullptr);
  if (bytes <= 1) return {};
  std::string out(static_cast<size_t>(bytes - 1), '\0');
  WideCharToMultiByte(CP_UTF8, 0, buf, -1, out.data(), bytes, nullptr, nullptr);
  return out;
}

std::string BuildMode() {
#if defined(_DEBUG)
  return "Debug";
#elif defined(AKASHA_PROFILE)
  return "Profile";
#else
  return "Release";
#endif
}

}  // namespace SteamRuntime
