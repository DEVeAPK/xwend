import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'config.dart';

// ============================================================
// ТОЧКА ВХОДА
// ============================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  runApp(const XwendApp());
}

class XwendApp extends StatelessWidget {
  const XwendApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xwend',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.dark, const Color(0xFF10B981), GlassMode.liquid),
      home: const AuthGate(),
    );
  }
}

// ============================================================
// ТЕМА: Liquid / Frosted / Solid
// ============================================================
enum GlassMode { liquid, frosted, solid }

ThemeData buildTheme(Brightness b, Color accent, GlassMode mode) {
  final dark = b == Brightness.dark;
  final bg = dark ? const Color(0xFF0B0D12) : const Color(0xFFEEF1F7);
  final text = dark ? const Color(0xFFEEF1F7) : const Color(0xFF10131A);
  return ThemeData(
    brightness: b,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: b),
    fontFamily: 'Roboto',
    textTheme: TextTheme(bodyMedium: TextStyle(color: text, fontSize: 15)),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xCC10131B) : const Color(0xCCFFFFFF),
      elevation: 0,
      centerTitle: false,
    ),
  );
}

// ============================================================
// AUTH GATE
// ============================================================
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snap) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) return const ChatListScreen();
        return const AuthScreen();
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  final _username = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (_isLogin) {
        await auth.signInWithPassword(
          email: _email.text.trim(), password: _pass.text);
      } else {
        final res = await auth.signUp(
          email: _email.text.trim(),
          password: _pass.text,
          data: {'name': _name.text.trim(), 'username': _username.text.trim().toLowerCase()},
        );
        if (res.user != null) {
          await Supabase.instance.client.from('profiles').upsert({
            'id': res.user!.id,
            'name': _name.text.trim(),
            'username': _username.text.trim().toLowerCase(),
            'stars': 0,
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
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                const Text('Xwend', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 24),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Вход')),
                    ButtonSegment(value: false, label: Text('Регистрация')),
                  ],
                  selected: {_isLogin},
                  onSelectionChanged: (s) => setState(() => _isLogin = s.first),
                ),
                const SizedBox(height: 16),
                TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 8),
                TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Пароль'), obscureText: true),
                if (!_isLogin) ...[
                  const SizedBox(height: 8),
                  TextField(controller: _name, decoration: const InputDecoration(labelText: 'Имя')),
                  const SizedBox(height: 8),
                  TextField(controller: _username, decoration: const InputDecoration(labelText: '@username')),
                ],
                if (_error != null) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_isLogin ? 'Войти' : 'Создать аккаунт'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// СПИСОК ЧАТОВ
// ============================================================
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _sb = Supabase.instance.client;
  List<Map<String, dynamic>> _chats = [];
  bool _loading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _channel = _sb.channel('messages-global')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        callback: (payload) => _load(),
      ).subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _load() async {
    final me = _sb.auth.currentUser!.id;
    try {
      final parts = await _sb.from('chat_participants').select('chat_id, role').eq('user_id', me);
      final ids = (parts as List).map((e) => e['chat_id']).toList();
      if (ids.isEmpty) {
        if (mounted) setState(() { _chats = []; _loading = false; });
        return;
      }
      final chats = await _sb.from('chats').select('*').inFilter('id', ids);
      final allParts = await _sb.from('chat_participants').select('chat_id, user_id, profiles:user_id(id, username, name, avatar_color, avatar_url)').inFilter('chat_id', ids);
      final lastMsgs = await _sb.from('messages').select('*').inFilter('chat_id', ids).order('created_at', ascending: false);

      final lastBy = <String, Map<String, dynamic>>{};
      for (final m in lastMsgs as List) {
        lastBy.putIfAbsent(m['chat_id'] as String, () => Map<String, dynamic>.from(m));
      }
      final list = <Map<String, dynamic>>[];
      for (final c in chats as List) {
        final otherParts = (allParts as List).where((p) => p['chat_id'] == c['id'] && p['user_id'] != me).toList();
        list.add({
          ...Map<String, dynamic>.from(c),
          'other': otherParts.isNotEmpty ? otherParts.first['profiles'] : null,
          'last': lastBy[c['id']],
        });
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
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.chat_bubble_outline, size: 22),
          SizedBox(width: 8),
          Text('Xwend', style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {
            // TODO: экран поиска
          }),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            cacheExtent: 800,
            itemCount: _chats.length,
            itemBuilder: (context, i) {
              final c = _chats[i];
              return RepaintBoundary(child: _ChatTile(chat: c, onTap: () => _openChat(c)));
            },
          ),
    );
  }

  void _openChat(Map<String, dynamic> chat) {
    Navigator.of(context).push(CupertinoPageRoute(
      builder: (_) => ChatScreen(chat: chat),
    ));
  }
}

class _ChatTile extends StatelessWidget {
  final Map<String, dynamic> chat;
  final VoidCallback onTap;
  const _ChatTile({required this.chat, required this.onTap});

  String _name() {
    if (chat['type'] == 'saved') return 'Избранное';
    if (chat['type'] == 'direct') return chat['other']?['name'] ?? chat['other']?['username'] ?? 'Пользователь';
    return chat['title'] ?? 'Без названия';
  }

