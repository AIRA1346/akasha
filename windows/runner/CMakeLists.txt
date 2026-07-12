cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

set(STEAMWORKS_SDK_ROOT "C:/dev/steamworks/steamworks_sdk_164/sdk" CACHE PATH
  "Steamworks SDK root (contains public/ and redistributable_bin/)")

add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "steam_inventory_poc_channel.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

apply_standard_settings(${BINARY_NAME})

target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")
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
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${CMAKE_CURRENT_SOURCE_DIR}/steam_appid.txt"
    "$<TARGET_FILE_DIR:${BINARY_NAME}>/steam_appid.txt"
  COMMENT "Copy Steam API redistributable and steam_appid.txt"
)

set_source_files_properties("steam_inventory_poc_channel.cpp" PROPERTIES
  COMPILE_OPTIONS "/W3;/wd4100;/wd4996;/wd4819"
)
