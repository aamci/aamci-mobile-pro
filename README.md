# @health/mobile-pro — Application Mobile Professionnel de Santé

Application mobile Flutter pour les professionnels de santé (médecins, pharmaciens, hôpitaux). Gestion des disponibilités, des rendez-vous, des consultations, des prescriptions, des patients et du portefeuille.

## Description

Application Flutter (Dart) ciblant Android et iOS. Authentification JWT avec support 2FA TOTP. La navigation est déclarative via `go_router`. Les appels API passent par `dio` avec intercepteur d'authentification automatique. Les tokens sont stockés de façon sécurisée (Keychain iOS / Keystore Android) via `flutter_secure_storage`. Architecture feature-based avec Riverpod pour la gestion d'état. Inclut des graphiques analytiques via `fl_chart`.

**SDK Flutter :** `^3.10.0`
**API :** `http://10.0.2.2:3002` (dev Android) / `http://localhost:3002` (dev iOS) / `https://api-ieis.onrender.com` (production)

---

## Stack technique

<!-- STACK:START -->
| Module | Version | Type | Description |
|--------|---------|------|-------------|
| flutter_riverpod | 2.6.x | State | Gestion d'état — Provider, Notifier, AsyncNotifier |
| go_router | 14.8.x | Navigation | Routing déclaratif avec guards d'authentification |
| dio | 5.7.x | HTTP | Client HTTP avec intercepteurs (auth, erreurs) |
| flutter_secure_storage | 9.2.x | Stockage | Stockage sécurisé des tokens (Keychain iOS / Keystore Android) |
| cached_network_image | 3.4.x | UI | Chargement et mise en cache des images réseau |
| shimmer | 3.0.x | UI | Effet squelette de chargement (shimmer) |
| intl | 0.19.x | Utilitaire | Internationalisation et formatage des dates |
| table_calendar | 3.1.x | UI | Widget calendrier pour le planning des disponibilités |
| jwt_decoder | 2.0.x | Auth | Décodage des JWT côté client (sans vérification de signature) |
| json_annotation | 4.9.x | Sérialisation | Annotations pour la génération de code JSON |
| url_launcher | 6.3.x | Utilitaire | Ouverture d'URLs et deep links |
| cupertino_icons | 1.0.x | UI | Pack d'icônes style iOS (Cupertino) |
| fl_chart | 0.69.x | UI | Graphiques et charts (barres, lignes, camembert) pour l'analytique |
| flutter_lints | 5.0.x | Dev | Règles de lint officielles Flutter |
| build_runner | 2.4.x | Dev | Runner de génération de code (json_serializable) |
| json_serializable | 6.9.x | Dev | Génération automatique des méthodes `toJson`/`fromJson` |
<!-- STACK:END -->

---

## Variables d'environnement / Configuration

L'URL de l'API est configurée directement dans `lib/core/config/api_config.dart` :

| Mode | URL |
|------|-----|
| Debug Android (émulateur) | `http://10.0.2.2:3002` |
| Debug iOS (simulateur) | `http://localhost:3002` |
| Release (production) | `https://api-ieis.onrender.com` |

Pour surcharger l'URL à la compilation :

```bash
flutter run --dart-define=API_BASE_URL=https://mon-api.example.com
```

---

## Lancement en local

### Prérequis

- Flutter SDK ≥ 3.10.0
- Dart SDK ≥ 3.0.0
- Android Studio / Xcode (selon la cible)
- L'API (`@health/api`) démarrée sur le port `3002`

### Démarrage

```bash
# 1. Récupérer les dépendances
flutter pub get

# 2. Générer le code (modèles JSON)
dart run build_runner build --delete-conflicting-outputs

# 3. Démarrer sur un émulateur/device connecté
flutter run
```

### Commandes utiles

```bash
flutter pub get                             # Installer les dépendances
dart run build_runner build                # Générer les modèles JSON
flutter run                                # Lancer en mode debug
flutter run --release                      # Lancer en mode release
flutter test                               # Tests unitaires
flutter test --coverage                    # Tests avec couverture
flutter analyze                            # Analyse statique du code
flutter build apk                          # Build APK Android
flutter build ipa                          # Build IPA iOS (macOS requis)
node scripts/validate-readme.js            # Vérifier la cohérence README ↔ pubspec.yaml
```

### Structure des fonctionnalités

```
lib/
├── core/
│   ├── config/          # ApiConfig (URLs)
│   ├── network/         # DioClient + AuthInterceptor
│   ├── router/          # AppRouter (go_router)
│   ├── storage/         # SecureStorage (tokens)
│   ├── theme/           # AppTheme
│   └── widgets/         # Widgets partagés
└── features/
    ├── auth/            # Connexion, inscription, 2FA
    ├── dashboard/       # Vue d'ensemble du professionnel
    ├── appointments/    # Gestion des rendez-vous
    ├── availability_rules/ # Règles de disponibilité
    ├── planning/        # Calendrier et créneaux
    ├── patients/        # Dossiers patients
    ├── consultations/   # Comptes-rendus de consultation
    ├── prescriptions/   # Ordonnances
    ├── medical_notes/   # Notes médicales
    ├── messages/        # Messagerie avec les patients
    ├── notifications/   # Notifications push
    ├── profile/         # Profil et paramètres
    ├── wallet/          # Portefeuille et paiements
    ├── invoices/        # Factures
    ├── analytics/       # Statistiques et graphiques
    ├── appointment_kinds/ # Types de rendez-vous personnalisés
    ├── absences/        # Gestion des absences
    └── team/            # Gestion de l'équipe (clinique/hôpital)
```

### Déploiement CI (Fastlane)

La CI utilise Fastlane pour les builds :

```bash
bundle exec fastlane android beta     # Build + Firebase App Distribution
bundle exec fastlane android release  # Build + Google Play
bundle exec fastlane ios beta         # Build + TestFlight
bundle exec fastlane ios release      # Build + App Store
```
