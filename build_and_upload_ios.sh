#!/bin/bash
# build_and_upload_ios.sh
# Script tự động build IPA và upload lên App Store Connect bằng Fastlane API Key (.p8)
# Đặt file này ở thư mục gốc dự án Flutter (cùng cấp với pubspec.yaml)

set -e

# Tài nguyên lấy từ https://appstoreconnect.apple.com/
# Vào Users and Integrations
# Đường dẫn tới file .p8, Key ID, Issuer ID (đặt trong thư mục gốc dự án hoặc ./certificates)
API_KEY_PATH="./certificates/AuthKey_M83S2YRQ52.p8" # Đổi tên file nếu cần
API_KEY_ID="M83S2YRQ52"                # Thay bằng Key ID của bạn
API_ISSUER_ID="533c7b01-879f-4284-b5f1-d3bfc63ea35f" # Thay bằng Issuer ID của bạn

# Build iOS app (release)
echo "==> Building iOS app..."
flutter clean
flutter pub get
flutter build ios --release --no-codesign

# Tạo thư mục xuất IPA
OUTPUT_DIR=build/ios/ipa
mkdir -p $OUTPUT_DIR

# Archive app
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -archivePath ../build/ios/Runner.xcarchive archive

# Export IPA
xcodebuild -exportArchive -archivePath ../build/ios/Runner.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath ../$OUTPUT_DIR
cd ..

# Cài đặt fastlane nếu chưa có
if ! command -v fastlane &> /dev/null; then
  echo "==> Installing fastlane..."
  sudo brew install fastlane
fi

# Upload IPA lên App Store Connect bằng Fastlane API Key
echo "==> Uploading IPA to App Store Connect..."
fastlane run upload_to_testflight \
  ipa:$OUTPUT_DIR/Runner.ipa \
  api_key_path:$API_KEY_PATH \
  api_key_id:$API_KEY_ID \
  api_issuer_id:$API_ISSUER_ID

echo "==> Done! Hãy vào App Store Connect để hoàn thiện metadata, screenshot, submit review."
