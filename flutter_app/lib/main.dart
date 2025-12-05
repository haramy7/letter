import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:animate_do/animate_do.dart';

const Color kBgDark = Color(0xFF1E1024);
const Color kCardBg = Color(0xFF2D1B36);
const Color kAccent = Color(0xFFA65D92);
const Color kTextWhite = Color(0xFFF3E5F5);
const Color kTextGrey = Color(0xFFB39DDB);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class ApiService {
  // final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:8081'));
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://letterbackend-production.up.railway.app/'));
  final _storage = const FlutterSecureStorage();

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'accessToken');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          final refreshToken = await _storage.read(key: 'refreshToken');
          if (refreshToken != null) {
            try {
              final res = await Dio(BaseOptions(baseUrl: 'http://localhost:8081'))
                  .post('/auth/refresh', options: Options(headers: {'RefreshToken': refreshToken}));
              final newAccess = res.data['accessToken'];
              await _storage.write(key: 'accessToken', value: newAccess);
              e.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
              return handler.resolve(await _dio.fetch(e.requestOptions));
            } catch (err) {
              await _storage.deleteAll();
            }
          }
        }
        return handler.next(e);
      },
    ));
  }

  Future<void> login(String u, String p, bool remember) async {
    final res = await _dio.post('/auth/login', data: {'username': u, 'password': p});
    await _storage.write(key: 'accessToken', value: res.data['accessToken']);
    if (remember) await _storage.write(key: 'refreshToken', value: res.data['refreshToken']);
  }

  Future<void> signup(String u, String p, String n) async {
    await _dio.post('/auth/signup', data: {'username': u, 'password': p, 'nickname': n});
  }

  Future<bool> hasWrittenToday() async {
    try {
      final res = await _dio.get('/api/letters/today');
      return res.data as bool;
    } catch (e) {
      return false;
    }
  }

  Future<void> write(String content) async {
    await _dio.post('/api/letters', data: {'content': content});
  }

  Future<List<dynamic>> getLetters() async {
    try {
      final res = await _dio.get('/api/letters');
      return res.data;
    } catch (e) {
      return [];
    }
  }
  
  Future<void> deleteLetter(int id) async {
    await _dio.delete('/api/letters/$id');
  }
  
  Future<void> logout() async => await _storage.deleteAll();
}

class AuthProvider extends ChangeNotifier {
  final ApiService api = ApiService();
  bool isAuthenticated = false;

