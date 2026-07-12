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
std::atomic<bool> g_last_needs_present{false};
std::atomic<uint64_t> g_timer_ticks{0};
std::atomic<uint64_t> g_needs_present_true{0};
std::atomic<uint64_t> g_force_redraws{0};

}  // namespace

bool Bootstrap() {
  if (g_attempted.exchange(true)) {
    return !g_restart.load();
  }

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
  OutputDebugStringW(L"[SteamRuntime] SteamAPI_Init ok (before Flutter/D3D)\n");
  return true;
}

void Pump() {
  if (g_initialized.load() && !g_shutdown.load()) {
    SteamAPI_RunCallbacks();
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

void SetOverlayActive(bool active) { g_overlay_active = active; }
bool IsOverlayActive() { return g_overlay_active.load(); }

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
#else
  return "Release";
#endif
}

}  // namespace SteamRuntime
