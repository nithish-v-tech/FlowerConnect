import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/state/app_state_provider.dart';
import 'core/state/auth_state_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/portal/portal_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[Firebase] Initialization notice: $e');
  }
  runApp(const ProviderScope(child: FlowerConnectApp()));
}

class FlowerConnectApp extends ConsumerStatefulWidget {
  const FlowerConnectApp({super.key});

  @override
  ConsumerState<FlowerConnectApp> createState() => _FlowerConnectAppState();
}

class _FlowerConnectAppState extends ConsumerState<FlowerConnectApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authStateProvider.notifier).initAuthSession();
      await ref.read(appStateProvider.notifier).refreshFromBackend();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'FlowerConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.isAuthenticated
          ? const PortalSelectionScreen()
          : const LoginScreen(),
    );
  }
}
