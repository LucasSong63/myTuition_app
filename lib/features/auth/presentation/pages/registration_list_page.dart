import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/auth/data/models/registration_model.dart';
import '../bloc/registration_bloc.dart';
import '../bloc/registration_event.dart';
import '../bloc/registration_state.dart';

class RegistrationListPage extends StatefulWidget {
  const RegistrationListPage({Key? key}) : super(key: key);

  @override
  State<RegistrationListPage> createState() => _RegistrationListPageState();
}

class _RegistrationListPageState extends State<RegistrationListPage> {
  @override
  void initState() {
    super.initState();
    // Load registration requests when page is initialized
    context.read<RegistrationBloc>().add(LoadRegistrationsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Registration'),
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

          if (state is RegistrationsLoaded) {
            final registrations = state.registrations;

            if (registrations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.app_registration,
                      size: 64,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No pending registration requests',
                      style: TextStyle(
                        color: AppColors.textMedium,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: registrations.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final registration = registrations[index];
                return _buildRegistrationCard(context, registration);
              },
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
                  'Failed to load registration requests',
                  style: TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<RegistrationBloc>().add(LoadRegistrationsEvent());
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

  Widget _buildRegistrationCard(BuildContext context, RegistrationRequest registration) {
    // Determine the consultation status icon
    final Icon consultedIcon = registration.hasConsulted
        ? Icon(Icons.check_circle, color: AppColors.success)
        : Icon(Icons.cancel, color: AppColors.error);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          registration.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Row(
          children: [
            Text(registration.phone),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  const Text('Consulted?'),
                  const SizedBox(width: 4),
                  consultedIcon,
                ],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            // Navigate to registration details page
            context.push('/tutor/registrations/${registration.id}');
          },
        ),
        onTap: () {
          // Navigate to registration details page
          context.push('/tutor/registrations/${registration.id}');
        },
      ),
    );
  }
}