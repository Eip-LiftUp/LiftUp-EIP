# Guide de lancement de l'application Android

Ce guide explique comment lancer l'application Flutter LiftUp sur un telephone Android,
avec une connexion USB ou en Wi-Fi.

## 1. Pre-requis

Installer et verifier :

- Flutter et Dart
- Android SDK et Android Platform-Tools
- Docker et Docker Compose
- Un telephone Android, un emulateur ou le navigateur Chrome

Depuis la racine du projet, verifier Flutter :

```bash
cd client/app
flutter doctor
flutter devices
```

## 2. Demarrer le backend

Le telephone a besoin de l'API. Depuis la racine du projet :

```bash
docker compose up --build
```

Le backend est expose sur le port `8080`. Verifier son etat :

```bash
curl http://localhost:8080/health
```

Laisser Docker fonctionner dans un terminal ouvert.

## 3. Preparer l'application Flutter

Dans un second terminal :

```bash
cd client/app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter devices
```

## 4. Methode USB

### Sur le telephone

1. Ouvrir les reglages et activer les Options developpeur.
2. Activer le Debogage USB.
3. Brancher le telephone avec un cable USB-C ou USB-A qui gere les donnees.
4. Deverrouiller le telephone.
5. Accepter la fenetre `Autoriser le debogage USB`.
6. Choisir `Transfert de fichiers` dans la notification USB si elle apparait.

### Verifier ADB

Sous Windows PowerShell ou Linux :

```bash
adb kill-server
adb start-server
adb devices -l
```

Le resultat attendu contient une ligne avec l'etat `device` :

```text
XXXXXXXX    device
```

- `device` : le telephone est pret.
- `unauthorized` : accepter l'autorisation sur le telephone.
- Liste vide : verifier le cable, le port USB, les pilotes et le debogage USB.

### Lancer l'application

```bash
cd client/app
flutter devices
flutter run -d <device-id>
```

Le `device-id` est celui affiche par `flutter devices`.

### Cas WSL2

WSL2 ne voit pas toujours les appareils USB branches a Windows. Les solutions les
plus simples sont :

- lancer Flutter et ADB directement dans PowerShell Windows ;
- utiliser `usbipd-win` pour attacher le telephone a WSL2.

Pour `usbipd-win`, dans PowerShell administrateur :

```powershell
usbipd list
usbipd bind --busid <BUSID>
usbipd attach --wsl --busid <BUSID>
```

Puis dans WSL :

```bash
adb kill-server
adb start-server
adb devices -l
```

## 5. Methode sans cable, par Wi-Fi

Cette methode fonctionne nativement avec Android 11 et plus recent.
Le telephone et le PC doivent etre sur le meme reseau Wi-Fi.

### Associer le telephone

Sur le telephone :

1. Ouvrir les Options developpeur.
2. Activer `Debogage sans fil`.
3. Choisir `Associer l'appareil avec un code de jumelage`.
4. Noter l'adresse IP, le port de jumelage et le code.

Dans PowerShell Windows ou un terminal Linux :

```bash
adb pair <IP_DU_TELEPHONE>:<PORT_DE_JUMELAGE>
```

Entrer le code affiche sur le telephone.

### Connecter le telephone

Dans l'ecran `Debogage sans fil`, relever le port de connexion, puis executer :

```bash
adb connect <IP_DU_TELEPHONE>:<PORT_DE_CONNEXION>
adb devices -l
```

Le telephone doit apparaitre avec l'etat `device`. Ensuite :

```bash
cd client/app
flutter devices
flutter run -d <IP_DU_TELEPHONE>:<PORT_DE_CONNEXION>
```

Sur Android 10 ou plus ancien, la premiere configuration ADB sans fil demande
generalement une connexion USB. Un reseau Wi-Fi d'entreprise peut aussi bloquer
la communication entre le PC et le telephone.

## 6. Adresse du backend sur un telephone physique

`localhost` designe le telephone lui-meme, pas le PC. L'application doit donc
utiliser l'adresse IP locale du PC, par exemple :

```text
http://192.168.1.25:8080
```

Le PC et le telephone doivent etre sur le meme reseau, et le pare-feu Windows doit
autoriser le port `8080`.

La configuration Flutter se trouve notamment dans :

- `client/app/lib/core/config/api_config.dart`
- `client/app/lib/core/constants/app_constants.dart`

Le script de configuration existant peut aider a definir l'adresse avant de generer
l'APK :

```bash
./rebuild_apk.sh
```

## 7. Tester sans telephone

Pour verifier rapidement l'interface sans appareil Android :

```bash
cd client/app
flutter run -d chrome
```

Pour un emulateur Android :

```bash
flutter emulators
flutter emulators --launch <emulator-id>
flutter run
```

## 8. Depannage rapide

```bash
adb devices -l
flutter doctor -v
flutter devices
```

- ADB vide : probleme de cable, pilote, port USB ou connexion Wi-Fi.
- `unauthorized` : confirmer l'autorisation sur le telephone.
- API inaccessible : verifier l'IP du PC, le port `8080`, le pare-feu et Docker.
- Licences Android manquantes :

```bash
flutter doctor --android-licenses
```
