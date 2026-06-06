import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  ENTRY POINT
// ═══════════════════════════════════════════════════════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  await RemoteConfig.fetch();
  runApp(const AiouBrowserApp());
}

// ═══════════════════════════════════════════════════════════════════════════════
//  REMOTE CONFIG — fetched from GitHub Gist on every launch
//  Update from Termux: gh gist edit a1c26df8253223f554e2f78de57cd9d1 ~/a7config.json
// ═══════════════════════════════════════════════════════════════════════════════
const String _kGistUrl =
  'https://gist.githubusercontent.com/AsifNawazLashari'
  '/a1c26df8253223f554e2f78de57cd9d1/raw/a7config.json';
const int _kAppVersion = 1;

class RemoteConfig {
  static Map<String, dynamic> _d = {};
  static bool _loaded = false;

  static String get noticeTitle   => _d['notice_title']   as String? ?? '📌 Important Notice';
  static String get noticeBody    => _d['notice_body']    as String? ?? 'Use this browser in accordance with AIOU policies.';
  static String get whatsappUrl   => _d['whatsapp_url']   as String? ?? 'https://chat.whatsapp.com/C0NOp1OOhAUATW2IMnaQ1r';
  static String get whatsappLabel => _d['whatsapp_label'] as String? ?? 'Join EduVerse WhatsApp Group';
  static String get whatsappSub   => _d['whatsapp_sub']   as String? ?? 'Stay updated · Get support · Community';
  static String get updateUrl     => _d['update_url']     as String? ?? '';
  static String get updateMsg     => _d['update_message'] as String? ?? '';
  static int    get minVersion    => (_d['min_version']   as num?)?.toInt() ?? 1;
  static bool   get hasUpdate     => minVersion > _kAppVersion && updateUrl.isNotEmpty;
  static bool   get isLoaded      => _loaded;

  static List<_QuickLink> get quickLinks {
    final raw = _d['quick_links'] as List?;
    if (raw == null || raw.isEmpty) return _defaultLinks;
    return raw.map((e) {
      final m = e as Map<String, dynamic>;
      return _QuickLink(
        m['label'] as String? ?? '',
        m['url']   as String? ?? 'https://google.com',
        _iconFromString(m['icon'] as String? ?? 'search'),
        _colorFromIcon(m['icon'] as String? ?? 'search'),
      );
    }).toList();
  }

  static IconData _iconFromString(String s) {
    switch (s) {
      case 'quiz':   return Icons.quiz_rounded;
      case 'school': return Icons.school_rounded;
      case 'mail':   return Icons.mail_rounded;
      case 'search': return Icons.search_rounded;
      case 'play':   return Icons.play_circle_rounded;
      case 'bot':    return Icons.smart_toy_rounded;
      case 'star':   return Icons.star_rounded;
      case 'link':   return Icons.link_rounded;
      case 'book':   return Icons.menu_book_rounded;
      default:       return Icons.language_rounded;
    }
  }

  static Color _colorFromIcon(String s) {
    switch (s) {
      case 'quiz':   return const Color(0xFF2D8BEF);
      case 'school': return const Color(0xFF059669);
      case 'mail':   return const Color(0xFFEA4335);
      case 'search': return const Color(0xFF4285F4);
      case 'play':   return const Color(0xFFCC0000);
      case 'bot':    return const Color(0xFF10A37F);
      case 'star':   return const Color(0xFFF59E0B);
      case 'book':   return const Color(0xFF7C3AED);
      default:       return const Color(0xFF2D8BEF);
    }
  }

  static final List<_QuickLink> _defaultLinks = [
    _QuickLink('Quiz',    'https://quiz.aiou.edu.pk',  Icons.quiz_rounded,       const Color(0xFF2D8BEF)),
    _QuickLink('AIOU',   'https://lms3.aiou.edu.pk/my/courses.php',        Icons.school_rounded,     const Color(0xFF059669)),
    _QuickLink('Gmail',  'https://gmail.com',          Icons.mail_rounded,       const Color(0xFFEA4335)),
    _QuickLink('Google', 'https://google.com',         Icons.search_rounded,     const Color(0xFF4285F4)),
    _QuickLink('YouTube','https://youtube.com',        Icons.play_circle_rounded,const Color(0xFFCC0000)),
    _QuickLink('ChatGPT','https://chat.openai.com',    Icons.smart_toy_rounded,  const Color(0xFF10A37F)),
  ];

  // Gist API endpoint — returns current raw_url with commit hash embedded,
  // bypassing GitHub CDN cache. Config updates are instant on every launch.
  static const String _kGistApiUrl =
      'https://api.github.com/gists/a1c26df8253223f554e2f78de57cd9d1';

