import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/common/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback? onRegisterSuccess;

  const RegisterScreen({
    super.key,
    this.onRegisterSuccess,
  });

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController
      _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final String name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Full name is required';
    }

    if (name.length < 2) {
      return 'Enter a valid name';
    }

    return null;
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

  String? _validatePassword(String? value) {
    final String password = value ?? '';

    if (password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 6) {
      return 'Password must contain at least 6 characters';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final String confirmPassword = value ?? '';

    if (confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }

    if (confirmPassword !=
        _passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please accept the terms and conditions',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 900),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    widget.onRegisterSuccess?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Account created successfully',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _goBackToLogin() {
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
          onPressed: _isLoading
              ? null
              : _goBackToLogin,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
          color: AppColors.textPrimary,
        ),
        title: const Text(
          'Create Account',
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
              10,
              24,
              30,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: AppLogo(
                    size: 72,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Join AgriAI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Create your farmer account to get started',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 28),

                AppTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  keyboardType:
                      TextInputType.name,
                  textInputAction:
                      TextInputAction.next,
                  prefixIcon:
                      Icons.person_outline_rounded,
                  validator: _validateName,
                ),

                const SizedBox(height: 15),

                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  keyboardType:
                      TextInputType.emailAddress,
                  textInputAction:
                      TextInputAction.next,
                  prefixIcon:
                      Icons.email_outlined,
                  validator: _validateEmail,
                ),

                const SizedBox(height: 15),

                AppTextField(
                  controller:
                      _passwordController,
                  label: 'Password',
                  hint: 'Create a password',
                  obscureText:
                      _obscurePassword,
                  textInputAction:
                      TextInputAction.next,
                  prefixIcon:
                      Icons.lock_outline_rounded,
                  suffixIcon:
                      _obscurePassword
                          ? Icons
                              .visibility_outlined
                          : Icons
                              .visibility_off_outlined,
                  onSuffixIconPressed: () {
                    setState(() {
                      _obscurePassword =
                          !_obscurePassword;
                    });
                  },
                  validator:
                      _validatePassword,
                ),

                const SizedBox(height: 15),

                AppTextField(
                  controller:
                      _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  obscureText:
                      _obscureConfirmPassword,
                  textInputAction:
                      TextInputAction.done,
                  prefixIcon:
                      Icons.lock_reset_outlined,
                  suffixIcon:
                      _obscureConfirmPassword
                          ? Icons
                              .visibility_outlined
                          : Icons
                              .visibility_off_outlined,
                  onSuffixIconPressed: () {
                    setState(() {
                      _obscureConfirmPassword =
                          !_obscureConfirmPassword;
                    });
                  },
                  validator:
                      _validateConfirmPassword,
                ),

                const SizedBox(height: 15),

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _acceptTerms,
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _acceptTerms =
                                      value ??
                                          false;
                                });
                              },
                        activeColor:
                            AppColors.primary,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Padding(
                        padding:
                            EdgeInsets.only(
                          top: 2,
                        ),
                        child: Text(
                          'I agree to the Terms and Conditions and Privacy Policy.',
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.4,
                            fontWeight:
                                FontWeight.w500,
                            color: AppColors
                                .textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _register,
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
                          : const Row(
                              key: ValueKey(
                                'register',
                              ),
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                Icon(
                                  Icons
                                      .person_add_alt_1_rounded,
                                  size: 19,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w500,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : _goBackToLogin,
                      style:
                          TextButton.styleFrom(
                        foregroundColor:
                            AppColors.primary,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 6,
                        ),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w800,
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
    );
  }
}