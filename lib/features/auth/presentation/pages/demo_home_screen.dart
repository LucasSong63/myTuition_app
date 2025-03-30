import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class DemoHomeScreen extends StatefulWidget {
  final bool isTutor;

  const DemoHomeScreen({
    Key? key,
    required this.isTutor,
  }) : super(key: key);

  @override
  State<DemoHomeScreen> createState() => _DemoHomeScreenState();
}

class _DemoHomeScreenState extends State<DemoHomeScreen> {
  late StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for auth state changes
    _authSubscription = context.read<AuthBloc>().stream.listen((state) {
      if (state is Unauthenticated && mounted) {
        // Only navigate when state becomes Unauthenticated and widget is still mounted
        WidgetsBinding.instance.addPostFrameCallback((_) {
          GoRouter.of(context).go('/login');
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTutor ? 'Tutor Dashboard' : 'Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                    ElevatedButton(
                      child: const Text('Logout'),
                      onPressed: () {
                        // Close dialog first
                        Navigator.of(dialogContext).pop();
                        // Just dispatch the logout event and let the listener handle navigation
                        context.read<AuthBloc>().add(LogoutEvent());
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: widget.isTutor
            ? _buildTutorDashboard(context)
            : _buildStudentDashboard(context),
      ),
    );
  }


Widget _buildTutorDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Registration requests card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Registration Requests',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        // Refresh registration requests
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage student registration requests',
                  style: TextStyle(color: AppColors.textMedium),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.push('/tutor/registrations');
                  },
                  icon: const Icon(Icons.app_registration),
                  label: const Text('View Pending Registrations'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Other dashboard items would go here
        const Text(
          'Other dashboard features will be implemented in future updates.',
          style: TextStyle(color: AppColors.textMedium),
        ),
      ],
    );
  }

  Widget _buildStudentDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your dashboard is being set up by your tutor.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          'Student features will be available soon.',
          style: TextStyle(color: AppColors.textMedium),
        ),
      ],
    );
  }
}