import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/providers/user_providers.dart';
import 'package:app/core/models/user.dart';

/// Examples of how to use the backend integration in your Flutter app

// ============================================================================
// Example 1: Check backend health in a widget
// ============================================================================

class HealthCheckWidget extends ConsumerWidget {
  const HealthCheckWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthCheck = ref.watch(healthCheckProvider);

    return healthCheck.when(
      data: (isHealthy) => Text(isHealthy ? '✓ Connected' : '✗ Disconnected'),
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => Text('Error: $error'),
    );
  }
}

// ============================================================================
// Example 2: Create user with button
// ============================================================================

class CreateUserButton extends ConsumerWidget {
  const CreateUserButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userCreationState = ref.watch(userCreationProvider);

    return Column(
      children: [
        ElevatedButton(
          onPressed: userCreationState.isLoading
              ? null
              : () {
                  final request = CreateUserRequest(
                    email: 'john.doe@example.com',
                    username: 'johndoe',
                    displayName: 'John Doe',
                    heightCm: 180,
                    weightKg: 75.0,
                    fitnessLevel: FitnessLevel.intermediate,
                  );

                  ref
                      .read(userCreationProvider.notifier)
                      .createUser(request);
                },
          child: userCreationState.isLoading
              ? const CircularProgressIndicator()
              : const Text('Create User'),
        ),
        
        // Show result
        userCreationState.when(
          data: (response) {
            if (response == null) return const SizedBox.shrink();
            return Text('User created: ${response.username}');
          },
          loading: () => const Text('Creating...'),
          error: (error, _) => Text('Error: $error', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}

// ============================================================================
// Example 3: Create user in a function (e.g., in onPressed)
// ============================================================================

void createUserExample(WidgetRef ref) async {
  final notifier = ref.read(userCreationProvider.notifier);

  final request = CreateUserRequest(
    email: 'jane@example.com',
    username: 'janedoe',
    fitnessLevel: FitnessLevel.beginner,
  );

  await notifier.createUser(request);

  // Check result
  final state = ref.read(userCreationProvider);
  state.when(
    data: (response) {
      if (response != null) {
        print('Success! User ID: ${response.id}');
      }
    },
    loading: () => print('Loading...'),
    error: (error, _) => print('Error: $error'),
  );
}

// ============================================================================
// Example 4: Direct API call (without state management)
// ============================================================================

Future<void> directApiCallExample(WidgetRef ref) async {
  final apiService = ref.read(userApiServiceProvider);

  try {
    // Health check
    final health = await apiService.healthCheck();
    print('Backend status: ${health.status}');

    // Create user
    final request = CreateUserRequest(
      email: 'api@example.com',
      username: 'apiuser',
      fitnessLevel: FitnessLevel.advanced,
    );

    final response = await apiService.createUser(request);
    print('User created: ${response.id}');
  } on ApiException catch (e) {
    print('API Error: ${e.message} (${e.statusCode})');
  } catch (e) {
    print('Unexpected error: $e');
  }
}

// ============================================================================
// Example 5: Using repository directly
// ============================================================================

Future<void> repositoryExample(WidgetRef ref) async {
  final repository = ref.read(userRepositoryProvider);

  // Check health
  final isHealthy = await repository.checkHealth();
  print('Backend healthy: $isHealthy');

  // Create user
  try {
    final request = CreateUserRequest(
      email: 'repo@example.com',
      username: 'repouser',
    );

    final response = await repository.createUser(request);
    print('Created user: ${response.username}');
  } on ApiException catch (e) {
    print('Failed: ${e.message}');
  }
}

// ============================================================================
// Example 6: Form with validation and user creation
// ============================================================================

class UserRegistrationForm extends ConsumerStatefulWidget {
  const UserRegistrationForm({super.key});

  @override
  ConsumerState<UserRegistrationForm> createState() =>
      _UserRegistrationFormState();
}

class _UserRegistrationFormState extends ConsumerState<UserRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final request = CreateUserRequest(
        email: _emailController.text,
        username: _usernameController.text,
        fitnessLevel: FitnessLevel.beginner,
      );

      ref.read(userCreationProvider.notifier).createUser(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userCreationState = ref.watch(userCreationProvider);

    // Listen to state changes
    ref.listen<AsyncValue<CreateUserResponse?>>(
      userCreationProvider,
      (previous, next) {
        next.whenOrNull(
          data: (response) {
            if (response != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('User ${response.username} created!'),
                  backgroundColor: Colors.green,
                ),
              );
              
              // Navigate to home or reset form
              _emailController.clear();
              _usernameController.clear();
            }
          },
          error: (error, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error.toString()),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
      },
    );

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (!value.contains('@')) return 'Invalid email';
              return null;
            },
          ),
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (value.length < 3) return 'Too short';
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: userCreationState.isLoading ? null : _handleSubmit,
            child: userCreationState.isLoading
                ? const CircularProgressIndicator()
                : const Text('Register'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Example 7: Handling different API responses
// ============================================================================

class ApiResponseHandler extends ConsumerWidget {
  const ApiResponseHandler({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userCreationState = ref.watch(userCreationProvider);

    return userCreationState.when(
      // Initial state - no data yet
      data: (response) {
        if (response == null) {
          return const Text('No user created yet');
        }

        // Success - show user data
        return Card(
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(response.username),
            subtitle: Text(response.email),
            trailing: Text(response.fitnessLevel),
          ),
        );
      },

      // Loading state
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Creating user...'),
          ],
        ),
      ),

      // Error state
      error: (error, stackTrace) {
        String errorMessage = 'An error occurred';

        if (error is ApiException) {
          errorMessage = error.message;

          // Handle specific error codes
          switch (error.statusCode) {
            case 409:
              errorMessage = 'Email already exists';
              break;
            case 422:
              errorMessage = 'Invalid data provided';
              break;
            case 500:
              errorMessage = 'Server error, please try again';
              break;
          }
        }

        return Card(
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    ref.read(userCreationProvider.notifier).reset();
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
