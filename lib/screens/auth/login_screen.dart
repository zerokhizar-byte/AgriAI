import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/common/app_text_field.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    super.key,
    this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.instance.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _handleLoginSuccess();
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showAuthError(
        _firebaseErrorMessage(e),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showAuthError(
        'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      await AuthService.instance.signInWithGoogle();

      if (!mounted) {
        return;
      }

      setState(() {
        _isGoogleLoading = false;
      });

      _handleLoginSuccess();
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isGoogleLoading = false;
      });

      _showAuthError(
        _firebaseErrorMessage(e),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isGoogleLoading = false;
      });

      final String message = e.toString().toLowerCase();

      if (message.contains('cancel')) {
        return;
      }

      _showAuthError(
        'Google sign-in failed. Please try again.',
      );
    }
  }

  Future<void> _loginWithFacebook() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isFacebookLoading = true;
    });

    try {
      final LoginResult result =
          await FacebookAuth.instance.login(
        permissions: const [
          'email',
          'public_profile',
        ],
      );

      if (result.status == LoginStatus.cancelled) {
        if (mounted) {
          setState(() {
            _isFacebookLoading = false;
          });
        }
        return;
      }

      if (result.status != LoginStatus.success ||
          result.accessToken == null) {
        if (mounted) {
          setState(() {
            _isFacebookLoading = false;
          });
        }

        _showAuthError(
          result.message ??
              'Facebook sign-in could not be completed.',
        );
        return;
      }

      final OAuthCredential credential =
          FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isFacebookLoading = false;
      });

      _handleLoginSuccess();
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isFacebookLoading = false;
      });

      _showAuthError(
        _firebaseErrorMessage(e),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isFacebookLoading = false;
      });

      final String message = e.toString().toLowerCase();

      if (message.contains('cancel')) {
        return;
      }

      _showAuthError(
        'Facebook sign-in failed. Please try again.',
      );
    }
  }

  void _handleLoginSuccess() {
    widget.onLoginSuccess?.call();

    if (widget.onLoginSuccess == null && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const HomeScreen(),
        ),
        (route) => false,
      );
    }
  }

  String _firebaseErrorMessage(
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';

      default:
        return error.message ??
            'Unable to sign in. Please try again.';
    }
  }

  void _showAuthError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _RegisterPlaceholder(),
      ),
    );
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _ForgotPasswordPlaceholder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool anyLoading =
        _isLoading ||
        _isGoogleLoading ||
        _isFacebookLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              24,
              35,
              24,
              30,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: AppLogo(
                    size: 82,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Welcome back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Sign in to continue using AgriAI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
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
                      TextInputAction.next,
                  prefixIcon: Icons.email_outlined,
                  validator: _validateEmail,
                ),

                const SizedBox(height: 16),

                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  obscureText: _obscurePassword,
                  textInputAction:
                      TextInputAction.done,
                  prefixIcon:
                      Icons.lock_outline_rounded,
                  suffixIcon: _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  onSuffixIconPressed: () {
                    setState(() {
                      _obscurePassword =
                          !_obscurePassword;
                    });
                  },
                  validator: _validatePassword,
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: anyLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _rememberMe =
                                      value ?? false;
                                });
                              },
                        activeColor:
                            AppColors.primary,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(5),
                        ),
                      ),
                    ),

                    const SizedBox(width: 7),

                    const Text(
                      'Remember me',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),

                    const Spacer(),

                    TextButton(
                      onPressed: anyLoading
                          ? null
                          : _openForgotPassword,
                      style:
                          TextButton.styleFrom(
                        foregroundColor:
                            AppColors.primary,
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        anyLoading ? null : _login,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(
                        alpha: 0.55,
                      ),
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15),
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
                                'email_loading',
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
                                'email_login',
                              ),
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.login_rounded,
                                  size: 19,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Sign In',
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

                const SizedBox(height: 25),

                Row(
                  children: [
                    const Expanded(
                      child: Divider(
                        color: AppColors.border,
                      ),
                    ),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color:
                              AppColors.textMuted,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(
                        color: AppColors.border,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // GOOGLE LOGIN
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: anyLoading
                        ? null
                        : _loginWithGoogle,
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          AppColors.textPrimary,
                      backgroundColor: Colors.white,
                      side: const BorderSide(
                        color: AppColors.border,
                        width: 1,
                      ),
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration:
                          const Duration(
                        milliseconds: 180,
                      ),
                      child: _isGoogleLoading
                          ? const SizedBox(
                              key: ValueKey(
                                'google_loading',
                              ),
                              width: 21,
                              height: 21,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.3,
                                color:
                                    AppColors.primary,
                              ),
                            )
                          : const Row(
                              key: ValueKey(
                                'google_button',
                              ),
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Center(
                                    child: Text(
                                      'G',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight.w900,
                                        color:
                                            Color(
                                          0xFF4285F4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // FACEBOOK LOGIN
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: anyLoading
                        ? null
                        : _loginWithFacebook,
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          AppColors.textPrimary,
                      backgroundColor: Colors.white,
                      side: const BorderSide(
                        color: AppColors.border,
                        width: 1,
                      ),
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration:
                          const Duration(
                        milliseconds: 180,
                      ),
                      child: _isFacebookLoading
                          ? const SizedBox(
                              key: ValueKey(
                                'facebook_loading',
                              ),
                              width: 21,
                              height: 21,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.3,
                                color:
                                    AppColors.primary,
                              ),
                            )
                          : const Row(
                              key: ValueKey(
                                'facebook_button',
                              ),
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Center(
                                    child: Text(
                                      'f',
                                      style: TextStyle(
                                        fontSize: 23,
                                        fontWeight:
                                            FontWeight.w900,
                                        color:
                                            Color(
                                          0xFF1877F2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Continue with Facebook',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                const Text(
                  'New to AgriAI?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 7),

                TextButton(
                  onPressed:
                      anyLoading ? null : _openRegister,
                  style: TextButton.styleFrom(
                    foregroundColor:
                        AppColors.primary,
                  ),
                  child: const Text(
                    'Create an account',
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

class _RegisterPlaceholder
    extends StatelessWidget {
  const _RegisterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: const Center(
        child: Text(
          'Register screen will be connected next.',
        ),
      ),
    );
  }
}

class _ForgotPasswordPlaceholder
    extends StatelessWidget {
  const _ForgotPasswordPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: const Center(
        child: Text(
          'Forgot password screen will be connected next.',
        ),
      ),
    );
  }
}