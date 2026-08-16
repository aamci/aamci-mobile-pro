import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _sections = [
    _Section(
      title: '1. Présentation du service',
      content:
          'Ibogha Pro est la plateforme professionnelle d\'Ibogha Health permettant aux professionnels de santé de gérer leur agenda, leurs rendez-vous, leur dossier patient, leurs consultations vidéo, leur portefeuille et leur correspondance médicale.',
    ),
    _Section(
      title: '2. Accès au service',
      content:
          'L\'accès à Ibogha Pro est réservé aux professionnels de santé dûment enregistrés. Vous êtes responsable de l\'exactitude des informations professionnelles fournies (RPPS, spécialité, établissements).\n\nVous êtes seul responsable de la confidentialité de vos identifiants de connexion.',
    ),
    _Section(
      title: '3. Obligations du professionnel',
      content:
          'En utilisant Ibogha Pro, vous vous engagez à :\n• Respecter le Code de déontologie médicale applicable\n• Fournir des informations professionnelles exactes et à jour\n• Assurer la confidentialité des données patients\n• Traiter les demandes de rendez-vous de façon diligente\n• Ne pas utiliser le service à des fins contraires à l\'éthique médicale',
    ),
    _Section(
      title: '4. Gestion des rendez-vous',
      content:
          'Les créneaux de disponibilité que vous définissez constituent une offre de consultation. La réservation par un patient forme un engagement bilatéral.\n\nEn cas d\'empêchement, vous devez annuler le rendez-vous et en informer le patient dans les meilleurs délais.',
    ),
    _Section(
      title: '5. Téléconsultation',
      content:
          'La téléconsultation vidéo est soumise aux mêmes obligations déontologiques qu\'une consultation présentielle. Vous devez vous assurer de disposer d\'un environnement garantissant la confidentialité et la qualité de la prise en charge.\n\n⚠️ La téléconsultation ne remplace pas une consultation physique pour les situations d\'urgence.',
    ),
    _Section(
      title: '6. Données patients (données sensibles)',
      content:
          'En tant que professionnel de santé, vous êtes responsable conjoint du traitement des données de santé de vos patients. Ces données sont chiffrées (AES-256-GCM) et leur accès est journalisé. Vous vous engagez à ne les consulter qu\'à des fins médicales légitimes.',
    ),
    _Section(
      title: '7. Paiements et portefeuille',
      content:
          'Les honoraires collectés via la plateforme sont crédités sur votre portefeuille Ibogha. Les virements sont effectués selon les modalités définies dans votre contrat de service.\n\nIbogha peut prélever une commission de service sur les transactions réalisées via la plateforme.',
    ),
    _Section(
      title: '8. Propriété intellectuelle',
      content:
          'L\'ensemble du contenu d\'Ibogha Pro (interface, algorithmes, composants) est protégé par le droit de la propriété intellectuelle. Toute reproduction ou adaptation sans autorisation écrite est interdite.',
    ),
    _Section(
      title: '9. Limitation de responsabilité',
      content:
          'Ibogha agit en tant qu\'intermédiaire technique et ne peut être tenu responsable :\n• Des actes médicaux réalisés via la plateforme\n• Des interruptions liées à des maintenances techniques\n• Des dommages indirects résultant de l\'utilisation du service',
    ),
    _Section(
      title: '10. Données personnelles',
      content:
          'Le traitement de vos données professionnelles est régi par notre Politique de confidentialité, accessible depuis ce menu. Les données médicales des patients sont conservées 10 ans conformément aux obligations légales.\n\nContact données : privacy@ibogha241.ga',
    ),
    _Section(
      title: '11. Résiliation',
      content:
          'Vous pouvez résilier votre compte à tout moment depuis les paramètres. Ibogha se réserve le droit de suspendre ou résilier un compte professionnel en cas de violation des présentes CGU ou du Code de déontologie.',
    ),
    _Section(
      title: '12. Modifications et contact',
      content:
          'Ibogha peut modifier ces conditions et vous informera 30 jours avant toute modification substantielle.\n\nSupport : support@ibogha241.ga\nDonnées : privacy@ibogha241.ga',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conditions générales d\'utilisation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Acceptation des conditions', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                const SizedBox(height: 4),
                const Text(
                  'En utilisant Ibogha Pro, vous acceptez les présentes conditions générales dans leur intégralité.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version 1.1 — août 2026',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._sections.map((s) => _SectionCard(section: s)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Section {
  final String title;
  final String content;
  const _Section({required this.title, required this.content});
}

class _SectionCard extends StatelessWidget {
  final _Section section;
  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Text(section.content, style: const TextStyle(fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
