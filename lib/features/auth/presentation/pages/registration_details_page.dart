import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import '../bloc/registration_bloc.dart';
import '../bloc/registration_event.dart';
import '../bloc/registration_state.dart';

class RegistrationDetailsPage extends StatefulWidget {
  final String registrationId;

  const RegistrationDetailsPage({
    Key? key,
    required this.registrationId,
  }) : super(key: key);

  @override
  State<RegistrationDetailsPage> createState() => _RegistrationDetailsPageState();
}

class _RegistrationDetailsPageState extends State<RegistrationDetailsPage> {
  final TextEditingController _rejectReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load registration details when page is initialized
    context.read<RegistrationBloc>().add(
      LoadRegistrationDetailsEvent(id: widget.registrationId),
    );
  }

  @override
  void dispose() {
    _rejectReasonController.dispose();
    super.dispose();
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Registration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for rejection:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rejectReasonController,
              decoration: const InputDecoration(
                hintText: 'Enter reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_rejectReasonController.text.trim().isNotEmpty) {
                Navigator.of(context).pop();

                // Submit rejection
                context.read<RegistrationBloc>().add(
                  RejectRegistrationEvent(
                    id: widget.registrationId,
                    reason: _rejectReasonController.text.trim(),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Details'),
        elevation: 0,
      ),
      body: BlocConsumer<RegistrationBloc, RegistrationState>(
        listener: (context, state) {
          if (state is RegistrationActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );

            // Navigate back to list after action
            context.pop();
          }

          if (state is RegistrationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is RegistrationLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is RegistrationDetailsLoaded) {
            final registration = state.registration;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Student name header
                  Text(
                    registration.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Actions (Approve/Reject)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showRejectDialog(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<RegistrationBloc>().add(
                              ApproveRegistrationEvent(id: widget.registrationId),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Student information card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Student Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Email', registration.email),
                          _buildInfoRow('Phone', registration.phone),
                          _buildInfoRow('Grade', 'Grade ${registration.grade}'),
                          _buildInfoRow(
                            'Has Consulted',
                            registration.hasConsulted ? 'Yes' : 'No',
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Subjects:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: registration.subjects.map((subject) {
                              return Chip(
                                label: Text(subject),
                                backgroundColor: AppColors.primaryBlueLight.withOpacity(0.2),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Registration Date: ${_formatDate(registration.createdAt)}',
                            style: TextStyle(
                              color: AppColors.textMedium,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Default state or error
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load registration details',
                  style: TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<RegistrationBloc>().add(
                      LoadRegistrationDetailsEvent(id: widget.registrationId),
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}