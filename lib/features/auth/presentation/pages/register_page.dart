import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/router/route_names.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/floating_educational_elements.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Step tracking
  bool _showConsultDialog = true;
  int _currentStep = 0;
  final PageController _pageController = PageController(initialPage: 0);

  // Form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Form values
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _hasConsulted = false;
  String _selectedGrade = 'One';
  final List<String> _grades = ['One', 'Two', 'Three', 'Four', 'Five', 'Six'];

  // Subject selection
  final Map<String, bool> _selectedSubjects = {
    'Mathematics': false,
    'Science': false,
    'English': false,
    'Bahasa Malaysia': false,
    'Bahasa Cina': false,
  };

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  void _handleConsultResponse(bool hasConsulted) {
    setState(() {
      _hasConsulted = hasConsulted;
      _showConsultDialog = false;
    });
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate credentials step
      if (_formKey.currentState!.validate()) {
        setState(() {
          _currentStep = 1;
        });
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (_currentStep == 1) {
      // Validate personal info step
      if (_formKey.currentState!.validate()) {
        setState(() {
          _currentStep = 2;
        });
        _pageController.animateToPage(
          2,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      // Submit the form on the final step
      _submitForm();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Get list of selected subjects
      final List<String> subjects = _selectedSubjects.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      // Convert grade string to int
      final int grade = _grades.indexOf(_selectedGrade) + 1;

      // Submit registration
      context.read<AuthBloc>().add(
        RegisterEvent(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          isTutor: false, // Always registering as student
          grade: grade,
          subjects: subjects,
          phone: _phoneController.text.trim(),
          hasConsulted: _hasConsulted,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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

          if (state is RegistrationSubmitted) {
            // Show success dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration submitted successfully! Please wait for tutor approval.'),
                backgroundColor: AppColors.success,
              ),
            );

            // Navigate back to login
            Future.delayed(const Duration(seconds: 2), () {
              context.goNamed(RouteNames.login);
            });
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

              // Consult Dialog
              if (_showConsultDialog)
                _buildConsultDialog(),

              // Content
              if (!_showConsultDialog)
                _buildRegistrationContent(state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConsultDialog() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Before Sign Up....',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Have you previously consulted with a tutor?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _handleConsultResponse(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('No'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () => _handleConsultResponse(true),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                    ),
                    child: const Text('Yes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationContent(AuthState state) {
    return SafeArea(
      child: Column(
        children: [
          // Title and progress indicator
          _buildHeader(),

          // Form content
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildAccountInfoStep(),
                  _buildPersonalInfoStep(),
                  _buildSubjectsStep(),
                ],
              ),
            ),
          ),

          // Navigation buttons
          _buildNavigationButtons(state),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Setup Wizard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),

          // Step indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepCircle(0, "1"),
              _buildStepConnector(0),
              _buildStepCircle(1, "2"),
              _buildStepConnector(1),
              _buildStepCircle(2, "3"),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'Please provide the following information to setup your account',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textMedium,
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryBlue : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildStepConnector(int step) {
    final isActive = _currentStep > step;
    return Container(
      width: 50,
      height: 2,
      color: isActive ? AppColors.primaryBlue : Colors.grey[300],
    );
  }

  Widget _buildAccountInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Account Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),

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
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
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
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm password field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: _toggleConfirmPasswordVisibility,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),

          // Name field
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Phone number field
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone),
              prefixText: '+60 | ',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              // Simple validation for Malaysian phone number
              if (!RegExp(r'^[0-9]{9,10}$').hasMatch(value)) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Grade dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Grade',
              prefixIcon: Icon(Icons.school),
            ),
            value: _selectedGrade,
            items: _grades.map((String grade) {
              return DropdownMenuItem<String>(
                value: grade,
                child: Text(grade),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedGrade = newValue;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Consulted dropdown (read-only)
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Consulted',
              prefixIcon: Icon(Icons.check_circle),
            ),
            value: _hasConsulted ? 'Yes' : 'No',
            items: const [
              DropdownMenuItem<String>(
                value: 'Yes',
                child: Text('Yes'),
              ),
              DropdownMenuItem<String>(
                value: 'No',
                child: Text('No'),
              ),
            ],
            onChanged: null, // Read-only
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select Subjects',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Please select the subjects you are interested in:',
            style: TextStyle(
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 24),

          // Subject checkboxes
          Column(
            children: _selectedSubjects.keys.map((String subject) {
              return CheckboxListTile(
                title: Text(subject),
                value: _selectedSubjects[subject],
                activeColor: AppColors.primaryBlue,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (bool? value) {
                  setState(() {
                    _selectedSubjects[subject] = value ?? false;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Summary information
          const Text(
            'By proceeding, you agree to the following:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('• Your registration will be reviewed by a tutor'),
          const Text('• You may be contacted for verification'),
          const Text('• You will receive an email once approved'),

          const SizedBox(height: 24),

          // Terms and conditions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'By clicking Sign Up, you agree to our ',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMedium,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to terms of service
                },
                child: Text(
                  'Terms of Service',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'and ',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMedium,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to privacy policy
                },
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(AuthState state) {
    final bool isLoading = state is AuthLoading;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Back button - hidden on first step
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[400]!),
                  backgroundColor: Colors.grey[300],
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: TextButton(
                onPressed: () {
                  context.goNamed(RouteNames.login);
                },
                child: const Text('Back to Login'),
              ),
            ),

          const SizedBox(width: 16),

          // Next/Submit button
          Expanded(
            child: ElevatedButton(
              onPressed: isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primaryBlue,
              ),
              child: isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentStep < 2 ? 'Next' : 'Sign Up',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_currentStep < 2)
                    const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}