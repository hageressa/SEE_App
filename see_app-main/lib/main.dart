import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:see_app/models/child.dart';
import 'package:see_app/models/user.dart';
import 'package:see_app/screens/appointments/appointments_screen.dart';
import 'package:see_app/screens/appointments/book_appointment_screen.dart';
import 'package:see_app/screens/login_screen.dart';
import 'package:see_app/screens/messaging/conversations_screen.dart';
import 'package:see_app/screens/messaging/message_screen.dart';
import 'package:see_app/screens/onboarding/onboarding_screen.dart';
import 'package:see_app/screens/parent/components/therapist_sharing_settings.dart';
import 'package:see_app/screens/parent/parent_dashboard.dart';
import 'package:see_app/screens/therapist/redesigned_therapist_dashboard.dart';
import 'package:see_app/services/ai_therapist_service.dart';
import 'package:see_app/services/app_initializer.dart';
import 'package:see_app/services/auth_service.dart';
import 'package:see_app/services/community_service.dart';
import 'package:see_app/services/connection_service.dart';
import 'package:see_app/services/database_service.dart';
import 'package:see_app/services/emotion_service.dart';
import 'package:see_app/services/gemini_service.dart';
import 'package:see_app/services/mission_service.dart';
import 'package:see_app/services/notification_service.dart';
import 'package:see_app/utils/theme.dart';
import 'package:see_app/widgets/see_logo.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:see_app/state/onboarding_state.dart';
import 'package:flutter/foundation.dart';

// Global navigator key for safer navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Error boundary to catch Flutter framework errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  
  const ErrorBoundary({super.key, required this.child});
  
  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Error? _error;
  
  @override
  void initState() {
    super.initState();
    
    // Register error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      // Filter out AuthService disposal warnings
      if (details.exception.toString().contains('AuthService was used after being disposed')) {
        debugPrint('Suppressed AuthService disposal warning');
        return;
      }
      
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _error = details.exception is Error ? details.exception as Error : Error();
            });
          }
        });
      }
      FlutterError.presentError(details);
    };
  }
  
  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: SeeAppTheme.lightTheme,
        darkTheme: SeeAppTheme.darkTheme,
        home: Material(
          child: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 24),
                    const Text(
                      'App Error',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error.toString(),
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _error = null;
                        });
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return widget.child;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // This _themeMode variable would typically live in a StatefulWidget
  // or a state management solution if you intend to change it dynamically.
  // For now, we set a default.
  ThemeMode _themeMode = ThemeMode.system;
  
  try {
    // Initialize Firebase with error handling
    await Firebase.initializeApp();
    
    // Configure Firestore for offline persistence with error handling
    try {
      FirebaseFirestore.instance.settings = const Settings( // changed to const Settings
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint('Firebase Firestore configured successfully');
    } catch (e) {
      debugPrint('Error configuring Firestore: $e');
      // Continue without Firestore configuration
    }
    
    // Create service instances outside of runApp to use them for initialization
    final databaseService = DatabaseService();
    final appInitializer = AppInitializer(databaseService);
    
    // TEMPORARY: Reset SharedPreferences to force fresh start
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('SharedPreferences cleared for fresh start');
    } catch (e) {
      debugPrint('Error clearing SharedPreferences: $e');
    }
    
    // Initialize test data on first run with error handling
    try {
      await appInitializer.initializeAppIfNeeded();
      debugPrint('App initialized successfully');
    } catch (e) {
      debugPrint('Error initializing app: $e');
      // Continue without initialization
    }
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    // Continue without Firebase
  }
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
    ),
  );
  
  // Create services once and reuse them
  final authService = AuthService();
  final databaseService = DatabaseService();
  final missionService = MissionService();
  final geminiService = GeminiService();
  final emotionService = EmotionService();
  final communityService = CommunityService();
  final aiTherapistService = AITherapistService();
  final connectionService = ConnectionService();
  final notificationService = NotificationService();
  
  debugPrint('All services created successfully');
  
  // Run the app with error boundary and providers
  runApp(
    ErrorBoundary(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>(create: (_) => authService),
          ChangeNotifierProvider<DatabaseService>(create: (_) => databaseService),
          ChangeNotifierProvider<MissionService>(create: (_) => missionService),
          ChangeNotifierProvider<GeminiService>(create: (_) => geminiService),
          ChangeNotifierProvider<EmotionService>(create: (_) => emotionService),
          ChangeNotifierProvider<CommunityService>(create: (_) => communityService),
          ChangeNotifierProvider<AITherapistService>(create: (_) => aiTherapistService),
          ChangeNotifierProvider<ConnectionService>(create: (_) => connectionService),
          ChangeNotifierProvider<NotificationService>(create: (_) => notificationService),
          ChangeNotifierProxyProvider<AuthService, OnboardingState>(
            create: (context) => OnboardingState(user: AppUser.empty()),
            update: (context, auth, previous) => OnboardingState(
              user: auth.currentUser ?? AppUser.empty(),
            ),
          ),
        ],
        child: const SeeApp(),
      ),
    ),
  );
}

