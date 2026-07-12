#include "utils.h"

#include <flutter_windows.h>
#include <fcntl.h>
#include <io.h>
#include <windows.h>

#include <cstdint>
#include <iostream>

namespace {

bool IsValidStandardHandle(HANDLE handle) {
  return handle != nullptr && handle != INVALID_HANDLE_VALUE;
}

void RestoreStandardHandle(DWORD which, HANDLE handle) {
  if (IsValidStandardHandle(handle)) {
    ::SetStdHandle(which, handle);
  }
}

void RedirectStandardStream(DWORD which, int descriptor, int flags) {
  HANDLE handle = ::GetStdHandle(which);
  if (!IsValidStandardHandle(handle)) {
    return;
  }
  int stream_descriptor = _open_osfhandle(
      reinterpret_cast<intptr_t>(handle), flags);
  if (stream_descriptor == -1) {
    return;
  }
  _dup2(stream_descriptor, descriptor);
  _close(stream_descriptor);
}

void RedirectStandardStreamsToConsole() {
  RedirectStandardStream(STD_INPUT_HANDLE, 0, _O_RDONLY);
  RedirectStandardStream(STD_OUTPUT_HANDLE, 1, _O_WRONLY);
  RedirectStandardStream(STD_ERROR_HANDLE, 2, _O_WRONLY);
  std::ios::sync_with_stdio();
  FlutterDesktopResyncOutputStreams();
}

}  // namespace

bool AttachToParentConsole() {
  HANDLE stdin_handle = ::GetStdHandle(STD_INPUT_HANDLE);
  HANDLE stdout_handle = ::GetStdHandle(STD_OUTPUT_HANDLE);
  HANDLE stderr_handle = ::GetStdHandle(STD_ERROR_HANDLE);
  if (!::AttachConsole(ATTACH_PARENT_PROCESS)) {
    return false;
  }
  // A command-mode caller may pipe JSON through the GUI-subsystem executable.
  // AttachConsole initializes missing handles to CONIN/CONOUT, so restore any
  // inherited pipe handles before binding the C runtime streams.
  RestoreStandardHandle(STD_INPUT_HANDLE, stdin_handle);
  RestoreStandardHandle(STD_OUTPUT_HANDLE, stdout_handle);
  RestoreStandardHandle(STD_ERROR_HANDLE, stderr_handle);
  RedirectStandardStreamsToConsole();
  return true;
}

void CreateAndAttachConsole() {
  if (::AllocConsole()) {
    RedirectStandardStreamsToConsole();
  }
}

std::vector<std::string> GetCommandLineArguments() {
  // Convert the UTF-16 command line arguments to UTF-8 for the Engine to use.
  int argc;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) {
    return std::vector<std::string>();
  }

  std::vector<std::string> command_line_arguments;

  // Skip the first argument as it's the binary name.
  for (int i = 1; i < argc; i++) {
    command_line_arguments.push_back(Utf8FromUtf16(argv[i]));
  }

  ::LocalFree(argv);

  return command_line_arguments;
}

std::string Utf8FromUtf16(const wchar_t* utf16_string) {
  if (utf16_string == nullptr) {
    return std::string();
  }
  // First, find the length of the string with a safe upper bound (CWE-126).
  // UNICODE_STRING_MAX_CHARS (32767) is the maximum length of a UNICODE_STRING.
  int input_length = static_cast<int>(wcsnlen(utf16_string, UNICODE_STRING_MAX_CHARS));
  // Now use that bounded length to determine the required buffer size.
  // When an explicit length is passed, WideCharToMultiByte does not include
  // the null terminator in its returned size.
  int target_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      input_length, nullptr, 0, nullptr, nullptr);
  std::string utf8_string;
  if (target_length == 0 || static_cast<size_t>(target_length) > utf8_string.max_size()) {
    return utf8_string;
  }
  utf8_string.resize(target_length);
  int converted_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      input_length, utf8_string.data(), target_length, nullptr, nullptr);
  if (converted_length == 0) {
    return std::string();
  }
  return utf8_string;
}
