# CMakeLists.txt

cmake_minimum_required(VERSION 3.4.1)

add_library(
        ear_comparator
        SHARED
        compare_ear_features.c
)

add_library(
        voice_comparator
        SHARED
        compare_voice_features.c
)
add_library(
        voice_mfcc
        SHARED
        libmfcc.c
)

find_library(
        log-lib
        log
)

target_link_libraries(
        ear_comparator
        ${log-lib}
)

target_link_libraries(
        voice_comparator
        ${log-lib}
)
target_link_libraries(
        voice_mfcc
        ${log-lib}
)