/// Safety wrapper to prevent null check errors in routes
class SafetyWrapper extends StatelessWidget {
  final Widget child;
  
  const SafetyWrapper({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    try {
      return child;
    } catch (e, stackTrace) {
      // Log the error
      debugPrint('Error in SafetyWrapper: $e');
      debugPrint(stackTrace.toString());
      
      // Return a fallback widget instead of crashing
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }
  }
}

/// Provider for theme data and controls
/// Makes theme information accessible throughout the app
class ThemeDataProvider extends InheritedWidget {
  final Brightness brightness;
  final ThemeMode themeMode;
  final VoidCallback toggleTheme;

  const ThemeDataProvider({
    super.key,
    required super.child,
    required this.brightness,
    required this.themeMode,
    required this.toggleTheme,
  });

  // Check if theme info has changed
  @override
  bool updateShouldNotify(ThemeDataProvider oldWidget) {
    return brightness != oldWidget.brightness || 
           themeMode != oldWidget.themeMode;
  }

  // Access theme info from anywhere in the widget tree
  static ThemeDataProvider of(BuildContext context) {
    final ThemeDataProvider? result = 
        context.dependOnInheritedWidgetOfExactType<ThemeDataProvider>();
    assert(result != null, 'No ThemeDataProvider found in context');
    return result!;
  }
  
  // Helper to check if dark mode is active
  bool get isDarkMode => brightness == Brightness.dark;
  
  // Get appropriate decoration based on current theme
  BoxDecoration getCardDecoration({bool emphasized = false}) {
    return emphasized 
      ? SeeAppTheme.getEmphasizedCardDecoration(brightness)
      : SeeAppTheme.getCardDecoration(brightness);
  }
}

class SeeApp extends StatelessWidget {
  const SeeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SEE App',
      theme: SeeAppTheme.lightTheme,
      darkTheme: SeeAppTheme.darkTheme,
      themeMode: ThemeMode.system,
      navigatorKey: navigatorKey,
      
      routes: {
        '/login': (context) => const LoginScreen(),
        '/parent-dashboard': (context) => const ParentDashboard(),
        '/therapist-dashboard': (context) => const RedesignedTherapistDashboard(),
        '/messages': (context) => const ConversationsScreen(),
        '/appointments': (context) => const AppointmentsScreen(),
      },
      
      onGenerateRoute: (settings) {
        if (settings.name == '/book-appointment') {
          final args = settings.arguments as Map<String, dynamic>?;
          final therapistId = args != null ? args['therapistId'] as String? : null;
          if (therapistId == null) {
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text('Missing therapistId for booking appointment')),
              ),
            );
          }
          return MaterialPageRoute(
            builder: (context) => BookAppointmentScreen(therapistId: therapistId),
          );
        }
        if (settings.name == '/therapist-sharing-settings') {
          final args = settings.arguments as Map<String, dynamic>?;
          final therapistId = args != null ? args['therapistId'] as String? : null;
          final childId = args != null ? args['childId'] as String? : null;

          if (therapistId == null || childId == null) {
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text('Missing therapistId or childId for sharing settings')),
              ),
            );
          }
          return MaterialPageRoute(
            builder: (context) => TherapistSharingSettings(therapistId: therapistId, childId: childId),
          );
        }
        if (settings.name?.startsWith('/messages/chat/') ?? false) {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => MessageScreen(
              conversationId: args?['conversationId'] ?? '',
              otherUserId: args?['otherUserId'] ?? '',
            ),
          );
        }
        return null;
      },
      
      home: Consumer<AuthService>(
        builder: (context, authService, _) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: authService.currentUser == null
                ? const LoginScreen()
                : authService.currentUser!.additionalInfo?['onboardingCompleted'] == true
                    ? (authService.currentUser!.role == UserRole.parent
                        ? const ParentDashboard()
                        : const RedesignedTherapistDashboard())
                    : OnboardingScreen(user: authService.currentUser!),
          );
        },
      ),
    );
  }
}