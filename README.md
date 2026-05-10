# DevMob Support Client

Application mobile de gestion de tickets de support, developpee avec Flutter et Firebase.

## Technologies
- **Flutter** - Framework mobile cross-platform
- **Firebase Auth** - Authentification securisee
- **Cloud Firestore** - Base de donnees temps reel
- **Firebase Storage** - Stockage des pieces jointes

## Fonctionnalites
- Connexion / Inscription avec roles (client / admin)
- Creation et suivi de tickets
- Fil de discussion en temps reel
- Upload de pieces jointes
- Tableau de bord admin avec statistiques

## Architecture
```
lib/
  models/    - Modeles de donnees
  services/  - Services Firebase
  screens/   - Ecrans de l'application
  widgets/   - Composants reutilisables
  providers/ - Gestion d etat
```

## Installation
1. `flutter pub get`
2. Configurer Firebase
3. `flutter run`