  static Future<void> fetch() async {
    try {
      // Step 1: Gist API → get commit-pinned raw_url (never cached by CDN)
      final apiRes = await http.get(
        Uri.parse(_kGistApiUrl),
        headers: {
          'Accept':        'application/vnd.github+json',
          'Cache-Control': 'no-cache, no-store',
          'Pragma':        'no-cache',
        },
      ).timeout(const Duration(seconds: 8));

      if (apiRes.statusCode == 200) {
        final gistJson = jsonDecode(apiRes.body) as Map<String, dynamic>;
        final files    = gistJson['files'] as Map<String, dynamic>?;
        final rawUrl   = files?['a7config.json']?['raw_url'] as String?;
        if (rawUrl != null) {
          // Step 2: Fetch config from commit-pinned URL
          final res = await http
              .get(Uri.parse(rawUrl))
              .timeout(const Duration(seconds: 6));
          if (res.statusCode == 200) {
            _d      = jsonDecode(res.body) as Map<String, dynamic>;
            _loaded = true;
            return;
          }
        }
      }
    } catch (_) {}

    // Fallback: direct raw URL with hard no-cache headers
    try {
      final res = await http.get(
        Uri.parse('$_kGistUrl?cb=${DateTime.now().millisecondsSinceEpoch}'),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma':        'no-cache',
          'Expires':       '0',
        },
      ).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        _d      = jsonDecode(res.body) as Map<String, dynamic>;
        _loaded = true;
      }
    } catch (_) {
      // silently fall back to defaults — app still works offline
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  THEME
// ═══════════════════════════════════════════════════════════════════════════════
class T {
  static const Color bg          = Color(0xFFF0F8FF);
  static const Color bgDeep      = Color(0xFFDDEEFB);
  static const Color chrome      = Color(0xFFFAFDFF);
  static const Color accent      = Color(0xFF2D8BEF);
  static const Color accentDeep  = Color(0xFF1565C0);
  static const Color accentLight = Color(0xFF7EC8F8);
  static const Color ink         = Color(0xFF0B2545);
  static const Color inkMid      = Color(0xFF3D6490);
  static const Color inkLight    = Color(0xFF94B8D8);
  static const Color divider     = Color(0xFFCDE4F5);
  static const Color white       = Color(0xFFFFFFFF);
  static const Color success     = Color(0xFF22C55E);
  static const Color error       = Color(0xFFEF4444);

  static const LinearGradient skyGrad = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [Color(0xFFEBF5FF), Color(0xFFD6ECFF)],
  );
  static const LinearGradient accentGrad = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [accent, accentDeep],
  );
  static const LinearGradient chromeGrad = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [Color(0xFFF8FCFF), Color(0xFFEFF8FF)],
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WEATHER MODEL
// ═══════════════════════════════════════════════════════════════════════════════
class WeatherData {
  final String cityName;
  final double tempC;
  final String description;
  final String icon;
  final int humidity;
  final double windKph;

