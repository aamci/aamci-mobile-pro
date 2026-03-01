class ApiEndpoints {
  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Dashboard / Stats
  static const String doctorOverview = '/stats/doctor/overview';
  static const String nextAppointments = '/stats/next-appointments';
  static const String revenueTimeline = '/stats/revenue-timeline';

  // Availability Rules
  static const String availabilityRules = '/availability-rules';
  static const String myAvailabilityRules = '/availability-rules/mine';
  static String availabilityRuleById(String id) => '/availability-rules/$id';

  // Doctor Absences
  static const String doctorAbsences = '/doctor-absences';
  static String doctorAbsenceById(String id) => '/doctor-absences/$id';

  // Slots
  static String availableSlots(String doctorId) => '/slots/available/$doctorId';

  // Appointment Kinds
  static const String appointmentKinds = '/appointment-kinds';
  static String appointmentKindsByDoctor(String doctorId) => '/appointment-kinds/doctor/$doctorId';
  static String appointmentKindById(String id) => '/appointment-kinds/$id';

  // Appointments
  static const String appointments = '/appointments';
  static String appointmentById(String id) => '/appointments/$id';
  static String appointmentStatus(String id) => '/appointments/$id/status';

  // Patients
  static const String patients = '/patients';
  static const String createPatient = '/users/create-patient';
  static String patientRecord(String id) => '/patient-record/$id';

  // Consultations
  static const String consultations = '/consultations';
  static String consultationById(String id) => '/consultations/$id';

  // Medical Notes
  static const String medicalNotes = '/medical-notes';
  static String medicalNoteById(String id) => '/medical-notes/$id';

  // Prescriptions
  static const String prescriptions = '/prescriptions';
  static String prescriptionById(String id) => '/prescriptions/$id';
  static const String prescriptionTemplates = '/prescription-templates';

  // Wallet
  static const String wallet = '/wallet/me';
  static const String walletMovements = '/wallet/movements';

  // Invoices
  static const String invoices = '/invoices';
  static String invoiceById(String id) => '/invoices/$id';

  // Notifications
  static const String notifications = '/notifications';
  static const String unreadCount = '/notifications/unread-count';
  static String markRead(String id) => '/notifications/$id/read';
  static const String markAllRead = '/notifications/mark-all-read';

  // Messages
  static const String conversations = '/messages/conversations';
  static String conversationMessages(String id) => '/messages/conversations/$id';
  static String markConversationRead(String id) => '/messages/conversations/$id/read';
  static const String sendMessage = '/messages/send';
  static const String unreadMessageCount = '/messages/unread-count';

  // User profile
  static const String profile = '/me';
  static const String changePassword = '/me/password';

  // Doctor Profile
  static const String doctorProfile = '/doctor-profiles/me';

  // Team
  static const String team = '/team';
  static const String teamStats = '/team/stats';
  static const String teamInvite = '/team/invite';
  static String teamMemberById(String id) => '/team/$id';
  static String teamDeactivate(String id) => '/team/$id/deactivate';
  static String teamReactivate(String id) => '/team/$id/reactivate';

  // Analytics
  static const String analytics = '/analytics';
  static const String analyticsDashboard = '/analytics/dashboard';
  static const String analyticsTrends = '/analytics/trends';
  static const String analyticsTopServices = '/analytics/top-services';
  static const String analyticsPerformanceByDay = '/analytics/performance-by-day';

  // Availability Preferences
  static const String availabilityPreferences = '/availability-preferences';
}
