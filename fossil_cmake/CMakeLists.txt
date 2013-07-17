set(WORKING_DIR ${CMAKE_CURRENT_SOURCE_DIR}/..)
set(OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR})

if (MINGW)
  # langinfo.h missing?
  message(STATUS "Internationalization may not be working under MSYS right now")
  add_definitions(-DFOSSIL_I18N=0)
endif (MINGW)

find_package(OpenSSL)
if (OPENSSL_FOUND)
  add_definitions(-DFOSSIL_ENABLE_SSL=1)
  include_directories(${OPENSSL_INCLUDE_DIR})
endif ()

add_executable(makeheaders ${WORKING_DIR}/fossil/src/makeheaders.c)
add_executable(translate ${WORKING_DIR}/fossil/src/translate.c)
add_executable(mkindex ${WORKING_DIR}/fossil/src/mkindex.c)

get_target_property(MAKEHEADERS_LOC makeheaders LOCATION)
get_target_property(TRANSLATE_LOC translate LOCATION)
get_target_property(MKINDEX_LOC mkindex LOCATION)

set(ACCUM_C_CORE _accum)
set(ACCUM_C ${OUTPUT_DIR}/_accum.c)
set(ACCUM_C_FINAL ${OUTPUT_DIR}/_accum_.c)
set(ACCUM_H_FINAL ${OUTPUT_DIR}/_accum_.h)
file(WRITE ${ACCUM_C} "/* merge all active C files, in order to be able to generate a non-broken header for external use */\n")

# The following is very minimal, more dependencies should be captured
# if actually modifying fossil code.

file(GLOB FOSSIL_SRCS RELATIVE ${WORKING_DIR}/fossil/src ${WORKING_DIR}/fossil/src/*.c)
set(GEN_HDRS)
set(MAKEHEADERS_ARGS)
set(GEN_SRCS)
set(ORG_SRCS)
foreach(src ${FOSSIL_SRCS})
  if (NOT src MATCHES "^(makeheaders.c)|(translate.c)|(mkindex.c)|(^th.c)|(sqlite3.c)|(shell.c)|(sqlcmd.c)$")
    string(REPLACE ".c" ".h" hdr ${src})
    set(GEN_HDRS ${GEN_HDRS} ${OUTPUT_DIR}/${hdr})
    string(REPLACE ".c" "_.c" src_ ${src})
    set(GEN_SRCS ${GEN_SRCS} ${OUTPUT_DIR}/${src_})
    set(MAKEHEADERS_ARGS ${MAKEHEADERS_ARGS} "${src_}:${hdr}")
    set(dir ${WORKING_DIR}/fossil/src)
    # If source code exists in src/fossil, override official code.
    if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/tweaks/${src})
      set(dir ${CMAKE_CURRENT_SOURCE_DIR}/tweaks)
    endif ()
    set(ORG_SRCS ${ORG_SRCS} ${dir}/${src})
    file(APPEND ${ACCUM_C} "/* ${src} */\n")
    file(READ ${dir}/${src} ACCUM_C1)
    # file(READ ${OUTPUT_DIR}/${src_} ACCUM_C1)
    file(APPEND ${ACCUM_C} "${ACCUM_C1}")
    add_custom_command(OUTPUT ${OUTPUT_DIR}/${src_}
      COMMAND ${TRANSLATE_LOC} ${src} > ${OUTPUT_DIR}/${src_}
      WORKING_DIRECTORY ${dir}
      DEPENDS ${dir}/${src}
      DEPENDS ${TRANSLATE_LOC}
    )
  endif ()
endforeach(src)

add_custom_command(OUTPUT ${ACCUM_C_FINAL}
  COMMAND ${TRANSLATE_LOC} ${ACCUM_C_CORE}.c > ${ACCUM_C_FINAL}
  WORKING_DIRECTORY ${OUTPUT_DIR}
  DEPENDS ${TRANSLATE_LOC}
)

add_custom_command(OUTPUT ${ACCUM_H_FINAL}
  COMMAND ${MAKEHEADERS_LOC} ${ACCUM_C_CORE}_.c:${ACCUM_C_CORE}_.h
  WORKING_DIRECTORY ${OUTPUT_DIR}
  DEPENDS ${MAKEHEADERS_LOC}
  DEPENDS ${ACCUM_C_FINAL}
)

add_custom_command(OUTPUT ${GEN_HDRS}
  COMMAND ${MAKEHEADERS_LOC} ${MAKEHEADERS_ARGS}  ${WORKING_DIR}/fossil/src/sqlite3.h ${WORKING_DIR}/fossil/src/th.h ${CMAKE_CURRENT_SOURCE_DIR}/tweaks/VERSION.h
  COMMAND touch ${GEN_HDRS}
  DEPENDS ${MAKEHEADERS_LOC}
)

add_custom_command(OUTPUT ${OUTPUT_DIR}/page_index.h
  COMMAND ${MKINDEX_LOC} ${GEN_SRCS} > ${OUTPUT_DIR}/page_index.h
  COMMAND cat ${CMAKE_CURRENT_SOURCE_DIR}/tweaks/main.h >> ${OUTPUT_DIR}/page_index.h
  DEPENDS ${GEN_SRCS}
  DEPENDS ${MKINDEX_LOC}
  DEPENDS ${ACCUM_H_FINAL}
)

include_directories(${OUTPUT_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/tweaks)
include_directories(${WORKING_DIR}/fossil/src)
add_library(fossilly ${GEN_SRCS} ${GEN_HDRS} 
  ${WORKING_DIR}/fossil/src/th.c 
  #fossil/src/sqlite3.c 
  ${OUTPUT_DIR}/page_index.h
  #src/csv_hooks.cpp 
  #src/ssfossil.h src/ssfossil.cpp
)

target_link_libraries(fossilly z)
if (OPENSSL_FOUND)
  target_link_libraries(fossilly ${OPENSSL_LIBRARIES})
  if (MINGW)
    target_link_libraries(fossilly crypt32)
  endif ()
endif ()
if (MINGW)
  target_link_libraries(fossilly ws2_32)
else (MINGW)
  target_link_libraries(fossilly dl pthread)
endif (MINGW)
target_link_libraries(fossilly sqlite3) # is this a conditional?

add_executable(test_fossilly main.cpp)
target_link_libraries(test_fossilly fossilly)
