// lib/features/admin/setup_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mytuition/config/theme/app_colors.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _isLoading = false;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Setup'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Database Setup',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This screen allows you to initialize the class data in the database. This should only be run once during the initial setup.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _initializeClassData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Initialize Class Data'),
                ),
              const SizedBox(height: 24),
              if (_status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _status.contains('Error')
                        ? AppColors.errorLight
                        : AppColors.successLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _status,
                    style: TextStyle(
                      color: _status.contains('Error')
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initializeClassData() async {
    setState(() {
      _isLoading = true;
      _status = 'Setting up class data...';
    });

    try {
      await setupInitialClassData(FirebaseFirestore.instance);
      setState(() {
        _status =
            'Setup completed successfully! The database has been initialized with class data.';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> setupInitialClassData(FirebaseFirestore firestore) async {
    // Define all subjects
    final subjects = [
      "mathematics",
      "english",
      "chinese",
      "bahasa-malaysia",
      "science"
    ];

    // Define grades
    final grades = [1, 2, 3, 4, 5, 6];

    final batch = firestore.batch();

    // For each grade, create classes for each subject
    for (var grade in grades) {
      for (var subject in subjects) {
        final docId = "$subject-grade$grade";
        final docRef = firestore.collection('classes').doc(docId);

        // Prepare a displayName with proper capitalization
        String displayName = subject.replaceAll('-', ' ');
        displayName = displayName
            .split(' ')
            .map((word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1)
                : '')
            .join(' ');

        batch.set(docRef, {
          'subject': displayName,
          'grade': grade,
          'tutorId': 'tutor-leong',
          'tutorName': 'Mr. Leong',
          'students': [],
          'schedules': [
            // Default schedule - you can customize this
            {
              'day': 'Monday',
              'startTime': Timestamp.fromDate(DateTime(2023, 1, 1, 14, 0)),
              'endTime': Timestamp.fromDate(DateTime(2023, 1, 1, 15, 30)),
              'location': 'Classroom A'
            }
          ],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // Execute the batch write
    await batch.commit();
  }
}
