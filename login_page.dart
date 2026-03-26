// lib/presentation/pages/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signIn(
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
    );
    final state = ref.read(authNotifierProvider);
    if (mounted && state.hasValue && state.value != null) {
      context.go(AppRoutes.home);
    } else if (mounted && state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error.toString())),
      );
    }
  }

  Future<void> _googleSignIn() async {
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    if (mounted) {
      final state = ref.read(authNotifierProvider);
      if (state.hasValue && state.value != null) {
        context.go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    _buildLogo(),
                    const SizedBox(height: 48),
                    _buildForm(isLoading),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Text('A7',
                style: TextStyle(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                  fontFamily: 'Rajdhani',
                )),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Cricket A7',
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 1,
            )),
        const SizedBox(height: 6),
        const Text('Professional Cricket Management',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            )),
      ],
    );
  }

  Widget _buildForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Sign In',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 4),
                const Text('Welcome back to Cricket A7',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    )),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Password too short';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showForgotPassword(),
                    child: const Text('Forgot Password?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textOnPrimary,
                          ),
                        )
                      : const Text('Sign In',
                          style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700,
                            color: AppColors.textOnPrimary,
                          )),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: isLoading ? null : _googleSignIn,
                  icon: const Icon(Icons.g_mobiledata, size: 22),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border),
                    foregroundColor: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account?",
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
              TextButton(
                onPressed: () => context.go(AppRoutes.register),
                child: const Text('Register',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Cricket A7 by A7 Studio\nasifnawazlashari',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                height: 1.5,
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showForgotPassword() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive a reset link.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(authNotifierProvider.notifier)
                  .sendPasswordReset(ctrl.text.trim());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset email sent!'),
                  ),
                );
              }
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }
}

// lib/presentation/pages/auth/register_page.dart
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  String _selectedRole = 'captain';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signUp(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      displayName: _nameCtrl.text.trim(),
      role: _selectedRole,
    );
    final state = ref.read(authNotifierProvider);
    if (mounted && state.hasValue && state.value != null) {
      context.go(AppRoutes.home);
    } else if (mounted && state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go(AppRoutes.login),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 8),
                    const Text('Create Account',
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                  ],
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.only(left: 52),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Join Cricket A7 as:',
                        style: TextStyle(
                          color: AppColors.textMuted, fontSize: 13,
                        )),
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Role selector
                        const Text('Select Your Role',
                            style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            )),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _RoleOption(
                              label: 'Organizer',
                              icon: Icons.emoji_events_outlined,
                              value: 'organizer',
                              selected: _selectedRole,
                              onTap: (v) => setState(() => _selectedRole = v),
                            ),
                            const SizedBox(width: 8),
                            _RoleOption(
                              label: 'Captain',
                              icon: Icons.sports_cricket_outlined,
                              value: 'captain',
                              selected: _selectedRole,
                              onTap: (v) => setState(() => _selectedRole = v),
                            ),
                            const SizedBox(width: 8),
                            _RoleOption(
                              label: 'Scorer',
                              icon: Icons.scoreboard_outlined,
                              value: 'scorer',
                              selected: _selectedRole,
                              onTap: (v) => setState(() => _selectedRole = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameCtrl,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outlined),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Name required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email required';
                            if (!v.contains('@')) return 'Invalid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 6) {
                              return 'Min 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscure,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: Icon(Icons.lock_outlined),
                          ),
                          validator: (v) {
                            if (v != _passCtrl.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textOnPrimary,
                                  ))
                              : const Text('Create Account',
                                  style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700,
                                    color: AppColors.textOnPrimary,
                                  )),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?',
                        style: TextStyle(color: AppColors.textMuted)),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('Sign In'),
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

class _RoleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String selected;
  final void Function(String) onTap;

  const _RoleOption({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.15)
                : AppColors.bgInput,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 22,
                  color: isSelected ? AppColors.primary : AppColors.textMuted),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textMuted,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