  @override
  Widget build(BuildContext context) {
    final other = chat['other'] as Map?;
    final color = other?['avatar_color'] ?? '#10B981';
    final preview = chat['last']?['content'] ?? 'Нет сообщений';
    final time = chat['last']?['created_at'] != null
      ? DateFormat('HH:mm').format(DateTime.parse(chat['last']['created_at']))
      : '';
    return ListTile(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        // TODO: показать bottom sheet с действиями
      },
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Color(int.parse(color.replaceFirst('#', '0xFF'))),
        backgroundImage: other?['avatar_url'] != null ? CachedNetworkImageProvider(other!['avatar_url']) : null,
        child: other?['avatar_url'] == null ? Text((_name().isNotEmpty ? _name()[0] : '?').toUpperCase()) : null,
      ),
      title: Text(_name(), style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    );
  }
}

// ============================================================
// ЭКРАН ПЕРЕПИСКИ
// ============================================================
class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> chat;
  const ChatScreen({super.key, required this.chat});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _sb = Supabase.instance.client;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  RealtimeChannel? _channel;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
    _channel = _sb.channel('chat-${widget.chat['id']}')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        callback: (payload) {
          final m = payload.newRecord;
          if (m['chat_id'] != widget.chat['id']) return;
          if (_messages.any((x) => x['id'] == m['id'])) return;
          if (mounted) setState(() => _messages.add(Map<String, dynamic>.from(m)));
          _scrollDown();
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'messages',
        callback: (payload) {
          final old = payload.oldRecord;
          if (old['chat_id'] != widget.chat['id']) return;
          if (mounted) setState(() => _messages.removeWhere((x) => x['id'] == old['id']));
        },
      )
      .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await _sb.from('messages').select('*').eq('chat_id', widget.chat['id']).order('created_at', ascending: true);
      if (mounted) setState(() { _messages = List<Map<String, dynamic>>.from(data); _loading = false; });
      _scrollDown();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    _sending = true;
    _input.clear();

    // Optimistic UI
    final tid = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = {
      'id': tid, 'chat_id': widget.chat['id'],
      'sender_id': _sb.auth.currentUser!.id,
      'content': text, 'message_type': 'text',
      'created_at': DateTime.now().toIso8601String(),
    };
    setState(() => _messages.add(optimistic));
    _scrollDown();

    try {
      final res = await _sb.from('messages').insert({
        'chat_id': widget.chat['id'],
        'sender_id': _sb.auth.currentUser!.id,
        'content': text,
        'message_type': 'text',
      }).select().single();
      final idx = _messages.indexWhere((m) => m['id'] == tid);
      if (idx >= 0 && mounted) setState(() => _messages[idx] = Map<String, dynamic>.from(res));
    } catch (e) {
      if (mounted) setState(() => _messages.removeWhere((m) => m['id'] == tid));
    } finally {
      _sending = false;
    }
  }

  Future<void> _delete(Map<String, dynamic> m) async {
    final idx = _messages.indexOf(m);
    if (idx < 0) return;
    setState(() => _messages.removeAt(idx));
    try {
      await _sb.from('messages').delete().eq('id', m['id']);
    } catch (e) {
      if (mounted) setState(() => _messages.insert(idx, m));
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = _sb.auth.currentUser!.id;
    final name = widget.chat['type'] == 'saved' ? 'Избранное'
      : (widget.chat['type'] == 'direct'
        ? (widget.chat['other']?['name'] ?? widget.chat['other']?['username'] ?? 'Чат')
        : (widget.chat['title'] ?? 'Чат'));
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(icon: const Icon(Icons.card_giftcard), onPressed: () {
            // TODO: магазин подарков
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scroll,
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  cacheExtent: 800,
                  addAutomaticKeepAlives: true,
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final m = _messages[i];
                    final out = m['sender_id'] == me;
                    return RepaintBoundary(child: _Bubble(
                      msg: m, out: out,
                      onLongPress: () {
                        HapticFeedback.mediumImpact();
                        showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          ListTile(leading: const Icon(Icons.reply), title: const Text('Ответить'), onTap: () => Navigator.pop(context)),
                          ListTile(leading: const Icon(Icons.star), title: const Text('В Избранное'), onTap: () => Navigator.pop(context)),
                          ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('Удалить', style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(context); _delete(m); }),
                        ])));
                      },
                    ));
                  },
                ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Theme.of(context).appBarTheme.backgroundColor,
              child: Row(children: [
                IconButton(icon: const Icon(Icons.attach_file), onPressed: () {}),
                Expanded(
                  child: TextField(
                    controller: _input,
                    decoration: const InputDecoration(hintText: 'Сообщение...', border: InputBorder.none),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _send),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool out;
  final VoidCallback onLongPress;
  const _Bubble({required this.msg, required this.out, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Align(
        alignment: out ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: out ? Theme.of(context).colorScheme.primary : Colors.grey[850],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(out ? 16 : 4), bottomRight: Radius.circular(out ? 4 : 16),
              ),
            ),
            child: Text(msg['content'] ?? '', style: TextStyle(color: out ? Colors.white : Colors.white70, fontSize: 15)),
          ),
        ),
      ),
    );
  }
}
