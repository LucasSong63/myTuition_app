import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/router/route_names.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/floating_educational_elements.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  late AnimationController _successAnimationController;
  late Animation<double> _successScaleAnimation;
  late Animation<double> _successOpacityAnimation;

  bool _isEmailSent = false;

  @override
  void initState() {
    super.initState();

    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _successScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _successOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successAnimationController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _successAnimationController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            ForgotPasswordEvent(email: _emailController.text.trim()),
          );
    }
  }

  void _resendEmail() {
    if (_emailController.text.isNotEmpty) {
      context.read<AuthBloc>().add(
            ForgotPasswordEvent(email: _emailController.text.trim()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(4.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
            );
          }

          if (state is PasswordResetSent) {
            setState(() {
              _isEmailSent = true;
            });
            _successAnimationController.forward();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Password reset email sent successfully!',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(4.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                color: AppColors.backgroundLight,
                child: const FloatingEducationalElements(),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Flexible(child: SizedBox(height: 2.h)),
                                _buildHeader(state),
                                SizedBox(height: 4.h),
                                _buildContentCard(state, theme),
                                SizedBox(height: 3.h),
                                _buildBackToLoginButton(),
                                Flexible(child: SizedBox(height: 2.h)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(AuthState state) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: _isEmailSent
              ? AnimatedBuilder(
                  animation: _successAnimationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _successScaleAnimation.value,
                      child: Opacity(
                        opacity: _successOpacityAnimation.value,
                        child: CircleAvatar(
                          radius: 12.w,
                          backgroundColor: AppColors.success.withOpacity(0.1),
                          child: Icon(
                            Icons.mark_email_read,
                            size: 12.w,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    );
                  },
                )
              : CircleAvatar(
                  key: const ValueKey('lock_icon'),
                  radius: 12.w,
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  child: Icon(
                    Icons.lock_reset,
                    size: 12.w,
                    color: AppColors.primaryBlue,
                  ),
                ),
        ),
        SizedBox(height: 3.h),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            _isEmailSent ? 'Check Your Email!' : 'Forgot Password?',
            key: ValueKey(_isEmailSent ? 'success_title' : 'forgot_title'),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color:
                      _isEmailSent ? AppColors.success : AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 1.h),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              _isEmailSent
                  ? 'We\'ve sent password reset instructions to your email'
                  : 'No worries! Enter your email and we\'ll send you reset instructions',
              key: ValueKey(
                  _isEmailSent ? 'success_subtitle' : 'forgot_subtitle'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textMedium,
                    fontSize: 13.sp,
                  ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard(AuthState state, ThemeData theme) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: 90.w,
      ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.w),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: EdgeInsets.all(5.w),
          child: _isEmailSent
              ? _buildSuccessContent(state)
              : _buildForgotPasswordForm(state, theme),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordForm(AuthState state, ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Reset Password',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.primaryBlue,
              fontSize: 15.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMedium,
              fontSize: 13.sp,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 3.h),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(fontSize: 13.sp),
            decoration: InputDecoration(
              labelText: 'Email Address',
              labelStyle: TextStyle(fontSize: 13.sp),
              hintText: 'Enter your email',
              hintStyle: TextStyle(fontSize: 13.sp),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: AppColors.primaryBlue,
                size: 5.w,
              ),
              filled: true,
              fillColor: AppColors.backgroundDark.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3.w),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3.w),
                borderSide: BorderSide(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3.w),
                borderSide: BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3.w),
                borderSide: BorderSide(
                  color: AppColors.error,
                  width: 1,
                ),
              ),
              errorStyle: TextStyle(fontSize: 13.sp),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 4.w,
                vertical: 2.h,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email address';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          SizedBox(height: 3.h),
          SizedBox(
            height: 6.h,
            child: ElevatedButton(
              onPressed: state is AuthLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.w),
                ),
                elevation: 2,
              ),
              child: state is AuthLoading
                  ? SizedBox(
                      height: 4.w,
                      width: 4.w,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send, size: 4.w),
                        SizedBox(width: 2.w),
                        Flexible(
                          child: Text(
                            'Send Reset Link',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(2.w),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primaryBlue,
                  size: 4.w,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Check your email for the reset link. It may take a few minutes to arrive.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.primaryBlue,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent(AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 16.w,
        ),
        SizedBox(height: 2.h),
        Text(
          'Email Sent Successfully!',
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.success,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 1.h),
        Text(
          'We\'ve sent password reset instructions to:',
          style: TextStyle(
            color: AppColors.textMedium,
            fontSize: 13.sp,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark.withOpacity(0.05),
            borderRadius: BorderRadius.circular(2.w),
          ),
          child: Text(
            _emailController.text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
              fontSize: 13.sp,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: 3.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.05),
            borderRadius: BorderRadius.circular(2.w),
            border: Border.all(
              color: AppColors.success.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Next Steps:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 1.h),
              _buildStep('1', 'Check your email inbox'),
              _buildStep('2', 'Click the reset link in the email'),
              _buildStep('3', 'Create a new password'),
              _buildStep('4', 'Return to the app and sign in'),
            ],
          ),
        ),
        SizedBox(height: 3.h),
        SizedBox(
          height: 5.h,
          child: OutlinedButton(
            onPressed: state is AuthLoading ? null : _resendEmail,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primaryBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            child: state is AuthLoading
                ? SizedBox(
                    height: 3.w,
                    width: 3.w,
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh,
                        color: AppColors.primaryBlue,
                        size: 4.w,
                      ),
                      SizedBox(width: 1.5.w),
                      Flexible(
                        child: Text(
                          'Resend Email',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w500,
                            fontSize: 13.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        SizedBox(height: 1.5.h),
        Text(
          'Didn\'t receive the email? Check your spam folder or try resending.',
          style: TextStyle(
            fontSize: 13.sp,
            color: AppColors.textMedium,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5.w,
            height: 5.w,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textMedium,
                fontSize: 13.sp,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackToLoginButton() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Remember your password? ',
          style: TextStyle(
            color: AppColors.textMedium,
            fontSize: 13.sp,
          ),
        ),
        TextButton(
          onPressed: () {
            context.goNamed(RouteNames.login);
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Back to Login',
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 13.sp,
            ),
          ),
        ),
      ],
    );
  }
}
