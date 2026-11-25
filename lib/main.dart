import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'config.dart';
const kDarkBase = Color(0xFF07090E);
const kLightBase = Color(0xFFEAF0F8);
const kAccents = [
Color(0xFF10B981),
Color(0xFF7C5CFF),
Color(0xFF3B82F6),
Color(0xFFFF6B6B),
Color(0xFFF59E0B),
Color(0xFFEC4899),
];
enum ThemeMode3 { liquid, frosted, solid }
class AppTheme {
final ThemeMode3 mode;
final Brightness base;
final Color accent;
final int bgIndex;
const AppTheme({
this.mode = ThemeMode3.liquid,
this.base = Brightness.dark,
this.accent = const Color(0xFF10B981),
this.bgIndex = 1,
});
bool get isDark => base == Brightness.dark;
Color get bg => isDark ? kDarkBase : kLightBase;
Color get text => isDark ? const Color(0xFFF4F7FB) : const Color(0xFF0F131A);
Color get muted => isDark ? const Color(0xFF94A0B8) : const Color(0xFF5A657D);
Color get card => isDark ? const Color(0x99141824) : const Color(0xB8FFFFFF);
Color get cardSolid => isDark ? const Color(0xFF151923) : Colors.white;
Color get border => isDark ? Colors.white.withOpacity(.12) : Colors.black.withOpacity(.08);
List get gradient {
switch (bgIndex) {
case 1: return const [Color(0xFF09131A), Color(0xFF132A38), Color(0xFF1D4154)];
case 2: return const [Color(0xFF28163B), Color(0xFF4D295E), Color(0xFF1A1429)];
case 3: return const [Color(0xFF040B1E), Color(0xFF0A2458), Color(0xFF06122E)];
case 4: return const [Color(0xFF0C241E), Color(0xFF184A3E), Color(0xFF0B1C18)];
case 5: return const [Color(0xFF2B0E1D), Color(0xFF5E1B3A), Color(0xFF1E0B16)];
case 6: return const [Color(0xFFDCE7F7), Color(0xFFEDF3FC), Color(0xFFC9D9F0)];
default: return [bg, Color.lerp(bg, accent, 0.08)!];
}
}
AppTheme copyWith({ThemeMode3? mode, Brightness? base, Color? accent, int? bgIndex}) {
return AppTheme(
mode: mode ?? this.mode,
base: base ?? this.base,
accent: accent ?? this.accent,
bgIndex: bgIndex ?? this.bgIndex,
);
}
Future save() async {
final p = await SharedPreferences.getInstance();
await p.setString('xwend_theme', jsonEncode({
'mode': mode.index,
'base': base.index,
'accent': accent.toARGB32(),
'bgIndex': bgIndex,
}));
}
static Future load() async {
final p = await SharedPreferences.getInstance();
final raw = p.getString('xwend_theme');
if (raw == null) return const AppTheme();
try {
final m = jsonDecode(raw);
return AppTheme(
mode: ThemeMode3.values[m['mode'] ?? 0],
base: Brightness.values[m['base'] ?? 1],
accent: Color(m['accent'] ?? 0xFF10B981),
bgIndex: m['bgIndex'] ?? 1,
);
} catch (_) {
return const AppTheme();
}
}
}
class ThemeCtl extends ChangeNotifier {
AppTheme _theme = const AppTheme();
AppTheme get theme => _theme;
Future init() async {
_theme = await AppTheme.load();
notifyListeners();
}
Future update(AppTheme t) async {
_theme = t;
await t.save();
notifyListeners();
}
}
final themeCtl = ThemeCtl();
Future main() async {
WidgetsFlutterBinding.ensureInitialized();
await Supabase.initialize(
url: AppConfig.supabaseUrl,
anonKey: AppConfig.supabaseAnonKey,
);
await themeCtl.init();
SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
runApp(const XwendApp());
}
class XwendApp extends StatelessWidget {
const XwendApp({super.key});
@override
Widget build(BuildContext context) {
return AnimatedBuilder(
animation: themeCtl,
builder: (_, __) {
final t = themeCtl.theme;
return MaterialApp(
title: 'Xwend',
debugShowCheckedModeBanner: false,
theme: ThemeData(
brightness: t.base,
useMaterial3: true,
colorSchemeSeed: t.accent,
scaffoldBackgroundColor: t.bg,
fontFamily: 'Roboto',
appBarTheme: AppBarTheme(
backgroundColor: Colors.transparent,
elevation: 0,
systemOverlayStyle: t.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
),
),
home: const RootGate(),
);
},
);
}
}
class RootGate extends StatefulWidget {
const RootGate({super.key});
@override
State createState() => _RootGateState();
}
class _RootGateState extends State {
Session? _session;
@override
void initState() {
super.initState();
_session = Supabase.instance.client.auth.currentSession;
Supabase.instance.client.auth.onAuthStateChange.listen((data) {
if (mounted) setState(() => _session = data.session);
});
}
@override
Widget build(BuildContext context) {
if (_session == null) return const AuthScreen();
return const HomeShell();
}
}
class XwendLogo extends StatefulWidget {
final double size;
final Color accent;
final bool pulse;
const XwendLogo({super.key, this.size = 28, required this.accent, this.pulse = true});
@override
State createState() => _XwendLogoState();
}
class _XwendLogoState extends State with SingleTickerProviderStateMixin {
late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
@override
void dispose() {
_c.dispose();
super.dispose();
}
@override
Widget build(BuildContext context) {
return SizedBox(
width: widget.size,
height: widget.size,
child: CustomPaint(
painter: _LogoPainter(widget.accent),
child: widget.pulse
? AnimatedBuilder(
animation: c,
builder: (, __) => Align(
alignment: const Alignment(0.85, -0.85),
child: Container(
width: widget.size * 0.14,
height: widget.size * 0.14,
decoration: BoxDecoration(
color: widget.accent.withOpacity(0.35 + 0.55 * (1 - _c.value)),
shape: BoxShape.circle,
boxShadow: [BoxShadow(color: widget.accent.withOpacity(0.6), blurRadius: 6)],
),
),
),
)
: const SizedBox.shrink(),
),
);
}
}
class _LogoPainter extends CustomPainter {
final Color accent;
_LogoPainter(this.accent);
@override
void paint(Canvas canvas, Size size) {
final s = size.width / 32.0;
final bg = Paint()..color = accent.withOpacity(0.22);
final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(9 * s));
canvas.drawRRect(rrect, bg);
final p = Paint()
..color = accent
..strokeWidth = 3 * s
..strokeCap = StrokeCap.round
..style = PaintingStyle.stroke;
canvas.drawLine(Offset(9 * s, 9 * s), Offset(23 * s, 23 * s), p);
canvas.drawLine(Offset(23 * s, 9 * s), Offset(9 * s, 23 * s), p);
}
@override
bool shouldRepaint(covariant _LogoPainter old) => old.accent != accent;
}
String fmtStars(num? n) {
final v = (n ?? 0).toInt();
return v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ');
}
String fmtTime(String? iso) {
if (iso == null) return '';
final d = DateTime.parse(iso).toLocal();
final now = DateTime.now();
if (d.year == now.year && d.month == now.month && d.day == now.day) {
return DateFormat('HH:mm').format(d);
}
final y = now.subtract(const Duration(days: 1));
if (d.year == y.year && d.month == y.month && d.day == y.day) return 'вчера';
return DateFormat('dd.MM').format(d);
}
String initials(String? name) {
final n = (name ?? '').trim();
if (n.isEmpty) return '?';
final parts = n.split(RegExp(r'\s+')).take(2);
return parts.map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').join();
}
Color colorFor(String? seed) {
final s = (seed ?? 'x');
var h = 0;
for (var i = 0; i < s.length; i++) {
h = (h * 31 + s.codeUnitAt(i)) & 0xFFFFFFFF;
}
const pal = [Color(0xFF7C5CFF), Color(0xFF10B981), Color(0xFF3B82F6), Color(0xFFFF6B6B), Color(0xFFF59E0B), Color(0xFFEC4899)];
return pal[h % pal.length];
}
Color hexColor(String? hex, {Color fallback = const Color(0xFF10B981)}) {
if (hex == null || hex.isEmpty) return fallback;
try {
final v = hex.replaceFirst('#', '');
return Color(int.parse('FF$v', radix: 16));
} catch (_) {
return fallback;
}
}
class AvatarView extends StatelessWidget {
final String? name;
final String? username;
final String? url;
final String? color;
final double size;
final IconData? icon;
const AvatarView({super.key, this.name, this.username, this.url, this.color, this.size = 48, this.icon});
@override
Widget build(BuildContext context) {
final bg = hexColor(color, fallback: colorFor(username ?? name));
Widget child;
if (icon != null) {
child = Container(
width: size,
height: size,
decoration: BoxDecoration(
shape: BoxShape.circle,
gradient: LinearGradient(colors: [bg, Color.lerp(bg, const Color(0xFF7C5CFF), 0.55)!]),
),
child: Icon(icon, color: Colors.white, size: size * 0.45),
);
} else if (url != null && url!.isNotEmpty) {
child = ClipOval(
child: CachedNetworkImage(
imageUrl: url!,
width: size,
height: size,
fit: BoxFit.cover,
placeholder: (_, __) => fallback(bg),
errorWidget: (, __, ___) => _fallback(bg),
),
);
} else {
child = _fallback(bg);
}
return Container(
decoration: BoxDecoration(
shape: BoxShape.circle,
border: Border.all(color: Colors.white.withOpacity(0.28), width: 1.2),
),
child: child,
);
}
Widget _fallback(Color bg) {
return Container(
width: size,
height: size,
alignment: Alignment.center,
decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
child: Text(initials(name ?? username), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.36)),
);
}
}
class AnimatedBackground extends StatefulWidget {
final AppTheme theme;
final Widget child;
const AnimatedBackground({super.key, required this.theme, required this.child});
@override
State createState() => _AnimatedBackgroundState();
}
class _AnimatedBackgroundState extends State with SingleTickerProviderStateMixin {
late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat(reverse: true);
@override
void dispose() {
_c.dispose();
super.dispose();
}
@override
Widget build(BuildContext context) {
final t = widget.theme;
return AnimatedBuilder(
animation: c,
builder: (, child) {
final v = _c.value;
return Container(
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment(-1 + 0.5 * v, -1 + 0.4 * v),
end: Alignment(1 - 0.4 * v, 1 - 0.5 * v),
colors: t.gradient,
),
),
child: Stack(children: [
Positioned(
top: -100 + 40 * math.sin(v * math.pi * 2),
left: -80 + 30 * math.cos(v * math.pi * 2),
child: _Blob(color: t.accent.withOpacity(0.28)),
),
Positioned(
bottom: -100 + 40 * math.cos(v * math.pi * 2),
right: -80 + 30 * math.sin(v * math.pi * 2),
child: _Blob(color: const Color(0xFF7C5CFF).withOpacity(0.20)),
),
Positioned.fill(child: child!),
]),
);
},
child: widget.child,
);
}
}
class _Blob extends StatelessWidget {
final Color color;
const _Blob({required this.color});
@override
Widget build(BuildContext context) {
return Container(
width: 380,
height: 380,
decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])),
);
}
}
class GlassBox extends StatelessWidget {
final AppTheme theme;
final Widget child;
final EdgeInsets? padding;
final BorderRadius? radius;
final bool blur;
const GlassBox({super.key, required this.theme, required this.child, this.padding, this.radius, this.blur = true});
@override
Widget build(BuildContext context) {
final t = theme;
final r = radius ?? BorderRadius.circular(24);
final isLiquid = t.mode == ThemeMode3.liquid;
final isFrosted = t.mode == ThemeMode3.frosted;
Widget content = Container(
padding: padding,
decoration: BoxDecoration(
borderRadius: r,
gradient: isLiquid
? LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: t.isDark
? [Colors.white.withOpacity(0.14), Colors.white.withOpacity(0.04), t.accent.withOpacity(0.09)]
: [Colors.white.withOpacity(0.82), Colors.white.withOpacity(0.45), t.accent.withOpacity(0.10)],
)
: null,
color: isLiquid ? null : (isFrosted ? t.card : t.cardSolid),
boxShadow: [
BoxShadow(color: Colors.black.withOpacity(t.isDark ? 0.35 : 0.08), blurRadius: 26, spreadRadius: -4, offset: const Offset(0, 12)),
if (isLiquid) BoxShadow(color: t.accent.withOpacity(0.12), blurRadius: 22, spreadRadius: -6),
],
),
child: child,
);
if (isLiquid) {
content = CustomPaint(foregroundPainter: _LiquidRimPainter(radius: r, isDark: t.isDark, accent: t.accent), child: content);
}
if ((isLiquid || isFrosted) && blur) {
return ClipRRect(
borderRadius: r,
child: BackdropFilter(filter: ImageFilter.blur(sigmaX: isLiquid ? 28 : 16, sigmaY: isLiquid ? 28 : 16), child: content),
);
}
return content;
}
}
class _LiquidRimPainter extends CustomPainter {
final BorderRadius radius;
final bool isDark;
final Color accent;
_LiquidRimPainter({required this.radius, required this.isDark, required this.accent});
@override
void paint(Canvas canvas, Size size) {
final rect = Offset.zero & size;
final rrect = radius.toRRect(rect).deflate(0.6);
final paint = Paint()
..style = PaintingStyle.stroke
..strokeWidth = 1.25
..shader = LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
stops: const [0.0, 0.35, 0.7, 1.0],
colors: isDark
? [Colors.white.withOpacity(0.48), Colors.white.withOpacity(0.06), accent.withOpacity(0.18), Colors.white.withOpacity(0.28)]
: [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.25), accent.withOpacity(0.22), Colors.white.withOpacity(0.75)],
).createShader(rect);
canvas.drawRRect(rrect, paint);
}
@override
bool shouldRepaint(covariant _LiquidRimPainter old) => old.isDark != isDark || old.accent != accent || old.radius != radius;
}
class HomeShell extends StatefulWidget {
const HomeShell({super.key});
@override
State createState() => _HomeShellState();
}
class _HomeShellState extends State {
int _index = 0;
@override
Widget build(BuildContext context) {
final t = themeCtl.theme;
return Scaffold(
extendBody: true,
body: AnimatedBackground(
theme: t,
child: SafeArea(
bottom: false,
child: Center(
child: ConstrainedBox(
constraints: const BoxConstraints(maxWidth: 560),
child: IndexedStack(index: _index, children: const [ChatsTab(), SearchTab(), ProfileTab()]),
),
),
),
),
bottomNavigationBar: SafeArea(
child: Padding(
padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
child: Center(
heightFactor: 1.0,
child: ConstrainedBox(
constraints: const BoxConstraints(maxWidth: 340),
child: GlassBox(
theme: t,
blur: true,
radius: BorderRadius.circular(34),
padding: const EdgeInsets.all(5),
child: SizedBox(
height: 54,
child: LayoutBuilder(
builder: (context, constraints) {
final tabW = constraints.maxWidth / 3;
return Stack(
children: [
AnimatedPositioned(
duration: const Duration(milliseconds: 340),
curve: Curves.easeOutBack,
left: _index * tabW,
top: 0,
bottom: 0,
width: tabW,
child: Container(
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(28),
gradient: LinearGradient(colors: [t.accent.withOpacity(0.35), t.accent.withOpacity(0.14)]),
border: Border.all(color: Colors.white.withOpacity(t.isDark ? 0.30 : 0.75), width: 1),
),
),
),
Row(children: [
_navBtn(0, Icons.chat_bubble_rounded, 'Чаты'),
_navBtn(1, Icons.search_rounded, 'Поиск'),
_navBtn(2, Icons.person_rounded, 'Профиль'),
]),
],
);
},
),
),
),
),
),
),
),
);
}
Widget _navBtn(int i, IconData icon, String label) {
final t = themeCtl.theme;
final on = _index == i;
return Expanded(
child: GestureDetector(
behavior: HitTestBehavior.opaque,
onTap: () { HapticFeedback.selectionClick(); setState(() => _index = i); },
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(icon, color: on ? (t.isDark ? Colors.white : t.accent) : t.muted, size: 22),
const SizedBox(height: 2),
Text(label, style: TextStyle(fontSize: 10.5, fontWeight: on ? FontWeight.w700 : FontWeight.w500, color: on ? (t.isDark ? Colors.white : t.accent) : t.muted)),
],
),
),
);
}
}
class AuthScreen extends StatefulWidget {
const AuthScreen({super.key});
@override
State createState() => _AuthScreenState();
}
class _AuthScreenState extends State {
final _email = TextEditingController();
final _pass = TextEditingController();
final _name = TextEditingController();
final _user = TextEditingController();
bool _isLogin = true;
bool _loading = false;
String? _error;
Future _submit() async {
setState(() { _loading = true; _error = null; });
try {
final auth = Supabase.instance.client.auth;
if (_isLogin) {
await auth.signInWithPassword(email: _email.text.trim(), password: _pass.text);
} else {
final username = _user.text.trim().toLowerCase();
final exists = await Supabase.instance.client.from('profiles').select('id').ilike('username', username).limit(1);
if ((exists as List).isNotEmpty) throw 'Этот @username занят';
final res = await auth.signUp(
email: _email.text.trim(),
password: _pass.text,
data: {'name': _name.text.trim(), 'username': username},
);
if (res.user != null) {
await Supabase.instance.client.from('profiles').upsert({
'id': res.user!.id,
'name': _name.text.trim(),
'username': username,
'stars': 0,
'avatar_color': '#10B981',
}, onConflict: 'id');
}
}
} catch (e) {
setState(() => _error = e.toString());
} finally {
if (mounted) setState(() => _loading = false);
}
}
@override
Widget build(BuildContext context) {
final t = themeCtl.theme;
return Scaffold(
body: AnimatedBackground(
theme: t,
child: SafeArea(
child: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: ConstrainedBox(
constraints: const BoxConstraints(maxWidth: 400),
child: Column(children: [
XwendLogo(size: 74, accent: t.accent),
const SizedBox(height: 12),
Text('Xwend', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: t.text)),
Text('Мессенджер нового поколения', style: TextStyle(fontSize: 13, color: t.muted)),
const SizedBox(height: 24),
GlassBox(
theme: t,
blur: true,
padding: const EdgeInsets.all(22),
radius: BorderRadius.circular(28),
child: Column(children: [
Row(children: [
Expanded(child: _authTab('Вход', true)),
Expanded(child: _authTab('Регистрация', false)),
]),
const SizedBox(height: 18),
_field('Email', _email, keyboard: TextInputType.emailAddress),
_field('Пароль', _pass, obscure: true),
if (!_isLogin) _field('Имя', _name),
if (!_isLogin) _field('@username', _user),
if (_error != null)
Padding(
padding: const EdgeInsets.only(top: 8),
child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12), textAlign: TextAlign.center),
),
const SizedBox(height: 16),
SizedBox(
width: double.infinity,
child: FilledButton(
style: FilledButton.styleFrom(
backgroundColor: t.accent,
padding: const EdgeInsets.symmetric(vertical: 15),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
),
onPressed: _loading ? null : _submit,
child: _loading
? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
: Text(_isLogin ? 'Войти' : 'Создать аккаунт', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
),
),
]),
),
]),
),
),
),
),
),
);
}
Widget _authTab(String text, bool login) {
final t = themeCtl.theme;
final on = _isLogin == login;
return GestureDetector(
onTap: () => setState(() => _isLogin = login),
child: AnimatedContainer(
duration: const Duration(milliseconds: 220),
margin: const EdgeInsets.symmetric(horizontal: 2),
padding: const EdgeInsets.symmetric(vertical: 10),
decoration: BoxDecoration(color: on ? t.accent : Colors.transparent, borderRadius: BorderRadius.circular(14)),
alignment: Alignment.center,
child: Text(text, style: TextStyle(color: on ? Colors.white : t.muted, fontWeight: FontWeight.w700)),
),
);
}
Widget _field(String label, TextEditingController c, {bool obscure = false, TextInputType? keyboard}) {
final t = themeCtl.theme;
return Padding(
padding: const EdgeInsets.only(bottom: 10),
child: TextField(
controller: c,
obscureText: obscure,
keyboardType: keyboard,
style: TextStyle(color: t.text),
decoration: InputDecoration(
labelText: label,
filled: true,
fillColor: Colors.white.withOpacity(t.isDark ? 0.06 : 0.5),
border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
labelStyle: TextStyle(color: t.muted),
),
),
);
}
}
class ChatsTab extends StatefulWidget {
const ChatsTab({super.key});
@override
State createState() => _ChatsTabState();
}
class _ChatsTabState extends State {
final _sb = Supabase.instance.client;
List<Map<String, dynamic>> _chats = [];
String? _savedId;
bool _loading = true;
RealtimeChannel? _ch;
RealtimeChannel? _chMsgs;
@override
void initState() {
super.initState();
_load();
_ch = sb.channel('chats-rt')
..onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'chats', callback: () => load())
..onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'chat_participants', callback: () => _load())
..subscribe();
_chMsgs = sb.channel('msgs-rt')
..onPostgresChanges(event: PostgresChangeEvent.insert, schema: 'public', table: 'messages', callback: () => _load())
..subscribe();
}
@override
void dispose() {
_ch?.unsubscribe();
_chMsgs?.unsubscribe();
super.dispose();
}
Future _ensureSaved() async {
if (_savedId != null) return;
try {
final r = await _sb.rpc('get_or_create_saved_chat');
savedId = r as String;
} catch () {}
}
Future _load() async {
final me = _sb.auth.currentUser!.id;
await _ensureSaved();
try {
final parts = await _sb.from('chat_participants').select('chat_id, role').eq('user_id', me);
final ids = (parts as List).map((e) => e['chat_id'] as String).toList();
if (ids.isEmpty) {
if (mounted) setState(() { _chats = []; _loading = false; });
return;
}
final chats = await _sb.from('chats').select('').inFilter('id', ids);
final allParts = await _sb.from('chat_participants').select('chat_id, user_id, role, profiles:user_id(id, username, name, avatar_color, avatar_url)').inFilter('chat_id', ids);
final lastMsgs = await _sb.from('messages').select('').inFilter('chat_id', ids).order('created_at', ascending: false);
final lastBy = <String, Map<String, dynamic>>{};
for (final m in lastMsgs as List) {
lastBy.putIfAbsent(m['chat_id'] as String, () => Map<String, dynamic>.from(m));
}
final list = <Map<String, dynamic>>[];
for (final c in chats as List) {
if (c['type'] == 'saved') continue;
final cMap = Map<String, dynamic>.from(c);
final otherParts = (allParts as List).where((p) => p['chat_id'] == c['id'] && p['user_id'] != me).toList();
final myRole = (parts as List).firstWhere((p) => p['chat_id'] == c['id'], orElse: () => {'role': 'member'})['role'];
cMap['other'] = otherParts.isNotEmpty ? otherParts.first['profiles'] : null;
cMap['last'] = lastBy[c['id']];
cMap['my_role'] = myRole;
list.add(cMap);
}
list.sort((a, b) {
final ta = a['last']?['created_at'];
final tb = b['last']?['created_at'];
if (ta == null && tb == null) return 0;
if (ta == null) return 1;
if (tb == null) return -1;
return DateTime.parse(tb).compareTo(DateTime.parse(ta));
});
if (mounted) setState(() { _chats = list; loading = false; });
} catch () {
if (mounted) setState(() => _loading = false);
}
}
String _name(Map<String, dynamic> c) {
if (c['type'] == 'saved') return 'Избранное';
if (c['type'] == 'direct') return c['other']?['name'] ?? c['other']?['username'] ?? 'Пользователь';
return c['title'] ?? 'Без названия';
}
String _preview(Map<String, dynamic>? m) {
if (m == null) return 'Нет сообщений';
switch (m['message_type']) {
case 'image': return '📷 Фото';
case 'voice': return '🎤 Голосовое';
case 'file': return '📎 Файл';
case 'gift': return '🎁 Подарок';
default: return m['content'] ?? '';
}
}
Future openChat(Map<String, dynamic> c) async {
await Navigator.of(context).push(CupertinoPageRoute(builder: () => ChatScreen(chat: c)));
_load();
}
void openContext(Map<String, dynamic> c) {
HapticFeedback.mediumImpact();
final t = themeCtl.theme;
showModalBottomSheet(
context: context,
backgroundColor: t.cardSolid,
shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
builder: () => SafeArea(
child: Column(mainAxisSize: MainAxisSize.min, children: [
ListTile(
title: Text(name(c), style: TextStyle(fontWeight: FontWeight.w700, color: t.text)),
subtitle: Text(c['username'] != null ? '@${c['username']}' : '', style: TextStyle(color: t.muted, fontSize: 12)),
),
const Divider(height: 1),
if (c['type'] == 'direct' && c['other'] != null) ...[
ListTile(leading: const Icon(Icons.person_outline), title: const Text('Открыть профиль'), onTap: () { Navigator.pop(context); Navigator.of(context).push(CupertinoPageRoute(builder: () => OtherProfileScreen(userId: c['other']['id'], user: c['other']))); }),
ListTile(leading: const Icon(Icons.block), title: const Text('Заблокировать'), onTap: () async {
Navigator.pop(context);
try { await Supabase.instance.client.rpc('toggle_block', params: {'p_user_id': c['other']['id']}); } catch () {}
}),
],
if (c['type'] == 'group' || c['type'] == 'channel')
ListTile(leading: const Icon(Icons.info_outline), title: const Text('Информация'), onTap: () { Navigator.pop(context); Navigator.push(context, CupertinoPageRoute(builder: () => GroupScreen(chat: c))); }),
ListTile(
leading: const Icon(Icons.delete, color: Colors.redAccent),
title: const Text('Удалить чат', style: TextStyle(color: Colors.redAccent)),
onTap: () async {
Navigator.pop(context);
try {
if (c['my_role'] == 'owner') {
await Supabase.instance.client.rpc('delete_chat', params: {'p_chat_id': c['id']});
} else {
await Supabase.instance.client.rpc('leave_chat', params: {'p_chat_id': c['id']});
}
load();
} catch () {}
},
),
]),
),
);
}
void openCreateSheet() {
final t = themeCtl.theme;
showModalBottomSheet(
context: context,
backgroundColor: t.cardSolid,
shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
builder: () => SafeArea(
child: Column(mainAxisSize: MainAxisSize.min, children: [
ListTile(leading: const Icon(Icons.group_add), title: const Text('Новая группа'), onTap: () { Navigator.pop(context); _createChat('group'); }),
ListTile(leading: const Icon(Icons.campaign), title: const Text('Новый канал'), onTap: () { Navigator.pop(context); _createChat('channel'); }),
]),
),
);
}
void createChat(String type) {
final t = themeCtl.theme;
final title = TextEditingController();
final uname = TextEditingController();
showDialog(
context: context,
builder: () => AlertDialog(
backgroundColor: t.cardSolid,
title: Text(type == 'group' ? 'Новая группа' : 'Новый канал'),
content: Column(mainAxisSize: MainAxisSize.min, children: [
TextField(controller: title, decoration: const InputDecoration(labelText: 'Название')),
TextField(controller: uname, decoration: const InputDecoration(labelText: '@username (необязательно)')),
]),
actions: [
TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
FilledButton(
style: FilledButton.styleFrom(backgroundColor: t.accent),
onPressed: () async {
Navigator.pop(context);
try {
final r = await Supabase.instance.client.rpc('create_group_or_channel', params: {
'p_type': type,
'p_title': title.text.trim(),
'p_username': uname.text.trim().isEmpty ? null : uname.text.trim().toLowerCase(),
});
final id = r as String;
await _load();
final c = _chats.firstWhere((x) => x['id'] == id, orElse: () => {});
if (c.isNotEmpty) _openChat(c);
} catch (e) {
if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
}
},
child: const Text('Создать'),
),
],
),
);
}
@override
Widget build(BuildContext context) {
final t = themeCtl.theme;
return Column(children: [
Padding(
padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
child: Row(children: [
XwendLogo(size: 30, accent: t.accent),
const SizedBox(width: 10),
Text('Xwend', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: t.text)),
const Spacer(),
GlassBox(
theme: t,
blur: false,
radius: BorderRadius.circular(14),
child: IconButton(icon: Icon(Icons.add_rounded, color: t.text), onPressed: _openCreateSheet),
),
]),
),
if (_savedId != null)
Padding(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
child: RepaintBoundary(
child: GlassBox(
theme: t,
blur: false,
radius: BorderRadius.circular(20),
child: ListTile(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
leading: AvatarView(icon: Icons.bookmark_rounded, size: 48, color: t.accent.toARGB32().toString()),
title: Text('Избранное', style: TextStyle(fontWeight: FontWeight.w700, color: t.text)),
subtitle: Text('Заметки, файлы, ГС и пересланные', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: t.muted, fontSize: 12.5)),
onTap: () => _openChat({'id': _savedId, 'type': 'saved', 'title': 'Избранное', 'my_role': 'owner'}),
),
),
),
),
const SizedBox(height: 2),
Expanded(
child: _loading
? Center(child: CircularProgressIndicator(color: t.accent))
: ListView.builder(
padding: const EdgeInsets.only(bottom: 95),
physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
cacheExtent: 800,
itemCount: _chats.length,
itemBuilder: (context, i) {
final c = _chats[i];
return RepaintBoundary(
child: _ChatTile(chat: c, name: _name(c), preview: _preview(c['last']), onTap: () => _openChat(c), onLong: () => _openContext(c)),
);
},
),
),
]);
}
}
class _ChatTile extends StatelessWidget {
final Map<String, dynamic> chat;
final String name;
final String preview;
final VoidCallback onTap, onLong;
const _ChatTile({required this.chat, required this.name, required this.preview, required this.onTap, required this.onLong});
@override
Widget build(BuildContext context) {
final t = themeCtl.theme;
final other = chat['other'] as Map?;
final time = chat['last'] != null ? fmtTime(chat['last']['created_at']) : '';
final isGroup = chat['type'] == 'group' || chat['type'] == 'channel';
return Padding(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
child: GlassBox(
theme: t,
blur: false,
radius: BorderRadius.circular(20),
child: InkWell(
onTap: onTap,
onLongPress: onLong,
borderRadius: BorderRadius.circular(20),
child: Padding(
padding: const EdgeInsets.all(11),
child: Row(children: [
AvatarView(
name: isGroup ? (chat['title'] ?? '') : (other?['name'] ?? ''),
username: isGroup ? (chat['username'] ?? '') : (other?['username'] ?? ''),
url: isGroup ? chat['avatar_url'] : other?['avatar_url'],
color: isGroup ? null : other?['avatar_color'],
size: 48,
),
const SizedBox(width: 12),
Expanded(
child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Row(children: [
if (isGroup)
Container(
margin: const EdgeInsets.only(right: 6),
padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
decoration: BoxDecoration(color: t.accent.withOpacity(0.22), borderRadius: BorderRadius.circular(7)),
child: Text(chat['type'] == 'channel' ? '📢 Канал' : '👥 Группа', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t.text)),
),
Expanded(child: Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: t.text), maxLines: 1, overflow: TextOverflow.ellipsis)),
]),
const SizedBox(height: 3),
Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: t.muted)),
]),
),
Text(time, style: TextStyle(fontSize: 11, color: t.muted)),
]),
),
),
),
);
}
}
class ChatScreen extends StatefulWidget {
final Map<String, dynamic> chat;
const ChatScreen({super.key, required this.chat});
@override
State createState() => _ChatScreenState();
}
class _ChatScreenState extends State {
final _sb = Supabase.instance.client;
final _input = TextEditingController();
final _scroll = ScrollController();
final _recorder = AudioRecorder();
final _player = AudioPlayer();
List<Map<String, dynamic>> _messages = [];
RealtimeChannel? _ch;
bool _loading = true;
bool _sending = false;
Map<String, dynamic>? _replyTo;
bool _showEmoji = false;
bool _recording = false;
int _recSecs = 0;
Timer? _recTimer;
String get chatId => widget.chat['id'] as String;
String get me => _sb.auth.currentUser!.id;
bool get canWrite {
if (widget.chat['type'] != 'channel') return true;
final role = widget.chat['my_role'] ?? 'member';
return role == 'owner' || role == 'admin';
}
@override
void initState() {
super.initState();
_input.addListener(() { if (mounted) setState(() {}); });
_load();
_ch = _sb.channel('chat-$chatId')
..onPostgresChanges(event: PostgresChangeEvent.insert, schema: 'public', table: 'messages', callback: (p) {
final m = p.newRecord;
if (m['chat_id'] != chatId) return;
if (_messages.any((x) => x['id'] == m['id'])) return;
if (mounted) setState(() => _messages.add(Map<String, dynamic>.from(m)));
_scrollDown();
})
..onPostgresChanges(event: PostgresChangeEvent.delete, schema: 'public', table: 'messages', callback: (p) {
final old = p.oldRecord;
if (old['chat_id'] != chatId) return;
if (mounted) setState(() => _messages.removeWhere((x) => x['id'] == old['id']));
})
..subscribe();
}
@override
void dispose() {
_ch?.unsubscribe();
_input.dispose();
_scroll.dispose();
_recTimer?.cancel();
_recorder.dispose();
_player.dispose();
super.dispose();
}
Future _load() async {
try {
final data = await _sb.from('messages').select('*').eq('chat_id', chatId).order('created_at', ascending: true);
if (mounted) setState(() { _messages = List<Map<String, dynamic>>.from(data); _loading = false; });
scrollDown();
} catch () {
if (mounted) setState(() => _loading = false);
}
}
void scrollDown() {
WidgetsBinding.instance.addPostFrameCallback(() {
if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
});
}
Future _send() async {
final text = _input.text.trim();
if (text.isEmpty || _sending || !canWrite) return;
_sending = true;
input.clear();
final tid = 'tmp${DateTime.now().millisecondsSinceEpoch}';
final optimistic = {
'id': tid, 'chat_id': chatId, 'sender_id': me,
'content': text, 'message_type': 'text',
'reply_to': _replyTo?['id'],
'created_at': DateTime.now().toIso8601String(),
};
setState(() { _messages.add(optimistic); _replyTo = null; _showEmoji = false; });
_scrollDown();
try {
final res = await _sb.from('messages').insert({
'chat_id': chatId,
'sender_id': me,
'content': text,
'message_type': 'text',
'reply_to': optimistic['reply_to'],
}).select().single();
final idx = _messages.indexWhere((m) => m['id'] == tid);
if (idx >= 0 && mounted) setState(() => messages[idx] = Map<String, dynamic>.from(res));
} catch () {
if (mounted) setState(() => _messages.removeWhere((m) => m['id'] == tid));
} finally {
_sending = false;
}
}
Future _deleteMessage(Map<String, dynamic> m) async {
final idx = _messages.indexOf(m);
if (idx < 0) return;
setState(() => _messages.removeAt(idx));
try { await sb.from('messages').delete().eq('id', m['id']); } catch () {
if (mounted) setState(() => _messages.insert(idx, m));
}
}
Future _sendMedia({required bool fromCamera}) async {
if (!canWrite) return;
final picker = ImagePicker();
final XFile? f = fromCamera
? await picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 2000)
: await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 2000);
if (f == null) return;
await _uploadAndSendFile(File(f.path), isImage: true, name: f.name);
}
Future _sendDocument() async {
if (!canWrite) return;
final r = await FilePicker.platform.pickFiles();
if (r == null || r.files.single.path == null) return;
await _uploadAndSendFile(File(r.files.single.path!), isImage: false, name: r.files.single.name);
}
Future uploadAndSendFile(File file, {required bool isImage, required String name}) async {
final tid = 'tmp${DateTime.now().millisecondsSinceEpoch}';
setState(() {
_messages.add({
'id': tid, 'chat_id': chatId, 'sender_id': me,
'content': '', 'message_type': isImage ? 'image' : 'file',
'file_url': file.path, 'file_name': name,
'created_at': DateTime.now().toIso8601String(),
});
});
_scrollDown();
try {
final ext = name.split('.').last;
final path = '$me/DateTime.now().millisecondsSinceEpoch.ext';
await _sb.storage.from(AppConfig.mediaBucket).upload(path, file);
final url = _sb.storage.from(AppConfig.mediaBucket).getPublicUrl(path);
final res = await _sb.from('messages').insert({
'chat_id': chatId, 'sender_id': me, 'content': '',
'message_type': isImage ? 'image' : 'file',
'file_url': url, 'file_name': name,
}).select().single();
final idx = _messages.indexWhere((m) => m['id'] == tid);
if (idx >= 0 && mounted) setState(() => _messages[idx] = Map<String, dynamic>.from(res));
} catch (e) {
if (mounted) setState(() => _messages.removeWhere((m) => m['id'] == tid));
if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
}
}
Future _startRecording() async {
if (!canWrite) return;
try {
if (!await _recorder.hasPermission()) return;
final dir = await getTemporaryDirectory();
final path = '{dir.path}/voice_{DateTime.now().millisecondsSinceEpoch}.m4a';
await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
setState(() { _recording = true; _recSecs = 0; });
recTimer = Timer.periodic(const Duration(seconds: 1), () => setState(() => _recSecs++));
} catch (e) {
if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Микрофон недоступен: $e')));
}
}
Future _stopRecording({bool send = true}) async {
_recTimer?.cancel();
final path = await _recorder.stop();
setState(() => _recording = false);
if (!send || path == null) return;
final file = File(path);
final dur = _recSecs < 1 ? 1 : recSecs;
final tid = 'tmp${DateTime.now().millisecondsSinceEpoch}';
setState(() {
_messages.add({
'id': tid, 'chat_id': chatId, 'sender_id': me,
'content': '', 'message_type': 'voice',
'file_url': file.path, 'duration_sec': dur,
'created_at': DateTime.now().toIso8601String(),
});
});
_scrollDown();
try {
final storagePath = 'me/voice_{DateTime.now().millisecondsSinceEpoch}.m4a';
await _sb.storage.from(AppConfig.mediaBucket).upload(storagePath, file);
final url = _sb.storage.from(AppConfig.mediaBucket).getPublicUrl(storagePath);
final res = await _sb.from('messages').insert({
'chat_id': chatId, 'sender_id': me, 'content': '',
'message_type': 'voice', 'file_url': url, 'duration_sec': dur,
}).select().single();
final idx = _messages.indexWhere((m) => m['id'] == tid);
if (idx >= 0 && mounted) setState(() => messages[idx] = Map<String, dynamic>.from(res));
} catch () {
if (mounted) setState(() => _messages.removeWhere((m) => m['id'] == tid));
}
}
void openMessageMenu(Map<String, dynamic> m) {
HapticFeedback.mediumImpact();
final t = themeCtl.theme;
showModalBottomSheet(
context: context,
backgroundColor: t.cardSolid,
shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
builder: () => SafeArea(
child: Column(mainAxisSize: MainAxisSize.min, children: [
ListTile(leading: const Icon(Icons.reply), title: const Text('Ответить'), onTap: () { Navigator.pop(context); setState(() => _replyTo = m); }),
ListTile(leading: const Icon(Icons.delete, color: Colors.redAccent), title: const Text('Удалить', style: TextStyle(color: Colors.redAccent)), onTap: () { Navigator.pop(context); _deleteMessage(m); }),
]),
),
);
}
void openChatInfo() {
if (widget.chat['type'] == 'group' || widget.chat['type'] == 'channel') {
Navigator.push(context, CupertinoPageRoute(builder: () => GroupScreen(chat: widget.chat)));
} else if (widget.chat['type'] == 'direct' && widget.chat['other'] != null) {
Navigator.push(context, CupertinoPageRoute(builder: (_) => OtherProfileScreen(userId: widget.chat['other']['id'], user: widget.chat['other'])));
}
}
String get _title {
if (widget.chat['type'] == 'saved') return 'Избранное';
if (widget.chat['type'] == 'direct') return widget.chat['other']?['name'] ?? widget.chat['other']?['username'] ?? 'Чат';
return widget.chat['title'] ?? 'Чат';
}
@override
Widget build(BuildContext context) {
final t = themeCtl.theme;
final avatarUrl = (widget.chat['type'] == 'direct' && widget.chat['other'] != null) ? widget.chat['other']['avatar_url'] : widget.chat['avatar_url'];
return Scaffold(
body: AnimatedBackground(
theme: t,
child: SafeArea(
bottom: false,
child: Center(
child: ConstrainedBox(
constraints: const BoxConstraints(maxWidth: 680),
child: Column(children: [
Padding(
padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
child: GlassBox(
theme: t,
blur: true,
radius: BorderRadius.circular(24),
padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
child: Row(children: [
IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.text, size: 20), onPressed: () => Navigator.pop(context)),
GestureDetector(
onTap: _openChatInfo,
child: Row(children: [
AvatarView(
name: widget.chat['type'] == 'direct' ? (widget.chat['other']?['name'] ?? '') : (widget.chat['title'] ?? ''),
username: widget.chat['type'] == 'direct' ? (widget.chat['other']?['username'] ?? '') : (widget.chat['username'] ?? ''),
url: avatarUrl,
size: 38,
icon: widget.chat['type'] == 'saved' ? Icons.bookmark_rounded : null,
),
const SizedBox(width: 10),
Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Text(_title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: t.text)),
Text(
widget.chat['type'] == 'direct'
? (widget.chat['other']?['username'] != null ? '@${widget.chat['other']['username']}' : '')
: widget.chat['username'] != null
? '@${widget.chat['username']}'
: (widget.chat['type'] == 'channel' ? 'Канал' : (widget.chat['type'] == 'saved' ? 'Личное облако' : 'Группа')),
style: TextStyle(fontSize: 11.5, color: t.muted),
),
]),
]),
),
const Spacer(),
]),
),
),
Expanded(
child: _loading
? Center(child: CircularProgressIndicator(color: t.accent))
: ListView.builder(
controller: _scroll,
physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
cacheExtent: 800,
addAutomaticKeepAlives: true,
itemCount: messages.length,
itemBuilder: (, i) {
final m = _messages[i];
final out = m['sender_id'] == me;
return RepaintBoundary(
child: _MessageBubble(
msg: m,
isOut: out,
onLong: () => _openMessageMenu(m),
onPlayAudio: () async {
final url = m['file_url']?.toString() ?? '';
if (url.isEmpty) return;
try {
await _player.stop();
if (url.startsWith('http')) {
await _player.play(UrlSource(url));
} else {
await _player.play(DeviceFileSource(url));
}
} catch (e) {
if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Не удалось воспроизвести ГС: $e')));
}
},
),
);
},
),
),
if (_replyTo != null)
Padding(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
child: GlassBox(
theme: t,
blur: true,
radius: BorderRadius.circular(14),
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
child: Row(children: [
Expanded(child: Text('Ответ: ${_replyTo!['content'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: t.muted, fontSize: 12))),
IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _replyTo = null)),
]),
),
),
if (_recording)
Padding(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
child: GlassBox(
theme: t,
blur: true,
radius: BorderRadius.circular(20),
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
child: Row(children: [
const Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 14),
const SizedBox(width: 8),
Text('Запись ГС: \({_recSecs ~/ 60}:\){(_recSecs % 60).toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
const Spacer(),
IconButton(icon: const Icon(Icons.close, color: Colors.redAccent), onPressed: () => _stopRecording(send: false)),
IconButton(icon: const Icon(Icons.send_rounded, color: Colors.green), onPressed: () => _stopRecording(send: true)),
]),
),
),
Padding(
padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
child: GlassBox(
theme: t,
blur: true,
radius: BorderRadius.circular(28),
padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
child: canWrite
? Row(children: [
IconButton(icon: Icon(Icons.attach_file_rounded, color: t.muted), onPressed: _sendDocument),
Expanded(
child: Container(
decoration: BoxDecoration(color: Colors.white.withOpacity(t.isDark ? 0.06 : 0.55), borderRadius: BorderRadius.circular(22)),
padding: const EdgeInsets.symmetric(horizontal: 6),
child: Row(children: [
IconButton(icon: Icon(Icons.emoji_emotions_outlined, color: t.muted), onPressed: () => setState(() => _showEmoji = !_showEmoji)),
Expanded(
child: TextField(
controller: input,
style: TextStyle(color: t.text),
decoration: const InputDecoration(hintText: 'Сообщение...', border: InputBorder.none),
onSubmitted: () => _send(),
),
),
IconButton(icon: Icon(Icons.photo_camera_outlined, color: t.muted), onPressed: () => _sendMedia(fromCamera: false)),
]),
),
),
const SizedBox(width: 6),
_input.text.trim().isEmpty
? IconButton(
style: IconButton.styleFrom(backgroundColor: t.accent.withOpacity(0.18)),
icon: Icon(Icons.mic_rounded, color: t.accent),
onPressed: _recording ? () => _stopRecording(send: true) : _startRecording,
)
: IconButton(
style: IconButton.styleFrom(backgroundColor: t.accent),
icon: const Icon(Icons.send_rounded, color: Colors.white),
onPressed: _send,
),
])
: Padding(padding: const EdgeInsets.all(10), child: Text('Только владелец/админ может писать', style: TextStyle(color: t.muted, fontSize: 13))),
),
),
if (_showEmoji)
Container(
color: t.cardSolid,
height: 240,
child: GridView.builder(
padding: const EdgeInsets.all(8),
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
itemCount: emojis.length,
itemBuilder: (, i) => InkWell(
onTap: () { _input.text += _emojis[i]; setState(() {}); },
child: Center(child: Text(_emojis[i], style: const TextStyle(fontSize: 24))),
),
),
),
SizedBox(height: MediaQuery.of(context).padding.bottom),
]),
),
),
),
),
);
}
}
const _emojis = ['😀','😃','😄','😁','😆','😅','😂','🤣','😊','😇','🙂','🙃','😉','😌','😍','🥰','😘','😋','😛','😝','🤪','🤨','🤓','😎','🥳','😏','😒','😞','😔','🙁','😣','😖','😫','😩','🥺','😢','😭','😤','😠','😡','🤬','🤯','😳','🥵','🥶','😱','😨','😰','😓','🤗','🤔','🤭','🤫','😶','😐','😑','😬','🙄','😮','😲','😴','🤤','😪','😵','🤐','🥴','🤢','🤮','🤧','😷','👍','👎','👌','✌️','🤞','🤟','🤘','🤙','👋','🤝','🙏','💪','❤️','🧡','💛','💚','💙','💜','🖤','⭐','🔥','🎉','🎁'];
class _MessageBubble extends StatelessWidget {
final Map<String, dynamic> msg;
final bool isOut;
final VoidCallback onLong;
final VoidCallback onPlayAudio;
const _MessageBubble({required this.msg, required this.isOut, required this.onLong, required this.onPlayAudio});
@override
Widget build(BuildContext context) {
final t = themeCtl.theme;
final pending = (msg['id']?.toString() ?? '').startsWith('tmp_');
final type = msg['message_type'] ?? 'text';
Widget body;
switch (type) {
case 'image':
body = ClipRRect(
borderRadius: BorderRadius.circular(14),
child: CachedNetworkImage(
imageUrl: msg['file_url'] ?? '',
width: 220,
fit: BoxFit.cover,
placeholder: (, __) => const SizedBox(width: 220, height: 160, child: Center(child: CircularProgressIndicator())),
errorWidget: (, __, ___) => const Icon(Icons.broken_image),
),
);
break;
case 'file':
body = Row(children: [
const Icon(Icons.insert_drive_file_rounded, color: Colors.white),
const SizedBox(width: 8),
Expanded(child: Text(msg['file_name'] ?? 'Файл', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
]);
break;
case 'voice':
body = InkWell(
onTap: onPlayAudio,
child: Row(mainAxisSize: MainAxisSize.min, children: [
Container(
width: 34,
height: 34,
decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), shape: BoxShape.circle),
child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
),
const SizedBox(width: 10),
Text('ГС • ${msg['duration_sec'] ?? 1} сек', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
]),
);
break;
case 'gift':
final meta = msg['meta'] is Map ? msg['meta'] : {};
body = Column(children: [
Text(meta['gift_emoji'] ?? '🎁', style: const TextStyle(fontSize: 40)),
Text(meta['gift_title'] ?? 'Подарок', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
]);
break;
default:
body = Text(msg['content'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.32));
}
return Padding(
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3.5),
child: Align(
alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
child: GestureDetector(
onLongPress: onLong,
child: Container(
constraints: BoxConstraints(maxWidth: math.min(MediaQuery.of(context).size.width * 0.78, 420)),
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
decoration: BoxDecoration(
gradient: t.mode == ThemeMode3.liquid
? LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: isOut
? [t.accent.withOpacity(0.92), Color.lerp(t.accent, const Color(0xFF0A1412), 0.35)!]
: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.06)],
)
: null,
color: t.mode == ThemeMode3.liquid ? null : (isOut ? t.accent : t.cardSolid),
borderRadius: BorderRadius.only(
topLeft: const Radius.circular(20),
topRight: const Radius.circular(20),
bottomLeft: Radius.circular(isOut ? 20 : 6),
bottomRight: Radius.circular(isOut ? 6 : 20),
),
border: t.mode == ThemeMode3.liquid ? Border.all(color: Colors.white.withOpacity(isOut ? 0.32 : 0.18), width: 1) : null,
boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4))],
),
child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
if (msg['reply_to'] != null)
Container(
margin: const EdgeInsets.only(bottom: 5),
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
decoration: BoxDecoration(color: Colors.black.withOpacity(0.22), borderRadius: BorderRadius.circular(8)),
child: const Text('Ответ на сообщение', style: TextStyle(color: Colors.white70, fontSize: 11)),
),
body,
const SizedBox(height: 3),
Row(mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
Text(fmtTime(msg['created_at']), style: const TextStyle(color: Colors.white60, fontSize: 10)),
const SizedBox(width: 4),
Icon(pending ? Icons.access_time : (msg['read_at'] != null ? Icons.done_all : Icons.done), size: 12, color: msg['read_at'] != null ? Colors.lightBlueAccent : Colors.white70),
]),
]),
),
),
),
);
}
}
class OtherProfileScreen extends StatefulWidget {
final String userId;
final Map<String, dynamic> user;
const OtherProfileScreen({super.key, required this.userId, required this.user});
@override
State createState() => _OtherProfileScreenState();
}
class _OtherProfileScreenState extends State {
final _sb = Supabase.instance.client;
List<Map<String, dynamic>> _gifts = [];
List<Map<String, dynamic>> _catalog = [];
@override
void initState() {
super.initState();
_load();
}
Future _load() async {
final g = await _sb.from('user_gifts').select('').eq('recipient_id', widget.userId).eq('is_hidden', false).order('created_at', ascending: false).limit(30);
final c = await _sb.from('gifts').select('');
if (mounted) setState(() { _gifts = List<Map<String, dynamic>>.from(g); _catalog = List<Map<String, dynamic>>.from(c); });
}
Future _openDirectChat() async {
try {
final r = await _sb.rpc('get_or_create_direct_chat', params: {'other_user_id': widget.userId});
final id = r as String;
final chats = await _sb.from('chats').select('*').eq('id', id).single();
final allParts = await _sb.from('chat_participants').select('user_id, role').eq('chat_id', id);
final me = sb.auth.currentUser!.id;
final myRole = (allParts as List).firstWhere((p) => p['user_id'] == me, orElse: () => {'role': 'member'})['role'];
final c = Map<String, dynamic>.from(chats);
c['other'] = widget.user;
c['my_role'] = myRole;
if (mounted) Navigator.pushReplacement(context, CupertinoPageRoute(builder: () => ChatScreen(chat: c)));
} catch (e) {
if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
}
}
@override
Widget build(BuildContext context) {
final t = themeCtl.theme;
return Scaffold(
body: AnimatedBackground(
theme: t,
child: SafeArea(
child: Center(
child: ConstrainedBox(
constraints: const BoxConstraints(maxWidth: 560),
child: Column(children: [
AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.text), onPressed: () => Navigator.pop(context))),
Expanded(
child: SingleChildScrollView(
padding: const EdgeInsets.symmetric(horizontal: 16),
child: Column(children: [
GlassBox(
theme: t,
blur: true,
radius: BorderRadius.circular(28),
padding: const EdgeInsets.all(20),
child: Column(children: [
AvatarView(name: widget.user['name'], username: widget.user['username'], url: widget.user['avatar_url'], color: widget.user['avatar_color'], size: 88),
const SizedBox(height: 12),
Text(widget.user['name'] ?? 'Без имени', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: t.text)),
Text('@${widget.user['username'] ?? ''}', style: TextStyle(color: t.accent, fontWeight: FontWeight.w600)),
if ((widget.user['bio'] ?? '').toString().isNotEmpty)
Padding(padding: const EdgeInsets.only(top: 10), child: Text(widget.user['bio'], style: TextStyle(color: t.muted), textAlign: TextAlign.center)),
const SizedBox(height: 16),
Row(children: [
Expanded(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: t.accent), onPressed: _openDirectChat, child: const Text('Написать'))),
const SizedBox(width: 8),
Expanded(child: OutlinedButton(onPressed: () async {
await GiftShopDialog.open(context, recipientId: widget.userId, recipientName: widget.user['name'] ?? widget.user['username'] ?? '');
_load();
}, child: const Text('🎁 Подарить'))),
]),
]),
),
const SizedBox(height: 16),
Align(alignment: Alignment.centerLeft, child: Text('Подарки (${_gifts.length})', style: TextStyle(color: t.muted, fontSize: 12, fontWeight: FontWeight.w700))),
const SizedBox(height: 8),
if (_gifts.isEmpty)
Padding(padding: const EdgeInsets.all(20), child: Text('Подарков пока нет', style: TextStyle(color: t.muted)))
else
GridView.builder(
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 105, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.95),
itemCount: gifts.length,
itemBuilder: (, i) {
final g = _gifts[i];
final gift = _catalog.firstWhere((x) => x['id'] == g['gift_id'], orElse: () => {});
return GlassBox(
theme: t,
blur: false,
radius: BorderRadius.circular(16),
padding: const EdgeInsets.all(6),
child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
Text(gift['emoji'] ?? '🎁', style: const TextStyle(fontSize: 24)),
const SizedBox(height: 3),
Text(gift['title'] ?? 'Подарок', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: t.text), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
]),
);
},
),
const SizedBox(height: 20),
]),
),
),
]),
),
),
),
),
);
}
}
class GroupScreen extends StatefulWidget {
final Map<String, dynamic> chat;
const GroupScreen({super.key, required this.chat});
@override
State createState() => _GroupScreenState();
}
class _GroupScreenState extends State {
final _sb = Supabase.instance.client;
List<Map<String, dynamic>> _members = [];
Map<String, dynamic> _chat = {};
@override
void initState() {
super.initState();
_chat = Map.of(widget.chat);
_load();
}
Future _load() async {
final parts = await _sb.from('chat_participants').select('user_id, role, profiles:user_id(id, username, name, avatar_color, avatar_url)').eq('chat_id', _chat['id']);
final c = await _sb.from('chats').select('*').eq('id', _chat['id']).single();
if (mounted) setState(() { _members = List<Map<String, dynamic>>.from(parts); _chat = Map<String, dynamic>.from(c); });
}
String get _myRole => _chat['my_role'] ?? 'member';
bool get _canEdit => _myRole == 'owner' || _myRole == 'admin';
bool get _isOwner => _myRole == 'owner';
@override
Widget build(BuildContext context) {
final t = themeCtl.theme;
return Scaffold(
body: AnimatedBackground(
theme: t,
child: SafeArea(
child: Center(
child: ConstrainedBox(
constraints: const BoxConstraints(maxWidth: 560),
child: Column(children: [
AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.text), onPressed: () => Navigator.pop(context)), title: Text('Информация', style: TextStyle(color: t.text))),
Expanded(
child: ListView(padding: const EdgeInsets.all(16), children: [
GlassBox(
theme: t,
blur: true,
radius: BorderRadius.circular(28),
padding: const EdgeInsets.all(20),
child: Column(children: [
AvatarView(name: _chat['title'], username: _chat['username'], url: _chat['avatar_url'], size: 88),
const SizedBox(height: 12),
Text(_chat['title'] ?? 'Без названия', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: t.text)),
if (_chat['username'] != null) Text('@${_chat['username']}', style: TextStyle(color: t.accent)),
Text(_chat['type'] == 'channel' ? 'Канал' : 'Группа', style: TextStyle(color: t.muted, fontSize: 12)),
const SizedBox(height: 16),
if (_canEdit) SizedBox(width: double.infinity, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: t.accent), onPressed: _editGroup, child: const Text('✏️ Редактировать'))),
if (_isOwner)
Padding(
padding: const EdgeInsets.only(top: 8),
child: SizedBox(
width: double.infinity,
child: FilledButton(
style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
onPressed: () async {
if (!await _confirm('Удалить навсегда?')) return;
try { await _sb.rpc('delete_chat', params: {'p_chat_id': chat['id']}); if (mounted) Navigator.popUntil(context, (r) => r.isFirst); } catch () {}
},
child: const Text('🗑 Удалить'),
),
),
),
if (!_isOwner)
Padding(
padding: const EdgeInsets.only(top: 8),
child: SizedBox(
width: double.infinity,
child: FilledButton(
style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
onPressed: () async {
if (!await _confirm('Покинуть чат?')) return;
try { await _sb.rpc('leave_chat', params: {'p_chat_id': chat['id']}); if (mounted) Navigator.popUntil(context, (r) => r.isFirst); } catch () {}
},
child: const Text('🚪 Покинуть'),
),
),
),
]),
),
const SizedBox(height: 20),
Text('Участники (${_members.length})', style: TextStyle(color: t.muted, fontSize: 12, fontWeight: FontWeight.w700)),
const SizedBox(height: 8),
..._members.map((m) {
final p = m['profiles'] ?? {};
final role = m['role'] ?? 'member';
final roleLabel = role == 'owner' ? 'Владелец' : role == 'admin' ? 'Админ' : 'Участник';
return Padding(
padding: const EdgeInsets.only(bottom: 6),
child: GlassBox(
theme: t,
blur: false,
radius: BorderRadius.circular(18),
padding: const EdgeInsets.all(10),
child: Row(children: [
AvatarView(name: p['name'], username: p['username'], url: p['avatar_url'], color: p['avatar_color'], size: 40),
const SizedBox(width: 10),
Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Text(p['name'] ?? p['username'] ?? 'Участник', style: TextStyle(fontWeight: FontWeight.w600, color: t.text)),
Text('@${p['username'] ?? ''}', style: TextStyle(fontSize: 11.5, color: t.muted)),
])),
Container(
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
decoration: BoxDecoration(color: role == 'owner' ? Colors.amber : (role == 'admin' ? const Color(0xFF7C5CFF) : t.accent.withOpacity(0.25)), borderRadius: BorderRadius.circular(8)),
child: Text(roleLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: role == 'owner' || role == 'admin' ? Colors.white : t.text)),
),
]),
),
);
}),
]),
),
]),
),
),
),
),
);
}
Future _editGroup() async {
final t = themeCtl.theme;
final title = TextEditingController(text: _chat['title'] ?? '');
final uname = TextEditingController(text: _chat['username'] ?? '');
final desc = TextEditingController(text: chat['description'] ?? '');
showDialog(
context: context,
builder: () => AlertDialog(
backgroundColor: t.cardSolid,
title: const Text('Редактировать'),
content: Column(mainAxisSize: MainAxisSize.min, children: [
TextField(controller: title, decoration: const InputDecoration(labelText: 'Название')),
TextField(controller: uname, decoration: const InputDecoration(labelText: '@username')),
TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Описание')),
]),
actions: [
TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
FilledButton(
style: FilledButton.styleFrom(backgroundColor: t.accent),
onPressed: () async {
Navigator.pop(context);
try {
await _sb.rpc('update_chat_info', params: {'p_chat_id': _chat['id'], 'p_title': title.text.trim(), 'p_description': desc.text.trim(), 'p_username': uname.text.trim()});
load();
} catch () {}
},
child: const Text('Сохранить'),
),
],
),
);
}
Future confirm(String text) async {
final r = await showDialog(
context: context,
builder: () => AlertDialog(
content: Text(text),
actions: [
TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Нет')),
FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Да')),
],
),
);
return r ?? false;
}
}
class SearchTab extends StatefulWidget {
const SearchTab({super.key});
@override
State createState() => _SearchTabState();
}
class _SearchTabState extends State {
final _sb = Supabase.instance.client;
final _q = TextEditingController();
List<Map<String, dynamic>> _results = [];
Timer? _deb;
bool _loading = false;
@override
void dispose() {
_q.dispose();
_deb?.cancel();
super.dispose();
}
Future _run(String q) async {
if (q.trim().isEmpty) { setState(() => _results = []); return; }
setState(() => _loading = true);
try {
final r = await _sb.rpc('global_search', params: {'p_query': q.trim()});
if (mounted) setState(() => results = List<Map<String, dynamic>>.from(r));
} catch () {} finally {
if (mounted) setState(() => _loading = false);
}
}
@override
Widget build(BuildContext context) {
final t = themeCtl.theme;
return Column(children: [
Padding(
padding: const EdgeInsets.all(12),
child: GlassBox(
theme: t,
blur: true,
radius: BorderRadius.circular(22),
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
child: TextField(
controller: _q,
style: TextStyle(color: t.text),
decoration: const InputDecoration(hintText: 'Поиск людей, групп, каналов', border: InputBorder.none, icon: Icon(Icons.search_rounded)),
onChanged: (v) { _deb?.cancel(); _deb = Timer(const Duration(milliseconds: 300), () => _run(v)); },
),
),
),
Expanded(
child: _loading
? Center(child: CircularProgressIndicator(color: t.accent))
: _results.isEmpty
? Center(child: Text('Введите @username или название', style: TextStyle(color: t.muted)))
: ListView.builder(
padding: const EdgeInsets.only(bottom: 95),
physics: const BouncingScrollPhysics(),
itemCount: results.length,
itemBuilder: (, i) {
final r = results[i];
final isUser = r['kind'] == 'user';
return Padding(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
child: GlassBox(
theme: t,
blur: false,
radius: BorderRadius.circular(20),
child: ListTile(
leading: isUser
? AvatarView(name: r['name'], username: r['username'], url: r['avatar_url'], color: r['avatar_color'], size: 42)
: CircleAvatar(backgroundColor: colorFor(r['username']), child: Text(r['bio'] == 'channel' ? '📢' : '👥')),
title: Text(r['name'] ?? 'Без имени', style: TextStyle(color: t.text, fontWeight: FontWeight.w700)),
subtitle: Text(isUser ? '@${r['username'] ?? ''}' : (r['bio'] == 'channel' ? 'Публичный канал' : 'Публичная группа'), style: TextStyle(color: t.muted, fontSize: 12)),
trailing: isUser
? null
: FilledButton(
style: FilledButton.styleFrom(backgroundColor: t.accent, padding: const EdgeInsets.symmetric(horizontal: 12)),
onPressed: () async {
try {
await sb.rpc('join_public_chat', params: {'p_chat_id': r['id']});
if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Вы вступили')));
} catch () {}
},
child: const Text('Вступить'),
),
onTap: isUser ? () => Navigator.push(context, CupertinoPageRoute(builder: () => OtherProfileScreen(userId: r['id'], user: r))) : null,
),
),
);
},
),
),
]);
}
}
class ProfileTab extends StatefulWidget {
const ProfileTab({super.key});
@override
State createState() => _ProfileTabState();
}
class _ProfileTabState extends State {
final _sb = Supabase.instance.client;
Map<String, dynamic>? _profile;
List<Map<String, dynamic>> _gifts = [];
List<Map<String, dynamic>> _catalog = [];
bool _vibro = true;
bool _hideOnline = false;
@override
void initState() {
super.initState();
_load();
}
Future _load() async {
final me = _sb.auth.currentUser!.id;
final p = await _sb.from('profiles').select('').eq('id', me).single();
final g = await _sb.from('user_gifts').select('').eq('recipient_id', me).order('created_at', ascending: false).limit(60);
final c = await _sb.from('gifts').select('*');
if (mounted) setState(() { _profile = p; _gifts = List.from(g); _catalog = List.from(c); });
}
Future _changeAvatar() async {
final picker = ImagePicker();
final f = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 400, maxHeight: 400);
if (f == null) return;
try {
final me = _sb.auth.currentUser!.id;
final path = 'avatars/{me}_{DateTime.now().millisecondsSinceEpoch}.jpg';
await _sb.storage.from(AppConfig.mediaBucket).upload(path, File(f.path));
final url = _sb.storage.from(AppConfig.mediaBucket).getPublicUrl(path);
await _sb.from('profiles').update({'avatar_url': url}).eq('id', me);
_load();
} catch (e) {
if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
}
}
void _editProfile() {
final t = themeCtl.theme;
final p = _profile;
if (p == null) return;
final nameCtrl = TextEditingController(text: p['name'] ?? '');
final userCtrl = TextEditingController(text: p['username'] ?? '');
final bioCtrl = TextEditingController(text: p['bio'] ?? '');
String selectedColor = p['avatar_color'] ?? '#10B981';
showDialog(
context: context,
builder: (_) => StatefulBuilder(
builder: (context, setLocal) => AlertDialog(
backgroundColor: t.cardSolid,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
title: Text('Редактировать профиль', style: TextStyle(color: t.text, fontWeight: FontWeight.w700)),
content: SingleChildScrollView(
child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
TextField(controller: nameCtrl, style: TextStyle(color: t.text), decoration: const InputDecoration(labelText: 'Имя')),
const SizedBox(height: 8),
TextField(controller: userCtrl, style: TextStyle(color: t.text), decoration: const InputDecoration(labelText: '@username')),
const SizedBox(height: 8),
TextField(controller: bioCtrl, maxLines: 3, style: TextStyle(color: t.text), decoration: const InputDecoration(labelText: 'О себе (Bio)')),
const SizedBox(height: 14),
Text('Цвет аватара', style: TextStyle(color: t.muted, fontSize: 12)),
const SizedBox(height: 8),
Wrap(
spacing: 8,
children: ['#10B981', '#7C5CFF', '#3B82F6', '#FF6B6B', '#F59E0B', '#EC4899'].map((hex) {
final active = selectedColor.toUpperCase() == hex;
return GestureDetector(
onTap: () => setLocal(() => selectedColor = hex),
child: Container(
width: 30,
height: 30,
decoration: BoxDecoration(color: hexColor(hex), shape: BoxShape.circle, border: Border.all(color: active ? Colors.white : Colors.transparent, width: 2.5)),
),
);
}).toList(),
),
]),
),
actions: [
TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
FilledButton(
style: FilledButton.styleFrom(backgroundColor: t.accent),
onPressed: () async {
final newUser = userCtrl.text.trim().toLowerCase().replaceAll('@', '');
if (newUser.isEmpty) return;
Navigator.pop(context);
try {
final me = _sb.auth.currentUser!.id;
await _sb.from('profiles').update({'name': nameCtrl.text.trim(), 'username': newUser, 'bio': bioCtrl.text.trim(), 'avatar_color': selectedColor}).eq('id', me);
_load();
if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Профиль обновлён')));
} catch (e) {
if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
}
},
child: const Text('Сохранить'),
),
],
),
),
);
}
void openThemeSettings() {
final t = themeCtl.theme;
showModalBottomSheet(
context: context,
isScrollControlled: true,
backgroundColor: t.cardSolid,
shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
builder: () => StatefulBuilder(
builder: (context, setLocal) => Padding(
padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
Text('Оформление и темы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: t.text)),
const SizedBox(height: 12),
Text('Стиль стекла', style: TextStyle(color: t.muted, fontSize: 12)),
const SizedBox(height: 6),
SegmentedButton(
segments: const [
ButtonSegment(value: ThemeMode3.liquid, label: Text('Liquid iOS 26')),
ButtonSegment(value: ThemeMode3.frosted, label: Text('Матовое')),
ButtonSegment(value: ThemeMode3.solid, label: Text('Плоский')),
],
selected: {themeCtl.theme.mode},
onSelectionChanged: (s) { themeCtl.update(themeCtl.theme.copyWith(mode: s.first)); setLocal(() {}); setState(() {}); },
),
const SizedBox(height: 12),
Text('База', style: TextStyle(color: t.muted, fontSize: 12)),
const SizedBox(height: 6),
SegmentedButton(
segments: const [ButtonSegment(value: Brightness.dark, label: Text('Тёмная')), ButtonSegment(value: Brightness.light, label: Text('Светлая'))],
selected: {themeCtl.theme.base},
onSelectionChanged: (s) { themeCtl.update(themeCtl.theme.copyWith(base: s.first)); setLocal(() {}); setState(() {}); },
),
const SizedBox(height: 12),
Text('Фон-градиент', style: TextStyle(color: t.muted, fontSize: 12)),
const SizedBox(height: 6),
Wrap(
spacing: 8,
children: List.generate(7, (idx) {
final names = ['База', 'Океан', 'Закат', 'Космос', 'Изумруд', 'Неон', 'Лёд'];
return ChoiceChip(
label: Text(names[idx]),
selected: themeCtl.theme.bgIndex == idx,
onSelected: (_) { themeCtl.update(themeCtl.theme.copyWith(bgIndex: idx)); setLocal(() {}); setState(() {}); },
);
}),
),
const SizedBox(height: 12),
Text('Акцент', style: TextStyle(color: t.muted, fontSize: 12)),
const SizedBox(height: 8),
Wrap(
spacing: 10,
children: kAccents.map((c) => GestureDetector(
onTap: () { themeCtl.update(themeCtl.theme.copyWith(accent: c)); setLocal(() {}); setState(() {}); },
child: Container(
width: 34,
height: 34,
decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: themeCtl.theme.accent == c ? Colors.white : Colors.transparent, width: 3)),
),
)).toList(),
),
const SizedBox(height: 20),
]),
),
),
);
}
void openExtraSettings() {
final t = themeCtl.theme;
showModalBottomSheet(
context: context,
backgroundColor: t.cardSolid,
shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
builder: () => StatefulBuilder(
builder: (context, setLocal) => SafeArea(
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
Text('Настройки приложения', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: t.text)),
const SizedBox(height: 8),
SwitchListTile(
title: Text('Тактильный отклик (вибрация)', style: TextStyle(color: t.text)),
value: _vibro,
activeColor: t.accent,
onChanged: (v) { setLocal(() => _vibro = v); setState(() => _vibro = v); },
),
SwitchListTile(
title: Text('Скрывать время последнего входа', style: TextStyle(color: t.text)),
value: _hideOnline,
activeColor: t.accent,
onChanged: (v) { setLocal(() => _hideOnline = v); setState(() => _hideOnline = v); },
),
ListTile(
leading: Icon(Icons.cleaning_services_outlined, color: t.accent),
title: Text('Очистить кэш изображений', style: TextStyle(color: t.text)),
onTap: () {
PaintingBinding.instance.imageCache.clear();
Navigator.pop(context);
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Кэш успешно очищен')));
},
),
ListTile(
leading: Icon(Icons.info_outline, color: t.muted),
title: Text('Версия Xwend', style: TextStyle(color: t.text)),
subtitle: Text('1.0.0 Native • Liquid Glass iOS 26', style: TextStyle(color: t.muted, fontSize: 12)),
),
]),
),
),
),
);
}
  void _openTopUp() {
    final t = themeCtl.theme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: t.cardSolid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Пополнить звёзды'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Укажите @${_profile?['username']} в комментарии к донату', style: TextStyle(fontSize: 12, color: t.muted)),
          const SizedBox(height: 12),
          ...AppConfig.donatePackages.map((p) => ListTile(
            title: Text('${fmtStars(p['stars'])} ★', style: TextStyle(color: t.accent, fontWeight: FontWeight.w700)),
            subtitle: Text(p['label']),
            trailing: Text(p['price']),
            onTap: () async {
              final url = Uri.parse('${AppConfig.donateUrl}?amount=${p['stars']}&comment=@${_profile?['username']}+${p['stars']}+stars');
              if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
            },
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = themeCtl.theme;
    final p = _profile;
    if (p == null) return Center(child: CircularProgressIndicator(color: t.accent));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      physics: const BouncingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GlassBox(
          theme: t,
          blur: true,
          padding: const EdgeInsets.all(20),
          radius: BorderRadius.circular(28),
          child: Column(children: [
            Stack(children: [
              AvatarView(name: p['name'], username: p['username'], url: p['avatar_url'], color: p['avatar_color'], size: 88),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _changeAvatar,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: t.accent, shape: BoxShape.circle, border: Border.all(color: t.cardSolid, width: 2)),
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Text(p['name'] ?? 'Без имени', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: t.text)),
            Text('@${p['username'] ?? ''}', style: TextStyle(color: t.accent, fontWeight: FontWeight.w600)),
            if ((p['bio'] ?? '').toString().isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text(p['bio'], style: TextStyle(color: t.muted, fontSize: 13), textAlign: TextAlign.center)),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.16), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber.withOpacity(0.45))),
                child: Text('⭐ ${fmtStars(p['stars'])}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: t.accent, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                onPressed: _openTopUp,
                child: const Text('Пополнить ★', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () async {
                  await GiftShopDialog.open(context, recipientId: _sb.auth.currentUser!.id, recipientName: p['name'] ?? 'себе', selfGift: true);
                  _load();
                },
                child: const Text('🎁 Подарить себе ★', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
        if (_gifts.isNotEmpty) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('Подарки (${_gifts.length})', style: TextStyle(color: t.muted, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 100, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.95),
            itemCount: _gifts.length,
            itemBuilder: (_, i) {
              final g = _gifts[i];
              final gift = _catalog.firstWhere((x) => x['id'] == g['gift_id'], orElse: () => {});
              return GlassBox(
                theme: t,
                blur: false,
                radius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(6),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(gift['emoji'] ?? '🎁', style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 3),
                  Text(gift['title'] ?? 'Подарок', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: t.text), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                ]),
              );
            },
          ),
        ],
        const SizedBox(height: 12),
        _row('✏️ Редактировать профиль', _editProfile),
        _row('🎨 Оформление и темы (Liquid iOS 26)', _openThemeSettings),
        _row('⚙️ Настройки приложения и приватность', _openExtraSettings),
        _row('🚪 Выйти из аккаунта', () async {
          await _sb.auth.signOut();
        }),
      ]),
    );
  }

  Widget _row(String label, VoidCallback onTap) {
    final t = themeCtl.theme;
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: GlassBox(
        theme: t,
        blur: false,
        radius: BorderRadius.circular(18),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(label, style: TextStyle(color: t.text, fontSize: 14.5, fontWeight: FontWeight.w600)),
          trailing: Icon(Icons.chevron_right_rounded, color: t.muted, size: 22),
          onTap: onTap,
        ),
      ),
    );
  }
}

