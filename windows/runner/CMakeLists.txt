cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

set(STEAMWORKS_SDK_ROOT "C:/dev/steamworks/steamworks_sdk_164/sdk" CACHE PATH
  "Steamworks SDK root (contains public/ and redistributable_bin/)")

add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "steam_runtime.cpp"
  "steam_inventory_poc_channel.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

apply_standard_settings(${BINARY_NAME})

# Capture source identity at configure/build time. The running app never reads
# a mutable worktree or invokes Git. Tracking HEAD and its current ref keeps an
# incremental build from silently retaining a stale commit after a new commit.
set(AKASHA_REPO_ROOT "${CMAKE_SOURCE_DIR}/..")
execute_process(
  COMMAND git rev-parse HEAD
  WORKING_DIRECTORY "${AKASHA_REPO_ROOT}"
  OUTPUT_VARIABLE AKASHA_GIT_COMMIT
  OUTPUT_STRIP_TRAILING_WHITESPACE
  ERROR_QUIET
  RESULT_VARIABLE AKASHA_GIT_RESULT
)
string(LENGTH "${AKASHA_GIT_COMMIT}" AKASHA_GIT_COMMIT_LENGTH)
if(NOT AKASHA_GIT_RESULT EQUAL 0 OR
   NOT AKASHA_GIT_COMMIT_LENGTH EQUAL 40 OR
   NOT AKASHA_GIT_COMMIT MATCHES "^[0-9a-fA-F]+$")
  set(AKASHA_GIT_COMMIT "unknown")
endif()
execute_process(
  COMMAND git rev-parse --git-path HEAD
  WORKING_DIRECTORY "${AKASHA_REPO_ROOT}"
  OUTPUT_VARIABLE AKASHA_GIT_HEAD_PATH
  OUTPUT_STRIP_TRAILING_WHITESPACE
  ERROR_QUIET
)
if(AKASHA_GIT_HEAD_PATH)
  get_filename_component(AKASHA_GIT_HEAD_ABSOLUTE
    "${AKASHA_GIT_HEAD_PATH}" ABSOLUTE BASE_DIR "${AKASHA_REPO_ROOT}")
  set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
    "${AKASHA_GIT_HEAD_ABSOLUTE}")
endif()
execute_process(
  COMMAND git symbolic-ref -q HEAD
  WORKING_DIRECTORY "${AKASHA_REPO_ROOT}"
  OUTPUT_VARIABLE AKASHA_GIT_REF
  OUTPUT_STRIP_TRAILING_WHITESPACE
  ERROR_QUIET
)
if(AKASHA_GIT_REF)
  execute_process(
    COMMAND git rev-parse --git-path "${AKASHA_GIT_REF}"
    WORKING_DIRECTORY "${AKASHA_REPO_ROOT}"
    OUTPUT_VARIABLE AKASHA_GIT_REF_PATH
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
  )
  get_filename_component(AKASHA_GIT_REF_ABSOLUTE
    "${AKASHA_GIT_REF_PATH}" ABSOLUTE BASE_DIR "${AKASHA_REPO_ROOT}")
  set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
    "${AKASHA_GIT_REF_ABSOLUTE}")
endif()

target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")
target_compile_definitions(${BINARY_NAME} PRIVATE
  "AKASHA_GIT_COMMIT=\"${AKASHA_GIT_COMMIT}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE
  "$<$<CONFIG:Profile>:AKASHA_PROFILE=1>")
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")
target_compile_definitions(${BINARY_NAME} PRIVATE "AKASHA_STEAM_INVENTORY_POC=1")

target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE
  "${CMAKE_SOURCE_DIR}"
  "${STEAMWORKS_SDK_ROOT}/public"
)
target_link_libraries(${BINARY_NAME} PRIVATE
  "${STEAMWORKS_SDK_ROOT}/redistributable_bin/win64/steam_api64.lib"
)

add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${STEAMWORKS_SDK_ROOT}/redistributable_bin/win64/steam_api64.dll"
    "$<TARGET_FILE_DIR:${BINARY_NAME}>/steam_api64.dll"
  COMMENT "Copy Steam API redistributable"
)

set_source_files_properties(
  "steam_inventory_poc_channel.cpp"
  "steam_runtime.cpp"
  PROPERTIES COMPILE_OPTIONS "/W3;/wd4100;/wd4996;/wd4819"
)
