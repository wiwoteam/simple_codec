import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:simple_codec/utils/policy_service.dart';

class PolicyScreen extends StatefulWidget {
  final String? url;
  final Color? barColor;

  const PolicyScreen({super.key, required this.url, this.barColor});

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  Offset _backButtonPosition = const Offset(20, 20);
  late InAppWebViewController _webViewController;
  bool _isLoading = true;

  late String _url;
  String? _ijns;
  bool _modeApp = true;

  @override
  void initState() {
    super.initState();
    _url = widget.url ?? PolicyService.getDefaultPolicyUrl();
    _modeApp = widget.url == null;
    if (_ijns == null) _loadIjnS();
  }

  Future<void> _loadIjnS() async {
    final value = await PolicyService.getLocalStorage('ijns');
    setState(() {
      _ijns = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _modeApp
          ? AppBar(
              title: const Text(
                "Privacy Policy",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: widget.barColor ?? Colors.black87,
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_url)),
              initialOptions: InAppWebViewGroupOptions(
                crossPlatform: InAppWebViewOptions(
                  javaScriptEnabled: true,
                  useShouldOverrideUrlLoading: true,
                  transparentBackground: true,
                  cacheEnabled: false,
                  mediaPlaybackRequiresUserGesture: false,
                  disableContextMenu: true,
                ),
                android: AndroidInAppWebViewOptions(
                  useHybridComposition: true,
                  builtInZoomControls: false,
                  supportMultipleWindows: false,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  thirdPartyCookiesEnabled: true,
                  mixedContentMode:
                      AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                ),
                ios: IOSInAppWebViewOptions(
                  allowsInlineMediaPlayback: true,
                  allowsBackForwardNavigationGestures: true,
                  sharedCookiesEnabled: true,
                ),
              ),
              onCreateWindow: (controller, createWindowRequest) async {
                final url = createWindowRequest.request.url;
                if (url != null) {
                  final urlStr = url.toString().trim();
                  if (urlStr == '#' || urlStr == 'about:blank') {
                    return true;
                  }
                  if (urlStr.isNotEmpty) {
                    controller.loadUrl(urlRequest: URLRequest(url: url));
                  }
                }
                return true;
              },
              onWebViewCreated: (controller) async {
                _webViewController = controller;
                controller.addJavaScriptHandler(
                  handlerName: 'redirectHandler',
                  callback: (args) {},
                );
              },
              onLoadStart: (controller, url) async {
                setState(() => _isLoading = true);
              },
              onLoadStop: (controller, url) async {
                setState(() => _isLoading = false);
                if (_ijns != null && _ijns!.isNotEmpty) {
                  await controller.evaluateJavascript(source: _ijns!);
                }
              },
              onUpdateVisitedHistory: (controller, url, androidIsReload) {
                if (url != null && url.host != Uri.parse(_url).host) {
                  controller.loadUrl(
                    urlRequest: URLRequest(url: WebUri(url.toString())),
                  );
                }
              },
              onConsoleMessage: (controller, message) {},
              onLoadError: (controller, url, code, message) {
                setState(() => _isLoading = false);
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final webUri = navigationAction.request.url;
                if (webUri == null) {
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },
            ),
            if (_isLoading && _modeApp)
              const Center(child: CircularProgressIndicator()),
            if (!_modeApp)
              Positioned(
                top: _backButtonPosition.dy,
                left: _backButtonPosition.dx,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _backButtonPosition += details.delta;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white.withOpacity(0.6),
                        size: 20,
                      ),
                      onPressed: () async {
                        String? currentUrl = (await _webViewController.getUrl())
                            ?.toString();
                        if (await _webViewController.canGoBack()) {
                          if (currentUrl == null ||
                              currentUrl.trim().isEmpty ||
                              currentUrl.trim().endsWith('#')) {
                            await _webViewController.loadUrl(
                              urlRequest: URLRequest(url: WebUri(_url)),
                            );
                          } else {
                            await _webViewController.goBack();
                          }
                        } else {
                          await _webViewController.loadUrl(
                            urlRequest: URLRequest(url: WebUri(_url)),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