class GiftShopDialog {
  static Future<void> open(BuildContext context, {required String recipientId, required String recipientName, bool selfGift = false}) async {
    final sb = Supabase.instance.client;
    final t = themeCtl.theme;
    final catalog = List<Map<String, dynamic>>.from(await sb.from('gifts').select('*').order('sort_order', ascending: true));
    if (!context.mounted) return;
    String? selectedCode;
    final note = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.cardSolid,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (_) => StatefulBuilder(builder: (context, setLocal) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Подарок для $recipientName', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: t.text)),
            const SizedBox(height: 12),
            SizedBox(
              height: 320,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.4),
                itemCount: catalog.length,
                itemBuilder: (_, i) {
                  final g = catalog[i];
                  final selected = selectedCode == g['code'];
                  return GestureDetector(
                    onTap: () => setLocal(() => selectedCode = g['code']),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? Colors.amber : t.border, width: selected ? 2 : 1)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(g['emoji'] ?? '🎁', style: const TextStyle(fontSize: 34)),
                        const SizedBox(height: 4),
                        Text(g['title'] ?? 'Подарок', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.text), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                        Text('${fmtStars(g['price'])} ★', style: const TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  );
                },
              ),
            ),
            TextField(controller: note, decoration: const InputDecoration(labelText: 'Подпись к подарку')),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
style: FilledButton.styleFrom(backgroundColor: t.accent, padding: const EdgeInsets.symmetric(vertical: 14)),
onPressed: selectedCode == null
? null
: () async {
try {
await sb.rpc('send_gift', params: {'p_recipient': recipientId, 'p_gift_code': selectedCode, 'p_note': note.text.trim(), 'p_chat_id': null});
if (context.mounted) Navigator.pop(context);
} catch (e) {
if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
}
},
child: const Text('Отправить'),
),
),
const SizedBox(height: 20),
]),
);
}),
);
}
}
