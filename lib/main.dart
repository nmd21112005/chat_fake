import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/user_session.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Firebase
  await Firebase.initializeApp();

  // 2. Kiểm tra trạng thái đăng nhập
  Widget startScreen = const LoginScreen();
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    // 3. QUAN TRỌNG: Khôi phục Session nếu đã đăng nhập
    // Nếu không có bước này, khi tắt app mở lại UserSession sẽ bị null -> Lỗi không hiện tin nhắn
    String? phone = user.phoneNumber;
    if (phone != null && phone.isNotEmpty) {
      UserSession.currentPhone = phone;
      print("✅ Đã khôi phục Session cho: $phone");
    }

    // Đã đăng nhập thì vào thẳng màn hình chính (có Footer)
    startScreen = const MainScreen();
  }

  runApp(MyApp(startScreen: startScreen));
}

class MyApp extends StatelessWidget {
  final Widget startScreen;

  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat App',
      theme: ThemeData(
        // Cấu hình Theme màu tím chủ đạo
        primaryColor: AppColors.purplePrimary,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.purplePrimary,
          foregroundColor: Colors.white, // Màu chữ/icon trên AppBar
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppColors.purplePrimary,
          secondary: AppColors.purpleSoft,
        ),
        useMaterial3: true,
      ),
      home: startScreen,
    );
  }
}