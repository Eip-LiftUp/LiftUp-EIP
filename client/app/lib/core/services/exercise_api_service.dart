import 'package:dio/dio.dart';

/// Exercise model from wger API
class ExerciseInfo {
  final int id;
  final String name;
  final String description;
  final String category;
  final List<String> muscles;
  final String? equipment;

  ExerciseInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.muscles,
    this.equipment,
  });

  factory ExerciseInfo.fromJson(Map<String, dynamic> json) {
    return ExerciseInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category']?.toString() ?? '',
      muscles: (json['muscles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      equipment: json['equipment']?.toString(),
    );
  }
}

/// Service to fetch exercises from wger.de API
class ExerciseApiService {
  final Dio _dio;
  static const String baseUrl = 'https://wger.de/api/v2';

  ExerciseApiService() : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Get exercises with optional filters
  Future<List<ExerciseInfo>> getExercises({
    String? language,
    String? category,
    int limit = 200,
  }) async {
    try {
      final params = <String, dynamic>{
        'limit': limit,
        'language': language ?? 2, // 2 = English, 1 = German, 4 = French
      };

      if (category != null) {
        params['category'] = category;
      }

      final response = await _dio.get('/exercise/', queryParameters: params);
      
      if (response.statusCode == 200) {
        final results = response.data['results'] as List<dynamic>;
        return results
            .map((json) => ExerciseInfo.fromJson(json))
            .where((ex) => ex.name.isNotEmpty) // Filter empty names
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching exercises: $e');
      return _getFallbackExercises();
    }
  }

  /// Search exercises by name
  Future<List<ExerciseInfo>> searchExercises(String query) async {
    try {
      final response = await _dio.get(
        '/exercise/search/',
        queryParameters: {
          'term': query,
          'language': 2, // English
        },
      );

      if (response.statusCode == 200) {
        final suggestions = response.data['suggestions'] as List<dynamic>;
        return suggestions
            .map((json) => ExerciseInfo.fromJson(json['data']))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error searching exercises: $e');
      return [];
    }
  }

  /// Fallback exercises if API fails
  List<ExerciseInfo> _getFallbackExercises() {
    return [
      ExerciseInfo(id: 1, name: 'Développé couché', description: 'Push', category: 'Pectoraux', muscles: ['Chest']),
      ExerciseInfo(id: 2, name: 'Squat', description: 'Legs', category: 'Jambes', muscles: ['Quads', 'Glutes']),
      ExerciseInfo(id: 3, name: 'Deadlift', description: 'Pull', category: 'Dos', muscles: ['Back', 'Hamstrings']),
      ExerciseInfo(id: 4, name: 'Bench Press', description: 'Push', category: 'Chest', muscles: ['Chest', 'Triceps']),
      ExerciseInfo(id: 5, name: 'Pull-ups', description: 'Pull', category: 'Back', muscles: ['Lats', 'Biceps']),
      ExerciseInfo(id: 6, name: 'Overhead Press', description: 'Push', category: 'Shoulders', muscles: ['Delts']),
      ExerciseInfo(id: 7, name: 'Barbell Row', description: 'Pull', category: 'Back', muscles: ['Upper Back']),
      ExerciseInfo(id: 8, name: 'Dips', description: 'Push', category: 'Chest', muscles: ['Chest', 'Triceps']),
      ExerciseInfo(id: 9, name: 'Leg Press', description: 'Legs', category: 'Legs', muscles: ['Quads']),
      ExerciseInfo(id: 10, name: 'Bicep Curl', description: 'Arms', category: 'Arms', muscles: ['Biceps']),
    ];
  }

  /// Get popular exercises (cached/predefined)
  List<ExerciseInfo> getPopularExercises() {
    return [
      ExerciseInfo(id: 101, name: 'Développé couché', description: 'Exercice de base pour les pectoraux', category: 'Pectoraux', muscles: ['Pectoraux', 'Triceps']),
      ExerciseInfo(id: 102, name: 'Squat', description: 'Exercice fondamental pour les jambes', category: 'Jambes', muscles: ['Quadriceps', 'Fessiers']),
      ExerciseInfo(id: 103, name: 'Soulevé de terre', description: 'Exercice complet du dos', category: 'Dos', muscles: ['Dos', 'Ischio-jambiers']),
      ExerciseInfo(id: 104, name: 'Développé militaire', description: 'Pour les épaules', category: 'Épaules', muscles: ['Deltoïdes']),
      ExerciseInfo(id: 105, name: 'Rowing barre', description: 'Pour le dos', category: 'Dos', muscles: ['Dorsaux', 'Trapèzes']),
      ExerciseInfo(id: 106, name: 'Dips', description: 'Poids du corps', category: 'Pectoraux', muscles: ['Pectoraux', 'Triceps']),
      ExerciseInfo(id: 107, name: 'Tractions', description: 'Pour le dos', category: 'Dos', muscles: ['Dorsaux', 'Biceps']),
      ExerciseInfo(id: 108, name: 'Développé incliné', description: 'Haut des pectoraux', category: 'Pectoraux', muscles: ['Pectoraux']),
      ExerciseInfo(id: 109, name: 'Leg curl', description: 'Ischio-jambiers', category: 'Jambes', muscles: ['Ischio-jambiers']),
      ExerciseInfo(id: 110, name: 'Presse à cuisses', description: 'Quadriceps', category: 'Jambes', muscles: ['Quadriceps']),
      ExerciseInfo(id: 111, name: 'Curl biceps', description: 'Biceps', category: 'Bras', muscles: ['Biceps']),
      ExerciseInfo(id: 112, name: 'Extension triceps', description: 'Triceps', category: 'Bras', muscles: ['Triceps']),
      ExerciseInfo(id: 113, name: 'Élévations latérales', description: 'Deltoïdes latéraux', category: 'Épaules', muscles: ['Deltoïdes']),
      ExerciseInfo(id: 114, name: 'Face pulls', description: 'Deltoïdes postérieurs', category: 'Épaules', muscles: ['Deltoïdes', 'Trapèzes']),
      ExerciseInfo(id: 115, name: 'Leg extension', description: 'Quadriceps', category: 'Jambes', muscles: ['Quadriceps']),
      ExerciseInfo(id: 116, name: 'Mollets debout', description: 'Mollets', category: 'Jambes', muscles: ['Mollets']),
      ExerciseInfo(id: 117, name: 'Crunch', description: 'Abdominaux', category: 'Abdos', muscles: ['Abdominaux']),
      ExerciseInfo(id: 118, name: 'Planche', description: 'Gainage', category: 'Abdos', muscles: ['Core']),
      ExerciseInfo(id: 119, name: 'Romanian deadlift', description: 'Ischio-jambiers', category: 'Jambes', muscles: ['Ischio-jambiers']),
      ExerciseInfo(id: 120, name: 'Hack squat', description: 'Quadriceps', category: 'Jambes', muscles: ['Quadriceps']),
    ];
  }
}