  WeatherData({
    required this.cityName,
    required this.tempC,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windKph,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WEATHER SERVICE — No GPS plugin needed. Uses ip-api.com for coords then
//  Open-Meteo for weather. Fully free, no API keys, no native permissions.
// ═══════════════════════════════════════════════════════════════════════════════
class WeatherService {
  /// Step 1: Get lat/lon + city from IP address (ip-api.com — free, no key)
  static Future<Map<String, dynamic>?> _getLocationFromIP() async {
    try {
      final res = await http
          .get(Uri.parse('http://ip-api.com/json/?fields=city,lat,lon,regionName,country'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    // Hard fallback: Thatta/Sakro area
    return {'city': 'Thatta', 'lat': 24.7506, 'lon': 67.9284};
  }

  /// Step 2: Get weather from Open-Meteo (free, no key)
  static Future<WeatherData?> fetch() async {
    try {
      final loc = await _getLocationFromIP();
      if (loc == null) return null;

      final lat  = loc['lat']  as num;
      final lon  = loc['lon']  as num;
      final city = loc['city'] as String? ?? 'Your Location';

      final weatherRes = await http.get(Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code'
        '&wind_speed_unit=kmh',
      )).timeout(const Duration(seconds: 8));

      if (weatherRes.statusCode == 200) {
        final wJson   = jsonDecode(weatherRes.body);
        final current = wJson['current'];
        final wCode   = (current['weather_code'] as num).toInt();

        return WeatherData(
          cityName:    city,
          tempC:       (current['temperature_2m'] as num).toDouble(),
          description: _desc(wCode),
          icon:        _icon(wCode),
          humidity:    (current['relative_humidity_2m'] as num).toInt(),
          windKph:     (current['wind_speed_10m'] as num).toDouble(),
        );
      }
    } catch (_) {}
    return null;
  }

  static String _desc(int c) {
    if (c == 0)  return 'Clear Sky';
    if (c <= 3)  return 'Partly Cloudy';
    if (c <= 48) return 'Foggy';
    if (c <= 57) return 'Drizzle';
    if (c <= 67) return 'Rain';
    if (c <= 77) return 'Snow';
    if (c <= 82) return 'Rain Showers';
    if (c <= 86) return 'Snow Showers';
    if (c <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  static String _icon(int c) {
    if (c == 0)  return '☀️';
    if (c <= 3)  return '⛅';
    if (c <= 48) return '🌫️';
    if (c <= 57) return '🌦️';
    if (c <= 67) return '🌧️';
    if (c <= 77) return '❄️';
    if (c <= 82) return '🌦️';
    if (c <= 86) return '🌨️';
    if (c <= 99) return '⛈️';
    return '🌡️';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  APP
// ═══════════════════════════════════════════════════════════════════════════════
class AiouBrowserApp extends StatelessWidget {
  const AiouBrowserApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A Browser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: T.bg,
        colorScheme: ColorScheme.fromSeed(seedColor: T.accent, primary: T.accent),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      home: const BrowserManagerScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  TAB MODEL
// ═══════════════════════════════════════════════════════════════════════════════
class BrowserTab {
  final String id;
  String title;
  String url;
  double progress;
  InAppWebViewController? webViewController;
  bool isHome;
  bool noInternet;

  BrowserTab({
    required this.id,
    this.title    = 'New Tab',
    this.url      = 'https://aiouquizassist.edu.pk',
    this.progress = 0.0,
    this.webViewController,
    this.isHome   = true,
    this.noInternet = false,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
//  BROWSER MANAGER
// ═══════════════════════════════════════════════════════════════════════════════
class BrowserManagerScreen extends StatefulWidget {
  const BrowserManagerScreen({Key? key}) : super(key: key);
  @override
  State<BrowserManagerScreen> createState() => _BrowserManagerScreenState();
}

class _BrowserManagerScreenState extends State<BrowserManagerScreen> {
  final List<BrowserTab> _tabs       = [];
  int                    _activeTabIndex = 0;
  final TextEditingController _addressCtrl  = TextEditingController();
  final FocusNode             _addressFocus = FocusNode();

  // ── Redesigned Quiz Copy JS ──────────────────────────────────────────────────
  final String _js = r'''
(function(){
  'use strict';
  if(document.getElementById('a7-btn'))return;

  const isQuizPage =
    window.location.hostname.includes('quiz.aiou.edu.pk') ||
    !!document.querySelector('h1.select-none') ||
    !!document.querySelector('.qtext');
  if(!isQuizPage) return;

  const COLORS = {
    idle:    'linear-gradient(135deg,#2D8BEF,#1565C0)',
    success: 'linear-gradient(135deg,#16a34a,#15803d)',
    error:   'linear-gradient(135deg,#dc2626,#b91c1c)',
  };

  const copyIconSVG = `<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"
    viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.2"
    stroke-linecap="round" stroke-linejoin="round">
    <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
    <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
  </svg>`;

  const checkSVG = `<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22"
    viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.8"
    stroke-linecap="round" stroke-linejoin="round">
    <polyline points="20 6 9 17 4 12"></polyline>
  </svg>`;

  const crossSVG = `<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22"
    viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.8"
    stroke-linecap="round" stroke-linejoin="round">
    <line x1="18" y1="6" x2="6" y2="18"></line>
    <line x1="6" y1="6" x2="18" y2="18"></line>
  </svg>`;

  const btn = document.createElement('div');
  btn.id = 'a7-btn';
  btn.innerHTML = `
    <span id="a7-icon-wrap">${copyIconSVG}</span>
    <span id="a7-lbl" style="
      font-family:system-ui,sans-serif;font-size:12px;font-weight:700;
      color:#fff;max-width:0;opacity:0;overflow:hidden;
      transition:all .38s cubic-bezier(.4,0,.2,1);
      white-space:nowrap;margin-left:0;letter-spacing:0.3px;">Copy Quiz</span>
  `;
  btn.style.cssText = `
    position:fixed;top:50%;right:16px;width:52px;height:52px;
    background:${COLORS.idle};border-radius:50px;
    box-shadow:0 6px 22px rgba(21,101,192,.45),0 2px 6px rgba(0,0,0,.12);
    display:flex;align-items:center;justify-content:center;
    cursor:pointer;z-index:9999999;transform:translateY(-50%);
    transition:all .38s cubic-bezier(.4,0,.2,1);overflow:hidden;
    animation:a7pulse 2.8s ease-in-out infinite;
    border:1.5px solid rgba(255,255,255,.25);
  `;

  const style = document.createElement('style');
  style.textContent = `
    @keyframes a7pulse{
      0%,100%{box-shadow:0 6px 22px rgba(21,101,192,.45),0 0 0 0 rgba(45,139,239,.5);}
      50%{box-shadow:0 8px 28px rgba(21,101,192,.55),0 0 0 8px rgba(45,139,239,0);}
    }
    @keyframes a7shake{
      0%,100%{transform:translateY(-50%) translateX(0);}
      20%{transform:translateY(-50%) translateX(-5px);}
      40%{transform:translateY(-50%) translateX(5px);}
      60%{transform:translateY(-50%) translateX(-3px);}
      80%{transform:translateY(-50%) translateX(3px);}
    }
    #a7-btn:active{transform:translateY(-50%) scale(0.94)!important;}
    #a7-icon-wrap svg{display:block;flex-shrink:0;}
  `;
  document.head.appendChild(style);

  function expand(label){
    const lbl=document.getElementById('a7-lbl');
    if(label) lbl.textContent=label;
    btn.style.width='138px';
    lbl.style.maxWidth='90px';
    lbl.style.opacity='1';
    lbl.style.marginLeft='8px';
  }
  function collapse(){
    btn.style.width='52px';
    const lbl=document.getElementById('a7-lbl');
    lbl.style.maxWidth='0';
    lbl.style.opacity='0';
    lbl.style.marginLeft='0';
  }
  function setIcon(svg){ document.getElementById('a7-icon-wrap').innerHTML=svg; }

  function getData(){
    let q='';
    const qEl=document.querySelector('h1.select-none')||document.querySelector('.qtext');
    if(qEl&&qEl.innerText.length>5) q=qEl.innerText.trim();
    if(!q) return null;
    const opts=[];
    document.querySelectorAll('div.border-1.cursor-pointer,div.border-2.cursor-pointer')
      .forEach((el,i)=>{
        const spans=el.querySelectorAll('span');
        const text=spans.length>=2
          ?spans[1].innerText.trim()
          :el.innerText.replace(/^[a-z0-9][\.\)]\s*/i,'').trim();
        opts.push({index:i+1,text});
      });
    return {question:q,options:opts};
  }

  function doCopy(){
    const data=getData();
    if(!data){onError();return;}
    let txt=`Question:\n${data.question}\n\nOptions:\n`;
    data.options.forEach(o=>{txt+=`${o.index}. ${o.text}\n`;});
    try{
      window.flutter_inappwebview.callHandler('onQuizCopied',txt);
      onSuccess();
    }catch(e){
      navigator.clipboard.writeText(txt).then(onSuccess).catch(onError);
    }
  }

  function onSuccess(){
    btn.style.animation='none';
    btn.style.background=COLORS.success;
    setIcon(checkSVG); expand('Copied!');
    setTimeout(()=>{
      btn.style.background=COLORS.idle;
      btn.style.animation='a7pulse 2.8s ease-in-out infinite';
      setIcon(copyIconSVG); expand('Copy Quiz');
      setTimeout(collapse,1200);
    },1800);
  }

  function onError(){
    btn.style.animation='a7shake 0.45s ease-in-out';
    btn.style.background=COLORS.error;
    setIcon(crossSVG); expand('No Quiz!');
    setTimeout(()=>{
      btn.style.animation='none';
      btn.style.background=COLORS.idle;
      btn.style.animation='a7pulse 2.8s ease-in-out infinite';
      setIcon(copyIconSVG); expand('Copy Quiz');
      setTimeout(collapse,1200);
    },1800);
  }

  btn.onclick=doCopy;
  btn.onmouseenter=()=>expand('Copy Quiz');
  btn.onmouseleave=()=>collapse();
  btn.addEventListener('touchstart',()=>expand('Copy Quiz'),{passive:true});
  document.body.appendChild(btn);
  setTimeout(()=>expand('Copy Quiz'),600);
  setTimeout(collapse,3400);
})();
  ''';

  @override
  void initState() {
    super.initState();
    _addTab();
    // Re-fetch gist on slow networks and rebuild home screen with fresh data
    if (!RemoteConfig.isLoaded) {
      RemoteConfig.fetch().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() { _addressCtrl.dispose(); _addressFocus.dispose(); super.dispose(); }

  BrowserTab get _active => _tabs[_activeTabIndex];

  // ── Tab management ───────────────────────────────────────────────────────────
  void _addTab({String url = 'https://aiouquizassist.edu.pk', bool isHome = true}) {
    final t = BrowserTab(
      id:     DateTime.now().millisecondsSinceEpoch.toString(),
      url:    url,
      isHome: isHome,
      title:  isHome ? 'New Tab' : 'Loading…',
    );
    setState(() {
      _tabs.add(t);
      _activeTabIndex = _tabs.length - 1;
      _addressCtrl.text = url;
    });
  }

  void _closeTab(int i) {
    if (_tabs.length <= 1) {
      setState(() {
        _tabs[0] = BrowserTab(id: DateTime.now().millisecondsSinceEpoch.toString());
        _activeTabIndex = 0;
        _addressCtrl.text = 'https://aiouquizassist.edu.pk';
      });
      return;
    }
    setState(() {
      _tabs.removeAt(i);
      if (_activeTabIndex >= _tabs.length) _activeTabIndex = _tabs.length - 1;
      _addressCtrl.text = _active.url;
    });
  }

  void _selectTab(int i) => setState(() {
    _activeTabIndex = i;
    _addressCtrl.text = _tabs[i].url;
  });

  // ── Navigation ───────────────────────────────────────────────────────────────
  void _go(String value) {
    if (value.isEmpty) return;
    String url = value.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = url.contains('.') && !url.contains(' ')
          ? 'https://$url'
          : 'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
    }
    _addressFocus.unfocus();
    final tab = _active;
    setState(() { tab.url = url; tab.isHome = false; _addressCtrl.text = url; });
    final ctrl = tab.webViewController;
    if (ctrl != null) {
      ctrl.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    }
    // If controller not ready yet, url is already set on tab — WebView will
    // pick it up from initialUrlRequest when it mounts.
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_active.isHome) {
          final ctrl = _active.webViewController;
          if (ctrl != null && await ctrl.canGoBack()) {
            await ctrl.goBack();
            return false;
          }
          setState(() { _active.isHome = true; });
          return false;
        }
        return false; // never quit; Android home gesture minimises instead
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: T.bg,
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildAddressBar(),
                  Expanded(child: _buildTabContent()),
                  if (_tabs.isEmpty || _active.isHome) _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ───────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        gradient: T.chromeGrad,
        border: Border(bottom: BorderSide(color: T.divider, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const _ABrowserLogo(),
          const Spacer(),
          if (_tabs.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                gradient: T.accentGrad,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${_tabs.length}',
                style: const TextStyle(color: T.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 8),
          _ChromeBtn(icon: Icons.add_rounded,      onTap: () => _addTab(), tooltip: 'New Tab'),
          _ChromeBtn(icon: Icons.tab_rounded,      onTap: _showTabsPanel,  tooltip: 'Tabs'),
          _ChromeBtn(icon: Icons.more_vert_rounded, onTap: _showMenu,      tooltip: 'Menu'),
        ],
      ),
    );
  }

  // ── ADDRESS BAR ──────────────────────────────────────────────────────────────
  Widget _buildAddressBar() {
    return Container(
      height: 46,
      decoration: const BoxDecoration(
        gradient: T.chromeGrad,
        border: Border(bottom: BorderSide(color: T.divider, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          _NavBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: 'Back',
            onTap: () async {
              final ctrl = _active.webViewController;
              if (ctrl != null && await ctrl.canGoBack()) {
                await ctrl.goBack();
              }
            },
            isActive: !_active.isHome,
          ),
          _NavBtn(
            icon: Icons.arrow_forward_ios_rounded,
            tooltip: 'Forward',
            onTap: () async {
              final ctrl = _active.webViewController;
              if (ctrl != null && await ctrl.canGoForward()) {
                await ctrl.goForward();
              }
            },
            isActive: !_active.isHome,
          ),
          Expanded(
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: T.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: T.divider, width: 1.5),
                boxShadow: const [BoxShadow(color: Color(0x0F2D8BEF), blurRadius: 6, offset: Offset(0,2))],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _addressCtrl,
                focusNode:  _addressFocus,
                onSubmitted: _go,
                onTap: () => _addressCtrl.selection = TextSelection(
                    baseOffset: 0, extentOffset: _addressCtrl.text.length),
                style: const TextStyle(fontSize: 13, color: T.ink, fontWeight: FontWeight.w500),
                textAlign: TextAlign.left,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'Search or enter URL…',
                  hintStyle: TextStyle(color: T.inkLight, fontSize: 13),
                  contentPadding: EdgeInsets.zero,
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
              ),
            ),
          ),
          _tabs.isNotEmpty && _active.progress > 0 && _active.progress < 1.0
              ? Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      value: _active.progress, strokeWidth: 2.5, color: T.accent),
                  ),
                )
              : _ChromeBtn(icon: Icons.refresh_rounded, size: 20,
                  onTap: () => _active.webViewController?.reload(), tooltip: 'Reload'),
        ],
      ),
    );
  }

  // ── TAB CONTENT ──────────────────────────────────────────────────────────────
  Widget _buildTabContent() {
    if (_tabs.isEmpty) return const SizedBox();
    return IndexedStack(
      index: _activeTabIndex,
      children: List.generate(_tabs.length, (i) {
        final tab = _tabs[i];
        if (tab.isHome) return _buildHomeScreen(tab);
        if (tab.noInternet) return _buildNoInternetScreen(tab);
        return _buildWebView(tab);
      }),
    );
  }

  // ── HOME SCREEN ──────────────────────────────────────────────────────────────
  Widget _buildHomeScreen(BrowserTab tab) {
    return Container(
      decoration: const BoxDecoration(gradient: T.skyGrad),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _WeatherClockWidget(),
            const SizedBox(height: 20),
            if (RemoteConfig.hasUpdate) _buildUpdateBanner(tab),
            if (RemoteConfig.hasUpdate) const SizedBox(height: 12),
            _buildPolicyBox(tab),
            const SizedBox(height: 20),
            _buildQuickLinks(tab),
          ],
        ),
      ),
    );
  }

  // ── UPDATE BANNER ──────────────────────────────────────────────────────────
  Widget _buildUpdateBanner(BrowserTab tab) {
    return GestureDetector(
      onTap: () {
        setState(() { tab.isHome = false; });
        _go(RemoteConfig.updateUrl);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFE53935)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: const Color(0xFFE53935).withOpacity(0.35),
            blurRadius: 12, offset: const Offset(0, 4),
          )],
        ),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.system_update_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Update Available!',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                    color: Colors.white)),
              Text(RemoteConfig.updateMsg.isNotEmpty
                  ? RemoteConfig.updateMsg : 'Tap to download the latest version',
                style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.85))),
            ],
          )),
          Icon(Icons.download_rounded, color: Colors.white.withOpacity(0.9), size: 20),
        ]),
      ),
    );
  }

  // ── POLICY MESSAGE BOX ───────────────────────────────────────────────────────
  Widget _buildPolicyBox(BrowserTab tab) {
    // values come from RemoteConfig; fallback strings shown if offline
    final title    = RemoteConfig.noticeTitle;
    final body     = RemoteConfig.noticeBody;
    final waUrl    = RemoteConfig.whatsappUrl;
    final waLabel  = RemoteConfig.whatsappLabel;
    final waSub    = RemoteConfig.whatsappSub;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1565C0).withOpacity(0.92),
                const Color(0xFF0D47A1).withOpacity(0.88),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
            boxShadow: [BoxShadow(
              color: T.accentDeep.withOpacity(0.3),
              blurRadius: 18, offset: const Offset(0, 6),
            )],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.policy_rounded, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: 0.3)),
                ),
              ]),
              const SizedBox(height: 12),
              Text(
                body,
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.88),
                    height: 1.55, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 14),
              // WhatsApp CTA row
              GestureDetector(
                onTap: () {
                  setState(() { tab.isHome = false; });
                  _go(waUrl);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF25D366).withOpacity(0.5), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.chat_rounded, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(waLabel,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                            Text(waSub,
                              style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7))),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12,
                          color: Colors.white.withOpacity(0.6)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLinks(BrowserTab tab) {
    final links = RemoteConfig.quickLinks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text('Quick Access',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: T.inkMid.withOpacity(0.8), letterSpacing: 1.1)),
        ),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: links.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final l = links[i];
              return GestureDetector(
                onTap: () {
                  setState(() { tab.isHome = false; });
                  _go(l.url);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFDEEFFB).withOpacity(0.78),
                            const Color(0xFFC4DFFB).withOpacity(0.60),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
                        boxShadow: [BoxShadow(
                          color: l.color.withOpacity(0.12),
                          blurRadius: 8, offset: const Offset(0, 3),
                        )],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: l.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: l.color.withOpacity(0.2), width: 1),
                            ),
                            child: Icon(l.icon, color: l.color, size: 18),
                          ),
                          const SizedBox(height: 5),
                          Text(l.label,
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                                color: T.inkMid),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── NO INTERNET SCREEN ───────────────────────────────────────────────────────
  Widget _buildNoInternetScreen(BrowserTab tab) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B2545), Color(0xFF1565C0), Color(0xFF1E3A5F)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles background
          Positioned(top: -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(bottom: -80, left: -40,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Wifi off icon with glow
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2D8BEF).withOpacity(0.3),
                          blurRadius: 40, spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  // No Internet title
                  const Text(
                    'No Internet',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Decorative line
                  Container(
                    width: 48, height: 2,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFF2D8BEF)],
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Messages
                  _noInternetLine('Through your phone away'),
                  const SizedBox(height: 14),
                  _noInternetLine('Find a spot in nature'),
                  const SizedBox(height: 14),
                  _noInternetLine('Enjoy'),
                  const SizedBox(height: 44),
                  // Retry button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        tab.noInternet = false;
                        tab.isHome = false;
                      });
                      tab.webViewController?.reload();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2D8BEF), Color(0xFF1565C0)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2D8BEF).withOpacity(0.45),
                            blurRadius: 20, offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Try Again',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                                color: Colors.white, letterSpacing: 0.3)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noInternetLine(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        color: Colors.white.withOpacity(0.72),
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0.1,
      ),
      textAlign: TextAlign.center,
    );
  }

  // ── WEBVIEW ──────────────────────────────────────────────────────────────────
  Widget _buildWebView(BrowserTab tab) {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(tab.url)),
      initialSettings: InAppWebViewSettings(
        // ── Core ──────────────────────────────────────────────────────────────
        javaScriptEnabled:                    true,
        domStorageEnabled:                    true,
        databaseEnabled:                      true,
        useShouldOverrideUrlLoading:          true,
        javaScriptCanOpenWindowsAutomatically: true,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,

        // ── Performance ───────────────────────────────────────────────────────
        hardwareAcceleration:                 true,   // GPU rendering
        renderPriority: WebViewRenderPriority.HIGH,   // high thread priority
        cacheMode:      CacheMode.LOAD_DEFAULT,       // use cache = faster loads
        safeBrowsingEnabled:                  false,  // removes background checks
        disableDefaultErrorPage:              true,

        // ── Viewport / media ──────────────────────────────────────────────────
        supportZoom:                          true,
        useWideViewPort:                      true,
        loadWithOverviewMode:                 true,
        mediaPlaybackRequiresUserGesture:     false,
        allowsInlineMediaPlayback:            true,

        // ── Scroll feel ───────────────────────────────────────────────────────
        overScrollMode: OverScrollMode.OVER_SCROLL_IF_CONTENT_SCROLLS,
      ),
      shouldOverrideUrlLoading: (ctrl, action) async =>
          NavigationActionPolicy.ALLOW,
      onWebViewCreated: (ctrl) {
        tab.webViewController = ctrl;
        ctrl.addJavaScriptHandler(
          handlerName: 'onQuizCopied',
          callback: (args) {
            if (args.isNotEmpty) {
              Clipboard.setData(ClipboardData(text: args[0].toString()));
              _showCopySnack();
            }
          },
        );
      },
      onLoadStart: (ctrl, url) {
        setState(() {
          tab.url        = url.toString();
          tab.title      = 'Loading…';
          tab.noInternet = false;
          _addressCtrl.text = tab.url;
        });
      },
      onLoadStop: (ctrl, url) async {
        final title = await ctrl.getTitle();
        setState(() {
          tab.url   = url.toString();
          tab.title = title ?? tab.url;
          tab.progress = 0;
          _addressCtrl.text = tab.url;
        });
        await ctrl.evaluateJavascript(source: _js);
      },
      onLoadError: (ctrl, url, code, message) {
        final isNetworkError = code == -2 || code == -6 || code == -7 ||
            message.toLowerCase().contains('net::err') ||
            message.toLowerCase().contains('failed to connect') ||
            message.toLowerCase().contains('network');
        setState(() {
          tab.title    = 'Error';
          tab.progress = 0;
          if (isNetworkError) tab.noInternet = true;
        });
      },
      onProgressChanged: (ctrl, progress) =>
          setState(() => tab.progress = progress / 100.0),
    );
  }

  void _showCopySnack() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: const [
        Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        SizedBox(width: 8),
        Text('Quiz copied to clipboard!', style: TextStyle(fontWeight: FontWeight.w600)),
      ]),
      backgroundColor: T.success,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── FOOTER ───────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFCFE8FA).withOpacity(0.95),
            const Color(0xFFBFDDF6).withOpacity(0.98),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thin decorative line
          Container(height: 1,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent, T.accentLight.withOpacity(0.5),
                T.accent.withOpacity(0.4), T.accentLight.withOpacity(0.5),
                Colors.transparent,
              ]),
            ),
          ),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 10.5, letterSpacing: 0.15),
              children: [
                TextSpan(text: 'A gift to ',
                  style: TextStyle(color: T.inkMid.withOpacity(0.75),
                      fontStyle: FontStyle.italic)),
                const TextSpan(text: 'EduVerse Members',
                  style: TextStyle(color: T.accentDeep,
                      fontWeight: FontWeight.w700, fontStyle: FontStyle.normal)),
                TextSpan(text: '  ·  crafted by ',
                  style: TextStyle(color: T.inkLight,
                      fontStyle: FontStyle.italic)),
                const TextSpan(text: 'Asif Lashari',
                  style: TextStyle(color: T.accent,
                      fontWeight: FontWeight.w700, fontStyle: FontStyle.normal)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text('© 2026  ·  All rights reserved',
            style: TextStyle(fontSize: 9, color: T.inkLight.withOpacity(0.7),
                letterSpacing: 0.5)),
        ],
      ),
    );
  }

  // ── TABS PANEL ───────────────────────────────────────────────────────────────
  void _showTabsPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: T.chrome,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
              decoration: BoxDecoration(color: T.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('Open Tabs',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: T.ink)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () { Navigator.pop(context); _addTab(); },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New Tab'),
                  style: TextButton.styleFrom(foregroundColor: T.accent),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: ListView.builder(
                itemCount: _tabs.length,
                itemBuilder: (_, i) {
                  final t = _tabs[i];
                  final isActive = i == _activeTabIndex;
                  return GestureDetector(
                    onTap: () { _selectTab(i); Navigator.pop(context); },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive ? T.accent.withOpacity(0.1) : T.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive ? T.accent : T.divider,
                          width: isActive ? 1.5 : 1),
                      ),
                      child: Row(
                        children: [
                          Icon(t.isHome ? Icons.home_rounded : Icons.language_rounded,
                            size: 18, color: isActive ? T.accent : T.inkMid),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.title,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                      color: isActive ? T.accent : T.ink),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(t.url,
                                  style: const TextStyle(fontSize: 11, color: T.inkLight),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () { Navigator.pop(context); _closeTab(i); },
                            child: const Icon(Icons.close_rounded, size: 18, color: T.inkLight)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── MENU ─────────────────────────────────────────────────────────────────────
  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: T.chrome,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
              decoration: BoxDecoration(color: T.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            _MenuItem(icon: Icons.home_rounded, label: 'Home', onTap: () {
              Navigator.pop(context);
              setState(() { _active.isHome = true; _active.url = 'https://aiouquizassist.edu.pk'; });
            }),
            _MenuItem(icon: Icons.copy_rounded, label: 'Copy URL', onTap: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: _active.url));
            }),
            _MenuItem(icon: Icons.refresh_rounded, label: 'Reload Page', onTap: () {
              Navigator.pop(context);
              _active.webViewController?.reload();
            }),
            _MenuItem(icon: Icons.quiz_rounded, label: 'AIOU Quiz', onTap: () {
              Navigator.pop(context);
              _go('https://quiz.aiou.edu.pk');
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  LOGO — Globe + orbit rings + A letter + arrow (matches uploaded image)
// ═══════════════════════════════════════════════════════════════════════════════
class _ABrowserLogo extends StatelessWidget {
  const _ABrowserLogo();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 34, height: 34,
          child: CustomPaint(painter: _GlobeLogoPainter())),
        const SizedBox(width: 8),
        const Text('A Browser',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
              color: Color(0xFF374151), letterSpacing: -0.3)),
      ],
    );
  }
}

