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
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _initializeClassData,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Initialize Class Data'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _updateCapacityForExistingClasses,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        backgroundColor: AppColors.accentOrange,
                      ),
                      child: const Text('Update Capacity for Existing Classes'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _initializeSubjectCosts,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        backgroundColor: AppColors.accentTeal,
                      ),
                      child: const Text('Add Subject Cost Fields (RM100)'),
                    ),
                    ElevatedButton(
                      onPressed: _migrateToSubjectCostsCollection,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        backgroundColor: Colors.purple,
                      ),
                      child: const Text('Migrate to Subject Costs Collection'),
                    ),
                    ElevatedButton(
                      onPressed: _setupSubjectCostsCollection,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        backgroundColor: Colors.indigo,
                      ),
                      child: const Text('Setup Subject Costs Collection'),
                    ),
                  ],
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

  Future<void> _updateCapacityForExistingClasses() async {
    setState(() {
      _isLoading = true;
      _status = 'Updating capacity for existing classes...';
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('classes').get();

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in snapshot.docs) {
        // Add 'capacity' field with value 20 for each class
        batch.update(doc.reference, {'capacity': 20});
      }

      await batch.commit();

      setState(() {
        _status =
            'Successfully updated capacity for ${snapshot.docs.length} classes!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error updating capacity: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  Future<void> _initializeSubjectCosts() async {
    setState(() {
      _isLoading = true;
      _status = 'Adding subjectCost field to existing classes...';
    });

    try {
      // Default cost for each subject
      const defaultCost = 100.0;

      // Get all class documents
      final snapshot =
          await FirebaseFirestore.instance.collection('classes').get();

      // Create a batch write operation
      final batch = FirebaseFirestore.instance.batch();

      // For each class document, add the subjectCost field
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'subjectCost': defaultCost});
      }

      // Execute the batch write
      await batch.commit();

      setState(() {
        _status =
            'Successfully added subjectCost field to ${snapshot.docs.length} classes!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error adding subject costs: $e';
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
          'capacity': 20, // Adding capacity field with default value
          'isActive': true, // Setting classes as active by default
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

  Future<void> _migrateToSubjectCostsCollection() async {
    setState(() {
      _isLoading = true;
      _status = 'Migrating subject costs to separate collection...';
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Step 1: Get all classes
      final classesSnapshot = await firestore.collection('classes').get();

      // Step 2: Extract unique subjects
      final Map<String, String> uniqueSubjects = {};
      for (var doc in classesSnapshot.docs) {
        final data = doc.data();
        final subject = data['subject'] as String;
        final subjectId = subject.toLowerCase().replaceAll(' ', '_');
        uniqueSubjects[subjectId] = subject;
      }

      // Step 3: Create entries in subject_costs collection
      final batch = firestore.batch();

      // Step 3a: First check if any subject costs already exist to avoid duplicates
      final existingCostsSnapshot =
          await firestore.collection('subject_costs').get();
      final existingSubjectIds = existingCostsSnapshot.docs
          .map((doc) => doc.data()['subjectId'] as String)
          .toList();

      // Step 3b: Create new subject cost documents
      int createdCount = 0;
      uniqueSubjects.forEach((subjectId, subjectName) {
        if (!existingSubjectIds.contains(subjectId)) {
          final docRef = firestore.collection('subject_costs').doc();
          batch.set(docRef, {
            'subjectId': subjectId,
            'subjectName': subjectName,
            'cost': 100.0, // Default cost
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          createdCount++;
        }
      });

      // Step 4: Remove subjectCost field from class documents
      int updatedCount = 0;
      for (var doc in classesSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('subjectCost')) {
          batch.update(doc.reference, {'subjectCost': FieldValue.delete()});
          updatedCount++;
        }
      }

      // Execute the batch
      await batch.commit();

      setState(() {
        _status = 'Migration completed successfully!\n'
            'Created $createdCount subject cost entries.\n'
            'Removed subjectCost field from $updatedCount classes.';
      });
    } catch (e) {
      setState(() {
        _status = 'Error during migration: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setupSubjectCostsCollection() async {
    setState(() {
      _isLoading = true;
      _status = 'Setting up subject costs collection...';
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Define the subjects
      final subjects = [
        "Mathematics",
        "English",
        "Chinese",
        "Bahasa Malaysia",
        "Science"
      ];

      // Define grades
      final grades = [1, 2, 3, 4, 5, 6];

      // Create a batch operation
      final batch = firestore.batch();

      // Track count of created documents
      int createdCount = 0;

      // Create subject cost documents for each subject-grade combination
      for (var subject in subjects) {
        for (var grade in grades) {
          final subjectId = subject.toLowerCase().replaceAll(' ', '-');
          final docId = '$subjectId-grade$grade';

          final docRef = firestore.collection('subject_costs').doc(docId);
          batch.set(docRef, {
            'subjectId': subjectId,
            'subjectName': subject,
            'grade': grade,
            'cost': 100.0, // Default cost
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          createdCount++;
        }
      }

      // Remove subjectCost field from all class documents
      final classesSnapshot = await firestore.collection('classes').get();
      int updatedCount = 0;
      for (var doc in classesSnapshot.docs) {
        if (doc.data().containsKey('subjectCost')) {
          batch.update(doc.reference, {'subjectCost': FieldValue.delete()});
          updatedCount++;
        }
      }

      // Execute the batch
      await batch.commit();

      setState(() {
        _status = 'Subject costs collection setup completed successfully!\n'
            'Created $createdCount subject cost entries.\n'
            'Removed subjectCost field from $updatedCount classes.';
      });
    } catch (e) {
      setState(() {
        _status = 'Error setting up subject costs: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
