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
animation: _c,
builder: (_, __) => Align(
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
placeholder: (_, __) => _fallback(bg),
errorWidget: (_, __, ___) => _fallback(bg),
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
animation: _c,
builder: (_, child) {
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
_ch = _sb.channel('chats-rt')
..onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'chats', callback: (_) => _load())
..onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'chat_participants', callback: (_) => _load())
..subscribe();
_chMsgs = _sb.channel('msgs-rt')
..onPostgresChanges(event: PostgresChangeEvent.insert, schema: 'public', table: 'messages', callback: (_) => _load())
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
_savedId = r as String;
} catch (_) {}
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
final chats = await _sb.from('chats').select('*').inFilter('id', ids);
final allParts = await _sb.from('chat_participants').select('chat_id, user_id, role, profiles:user_id(id, username, name, avatar_color, avatar_url)').inFilter('chat_id', ids);
final lastMsgs = await _sb.from('messages').select('*').inFilter('chat_id', ids).order('created_at', ascending: false);
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
if (mounted) setState(() { _chats = list; _loading = false; });
} catch (_) {
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
Future _openChat(Map<String, dynamic> c) async {
await Navigator.of(context).push(CupertinoPageRoute(builder: (_) => ChatScreen(chat: c)));
_load();
}
void _openContext(Map<String, dynamic> c) {
HapticFeedback.mediumImpact();
final t = themeCtl.theme;
showModalBottomSheet(
context: context,
backgroundColor: t.cardSolid,
shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
builder: (_) => SafeArea(
child: Column(mainAxisSize: MainAxisSize.min, children: [
ListTile(
title: Text(_name(c), style: TextStyle(fontWeight: FontWeight.w700, color: t.text)),
subtitle: Text(c['username'] != null ? '@${c['username']}' : '', style: TextStyle(color: t.muted, fontSize: 12)),
),
const Divider(height: 1),
if (c['type'] == 'direct' && c['other'] != null) ...[
ListTile(leading: const Icon(Icons.person_outline), title: const Text('Открыть профиль'), onTap: () { Navigator.pop(context); Navigator.of(context).push(CupertinoPageRoute(builder: (_) => OtherProfileScreen(userId: c['other']['id'], user: c['other']))); }),
ListTile(leading: const Icon(Icons.block), title: const Text('Заблокировать'), onTap: () async {
Navigator.pop(context);
try { await Supabase.instance.client.rpc('toggle_block', params: {'p_user_id': c['other']['id']}); } catch (_) {}
}),
],
if (c['type'] == 'group' || c['type'] == 'channel')
ListTile(leading: const Icon(Icons.info_outline), title: const Text('Информация'), onTap: () { Navigator.pop(context); Navigator.push(context, CupertinoPageRoute(builder: (_) => GroupScreen(chat: c))); }),
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
_load();
} catch (_) {}
},
),
]),
),
);
}
void _openCreateSheet() {
final t = themeCtl.theme;
showModalBottomSheet(
context: context,
backgroundColor: t.cardSolid,
shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
builder: (_) => SafeArea(
child: Column(mainAxisSize: MainAxisSize.min, children: [
ListTile(leading: const Icon(Icons.group_add), title: const Text('Новая группа'), onTap: () { Navigator.pop(context); _createChat('group'); }),
ListTile(leading: const Icon(Icons.campaign), title: const Text('Новый канал'), onTap: () { Navigator.pop(context); _createChat('channel'); }),
]),
),
);
}
void _createChat(String type) {
final t = themeCtl.theme;
final title = TextEditingController();
final uname = TextEditingController();
showDialog(
context: context,
builder: (_) => AlertDialog(
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
_scrollDown();
} catch (_) {
if (mounted) setState(() => _loading = false);
}
}
void _scrollDown() {
WidgetsBinding.instance.addPostFrameCallback((_) {
if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
});
}
Future _send() async {
final text = _input.text.trim();
if (text.isEmpty || _sending || !canWrite) return;
_sending = true;
_input.clear();
final tid = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
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
if (idx >= 0 && mounted) setState(() => _messages[idx] = Map<String, dynamic>.from(res));
} catch (_) {
if (mounted) setState(() => _messages.removeWhere((m) => m['id'] == tid));
} finally {
_sending = false;
}
}
Future _deleteMessage(Map<String, dynamic> m) async {
final idx = _messages.indexOf(m);
if (idx < 0) return;
setState(() => _messages.removeAt(idx));
try { await _sb.from('messages').delete().eq('id', m['id']); } catch (_) {
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
Future _uploadAndSendFile(File file, {required bool isImage, required String name}) async {
final tid = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
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
final path = '$me/\({DateTime.now().millisecondsSinceEpoch}.\)ext';
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
final path = '\({dir.path}/voice\_\){DateTime.now().millisecondsSinceEpoch}.m4a';
await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
setState(() { _recording = true; _recSecs = 0; });
_recTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _recSecs++));
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
final dur = _recSecs < 1 ? 1 : _recSecs;
final tid = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
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
final storagePath = '\(me/voice\_\){DateTime.now().millisecondsSinceEpoch}.m4a';
await _sb.storage.from(AppConfig.mediaBucket).upload(storagePath, file);
final url = _sb.storage.from(AppConfig.mediaBucket).getPublicUrl(storagePath);
final res = await _sb.from('messages').insert({
'chat_id': chatId, 'sender_id': me, 'content': '',
'message_type': 'voice', 'file_url': url, 'duration_sec': dur,
}).select().single();
final idx = _messages.indexWhere((m) => m['id'] == tid);
if (idx >= 0 && mounted) setState(() => _messages[idx] = Map<String, dynamic>.from(res));
} catch (_) {
if (mounted) setState(() => _messages.removeWhere((m) => m['id'] == tid));
}
}
void _openMessageMenu(Map<String, dynamic> m) {
HapticFeedback.mediumImpact();
final t = themeCtl.theme;
showModalBottomSheet(
context: context,
backgroundColor: t.cardSolid,
shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
builder: (_) => SafeArea(
child: Column(mainAxisSize: MainAxisSize.min, children: [
ListTile(leading: const Icon(Icons.reply), title: const Text('Ответить'), onTap: () { Navigator.pop(context); setState(() => _replyTo = m); }),
ListTile(leading: const Icon(Icons.delete, color: Colors.redAccent), title: const Text('Удалить', style: TextStyle(color: Colors.redAccent)), onTap: () { Navigator.pop(context); _deleteMessage(m); }),
]),
),
);
}
