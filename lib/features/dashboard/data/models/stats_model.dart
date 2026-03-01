class DoctorStats {
  final int totalAppointments;
  final int upcomingAppointments;
  final int confirmedThisMonth;
  final double revenueThisMonth;
  final double noShowRate;
  final List<DailyCount> last30Days;

  DoctorStats({
    required this.totalAppointments,
    required this.upcomingAppointments,
    required this.confirmedThisMonth,
    required this.revenueThisMonth,
    required this.noShowRate,
    required this.last30Days,
  });

  factory DoctorStats.fromJson(Map<String, dynamic> json) {
    return DoctorStats(
      totalAppointments: json['totalAppointments'] as int? ?? 0,
      upcomingAppointments: json['upcomingAppointments'] as int? ?? 0,
      confirmedThisMonth: json['confirmedThisMonth'] as int? ?? 0,
      revenueThisMonth: (json['revenueThisMonth'] as num?)?.toDouble() ?? 0,
      noShowRate: (json['noShowRate'] as num?)?.toDouble() ?? 0,
      last30Days: (json['last30Days'] as List?)
              ?.map((e) => DailyCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DailyCount {
  final String date;
  final int count;

  DailyCount({required this.date, required this.count});

  factory DailyCount.fromJson(Map<String, dynamic> json) {
    return DailyCount(
      date: json['date']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class NextAppointment {
  final String id;
  final String status;
  final DateTime? slotStart;
  final DateTime? slotEnd;
  final String? patientName;
  final String? patientEmail;
  final String? kindName;

  NextAppointment({
    required this.id,
    required this.status,
    this.slotStart,
    this.slotEnd,
    this.patientName,
    this.patientEmail,
    this.kindName,
  });

  factory NextAppointment.fromJson(Map<String, dynamic> json) {
    final slot = json['slot'] as Map<String, dynamic>?;
    final patient = json['patient'] as Map<String, dynamic>?;
    final kind = json['kind'] as Map<String, dynamic>?;

    return NextAppointment(
      id: json['id'] as String,
      status: json['status'] as String,
      slotStart: slot != null ? DateTime.parse(slot['start'] as String) : null,
      slotEnd: slot != null ? DateTime.parse(slot['end'] as String) : null,
      patientName: patient?['fullName'] as String?,
      patientEmail: patient?['email'] as String?,
      kindName: kind?['name'] as String?,
    );
  }
}
