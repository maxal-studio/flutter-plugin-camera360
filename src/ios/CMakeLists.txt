cmake_minimum_required(VERSION 3.21)
project(camera_360)

#CONFIGURATION

set(OPENCV_VERSION 4.8.0)

message("architecture ${IOS_ARCH}")
message("sys_root ${CMAKE_OSX_SYSROOT}")

#Paths

set(opencv ${CMAKE_CURRENT_SOURCE_DIR}/opencv-build/opencv-${OPENCV_VERSION}-ios-build/build/build-${IOS_ARCH}-${CMAKE_OSX_SYSROOT}/install/lib/cmake/opencv4) ## need to be precompiled!!
set(umbrella ${CMAKE_CURRENT_SOURCE_DIR}/../umbrella)
message("opencv path ${opencv}")

#OpenCV
set(OpenCV_DIR ${opencv})
find_package(OpenCV REQUIRED HINTS ${opencv})

set(CMAKE_CXX_STANDARD 17) #set c++ language standart

set(CMAKE_OSX_DEPLOYMENT_TARGET 11)

set(FLUTTER_UMBRELLA
  ${umbrella}/Stitcher/Stitcher.cpp
  ${umbrella}/Stitcher/Stitcher.h
)

set(FLUTTER_UMBRELLA_PUBLIC
	${umbrella}/Stitcher/Stitcher.h
)

set(CMAKE_INSTALL_PREFIX
	${CMAKE_CURRENT_SOURCE_DIR}/../../ios
)

###Build a shared library with our umbrella clases and opencv
add_library(${CMAKE_PROJECT_NAME} SHARED
	${FLUTTER_UMBRELLA}
)

target_link_libraries(${CMAKE_PROJECT_NAME} PUBLIC
	${OpenCV_LIBS}
    # ${OpenSSL}
)

target_include_directories(${CMAKE_PROJECT_NAME} PUBLIC
    ${umbrella}
)
## compile option nessessary to build propper framework
target_compile_options(${CMAKE_PROJECT_NAME}
  PUBLIC
    "-fembed-bitcode"
  )

# https://cmake.org/cmake/help/latest/prop_tgt/MACOSX_FRAMEWORK_INFO_PLIST.html

set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
	FRAMEWORK TRUE
	MACOSX_FRAMEWORK_IDENTIFIER al.max.camera360
	PUBLIC_HEADER "${FLUTTER_UMBRELLA_PUBLIC}"
	MACOSX_FRAMEWORK_BUNDLE_VERSION 1.0.4
	MACOSX_FRAMEWORK_SHORT_VERSION_STRING 1.0.4
	VERSION 1.0.4
	SOVERSION 1.0.4
#For release build add your credentials
	#XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY ""
	#XCODE_ATTRIBUTE_DEVELOPMENT_TEAM ""
    #XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "Yes"
)

message("ready to compile")
