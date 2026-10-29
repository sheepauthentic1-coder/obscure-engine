#!/bin/sh
# Build trên macOS runner (GitHub Actions). Máy Linux không có Xcode/iOS SDK.
set -e
cd "$(dirname "$0")"
xcrun --sdk iphoneos clang++ -arch arm64 -miphoneos-version-min=14.0 \
  -std=c++17 \
  obscure_engine.cpp \
  -shared -o obscure_engine.dylib
ls -lh obscure_engine.dylib
file obscure_engine.dylib
