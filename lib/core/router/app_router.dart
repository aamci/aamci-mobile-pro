import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/planning/presentation/screens/planning_screen.dart';
import '../../features/appointments/presentation/screens/appointments_screen.dart';
import '../../features/patients/presentation/screens/patients_screen.dart';
import '../../features/patients/presentation/screens/patient_record_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/availability_rules/presentation/screens/availability_rules_screen.dart';
import '../../features/absences/presentation/screens/absences_screen.dart';
import '../../features/messages/presentation/screens/conversations_screen.dart';
import '../../features/messages/presentation/screens/conversation_detail_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/consultations/presentation/screens/consultations_screen.dart';
import '../../features/consultations/presentation/screens/consultation_detail_screen.dart';
import '../../features/medical_notes/presentation/screens/medical_notes_screen.dart';
import '../../features/prescriptions/presentation/screens/prescriptions_screen.dart';
import '../../features/prescriptions/presentation/screens/prescription_detail_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../../features/invoices/presentation/screens/invoices_screen.dart';
import '../../features/appointment_kinds/presentation/screens/appointment_kinds_screen.dart';
import '../../features/team/presentation/screens/team_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import 'shell_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isOnSplash = state.matchedLocation == '/splash';
      final isLoggingIn = state.matchedLocation == '/login';

      if (authState.status == AuthStatus.initial || authState.status == AuthStatus.loading) {
        return isOnSplash ? null : '/splash';
      }

      final isRegistering = state.matchedLocation == '/register';
      if (!isAuthenticated && !isLoggingIn && !isRegistering) return '/login';
      if (isAuthenticated && (isLoggingIn || isOnSplash || isRegistering)) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/patient/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final patient = state.extra as Map<String, dynamic>?;
          return PatientRecordScreen(patientId: id, patientData: patient);
        },
      ),
      GoRoute(
        path: '/availability-rules',
        builder: (context, state) => const AvailabilityRulesScreen(),
      ),
      GoRoute(
        path: '/absences',
        builder: (context, state) => const AbsencesScreen(),
      ),
      GoRoute(
        path: '/messages',
        builder: (context, state) => const ConversationsScreen(),
      ),
      GoRoute(
        path: '/conversation/:id',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ConversationDetailScreen(
            conversationId: state.pathParameters['id']!,
            participantName: extra['name'] as String? ?? 'Conversation',
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/consultations',
        builder: (context, state) => const ConsultationsScreen(),
      ),
      GoRoute(
        path: '/consultation/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ConsultationDetailScreen(consultationId: id);
        },
      ),
      GoRoute(
        path: '/medical-notes',
        builder: (context, state) => const MedicalNotesScreen(),
      ),
      GoRoute(
        path: '/prescriptions',
        builder: (context, state) => const PrescriptionsScreen(),
      ),
      GoRoute(
        path: '/prescription/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PrescriptionDetailScreen(prescriptionId: id);
        },
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/invoices',
        builder: (context, state) => const InvoicesScreen(),
      ),
      GoRoute(
        path: '/appointment-kinds',
        builder: (context, state) => const AppointmentKindsScreen(),
      ),
      GoRoute(
        path: '/team',
        builder: (context, state) => const TeamScreen(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/planning',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlanningScreen(),
            ),
          ),
          GoRoute(
            path: '/appointments',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AppointmentsScreen(),
            ),
          ),
          GoRoute(
            path: '/patients',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PatientsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
