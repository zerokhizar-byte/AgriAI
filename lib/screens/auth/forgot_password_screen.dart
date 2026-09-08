import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/common/app_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
  });

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _emailController =
      TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email is required';
    }

    final RegExp emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final String email =
        _emailController.text.trim();

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _emailSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset link sent successfully',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      String message;

      switch (e.code) {
        case 'invalid-email':
          message = 'Enter a valid email address.';
          break;

        case 'user-not-found':
          message =
              'No account was found with this email address.';
          break;

        case 'network-request-failed':
          message =
              'Check your internet connection and try again.';
          break;

        case 'too-many-requests':
          message =
              'Too many attempts. Please try again later.';
          break;

        case 'operation-not-allowed':
          message =
              'Email/password authentication is not enabled.';
          break;

        default:
          message =
              e.message ??
              'Unable to send the reset link. Please try again.';
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _backToLogin() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed:
              _isLoading ? null : _backToLogin,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
          color: AppColors.textPrimary,
        ),
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              24,
              30,
              24,
              30,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: AppLogo(
                    size: 78,
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  'Reset your password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _emailSent
                      ? 'Check your email for instructions to reset your password.'
                      : 'Enter the email address linked to your AgriAI account.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 32),

                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  keyboardType:
                      TextInputType.emailAddress,
                  textInputAction:
                      TextInputAction.done,
                  prefixIcon:
                      Icons.email_outlined,
                  enabled: !_emailSent,
                  validator: _validateEmail,
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _sendResetLink,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.primary,
                      foregroundColor:
                          Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary
                              .withValues(
                        alpha: 0.55,
                      ),
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration:
                          const Duration(
                        milliseconds: 180,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              key: ValueKey(
                                'loading',
                              ),
                              width: 21,
                              height: 21,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _emailSent
                                  ? 'Send Again'
                                  : 'Send Reset Link',
                              key: ValueKey(
                                _emailSent
                                    ? 'again'
                                    : 'send',
                              ),
                              style:
                                  const TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (_emailSent)
                  Container(
                    padding:
                        const EdgeInsets.all(16),
                    decoration:
                        BoxDecoration(
                      color: AppColors.primary
                          .withValues(
                        alpha: 0.08,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                      border: Border.all(
                        color: AppColors.primary
                            .withValues(
                          alpha: 0.18,
                        ),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons
                              .check_circle_outline_rounded,
                          color:
                              AppColors.primary,
                          size: 22,
                        ),
                        SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            'A password reset link has been sent to your email address. Please check your inbox and spam folder.',
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.45,
                              fontWeight:
                                  FontWeight.w600,
                              color: AppColors
                                  .textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 22),

                TextButton(
                  onPressed:
                      _isLoading
                          ? null
                          : _backToLogin,
                  style:
                      TextButton.styleFrom(
                    foregroundColor:
                        AppColors.primary,
                  ),
                  child: const Text(
                    'Back to Sign In',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}