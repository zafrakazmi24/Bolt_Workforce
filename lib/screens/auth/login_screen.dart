import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/firebase_seed_service.dart';
import '../../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final AuthController _auth = Get.find<AuthController>();
  bool _obscure = true;
  bool _remember = false;
  bool _seeding = false;

  final List<Map<String, String>> _demoAccounts = const [
    {'label': 'Super Admin', 'email': 'superadmin@test.com'},
    {'label': 'Admin', 'email': 'admin@test.com'},
    {'label': 'Manager', 'email': 'manager@test.com'},
    {'label': 'Employee', 'email': 'employee@test.com'},
    {'label': 'Guest', 'email': 'guest@test.com'},
    {'label': 'HR Admin', 'email': 'hradmin@test.com'},
    {'label': 'Payroll / Accounts', 'email': 'payroll@test.com'},
    {'label': 'Regional Manager', 'email': 'regional@test.com'},
    {'label': 'Department Manager', 'email': 'deptmanager@test.com'},
    {'label': 'Viewer / Auditor', 'email': 'auditor@test.com'},
  ];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _fillDemo(String email) {
    _emailCtrl.text = email;
    _passCtrl.text = '123456';
  }

  /// DEV ONLY: creates demo accounts, roles and master data in Firebase.
  Future<void> _seed() async {
    setState(() => _seeding = true);
    try {
      final msg = await FirebaseSeedService.run();
      Get.snackbar('Firebase setup', msg, snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(12), borderRadius: 12, duration: const Duration(seconds: 6));
    } catch (e) {
      Get.snackbar('Setup failed', '$e', backgroundColor: AppColors.danger, colorText: Colors.white,
          snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(12), borderRadius: 12,
          duration: const Duration(seconds: 8));
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<void> _forgot() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      Get.snackbar('Forgot password', 'Enter your email first', snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(12));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (_) {/* do not reveal whether the account exists */}
    Get.snackbar('Forgot password', 'If this email is registered, a reset link has been sent.',
        snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(12));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await _auth.login(
      _emailCtrl.text,
      _passCtrl.text,
      remember: _remember,
    );
    if (success) {
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      Get.snackbar(
        'Login Failed',
        _auth.errorMessage.value,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark, AppColors.secondary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 900 : 420),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: isWide
                      ? Row(
                          children: [
                            Expanded(child: _brandPanel()),
                            Expanded(child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: _formPanel(),
                            )),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.all(28),
                          child: _formPanel(),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brandPanel() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.shield_rounded, color: Colors.white, size: 56),
          SizedBox(height: 20),
          Text(
            'RBAC Employee\nManagement',
            style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.2),
          ),
          SizedBox(height: 14),
          Text(
            'Secure access based on roles & permissions.\nSuper Admin, Admin, HR Admin, Payroll / Accounts,\nRegional & Department Manager, Viewer / Auditor.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _formPanel() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Welcome back 👋',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Sign in to continue',
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            validator: Validators.password,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Checkbox(
                value: _remember,
                onChanged: (v) => setState(() => _remember = v ?? false),
              ),
              const Text('Remember Me', style: TextStyle(fontSize: 13)),
              const Spacer(),
              TextButton(onPressed: _forgot, child: const Text('Forgot password?', style: TextStyle(fontSize: 13))),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _auth.isLoading.value ? null : _submit,
                  child: _auth.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Login'),
                ),
              )),
          const SizedBox(height: 20),
          Text('Quick demo login',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _demoAccounts.map((acc) {
              return ActionChip(
                label: Text(
                  acc['label']!,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
                onPressed: () => _fillDemo(acc['email']!),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          Text('Password for all demo accounts: 123456',
              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          if (kDebugMode) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _seeding ? null : _seed,
              icon: _seeding
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_upload_outlined, size: 18),
              label: const Text('First-time setup: create demo data in Firebase'),
            ),
          ],
        ],
      ),
    );
  }
}
