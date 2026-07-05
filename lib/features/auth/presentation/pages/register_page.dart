import 'package:flutter/material.dart';
import 'package:hru_atms/app/app_routes.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/auth/data/teacher_registration_repository.dart';
import 'package:hru_atms/shared/widgets/language_toggle_button.dart';

const _schoolLogoUrl =
    'https://res.cloudinary.com/dnrblpkal/image/upload/q_auto/f_auto/v1775536855/branding/k6obqtagifkszo8pehnd.png';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specializationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  late final TeacherRegistrationRepository _repository;
  late Future<List<RegistrationDepartment>> _departmentsFuture;

  int? _departmentId;
  bool _obscurePassword = true;
  bool _isSendingOtp = false;
  bool _isSubmitting = false;
  bool _otpSent = false;
  bool _isSubmitted = false;
  String? _message;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = TeacherRegistrationRepository();
    _departmentsFuture = _repository.departments();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _message = null;
        _errorMessage = context.tr(
          'Please enter a valid email before sending OTP.',
        );
      });
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _message = null;
      _errorMessage = null;
    });

    try {
      await _repository.sendEmailOtp(email);
      setState(() {
        _otpSent = true;
        _otpController.clear();
        _message = context.l10n.format('Verification code sent to {email}.', {
          'email': email,
        });
      });
    } on ApiException catch (error) {
      setState(() => _errorMessage = _messageFromApiException(error));
    } catch (_) {
      setState(
        () => _errorMessage = context.tr('Could not send verification code.'),
      );
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _message = null;
      _errorMessage = null;
    });

    try {
      await _repository.registerTeacher(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        emailOtp: _otpController.text,
        departmentId: _departmentId,
        specialization: _specializationController.text,
      );

      if (!mounted) return;
      setState(() {
        _isSubmitted = true;
        _message = null;
        _errorMessage = null;
      });
    } on ApiException catch (error) {
      setState(() => _errorMessage = _messageFromApiException(error));
    } catch (_) {
      setState(
        () => _errorMessage = context.tr('Registration failed. Try again.'),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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
                  constraints: const BoxConstraints(maxWidth: 460),
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
                    child: _isSubmitted
                        ? _PendingApprovalView(
                            email: _emailController.text.trim(),
                            onSignIn: () => Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRoutes.login),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _RegisterHeader(),
                              const SizedBox(height: 24),
                              _StudentNotice(),
                              const SizedBox(height: 16),
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextFormField(
                                      controller: _nameController,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        labelText: context.tr('Full name'),
                                        prefixIcon: Icon(Icons.person_outline),
                                      ),
                                      validator: _required,
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      onChanged: (_) {
                                        if (_otpSent) {
                                          setState(() {
                                            _otpSent = false;
                                            _otpController.clear();
                                            _message = null;
                                          });
                                        }
                                      },
                                      decoration: InputDecoration(
                                        labelText: context.tr('Email'),
                                        helperText: _otpSent
                                            ? context.tr(
                                                'OTP sent. Enter the 6-digit code below.',
                                              )
                                            : context.tr(
                                                'Send OTP to verify this email.',
                                              ),
                                        prefixIcon: Icon(Icons.email_outlined),
                                        suffixIcon: TextButton(
                                          onPressed: _isSendingOtp
                                              ? null
                                              : _sendOtp,
                                          child: Text(
                                            _isSendingOtp
                                                ? context.tr('Sending...')
                                                : _otpSent
                                                ? context.tr('Resend')
                                                : context.tr('Send code'),
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty ||
                                            !value.contains('@')) {
                                          return context.tr(
                                            'Please enter a valid email.',
                                          );
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _otpController,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        labelText: context.tr('Email OTP'),
                                        prefixIcon: Icon(
                                          Icons.verified_outlined,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().length != 6) {
                                          return context.tr(
                                            'Enter the 6-digit OTP.',
                                          );
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        labelText: context.tr('Phone'),
                                        prefixIcon: Icon(Icons.phone_outlined),
                                      ),
                                      validator: _required,
                                    ),
                                    const SizedBox(height: 14),
                                    FutureBuilder<List<RegistrationDepartment>>(
                                      future: _departmentsFuture,
                                      builder: (context, snapshot) {
                                        final departments =
                                            snapshot.data ?? const [];
                                        return DropdownButtonFormField<int>(
                                          initialValue: _departmentId,
                                          decoration: InputDecoration(
                                            labelText: context.tr('Department'),
                                            prefixIcon: Icon(
                                              Icons.account_tree_outlined,
                                            ),
                                          ),
                                          items: departments
                                              .map(
                                                (
                                                  department,
                                                ) => DropdownMenuItem<int>(
                                                  value: department.id,
                                                  child: Text(
                                                    department.code.isEmpty
                                                        ? department.name
                                                        : '${department.name} (${department.code})',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (value) => setState(
                                            () => _departmentId = value,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _specializationController,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        labelText: context.tr('Specialization'),
                                        prefixIcon: Icon(Icons.work_outline),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        labelText: context.tr('Password'),
                                        prefixIcon: Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.length < 8) {
                                          return context.tr(
                                            'Password must be at least 8 characters.',
                                          );
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _submit(),
                                      decoration: InputDecoration(
                                        labelText: context.tr(
                                          'Confirm password',
                                        ),
                                        prefixIcon: Icon(
                                          Icons.lock_reset_outlined,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value != _passwordController.text) {
                                          return context.tr(
                                            'Passwords do not match.',
                                          );
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    if (_message != null) ...[
                                      _InfoBanner(message: _message!),
                                      const SizedBox(height: 12),
                                    ],
                                    if (_errorMessage != null) ...[
                                      _ErrorBanner(message: _errorMessage!),
                                      const SizedBox(height: 12),
                                    ],
                                    SizedBox(
                                      height: 52,
                                      child: FilledButton(
                                        onPressed: _isSubmitting
                                            ? null
                                            : _submit,
                                        style: FilledButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            _isSubmitting
                                                ? const SizedBox.square(
                                                    dimension: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.how_to_reg_rounded,
                                                  ),
                                            const SizedBox(width: 10),
                                            Flexible(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  _isSubmitting
                                                      ? context.tr(
                                                          'Submitting...',
                                                        )
                                                      : context.tr(
                                                          'Send request for approval',
                                                        ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  spacing: 4,
                                  runSpacing: 2,
                                  children: [
                                    Text(
                                      context.tr('Already approved?'),
                                      style: TextStyle(
                                        color: AppColors.bodyText,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => Navigator.of(
                                        context,
                                      ).pushReplacementNamed(AppRoutes.login),
                                      icon: const Icon(
                                        Icons.login_rounded,
                                        size: 18,
                                      ),
                                      label: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          context.tr('Back to sign in'),
                                          maxLines: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('This field is required.');
    }
    return null;
  }

  String _messageFromApiException(ApiException error) {
    for (final messages in error.errors.values) {
      if (messages.isNotEmpty) return messages.first;
    }
    return error.message;
  }
}

class _PendingApprovalView extends StatelessWidget {
  const _PendingApprovalView({required this.email, required this.onSignIn});

  final String email;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _RegisterHeader(),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  color: AppColors.green,
                  size: 34,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.tr('Request sent for approval'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.format(
                  'Your teacher account request for {email} is waiting for HRU admin approval. You can sign in after the account is approved.',
                  {'email': email},
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 14.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: onSignIn,
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
                Icon(Icons.login_rounded),
                const SizedBox(width: 10),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      context.tr('Back to sign in'),
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
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
          context.tr('Teacher Account Registration'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          context.tr('Request teacher access'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          context.tr('Verify your email with OTP before submitting.'),
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.mutedText, fontSize: 14.5),
        ),
      ],
    );
  }
}

class _StudentNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandTeal.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.school_outlined, color: AppColors.brandTeal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr(
                'Students do not register here. Students sign in using email and student code from HRU records.',
              ),
              style: TextStyle(
                color: AppColors.bodyText,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: AppColors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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
