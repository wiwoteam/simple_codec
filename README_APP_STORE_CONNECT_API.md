# Hướng dẫn sử dụng file .p8 (Apple AuthKey) cho App Store Connect API và CI/CD

## 1. Tổng quan về file .p8
- File `.p8` là Apple AuthKey dùng để xác thực với App Store Connect API (ví dụ: upload app tự động qua CI/CD, Fastlane).
- KHÔNG import file này vào Xcode hoặc Keychain.
- Chỉ cần lưu file này ở nơi an toàn trên máy hoặc server CI/CD.

## 2. Lấy thông tin cần thiết
- **File .p8**: Tải từ Apple Developer Portal (Certificates, Identifiers & Profiles > Keys).
- **Key ID**: Ví dụ `87C48TXH8B` (hiện trên portal khi tạo key).
- **Issuer ID**: Vào App Store Connect > Users and Access > Keys > Copy Issuer ID.

## 3. Sử dụng với Fastlane (CI/CD)

### a. Cài đặt Fastlane (nếu chưa có)
```sh
[sudo] gem install fastlane -NV
```

### b. Cấu hình Fastlane cho App Store Connect API

Trong file `Fastfile` hoặc khi dùng lệnh fastlane, bạn cần các biến sau:
- `api_key_path`: Đường dẫn tới file `.p8`
- `api_key_id`: Key ID
- `api_issuer_id`: Issuer ID

Ví dụ cấu hình trong `Fastfile`:
```ruby
app_store_connect_api_key(
  key_id: "87C48TXH8B", # Thay bằng Key ID của bạn
  issuer_id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", # Thay bằng Issuer ID của bạn
  key_filepath: "./AuthKey_87C48TXH8B.p8", # Đường dẫn tới file .p8
  in_house: false
)

deliver(
  api_key: app_store_connect_api_key,
  skip_metadata: true,
  skip_screenshots: true
)
```

Hoặc dùng biến môi trường trong CI:
```sh
export APP_STORE_CONNECT_API_KEY_PATH=./AuthKey_87C48TXH8B.p8
export APP_STORE_CONNECT_API_KEY_ID=87C48TXH8B
export APP_STORE_CONNECT_API_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### c. Build và upload app tự động
```sh
fastlane build
fastlane upload_to_app_store # hoặc fastlane ios release
```

## 4. Lưu ý bảo mật
- KHÔNG commit file `.p8` lên git.
- Chỉ cấp quyền đọc file này cho CI/CD hoặc người quản lý release.
- Nếu lộ key, hãy thu hồi (revoke) trên Apple Developer Portal và tạo key mới.

## 5. Tài liệu tham khảo
- [Fastlane App Store Connect API Key](https://docs.fastlane.tools/app-store-connect-api/#using-fastlane)
- [Apple Docs: Generating API Keys](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api)

---

**Tóm lại:**
- File `.p8` chỉ dùng cho backend, CI/CD, Fastlane, KHÔNG import vào Xcode/Keychain.
- Cần 3 thông tin: file `.p8`, Key ID, Issuer ID.
- Cấu hình đúng cho Fastlane hoặc CI/CD để tự động build, upload app lên App Store Connect.
