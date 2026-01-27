import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/tournament_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_layout.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authProvider = AuthProvider();
  await authProvider.checkAuthStatus();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => TournamentProvider()),
      ],
      child: const PikApp(),
    ),
  );
}

class PikApp extends StatelessWidget {
  const PikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vợt Thủ Phố Núi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoggedIn) {
            return const MainLayout();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
