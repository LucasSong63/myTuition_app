import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;

  const EmailVerificationPage({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _isResendingEmail = false;
  bool _hasResentEmail = false;
  bool _isCheckingVerification = false;

  void _resendVerificationEmail() {
    setState(() {
      _isResendingEmail = true;
    });

    context.read<AuthBloc>().add(ResendVerificationEmailEvent(email: widget.email));
  }

  void _checkVerificationStatus() {
    setState(() {
      _isCheckingVerification = true;
    });

    context.read<AuthBloc>().add(CheckEmailVerificationEvent(email: widget.email));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is EmailVerificationSent) {
            setState(() {
              _isResendingEmail = false;
              _hasResentEmail = true;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verification email sent successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          }

          if (state is AuthError) {
            setState(() {
              _isResendingEmail = false;
              _isCheckingVerification = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }

          if (state is EmailVerificationRequired) {
            setState(() {
              _isCheckingVerification = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your email is not verified yet. Please check your inbox and click the verification link.'),
                backgroundColor: AppColors.warning,
              ),
            );
          }

          if (state is Authenticated) {
            // User is verified and authenticated, navigate to dashboard
            if (state.isTutor) {
              context.go('/tutor');
            } else {
              context.go('/student');
            }
          }

          if (state is AuthLoading) {
            // Keep loading state for UI feedback
          } else {
            // Reset the checking state for any other state
            setState(() {
              _isCheckingVerification = false;
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.mark_email_unread,
                size: 80,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(height: 24),
              Text(
                'Verify Your Email',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We\'ve sent a verification email to:',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                'Please check your email and click the verification link to continue.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _isCheckingVerification ? null : _checkVerificationStatus,
                icon: _isCheckingVerification
                    ? Container(
                  width: 24,
                  height: 24,
                  padding: const EdgeInsets.all(2.0),
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.check_circle),
                label: Text(_isCheckingVerification ? 'Checking...' : 'I\'ve Verified My Email'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              if (_hasResentEmail)
                const Text(
                  'We\'ve sent another verification email. Please check your inbox and spam folder.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMedium,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                _isResendingEmail
                    ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                )
                    : TextButton(
                  onPressed: _resendVerificationEmail,
                  child: const Text('Didn\'t receive the email? Resend'),
                ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  context.read<AuthBloc>().add(LogoutEvent());
                  context.go('/login');
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}