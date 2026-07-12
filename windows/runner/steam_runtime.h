#ifndef RUNNER_STEAM_RUNTIME_H_
#define RUNNER_STEAM_RUNTIME_H_

#include <cstdint>
#include <string>

// Minimal process-lifetime Steam bootstrap for Inventory POC.
// Init must run before Flutter/D3D. Shutdown once at process exit.
namespace SteamRuntime {

constexpr uint32_t kAppId = 4677560;

// SteamAPI_RestartAppIfNecessary then SteamAPI_Init.
// Returns false if the process should exit (restart requested).
bool Bootstrap();

void Pump();
void Shutdown();

bool InitializationAttempted();
bool Initialized();
bool RestartRequested();
bool ShutdownPerformed();

// ISteamUtils::BOverlayNeedsPresent - event-driven apps must Present when true.
bool OverlayNeedsPresent();

// Optional process-lifetime overlay open state (GameOverlayActivated_t).
void SetOverlayActive(bool active);
bool IsOverlayActive();

// Timer / Present diagnostics (UI thread).
void NoteSteamTimerTick();
void NoteOverlayForceRedraw();
uint64_t SteamTimerTickCount();
uint64_t OverlayNeedsPresentTrueCount();
uint64_t OverlayForceRedrawCount();
bool LastOverlayNeedsPresent();

std::string ExecutablePath();
std::string CurrentWorkingDirectory();
std::string BuildMode();

}  // namespace SteamRuntime

#endif  // RUNNER_STEAM_RUNTIME_H_
