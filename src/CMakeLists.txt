project(Telescope)

cmake_minimum_required(VERSION 3.7)
set(CMAKE_MACOSX_RPATH 1)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

find_package(JlCxx)
get_target_property(JlCxx_location JlCxx::cxxwrap_julia LOCATION)
get_filename_component(JlCxx_location ${JlCxx_location} DIRECTORY)
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib;${JlCxx_location}")

message(STATUS "Found JlCxx at ${JlCxx_location}")

add_library(telescope SHARED Telescope.cpp)

target_link_libraries(telescope JlCxx::cxxwrap_julia)
target_link_libraries(telescope SDL2 SDL2_ttf SDL2_mixer SDL2_image)
target_link_libraries(telescope vulkan)

install(TARGETS
telescope
LIBRARY DESTINATION lib
ARCHIVE DESTINATION lib
RUNTIME DESTINATION lib)