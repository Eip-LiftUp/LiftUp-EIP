import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the device has a network connection (Wi-Fi, mobile data…).
/// Being connected does not guarantee the server answers: sync attempts
/// still handle failures.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool online(List<ConnectivityResult> results) => results.any((r) => r != ConnectivityResult.none);
  yield online(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(online).distinct();
});

/// Shown by the features that only work with the server (account, profile,
/// program generation, video analysis).
const offlineMessage = 'Tu es hors ligne : cette action a besoin d\'une connexion internet.';

/// Profile never loaded on this device and no network to load it.
const offlineProfileMessage = 'Hors ligne : ton profil s\'affichera à la prochaine connexion.';

/// Last known connectivity; assumed online until the platform answers.
final isOnlineProvider = Provider<bool>((ref) => ref.watch(connectivityProvider).valueOrNull ?? true);
