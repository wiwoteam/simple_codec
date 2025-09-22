import 'package:flutter/material.dart';
import 'package:simple_codec/utils/policy_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PolicyScreen extends StatefulWidget {
  final String? url;

  const PolicyScreen({super.key, required this.url});

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen>
    with WidgetsBindingObserver {
  late String _url;
  late LaunchMode _mode;
  bool _hasLaunched = false;
  bool _shouldReopenOnResume = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _url = widget.url ?? PolicyService.getDefaultPolicyUrl();
    if (widget.url != null) {
      _mode = LaunchMode.platformDefault;
      _shouldReopenOnResume = true; // Nếu có widget.url, sẽ mở lại khi resume
    } else {
      _mode = LaunchMode.inAppWebView;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Khi app resume và có widget.url, mở lại URL mà không hiển thị loading
    if (state == AppLifecycleState.resumed &&
        _shouldReopenOnResume &&
        widget.url != null &&
        _hasLaunched &&
        mounted) {
      // Chỉ delay ngắn rồi launch lại, không hiển thị loading
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          launchUrl(Uri.parse(_url), mode: _mode);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Nếu có widget.url, không cho phép pop
        if (widget.url != null) {
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mở URL trong trình duyệt
    if (!_hasLaunched) {
      Future.microtask(() async {
        await launchUrl(Uri.parse(_url), mode: _mode);
        if (mounted) {
          setState(() {
            _hasLaunched = true;
          });
        }
        // Nếu không có widget.url (dùng default URL) thì pop màn hình
        if (widget.url == null && mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }
}
