import 'package:flutter/material.dart';
import 'package:hru_atms/app/app_routes.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/auth/data/auth_repository.dart';
import 'package:hru_atms/shared/widgets/language_toggle_button.dart';
import 'package:hru_atms/shared/widgets/maintenance_page.dart';

const _schoolLogoUrl =
    'https://res.cloudinary.com/dnrblpkal/image/upload/q_auto/f_auto/v1775536855/branding/k6obqtagifkszo8pehnd.png';

class LoginPage extends StatefulWidget {
  const LoginPage({required this.authRepository, super.key});

  final AuthRepository authRepository;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _studentCodeController = TextEditingController();

  String _role = 'student';
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _studentCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.authRepository.login(
        login: _loginController.text.trim(),
        password: _role == 'teacher' ? _passwordController.text : null,
        role: _role,
        studentCode: _role == 'student' ? _studentCodeController.text : null,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    } on ApiException catch (error) {
      if (error.statusCode == 503 && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => MaintenancePage(
              message: error.message,
              onRetry: () async => Navigator.of(context).pop(),
            ),
          ),
        );
      }
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() {
        _errorMessage = context.tr(
          'Could not connect to the HRU API. Check the backend server URL.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String get _loginLabel {
    if (_role == 'teacher') {
      return context.tr('Email, phone, or teacher code');
    }

    return context.tr('Email or phone');
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthHeader(
            title: context.tr('Welcome back'),
            subtitle: context.tr('Sign in with your HRU account to continue.'),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RoleSelector(
                  selectedRole: _role,
                  onChanged: (value) => setState(() => _role = value),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _loginController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: _loginLabel,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return _role == 'student'
                          ? context.tr('Please enter your email or phone.')
                          : context.tr('Please enter your login identifier.');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                if (_role == 'student') ...[
                  TextFormField(
                    controller: _studentCodeController,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: context.tr('Student code'),
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.tr('Please enter your student code.');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                ],
                if (_role == 'teacher') ...[
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: context.tr('Password'),
                      prefixIcon: Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        tooltip: _obscurePassword
                            ? context.tr('Show password')
                            : context.tr('Hide password'),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('Please enter your password.');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 10),
                if (_errorMessage != null) ...[
                  _ErrorBanner(message: _errorMessage!),
                  const SizedBox(height: 14),
                ],
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _isSubmitting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login_rounded),
                        const SizedBox(width: 10),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _isSubmitting
                                  ? context.tr('Signing in...')
                                  : context.tr('Continue to dashboard'),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 2,
              children: [
                Text(
                  context.tr('Teacher account?'),
                  style: TextStyle(
                    color: AppColors.bodyText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.register),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      context.tr('Request teacher access'),
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${context.tr('Developed by')}: ${"Darith | @HRU"}',
            // '${context.tr('API')}: ${ApiConfig.baseUrl}',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(14),
                child: LanguageToggleButton(),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.isDark
                              ? Colors.black.withValues(alpha: 0.28)
                              : const Color(0x14145DA0),
                          blurRadius: 22,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 70,
          height: 70,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F145DA0),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Image.network(
            _schoolLogoUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Text(
                'HRU',
                style: TextStyle(
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          context.tr('HRU University'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.brandBlue,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          context.tr('Student Attendance Management System'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.mutedText, fontSize: 14.5),
        ),
      ],
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.selectedRole, required this.onChanged});

  final String selectedRole;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(
          value: 'student',
          icon: Icon(Icons.school_outlined),
          label: Text(context.tr('Student')),
        ),
        ButtonSegment(
          value: 'teacher',
          icon: Icon(Icons.co_present_outlined),
          label: Text(context.tr('Teacher')),
        ),
      ],
      selected: {selectedRole},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.rose.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.rose.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.rose),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.rose,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
