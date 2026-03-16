import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/providers/user_providers.dart';
import 'package:app/core/models/user.dart';
import 'package:app/core/constants/app_constants.dart';

/// Test screen for backend integration
class BackendTestScreen extends ConsumerStatefulWidget {
  const BackendTestScreen({super.key});

  @override
  ConsumerState<BackendTestScreen> createState() => _BackendTestScreenState();
}

class _BackendTestScreenState extends ConsumerState<BackendTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  
  FitnessLevel _selectedLevel = FitnessLevel.beginner;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _createUser() {
    if (_formKey.currentState!.validate()) {
      final request = CreateUserRequest(
        email: _emailController.text,
        username: _usernameController.text,
        displayName: _displayNameController.text.isEmpty 
            ? null 
            : _displayNameController.text,
        heightCm: _heightController.text.isEmpty 
            ? null 
            : int.tryParse(_heightController.text),
        weightKg: _weightController.text.isEmpty 
            ? null 
            : double.tryParse(_weightController.text),
        fitnessLevel: _selectedLevel,
      );

      ref.read(userCreationProvider.notifier).createUser(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthCheck = ref.watch(healthCheckProvider);
    final userCreationState = ref.watch(userCreationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Integration Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(healthCheckProvider),
            tooltip: 'Refresh health check',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Health Check Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Backend Health Check',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    healthCheck.when(
                      data: (isHealthy) => Row(
                        children: [
                          Icon(
                            isHealthy ? Icons.check_circle : Icons.error,
                            color: isHealthy ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: AppConstants.spacingS),
                          Text(
                            isHealthy 
                                ? 'Backend is healthy ✓' 
                                : 'Backend is not responding ✗',
                            style: TextStyle(
                              color: isHealthy ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      loading: () => const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: AppConstants.spacingS),
                          Text('Checking...'),
                        ],
                      ),
                      error: (error, _) => Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: AppConstants.spacingS),
                          Expanded(
                            child: Text(
                              'Error: $error',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppConstants.spacingL),

            // Create User Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create New User',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.contains('@')) {
                            return 'Invalid email format';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Username is required';
                          }
                          if (value.length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      
                      TextFormField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              decoration: const InputDecoration(
                                labelText: 'Height (cm)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingM),
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              decoration: const InputDecoration(
                                labelText: 'Weight (kg)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      
                      DropdownButtonFormField<FitnessLevel>(
                        value: _selectedLevel,
                        decoration: const InputDecoration(
                          labelText: 'Fitness Level',
                          border: OutlineInputBorder(),
                        ),
                        items: FitnessLevel.values.map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(level.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedLevel = value);
                          }
                        },
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: userCreationState.isLoading 
                              ? null 
                              : _createUser,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(AppConstants.spacingM),
                          ),
                          child: userCreationState.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Create User'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppConstants.spacingL),

            // Response Section
            userCreationState.when(
              data: (response) {
                if (response == null) return const SizedBox.shrink();
                
                return Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: AppConstants.spacingS),
                            Text(
                              'User Created Successfully!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        Text('ID: ${response.id}'),
                        Text('Email: ${response.email}'),
                        Text('Username: ${response.username}'),
                        if (response.displayName != null)
                          Text('Display Name: ${response.displayName}'),
                        Text('Fitness Level: ${response.fitnessLevel}'),
                        Text('Created At: ${response.createdAt}'),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, _) => Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(width: AppConstants.spacingS),
                          Text(
                            'Error Creating User',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      Text(
                        error.toString(),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
