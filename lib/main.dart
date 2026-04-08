import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as ap;
import 'providers/ticket_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/create_ticket_screen.dart';
import 'screens/ticket_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await ap.AuthProvider().ensureAdminAccountsExist();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ap.AuthProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
      ],
      child: Builder(
        builder: (context) {
          final router = _buildRouter(context);
          return MaterialApp.router(
            title: 'SupportDesk',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(),
            routerConfig: router,
          );
        },
      ),
    );
  }

  GoRouter _buildRouter(BuildContext context) {
    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final authProvider = Provider.of<ap.AuthProvider>(
          context,
          listen: false,
        );
        final isAuthenticated =
            authProvider.status == ap.AuthStatus.authenticated;
        final isLoading = authProvider.status == ap.AuthStatus.initial;

        if (isLoading) return null;

        final isPublicPage =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (!isAuthenticated && !isPublicPage) return '/login';
        if (isAuthenticated && isPublicPage) {
          return authProvider.isAdmin ? '/admin' : '/dashboard';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
        GoRoute(
          path: '/dashboard',
          builder: (_, _) => const ClientDashboardScreen(),
        ),
        GoRoute(
          path: '/admin',
          builder: (_, _) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/create-ticket',
          builder: (_, _) => const CreateTicketScreen(),
        ),
        GoRoute(
          path: '/ticket/:id',
          builder: (_, state) =>
              TicketDetailScreen(ticketId: state.pathParameters['id']!),
        ),
      ],
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5D5FEF),
        brightness: Brightness.light,
      ),
      fontFamily: 'Inter',
      scaffoldBackgroundColor: const Color(0xFFF0F2F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}
