set(CREATE_RUBY TRUE CACHE BOOL "Do you want to create the Ruby interface")

if (CREATE_RUBY)
  find_package(SWIG REQUIRED)
  include(${SWIG_USE_FILE})
  message(STATUS "${SWIG_USE_FILE}")
endif ()

include_directories(${CMAKE_BINARY_DIR}/fossil_cmake)
include_directories(${CMAKE_SOURCE_DIR}/fossil)

if (CREATE_RUBY)
  find_package(Ruby REQUIRED)
  set(CMAKE_SWIG_FLAGS "-Wall;-module;fossil")
  include_directories(${RUBY_INCLUDE_PATH})
  swig_add_module(fossil ruby fossil.i)
  swig_link_libraries(fossil ${RUBY_LIBRARY})
  set_target_properties(fossil PROPERTIES PREFIX "")
  target_link_libraries(fossil fossilly)
endif (CREATE_RUBY)

