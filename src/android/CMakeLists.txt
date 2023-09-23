cmake_minimum_required(VERSION 3.21)
project(camera_360)

#CONFIGURATION

set(OPENCV_VERSION 4.8.0)
set(OpenCV_STATIC ON)
set(OpenCV_SHARED OFF)

message("api level ${ANDROID_PLATFORM}")
message("ndk ${ANDROID_NDK}")
message("abi ${ANDROID_ABI}")

#Paths
set(opencv ${CMAKE_CURRENT_SOURCE_DIR}/opencv-build/opencv-${OPENCV_VERSION}-android/sdk/native/jni) ## need to be precompiled!!
set(umbrella ${CMAKE_CURRENT_SOURCE_DIR}/../umbrella)

include(ExternalProject)
find_library(log-lib log) #add android logging
# GLESv2 look for opengl android
find_path(GLES2_INCLUDE_DIR GLES2/gl2.h
    HINTS ${ANDROID_NDK})
find_library(GLES2_LIBRARY libGLESv2.so
    HINTS ${GLES2_INCLUDE_DIR}/../lib)


#OpenCV
set(OpenCV_DIR ${opencv})
find_package(OpenCV REQUIRED HINTS ${opencv})

set(CMAKE_CXX_STANDARD 17) #set c++ language standart
set(FLUTTER_UMBRELLA
	${umbrella}/Stitcher/Stitcher.cpp
)

###Build a shared library with our umbrella clases and opencv
add_library(${CMAKE_PROJECT_NAME} SHARED
	${FLUTTER_UMBRELLA}
)

#target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE
#	${SBSDK_TFLITE_DEFS})

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE
	${GLES2_INCLUDE_DIR}
)

target_include_directories(${CMAKE_PROJECT_NAME} PUBLIC
    ${umbrella}
)

target_link_libraries(${CMAKE_PROJECT_NAME} PUBLIC
	${OpenCV_LIBS}
	${log-lib}
	${GLES2_LIBRARY}
)

#NDK ONLY?
#add_compile_options(-fexceptions -frtti)

message("ready to compile")
