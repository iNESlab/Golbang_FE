import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Android 전용
import 'package:webview_flutter_android/webview_flutter_android.dart';
// iOS/macOS 전용
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../utils/enqueued_download.dart';

class NewPeoriaWebViewPage extends StatefulWidget {
  final String url;
  const NewPeoriaWebViewPage({super.key, required this.url});

  @override
  State<NewPeoriaWebViewPage> createState() => _NewPeoriaWebViewPageState();
}

class _NewPeoriaWebViewPageState extends State<NewPeoriaWebViewPage> {
  late final WebViewController _controller;
  late final Uri _initialBase;   // 항상 존재
  Uri? _currentPage;             // onPageStarted 때 갱신
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _initialBase = Uri.parse(widget.url);
    _currentPage = _initialBase; // 초기값 지정(LateInit 방지)

    // 플랫폼별 컨트롤러 생성 파라미터
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'Console',
        onMessageReceived: (m) => debugPrint('[WV] ${m.message}'),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          // 초기 진입/일반 로딩: 차단하지 않음
          onPageStarted: (url) {
            _currentPage = Uri.parse(url);
            setState(() => _isLoading = true);
          },

          // 리다이렉트 등 커밋 후 URL 변경도 여기서 잡음
          onUrlChange: (change) async {
            final s = change.url ?? '';
            if (s.isEmpty) return;
            final u = Uri.parse(s);

            if (u.path.contains('/calculator/download') || u.path.contains('/calculate/download')) {
              final downloadEndpoint = _absolutize(s);
              debugPrint('[WV] PREVENT download-redirect: $downloadEndpoint');

              await enqueueDownload(downloadEndpoint, context);

              // 이미 커밋됐을 수 있어 중단/복귀는 시도만
              try { await _controller.runJavaScript('window.stop();'); } catch (_) {}
              if (await _controller.canGoBack()) await _controller.goBack();
            }
          },