class _GlobeLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.48, size.height * 0.52);
    final r = size.width * 0.36;

    final globePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: const [Color(0xFF38BDF8), Color(0xFF2D8BEF), Color(0xFF1565C0)],
      ).createShader(Rect.fromCircle(center: c, radius: r));

    final greenPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF34D399), Color(0xFF059669)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.085
      ..strokeCap = StrokeCap.round;

    final bluePaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.065
      ..strokeCap = StrokeCap.round;

    // Globe body
    canvas.drawCircle(c, r, globePaint);

    // Green orbit ring (tilted ellipse)
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.52);
    canvas.scale(1.0, 0.38);
    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 1.18),
        0.2, 5.2, false, greenPaint);
    canvas.restore();

    // Blue orbit ring
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(0.9);
    canvas.scale(0.42, 1.0);
    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 1.12),
        0.5, 4.8, false, bluePaint);
    canvas.restore();

    // Letter A
    final tp = TextPainter(
      text: const TextSpan(
        text: 'A',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
            color: Colors.white, height: 1),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));

    // Arrow line
    final arrowPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF34D399), Color(0xFF059669)],
      ).createShader(Rect.fromLTWH(
          size.width * 0.55, 0, size.width * 0.45, size.height * 0.5))
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.55, size.height * 0.42)
        ..lineTo(size.width * 0.88, size.height * 0.12),
      arrowPaint,
    );

    // Arrow head
    final tip = Offset(size.width * 0.88, size.height * 0.12);
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - size.width * 0.18, tip.dy)
        ..lineTo(tip.dx, tip.dy + size.height * 0.18)
        ..close(),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF059669)],
        ).createShader(Rect.fromLTWH(
            size.width * 0.55, 0, size.width * 0.45, size.height * 0.5))
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  LIVE WEATHER + CLOCK WIDGET
// ═══════════════════════════════════════════════════════════════════════════════
class _WeatherClockWidget extends StatefulWidget {
  const _WeatherClockWidget();
  @override
  State<_WeatherClockWidget> createState() => _WeatherClockWidgetState();
}

