import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/router/route_names.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/floating_educational_elements.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String _selectedRole = 'student'; // Default role

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        LoginEvent(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          isTutor: _selectedRole == 'tutor',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }

          // Add handler for pending registration
          if (state is RegistrationPending) {
            // Show a nicer dialog instead of a snackbar
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      Icons.pending_actions,
                      color: AppColors.primaryBlue,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text('Registration Pending'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your registration is pending approval.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Please wait for the tutor to review your application. You\'ll be able to login once approved.',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'If you have any questions, please contact the tutor directly.',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }

          if (state is Authenticated) {
            // Navigate based on user role
            if (state.isTutor) {
              context.goNamed(RouteNames.tutorRoot);
            } else {
              context.goNamed(RouteNames.studentRoot);
            }
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Background floating elements
              Container(
                width: double.infinity,
                height: double.infinity,
                color: AppColors.backgroundLight,
                child: const FloatingEducationalElements(),
              ),

              // Content
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo and title
                          Column(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor:
                                AppColors.primaryBlue.withOpacity(0.1),
                                child: Icon(
                                  Icons.school,
                                  size: 48,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'myTuition',
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Classroom Management Platform',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.textMedium,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          // Form
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Login',
                                      style: theme.textTheme.headlineSmall,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),

                                    // Role selector
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.backgroundDark
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedRole = 'student';
                                                });
                                              },
                                              child: Container(
                                                padding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: _selectedRole ==
                                                      'student'
                                                      ? AppColors.primaryBlue
                                                      : Colors.transparent,
                                                  borderRadius:
                                                  BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'Student',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: _selectedRole ==
                                                        'student'
                                                        ? Colors.white
                                                        : AppColors.textMedium,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedRole = 'tutor';
                                                });
                                              },
                                              child: Container(
                                                padding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: _selectedRole ==
                                                      'tutor'
                                                      ? AppColors.primaryBlue
                                                      : Colors.transparent,
                                                  borderRadius:
                                                  BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'Tutor',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: _selectedRole ==
                                                        'tutor'
                                                        ? Colors.white
                                                        : AppColors.textMedium,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Email field
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: Icon(Icons.email),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                            .hasMatch(value)) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Password field
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: !_isPasswordVisible,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: const Icon(Icons.lock),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordVisible
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                          onPressed: _togglePasswordVisibility,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        if (value.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 8),

                                    // Forgot password
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          context.pushNamed(
                                              RouteNames.forgotPassword);
                                        },
                                        child: Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Login button
                                    ElevatedButton(
                                      onPressed: state is AuthLoading
                                          ? null
                                          : _submitForm,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                      child: state is AuthLoading
                                          ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                          : const Text('Login'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Register link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: AppColors.textMedium,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.pushNamed(RouteNames.register);
                                },
                                child: Text(
                                  'Register',
                                  style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}