          // 사전 차단: 메인 프레임만
          onNavigationRequest: (req) async {
            final uri = Uri.parse(req.url);

            if (!req.isMainFrame) return NavigationDecision.navigate;

            // ✅ 다운로드 엔드포인트: 브라우저 X, DownloadManager에 큐 등록
            if (uri.path.contains('/calculator/download') || uri.path.contains('/calculate/download')) {
              final downloadEndpoint = _absolutize(req.url); // req.url 그대로
              debugPrint('[WV] PREVENT download-mainframe: $downloadEndpoint');
              await enqueueDownload(downloadEndpoint,context);      // 👈 여기!
              return NavigationDecision.prevent;
            }

            // (선택) 업로드 파일 경로는 아무 것도 안 하거나 외부로 열기
            // if (_isUploadUrl(uri)) { ... }

            // 직접 파일 링크(.xlsx/.xls/.csv)를 눌렀을 때에도 큐 등록하고 막고 싶다면:
            if (_looksLikeExcel(req.url)) {
              final u = _absolutize(req.url);
              debugPrint('[WV] PREVENT direct-file: $u');
              await enqueueDownload(u, context);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },

          onPageFinished: (url) async {
            await controller.runJavaScript(_jsHookConsole);
            await controller.runJavaScript(_jsPatchWindowOpenAndBlankTargets);
            setState(() => _isLoading = false);
          },

          onWebResourceError: (err) {
            // 페이지 토스트 + Logcat 동시
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('웹뷰 로딩 실패: ${err.description}')),
            );
            debugPrint('[WV][error] ${err.errorCode} ${err.description}');
          },
        ),
      )
      ..loadRequest(_initialBase);

    // Android 추가 설정
    if (controller.platform is AndroidWebViewController) {
      final android = controller.platform as AndroidWebViewController;
      AndroidWebViewController.enableDebugging(true);
      android.setMediaPlaybackRequiresUserGesture(false);
      android.setOnShowFileSelector(_onShowAndroidFileSelector);
    }

    _controller = controller;
  }

  // JS 콘솔 훅: console.log/warn/error와 window.onerror를 Dart 로그로
  static const String _jsHookConsole = r'''
(function() {
  try {
    ['log','warn','error'].forEach(function(k){
      var _ = console[k];
      console[k] = function(){
        try { Console.postMessage(k+': ' + Array.from(arguments).join(' ')); } catch(e) {}
        return _.apply(console, arguments);
      };
    });
    window.addEventListener('error', function(e){
      try { Console.postMessage('uncaught: ' + e.message + ' @' + e.filename + ':' + e.lineno); } catch(_) {}
    });
  } catch(e) {}
})();
''';

  // JS: window.open/target='_blank' 패치 (다운로드 류는 예외)
  static const String _jsPatchWindowOpenAndBlankTargets = r'''
(function() {
  try {
    // window.open 가로채기 - 다운로드/업로드 경로는 예외
    var _open = window.open;
    window.open = function(u) {
      try {
        if (typeof u === 'string' && (/\.(xlsx|xls|csv)(\?|#|$)/i.test(u) || /\/(calculator|calculate)\/upload/i.test(u))) {
          return _open.call(window, u, '_blank'); // 네이티브가 onUrlChange 등으로 처리
        }
        window.location.href = u;
      } catch(e) {}
    };

    function patchLinks() {
      var as = document.querySelectorAll('a[target="_blank"], a[download]');
      for (var i=0; i<as.length; i++) {
        var a = as[i];
        var href = a.getAttribute('href') || '';
        var isDownloadLike =
          a.hasAttribute('download') ||
          /\.(xlsx|xls|csv)(\?|#|$)/i.test(href) ||
          /\/(calculator|calculate)\/upload/i.test(href) ||
          /\/(calculator|calculate)\/download/i.test(href);

        if (isDownloadLike) {
          // 네이티브가 잡게 두기 위해 같은 탭 강제는 하지 않음
          continue;
        }

        // 그 외 _blank 는 같은 탭으로 강제
        if (a.getAttribute('target') === '_blank') {
          a.addEventListener('click', function(ev) {
            try {
              ev.preventDefault();
              window.location.href = this.href;
            } catch(e) {}
          }, {passive:false});
        }
      }
    }
    patchLinks();

    var obs = new MutationObserver(function(){ patchLinks(); });
    obs.observe(document.documentElement || document.body, {childList:true, subtree:true});
  } catch (e) {}
})();
''';

  // 상대 href를 안전하게 절대 URL로 변환
  Uri _absolutize(String href, {Uri? base}) {
    final b = base ?? _currentPage ?? _initialBase;

    // 보정: "https:domain/path" → "https://domain/path"
    final fixedHref = href.replaceFirst(RegExp(r'^(https?):(?=[^/])', caseSensitive: false), r'$1://');

    final u = Uri.tryParse(fixedHref);
    if (u == null) return b;
    if (u.hasScheme) return u;                          // http/https/file/content
    if (fixedHref.startsWith('//')) return Uri.parse('${b.scheme}:$fixedHref');
    if (u.path.startsWith('/')) {
      return Uri(
        scheme: b.scheme, host: b.host, port: b.hasPort ? b.port : null,
        path: u.path, query: u.query, fragment: u.fragment,
      );
    }
    return b.resolveUri(u);                              // 상대경로
  }

  bool _looksLikeExcel(String url) {
    final l = url.toLowerCase();
    return l.contains('.xlsx') || l.contains('.xls') || l.contains('.csv');
  }

  // Android 파일 선택 콜백: <input type="file">
  Future<List<String>> _onShowAndroidFileSelector(FileSelectorParams params) async {
    const groups = [
      XTypeGroup(
        label: 'Excel',
        mimeTypes: [
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', // .xlsx
          'application/vnd.ms-excel',                                          // .xls
        ],
        extensions: ['xlsx', 'xls'],
      ),
      XTypeGroup(
        label: 'CSV',
        mimeTypes: ['text/csv'],
        extensions: ['csv'],
      ),
    ];

    final List<XFile> picked = [];
    final file = await openFile(acceptedTypeGroups: groups);
    if (file != null) picked.add(file);

    final List<String> uris = [];
    for (final f in picked) {
      final p = f.path;
      if (p.isNotEmpty) {
        if (p.startsWith('content://') || p.startsWith('file://')) {
          uris.add(p);
        } else {
          uris.add(Uri.file(p).toString()); // file:///... 로 변환
        }
      } else {
        // 드문 케이스: 임시 경로로 저장 후 file:// 반환
        final tmpPath = '${Directory.systemTemp.path}/${DateTime.now().microsecondsSinceEpoch}_${f.name}';
        await f.saveTo(tmpPath);
        uris.add(Uri.file(tmpPath).toString());
      }
    }
    return uris;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('신페리온 계산기'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const IgnorePointer(
                ignoring: true,
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