class _WeatherClockWidgetState extends State<_WeatherClockWidget> {
  WeatherData? _weather;
  bool         _loading = true;
  String       _error   = '';
  late Timer   _clockTimer;
  DateTime     _now     = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
    _fetchWeather();
  }

  @override
  void dispose() { _clockTimer.cancel(); super.dispose(); }

  Future<void> _fetchWeather() async {
    setState(() { _loading = true; _error = ''; });
    final w = await WeatherService.fetch();
    setState(() {
      _weather = w;
      _loading = false;
      if (w == null) _error = 'Weather unavailable';
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm').format(_now);
    final secStr  = DateFormat('ss').format(_now);
    final ampm    = DateFormat('a').format(_now);
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(_now);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: T.accentDeep.withOpacity(0.35),
          blurRadius: 20, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clock row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(children: [
                  TextSpan(text: timeStr,
                    style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w300,
                        color: Colors.white, letterSpacing: -2, height: 1)),
                  TextSpan(text: ':$secStr',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300,
                        color: Colors.white.withOpacity(0.5),
                        letterSpacing: -1, height: 1.4)),
                ]),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(ampm,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.65), letterSpacing: 1)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _fetchWeather,
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.refresh_rounded, size: 18,
                      color: Colors.white.withOpacity(0.8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(dateStr,
            style: TextStyle(fontSize: 13,
                color: Colors.white.withOpacity(0.65), fontWeight: FontWeight.w400)),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.12), height: 1),
          const SizedBox(height: 16),
          // Weather section
          if (_loading)
            Row(children: [
              SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white.withOpacity(0.6))),
              const SizedBox(width: 10),
              Text('Fetching weather…',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
            ])
          else if (_error.isNotEmpty)
            Row(children: [
              Icon(Icons.cloud_off_rounded, color: Colors.white.withOpacity(0.4), size: 18),
              const SizedBox(width: 8),
              Text(_error,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
            ])
          else if (_weather != null)
            _buildWeatherRow(_weather!),
        ],
      ),
    );
  }

  Widget _buildWeatherRow(WeatherData w) {
    return Row(
      children: [
        Text(w.icon, style: const TextStyle(fontSize: 36)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${w.tempC.round()}',
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w300,
                      color: Colors.white, height: 1)),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('°C',
                    style: TextStyle(fontSize: 16,
                        color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w400)),
                ),
              ],
            ),
            Text(w.description,
              style: TextStyle(fontSize: 12,
                  color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w400)),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(w.cityName,
              style: const TextStyle(fontSize: 13, color: Colors.white,
                  fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.water_drop_outlined, size: 12,
                  color: Colors.white.withOpacity(0.6)),
              const SizedBox(width: 3),
              Text('${w.humidity}%',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
              const SizedBox(width: 8),
              Icon(Icons.air_rounded, size: 12,
                  color: Colors.white.withOpacity(0.6)),
              const SizedBox(width: 3),
              Text('${w.windKph.round()} km/h',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
            ]),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════
class _ChromeBtn extends StatelessWidget {
  final IconData   icon;
  final VoidCallback onTap;
  final String     tooltip;
  final double     size;
  const _ChromeBtn({required this.icon, required this.onTap,
      required this.tooltip, this.size = 20});
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: size, color: T.inkMid),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Future<void> Function() onTap;
  final bool isActive;
  const _NavBtn({required this.icon, required this.tooltip,
      required this.onTap, required this.isActive});
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: isActive ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18,
            color: isActive ? T.inkMid : T.inkLight.withOpacity(0.45)),
        ),
      ),
    );
  }
}
class _QuickLink {
  final String label;
  final String url;
  final IconData icon;
  final Color color;
  const _QuickLink(this.label, this.url, this.icon, this.color);
}

class _MenuItem extends StatelessWidget {
  final IconData   icon;
  final String     label;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: T.bgDeep, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: T.accent),
          ),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, color: T.ink)),
        ]),
      ),
    );
  }
}

