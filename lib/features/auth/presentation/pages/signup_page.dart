import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../store/auth_store.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _obscurePassword = true;
  late final AuthStore _authStore;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _authStore = sl<AuthStore>();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSignup() async {
    FocusScope.of(context).unfocus();

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final user = await _authStore.signup(
      name: name,
      email: email,
      password: password,
    );
    if (!mounted) return;

    if (user != null) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      final msg = _authStore.error ?? 'Signup failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1B4A), Color(0xFF1E3A8A), Color(0xFF3B5FD3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _authStore,
            builder: (context, _) {
              return Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight * 0.04),
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: _buildBrandingSection(),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: _buildFormCard(context),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  if (_authStore.loading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.25),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingSection() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Create Account',
          style: AppTextStyles.heading1.copyWith(
            color: Colors.white,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join us and start managing expenses',
          style: AppTextStyles.bodyRegular.copyWith(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full Name
          _buildFieldLabel('Full Name'),
          const SizedBox(height: 8),
          CustomTextField(
            hintText: 'Enter your full name',
            controller: _nameCtrl,
            prefixIcon: Icon(
              Icons.person_outline,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 18),
          // Email
          _buildFieldLabel('Email'),
          const SizedBox(height: 8),
          CustomTextField(
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            controller: _emailCtrl,
            prefixIcon: Icon(
              Icons.email_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 18),
          // Password
          _buildFieldLabel('Password'),
          const SizedBox(height: 8),
          CustomTextField(
            hintText: 'Create a password',
            isPassword: _obscurePassword,
            controller: _passwordCtrl,
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: AppColors.primary,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 24),
          // Sign Up button
          _buildGradientButton(
            'Create Account',
            _authStore.loading ? () {} : _onSignup,
          ),
          const SizedBox(height: 20),
          // Divider
          // Row(
          //   children: [
          //     Expanded(
          //       child: Divider(color: AppColors.border.withOpacity(0.5)),
          //     ),
          //     Padding(
          //       padding: const EdgeInsets.symmetric(horizontal: 16),
          //       child: Text(
          //         'or sign up with',
          //         style: AppTextStyles.caption.copyWith(
          //           color: AppColors.textMuted,
          //         ),
          //       ),
          //     ),
          //     Expanded(
          //       child: Divider(color: AppColors.border.withOpacity(0.5)),
          //     ),
          //   ],
          // ),
          const SizedBox(height: 16),
          // Google sign-up
          // _buildSocialButton(
          //   icon: Icons.g_mobiledata,
          //   text: 'Sign up with Google',
          //   onPressed: () {
          //     Navigator.pushReplacementNamed(context, AppRoutes.home);
          //   },
          // ),
          const SizedBox(height: 20),
          // Sign in link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: AppTextStyles.bodyRegular.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
                child: Text(
                  'Sign In',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onPressed) {
    return Material(
      borderRadius: BorderRadius.circular(14),
      elevation: 4,
      shadowColor: AppColors.primary.withOpacity(0.35),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF3B5FD3)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              text,
              style: AppTextStyles.button.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