  Future<bool> tryAutoLogin() async {
    final token = await const FlutterSecureStorage().read(key: 'accessToken');
    if (token != null) {
      isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> login(String u, String p, bool remember) async {
    await api.login(u, p, remember);
    isAuthenticated = true;
    notifyListeners();
  }

  Future<void> signup(String u, String p, String n) async {
    await api.signup(u, p, n);
  }

  void logout() {
    api.logout();
    isAuthenticated = false;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'ChosunGu',
          brightness: Brightness.dark,
          scaffoldBackgroundColor: kBgDark,
          useMaterial3: true,
          colorScheme: const ColorScheme.dark(
            primary: kAccent,
            surface: kCardBg,
          ),
        ),
        home: const AuthCheck(),
      ),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});
  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (ctx, auth, _) => auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _uCon = TextEditingController();
  final _pCon = TextEditingController();
  bool _remember = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kCardBg,
                    border: Border.all(color: Colors.white10, width: 1),
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.cover,
                      errorBuilder: (c, o, s) => const Icon(Icons.mail, size: 50, color: kAccent)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              FadeIn(
                delay: const Duration(milliseconds: 200),
                child: const Text("익명발신감정함", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: kTextWhite)),
              ),
              const SizedBox(height: 10),
              const Text("오늘의 내가 나에게 보내는 편지", style: TextStyle(fontSize: 14, color: kTextGrey)),
              const SizedBox(height: 50),
              _FlatField(controller: _uCon, hint: "아이디", icon: CupertinoIcons.person),
              const SizedBox(height: 15),
              _FlatField(controller: _pCon, hint: "비밀번호", icon: CupertinoIcons.lock, obscure: true),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () => setState(() => _remember = !_remember),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(_remember ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle, color: kTextGrey, size: 18),
                    const SizedBox(width: 8),
                    const Text("로그인 유지", style: TextStyle(color: kTextGrey, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _FlatButton(text: "로그인", onTap: () async {
                try {
                  await context.read<AuthProvider>().login(_uCon.text, _pCon.text, _remember);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("로그인 실패")));
                }
              }),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                child: const Text("아직 계정이 없으신가요? 회원가입", style: TextStyle(color: kTextGrey, fontSize: 13)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _uCon = TextEditingController();
  final _pCon = TextEditingController();
  final _nCon = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("회원가입", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kTextWhite)),
              const SizedBox(height: 40),
              _FlatField(controller: _uCon, hint: "아이디", icon: CupertinoIcons.person),
              const SizedBox(height: 15),
              _FlatField(controller: _pCon, hint: "비밀번호", icon: CupertinoIcons.lock, obscure: true),
              const SizedBox(height: 15),
              _FlatField(controller: _nCon, hint: "닉네임", icon: CupertinoIcons.tag),
              const SizedBox(height: 40),
              _FlatButton(text: "가입하기", onTap: () async {
                if (_uCon.text.isEmpty || _pCon.text.isEmpty || _nCon.text.isEmpty) return;
                try {
                  await context.read<AuthProvider>().signup(_uCon.text, _pCon.text, _nCon.text);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("환영합니다! 로그인을 진행해주세요.")));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("가입 실패")));
                }
              }),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("이미 계정이 있으신가요? 로그인", style: TextStyle(color: kTextGrey, fontSize: 13)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasWritten = false;
  List<dynamic> _letters = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final api = context.read<AuthProvider>().api;
    final w = await api.hasWrittenToday();
    final l = await api.getLetters();
    setState(() {
      _hasWritten = w;
      _letters = l;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text("나의 감정들", style: TextStyle(color: kTextWhite, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.square_arrow_right, color: kTextGrey),
            onPressed: () => context.read<AuthProvider>().logout(),
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          FadeInDown(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MM월 dd일').format(DateTime.now()), style: const TextStyle(color: kTextGrey, fontSize: 14)),
                      Icon(CupertinoIcons.moon_stars, color: kTextGrey.withOpacity(0.5), size: 20),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _hasWritten ? "오늘의 감정이\n봉인되었습니다." : "오늘 하루,\n어떤 감정을 느끼셨나요?",
                    style: const TextStyle(color: kTextWhite, fontSize: 22, height: 1.4, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 25),
                  if (!_hasWritten)
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WriteScreen())).then((_) => _loadData()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(color: kTextWhite, borderRadius: BorderRadius.circular(14)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("기록하기", style: TextStyle(color: kBgDark, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(CupertinoIcons.arrow_right, size: 16, color: kBgDark),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Text("내일 확인 가능", style: TextStyle(color: kTextGrey, fontSize: 12)),
                    )
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _letters.length,
              itemBuilder: (ctx, i) => _LetterItem(
                letter: _letters[i], 
                index: i,
                onDeleted: _loadData,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(String dateStr) {
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('MM월 dd일').format(date);
  } catch (e) {
    return dateStr;
  }
}

String _formatDateFull(String dateStr) {
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('yyyy년 MM월 dd일').format(date);
  } catch (e) {
    return dateStr;
  }
}

class _LetterItem extends StatelessWidget {
  final dynamic letter;
  final int index;
  final VoidCallback onDeleted;
  const _LetterItem({required this.letter, required this.index, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    bool isPast = letter['past'] ?? false;
    String dateStr = letter['date']?.toString() ?? '';
    String formattedDate = _formatDate(dateStr);
    
    return FadeInUp(
      delay: Duration(milliseconds: index * 50),
      child: GestureDetector(
        onTap: isPast ? () => _showLetterDetail(context, letter) : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kCardBg.withOpacity(0.6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: kBgDark,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPast ? CupertinoIcons.envelope_open : CupertinoIcons.lock,
                  color: isPast ? kTextWhite : kTextGrey.withOpacity(0.3),
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formattedDate, style: const TextStyle(color: kTextWhite, fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                      isPast ? (letter['content'] ?? '') : "비밀에 부쳐진 편지입니다.",
                      style: const TextStyle(color: kTextGrey, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isPast)
                Icon(CupertinoIcons.chevron_right, color: kTextGrey.withOpacity(0.4), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showLetterDetail(BuildContext context, dynamic letter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LetterDetailSheet(letter: letter, onDeleted: onDeleted),
    );
  }
}

class LetterDetailSheet extends StatelessWidget {
  final dynamic letter;
  final VoidCallback onDeleted;
  const LetterDetailSheet({super.key, required this.letter, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    String dateStr = letter['date']?.toString() ?? '';
    String content = letter['content'] ?? '';
    int letterId = letter['id'] ?? 0;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: kBgDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInDown(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: kCardBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(CupertinoIcons.envelope_open, color: kAccent, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("과거의 나로부터", style: TextStyle(color: kTextGrey, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text(_formatDateFull(dateStr), style: const TextStyle(color: kTextWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showDeleteDialog(context, letterId),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(CupertinoIcons.trash, color: Colors.red.withOpacity(0.7), size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),
                    FadeIn(
                      delay: const Duration(milliseconds: 150),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: kCardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(CupertinoIcons.quote_bubble, color: kAccent.withOpacity(0.5), size: 28),
                            const SizedBox(height: 20),
                            Text(
                              content,
                              style: const TextStyle(
                                color: kTextWhite,
                                fontSize: 17,
                                height: 1.8,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 25),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "- 그날의 나",
                                style: TextStyle(color: kTextGrey.withOpacity(0.7), fontSize: 14, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: Center(
                        child: Text(
                          "지나간 감정도 나의 일부입니다",
                          style: TextStyle(color: kTextGrey.withOpacity(0.6), fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int letterId) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("편지 삭제"),
        content: const Text("\n이 감정의 기록을 정말 삭제할까요?\n삭제된 편지는 복구할 수 없어요."),
        actions: [
          CupertinoDialogAction(
            child: const Text("취소"),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ctx.read<AuthProvider>().api.deleteLetter(letterId);
                if (context.mounted) {
                  Navigator.pop(context);
                  onDeleted();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("편지가 삭제되었습니다.")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("삭제 실패")),
                  );
                }
              }
            },
            child: const Text("삭제"),
          ),
        ],
      ),
    );
  }
}

class WriteScreen extends StatefulWidget {
  const WriteScreen({super.key});
  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  final _con = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark, color: kTextGrey),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (_con.text.trim().isEmpty) return;
              await context.read<AuthProvider>().api.write(_con.text);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("보내기", style: TextStyle(color: kAccent, fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("오늘의 나에게,", style: TextStyle(color: kTextWhite, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: TextField(
                controller: _con,
                maxLines: null,
                style: const TextStyle(color: kTextWhite, fontSize: 16, height: 1.6),
                cursorColor: kAccent,
                decoration: const InputDecoration(
                  hintText: "솔직한 마음을 적어주세요.\n이 편지는 내일 도착합니다.",
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlatField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;

  const _FlatField({required this.controller, required this.hint, required this.icon, this.obscure = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: kTextWhite),
        cursorColor: kAccent,
        decoration: InputDecoration(
          icon: Icon(icon, color: kTextGrey, size: 20),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: kTextGrey.withOpacity(0.5)),
        ),
      ),
    );
  }
}

class _FlatButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _FlatButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: kAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
