import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/patients_provider.dart';

// ─── Utility helpers ─────────────────────────────────────────────────────────

String _fmt(dynamic dateStr) {
  if (dateStr == null) return '';
  try {
    return DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr.toString()));
  } catch (_) {
    return dateStr.toString();
  }
}

int _age(dynamic birthdate) {
  if (birthdate == null) return 0;
  try {
    final d = DateTime.parse(birthdate.toString());
    final now = DateTime.now();
    int a = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) a--;
    return a;
  } catch (_) {
    return 0;
  }
}

// ─── Root screen ─────────────────────────────────────────────────────────────

class PatientRecordScreen extends ConsumerWidget {
  final String patientId;
  final Map<String, dynamic>? patientData;

  const PatientRecordScreen({
    super.key,
    required this.patientId,
    this.patientData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(patientRecordProvider(patientId));
    final patientName = patientData?['fullName'] as String? ?? 'Patient';

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(patientName),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Infos'),
              Tab(text: 'Médical'),
              Tab(text: 'Traitements'),
              Tab(text: 'Constantes'),
              Tab(text: 'Vaccins'),
              Tab(text: 'Historique'),
            ],
          ),
        ),
        body: recordAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Erreur de chargement', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.invalidate(patientRecordProvider(patientId)),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
          data: (record) {
            final patient = (record['patient'] as Map<String, dynamic>?) ?? patientData ?? {};
            final profile = (record['profile'] as Map<String, dynamic>?) ?? {};
            final medicalHistory =
                (record['medicalHistory'] as List? ?? []).cast<Map<String, dynamic>>();
            final treatments =
                (record['treatments'] as List? ?? []).cast<Map<String, dynamic>>();
            final biometrics =
                (record['biometrics'] as List? ?? []).cast<Map<String, dynamic>>();
            final labResults =
                (record['labResults'] as List? ?? []).cast<Map<String, dynamic>>();
            final vaccinations =
                (record['vaccinations'] as List? ?? []).cast<Map<String, dynamic>>();
            final observations =
                (record['observations'] as List? ?? []).cast<Map<String, dynamic>>();
            final appointments =
                (record['appointments'] as List? ?? []).cast<Map<String, dynamic>>();
            final emergencyContacts =
                (record['emergencyContacts'] as List? ?? []).cast<Map<String, dynamic>>();

            return Column(
              children: [
                _PatientHeader(patient: patient, profile: profile),
                Expanded(
                  child: TabBarView(
                    children: [
                      _InfosTab(
                          patient: patient,
                          profile: profile,
                          emergencyContacts: emergencyContacts),
                      _MedicalTab(medicalHistory: medicalHistory),
                      _TraitementsTab(treatments: treatments),
                      _ConstantesTab(biometrics: biometrics, labResults: labResults),
                      _VaccinsTab(vaccinations: vaccinations),
                      _HistoriqueTab(
                          appointments: appointments, observations: observations),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Patient header card ──────────────────────────────────────────────────────

class _PatientHeader extends StatelessWidget {
  final Map<String, dynamic> patient;
  final Map<String, dynamic> profile;

  const _PatientHeader({required this.patient, required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = patient['fullName'] as String? ?? 'Patient';
    final birthdate = patient['birthdate'] ?? profile['birthDate'];
    final age = birthdate != null ? _age(birthdate) : null;
    final sex = patient['sex'] as String?;
    final bloodGroup = profile['bloodGroup'] as String?;
    final heightCm = profile['heightCm'];
    final weightKg = profile['weightKg'];
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      color: primary.withValues(alpha: 0.06),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: primary.withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'P',
              style:
                  TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (age != null) _chip('$age ans'),
                    if (sex != null)
                      _chip(sex == 'MALE'
                          ? 'Homme'
                          : sex == 'FEMALE'
                              ? 'Femme'
                              : sex),
                    if (bloodGroup != null)
                      _chip('Gr. $bloodGroup', color: Colors.red[300]),
                    if (heightCm != null) _chip('${heightCm}cm'),
                    if (weightKg != null) _chip('${weightKg}kg'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey[400])!.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color ?? Colors.grey[700],
              fontWeight: FontWeight.w500)),
    );
  }
}

// ─── Infos tab ────────────────────────────────────────────────────────────────

class _InfosTab extends StatelessWidget {
  final Map<String, dynamic> patient;
  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> emergencyContacts;

  const _InfosTab(
      {required this.patient,
      required this.profile,
      required this.emergencyContacts});

  @override
  Widget build(BuildContext context) {
    final birthdate = patient['birthdate'] ?? profile['birthDate'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Section(
          title: 'Informations personnelles',
          icon: Icons.person,
          children: [
            _InfoRow('Civilité', _civility(profile['civility'] as String?)),
            _InfoRow('Nom de naissance', profile['birthLastName'] as String?),
            _InfoRow('Prénom usuel', profile['usualFirstName'] as String?),
            _InfoRow('Date de naissance', _fmt(birthdate)),
            _InfoRow('Lieu de naissance', profile['birthPlace'] as String?),
            _InfoRow('Pays de naissance', profile['birthCountry'] as String?),
            _InfoRow('Sexe', _sexLabel(patient['sex'] as String?)),
            _InfoRow('Ville', patient['city'] as String?),
            _InfoRow('Code patient', profile['patientCode'] as String?),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Coordonnées',
          icon: Icons.contact_phone,
          children: [
            _InfoRow('Email', patient['email'] as String?),
            _InfoRow(
                'Téléphone',
                profile['phonePrimary'] as String? ??
                    patient['phone'] as String?),
            _InfoRow('Téléphone 2', profile['phoneSecondary'] as String?),
            _InfoRow('Adresse', profile['addressLine1'] as String?),
            _InfoRow('Code postal', profile['postalCode'] as String?),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Couverture sociale',
          icon: Icons.health_and_safety,
          children: [
            _InfoRow('N° séc. sociale',
                _maskSsn(profile['socialSecurityNumber'] as String?)),
            _InfoRow('Mutuelle', profile['mutualInsurance'] as String?),
            _InfoRow('Assurance', profile['insuranceProvider'] as String?),
            _InfoRow(
                'Médecin traitant', profile['primaryDoctorName'] as String?),
          ],
        ),
        if (emergencyContacts.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Section(
            title: 'Contacts d\'urgence',
            icon: Icons.emergency,
            children: emergencyContacts.map((c) {
              final isPrimary = c['isPrimary'] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.person_pin,
                        size: 16,
                        color:
                            isPrimary ? Colors.red[400] : Colors.grey[400]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(c['fullName'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              if (isPrimary) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('Principal',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.red[600])),
                                ),
                              ],
                            ],
                          ),
                          Text(
                              '${c['relationship'] ?? ''} • ${c['phone'] ?? ''}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  String? _civility(String? c) {
    switch (c) {
      case 'MR':
        return 'M.';
      case 'MME':
        return 'Mme';
      case 'MLLE':
        return 'Mlle';
      default:
        return c;
    }
  }

  String? _sexLabel(String? s) {
    switch (s) {
      case 'MALE':
        return 'Masculin';
      case 'FEMALE':
        return 'Féminin';
      default:
        return s;
    }
  }

  String? _maskSsn(String? ssn) {
    if (ssn == null || ssn.length < 4) return ssn;
    return '${ssn.substring(0, 4)} *** ${ssn.substring(ssn.length - 2)}';
  }
}

// ─── Medical history tab ──────────────────────────────────────────────────────

class _MedicalTab extends StatelessWidget {
  final List<Map<String, dynamic>> medicalHistory;

  const _MedicalTab({required this.medicalHistory});

  static const _categories = <String, (String, IconData, Color)>{
    'ALLERGY': ('Allergies', Icons.warning_amber, Colors.red),
    'MEDICAL': ('Antécédents médicaux', Icons.medical_information, Colors.blue),
    'CARDIOVASCULAR': (
      'Cardiovasculaire',
      Icons.favorite,
      Colors.pink
    ),
    'SURGICAL': ('Chirurgicaux', Icons.cut, Colors.orange),
    'FAMILY': ('Familiaux', Icons.family_restroom, Colors.purple),
    'LIFESTYLE': ('Mode de vie', Icons.directions_run, Colors.green),
  };

  @override
  Widget build(BuildContext context) {
    if (medicalHistory.isEmpty) {
      return _EmptyState(
          icon: Icons.medical_information,
          message: 'Aucun antécédent enregistré');
    }

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in medicalHistory) {
      final cat = item['category'] as String? ?? 'MEDICAL';
      grouped.putIfAbsent(cat, () => []).add(item);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _categories.entries
          .where((e) => grouped.containsKey(e.key))
          .map((e) {
        final (label, icon, color) = e.value;
        final items = grouped[e.key]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _Section(
            title: '$label (${items.length})',
            icon: icon,
            iconColor: color,
            children: items.map((item) {
              final isActive = item['isActive'] == true;
              final severity = item['severity'] as String?;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item['title'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                        if (severity != null) _SeverityChip(severity),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green[50]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isActive ? 'Actif' : 'Résolu',
                            style: TextStyle(
                                fontSize: 10,
                                color: isActive
                                    ? Colors.green[700]
                                    : Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                    if (item['description'] != null) ...[
                      const SizedBox(height: 2),
                      Text(item['description'],
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                    ],
                    if (item['diagnosedAt'] != null)
                      Text(
                          'Diagnostiqué le ${_fmt(item['diagnosedAt'])}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Treatments tab ───────────────────────────────────────────────────────────

class _TraitementsTab extends StatelessWidget {
  final List<Map<String, dynamic>> treatments;

  const _TraitementsTab({required this.treatments});

  @override
  Widget build(BuildContext context) {
    if (treatments.isEmpty) {
      return _EmptyState(
          icon: Icons.medication, message: 'Aucun traitement enregistré');
    }

    final active =
        treatments.where((t) => t['status'] == 'ACTIVE').toList();
    final paused =
        treatments.where((t) => t['status'] == 'PAUSED').toList();
    final stopped = treatments
        .where((t) =>
            t['status'] == 'STOPPED' || t['status'] == 'COMPLETED')
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (active.isNotEmpty)
          _Section(
            title: 'En cours (${active.length})',
            icon: Icons.medication,
            iconColor: Colors.green,
            children: active.map((t) => _TreatmentTile(t)).toList(),
          ),
        if (paused.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Section(
            title: 'En pause (${paused.length})',
            icon: Icons.pause_circle,
            iconColor: Colors.orange,
            children: paused.map((t) => _TreatmentTile(t)).toList(),
          ),
        ],
        if (stopped.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Section(
            title: 'Terminés / Arrêtés (${stopped.length})',
            icon: Icons.check_circle,
            iconColor: Colors.grey,
            children: stopped.map((t) => _TreatmentTile(t)).toList(),
          ),
        ],
      ],
    );
  }
}

class _TreatmentTile extends StatelessWidget {
  final Map<String, dynamic> t;
  const _TreatmentTile(this.t);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${t['medicationName'] ?? ''}${t['genericName'] != null ? ' (${t['genericName']})' : ''}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 2),
          if (t['dosage'] != null || t['frequency'] != null)
            Text(
              [t['dosage'], t['frequency']]
                  .where((v) => v != null)
                  .join(' — '),
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          if (t['indication'] != null)
            Text('Indication : ${t['indication']}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text(
            [
              if (t['startDate'] != null)
                'Depuis le ${_fmt(t['startDate'])}',
              if (t['endDate'] != null)
                'jusqu\'au ${_fmt(t['endDate'])}',
            ].join(' '),
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// ─── Constantes tab ───────────────────────────────────────────────────────────

class _ConstantesTab extends StatelessWidget {
  final List<Map<String, dynamic>> biometrics;
  final List<Map<String, dynamic>> labResults;

  const _ConstantesTab(
      {required this.biometrics, required this.labResults});

  static const _biometricMeta =
      <String, (String, String, IconData)>{
    'WEIGHT': ('Poids', 'kg', Icons.monitor_weight),
    'HEIGHT': ('Taille', 'cm', Icons.height),
    'BLOOD_PRESSURE': ('Tension', 'mmHg', Icons.favorite),
    'HEART_RATE': ('Fréquence cardiaque', 'bpm', Icons.monitor_heart),
    'TEMPERATURE': ('Température', '°C', Icons.thermostat),
    'OXYGEN_SATURATION': ('Saturation O₂', '%', Icons.air),
    'BLOOD_GLUCOSE': ('Glycémie', 'mg/dL', Icons.water_drop),
    'BMI': ('IMC', '', Icons.scale),
    'WAIST_CIRCUMFERENCE': ('Tour de taille', 'cm', Icons.straighten),
  };

  @override
  Widget build(BuildContext context) {
    // Most recent per type (API returns ordered by measuredAt desc)
    final latest = <String, Map<String, dynamic>>{};
    for (final b in biometrics) {
      final type = b['type'] as String? ?? '';
      latest.putIfAbsent(type, () => b);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (latest.isNotEmpty) ...[
          _SectionHeader(
              title: 'Dernières mesures', icon: Icons.monitor_heart),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: latest.length,
            itemBuilder: (context, index) {
              final entry = latest.entries.elementAt(index);
              final meta = _biometricMeta[entry.key];
              final b = entry.value;
              final value = b['value'];
              final value2 = b['valueSecondary'];
              final unit = b['unit'] ?? meta?.$2 ?? '';
              final label = meta?.$1 ?? entry.key;
              final icon = meta?.$3 ?? Icons.monitor_heart;
              final isAbnormal = b['isAbnormal'] == true;

              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isAbnormal ? Colors.red[50] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isAbnormal
                          ? Colors.red[200]!
                          : Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(icon,
                        size: 18,
                        color: isAbnormal
                            ? Colors.red[400]
                            : Colors.blue[300]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(label,
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[600])),
                          Text(
                            value2 != null
                                ? '$value/$value2 $unit'
                                : '$value $unit',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color:
                                  isAbnormal ? Colors.red[700] : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        if (labResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionHeader(
              title: 'Résultats de laboratoire (${labResults.length})',
              icon: Icons.biotech),
          const SizedBox(height: 8),
          ...labResults.map((lab) {
            final isAbnormal = lab['isAbnormal'] == true;
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              color: isAbnormal ? Colors.red[50] : null,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(lab['testName'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            '${lab['value'] ?? ''} ${lab['unit'] ?? ''}'.trim(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isAbnormal ? Colors.red[700] : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAbnormal) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.warning_amber,
                              size: 14, color: Colors.red[400]),
                        ],
                      ],
                    ),
                    if (lab['interpretation'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(lab['interpretation'],
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2),
                      ),
                    Wrap(
                      spacing: 8,
                      children: [
                        Text(
                            _fmt(lab['resultDate'] ?? lab['sampleDate']),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
                        if (lab['normalRange'] != null)
                          Text('Norme: ${lab['normalRange']}',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
        if (latest.isEmpty && labResults.isEmpty)
          _EmptyState(
              icon: Icons.monitor_heart,
              message: 'Aucune mesure enregistrée'),
      ],
    );
  }
}

// ─── Vaccinations tab ─────────────────────────────────────────────────────────

class _VaccinsTab extends StatelessWidget {
  final List<Map<String, dynamic>> vaccinations;

  const _VaccinsTab({required this.vaccinations});

  @override
  Widget build(BuildContext context) {
    if (vaccinations.isEmpty) {
      return _EmptyState(
          icon: Icons.vaccines, message: 'Aucun vaccin enregistré');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vaccinations.length,
      itemBuilder: (context, index) {
        final v = vaccinations[index];
        final nextDose = v['nextDoseAt'];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.vaccines,
                      size: 18, color: Colors.green[600]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v['vaccineName'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      if (v['vaccineType'] != null)
                        Text(v['vaccineType'],
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(
                          'Administré le ${_fmt(v['administeredAt'])}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                      if (v['doseNumber'] != null)
                        Text('Dose n°${v['doseNumber']}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      if (v['administeredBy'] != null)
                        Text('Par : ${v['administeredBy']}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
                if (nextDose != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Rappel',
                          style: TextStyle(
                              fontSize: 10, color: Colors.orange[700])),
                      Text(_fmt(nextDose),
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── History tab ──────────────────────────────────────────────────────────────

class _HistoriqueTab extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> observations;

  const _HistoriqueTab(
      {required this.appointments, required this.observations});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (appointments.isNotEmpty) ...[
          _SectionHeader(
              title: 'Rendez-vous (${appointments.length})',
              icon: Icons.event),
          const SizedBox(height: 8),
          ...appointments.map((apt) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  leading:
                      Icon(Icons.event, color: Colors.blue[400], size: 20),
                  title: Text(
                      apt['appointmentKind']?['name'] ?? 'Consultation',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  subtitle:
                      Text(_fmt(apt['slotStart'] ?? apt['date'])),
                  trailing: _StatusChip(apt['status'] as String?),
                ),
              )),
        ],
        if (observations.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionHeader(
              title:
                  'Observations cliniques (${observations.length})',
              icon: Icons.note_alt),
          const SizedBox(height: 8),
          ...observations.map((obs) {
            final isUrgent = obs['isUrgent'] == true;
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              color: isUrgent ? Colors.red[50] : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isUrgent)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(Icons.warning_amber,
                                size: 14, color: Colors.red[400]),
                          ),
                        Expanded(
                          child: Text(obs['title'] ?? 'Observation',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                        Text(
                            _fmt(obs['observedAt'] ??
                                obs['createdAt']),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                    if (obs['content'] != null) ...[
                      const SizedBox(height: 4),
                      Text(obs['content'],
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[700]),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
        if (appointments.isEmpty && observations.isEmpty)
          _EmptyState(
              icon: Icons.history,
              message: 'Aucun historique disponible'),
      ],
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final List<Widget> children;

  const _Section(
      {required this.title,
      required this.icon,
      required this.children,
      this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Icon(icon,
                    size: 16,
                    color: iconColor ??
                        Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style:
                    TextStyle(fontSize: 12, color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value!,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String? status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'CONFIRMED' => ('Confirmé', Colors.green),
      'PENDING' => ('En attente', Colors.orange),
      'CANCELLED' => ('Annulé', Colors.red),
      'COMPLETED' => ('Terminé', Colors.blue),
      _ => (status ?? '', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500)),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final String severity;
  const _SeverityChip(this.severity);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (severity) {
      'MILD' => ('Léger', Colors.green),
      'MODERATE' => ('Modéré', Colors.orange),
      'SEVERE' => ('Sévère', Colors.deepOrange),
      'CRITICAL' => ('Critique', Colors.red),
      _ => (severity, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(icon, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
