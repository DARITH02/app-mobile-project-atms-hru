import 'package:flutter/material.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/core/network/api_config.dart';
import 'package:hru_atms/features/profile/data/student_profile_repository.dart';
import 'package:hru_atms/shared/widgets/app_loading_screen.dart';
import 'package:hru_atms/shared/widgets/fixed_menu_page_slide.dart';
import 'package:hru_atms/shared/widgets/student_bottom_navigation.dart';
import 'package:image_picker/image_picker.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  late final StudentProfileRepository _repository;
  late Future<StudentProfile> _profileFuture;
  final _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _repository = StudentProfileRepository();
    _profileFuture = _repository.fetchProfile();
  }

  Future<void> _refresh() async {
    final future = _repository.fetchProfile();
    setState(() => _profileFuture = future);
    await future;
  }

  Future<void> _changePhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 88,
    );
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      await _repository.uploadProfilePhoto(image);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Profile photo updated.'))),
      );
      await _refresh();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Could not update profile photo.'))),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('Profile')),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: Icon(Icons.refresh_rounded),
            tooltip: context.tr('Refresh profile'),
          ),
        ],
      ),
      body: FixedMenuPageSlide(
        child: SafeArea(
          child: FutureBuilder<StudentProfile>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingScreen();
              }
              if (snapshot.hasError || snapshot.data == null) {
                return _ProfileError(onRetry: _refresh);
              }

              return _ProfileContent(
                profile: snapshot.data!,
                isUploading: _isUploading,
                onChangePhoto: _changePhoto,
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const StudentBottomNavigationForRole(
        current: StudentNavDestination.profile,
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.isUploading,
    required this.onChangePhoto,
  });

  final StudentProfile profile;
  final bool isUploading;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final student = profile.student;
    final teacher = profile.teacher;
    final photoUrl = _resolveImageUrl(
      profile.profilePhotoUrl.isNotEmpty
          ? profile.profilePhotoUrl
          : student?.profilePhotoUrl ?? '',
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        _ProfileHeader(
          name: profile.name,
          code: student?.studentCode ?? teacher?.teacherCode ?? profile.role,
          photoUrl: photoUrl,
          isUploading: isUploading,
          onChangePhoto: onChangePhoto,
        ),
        const SizedBox(height: 16),
        _InfoPanel(
          title: context.tr('Account'),
          children: [
            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: context.tr('Full name'),
              value: profile.name,
            ),
            _InfoRow(
              icon: Icons.email_outlined,
              label: context.tr('Email'),
              value: profile.email,
            ),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: context.tr('Phone'),
              value: profile.phone,
            ),
            _InfoRow(
              icon: Icons.verified_user_outlined,
              label: context.tr('Role'),
              value: profile.role,
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (teacher != null)
          _InfoPanel(
            title: context.tr('Teacher information'),
            children: [
              _InfoRow(
                icon: Icons.badge_outlined,
                label: context.tr('Teacher code'),
                value: teacher.teacherCode,
              ),
              _InfoRow(
                icon: Icons.account_tree_outlined,
                label: context.tr('Department'),
                value: teacher.department,
              ),
              _InfoRow(
                icon: Icons.work_outline_rounded,
                label: context.tr('Specialization'),
                value: teacher.specialization,
              ),
              _InfoRow(
                icon: Icons.info_outline_rounded,
                label: context.tr('Status'),
                value: teacher.status,
              ),
            ],
          )
        else
          _InfoPanel(
            title: context.tr('Student information'),
            children: [
              _InfoRow(
                icon: Icons.badge_outlined,
                label: context.tr('Student code'),
                value: student?.studentCode ?? 'N/A',
              ),
              _InfoRow(
                icon: Icons.groups_outlined,
                label: context.tr('Group'),
                value: student?.group ?? 'N/A',
              ),
              _InfoRow(
                icon: Icons.school_outlined,
                label: context.tr('Major'),
                value: student?.major ?? 'N/A',
              ),
              _InfoRow(
                icon: Icons.account_tree_outlined,
                label: context.tr('Department'),
                value: student?.department ?? 'N/A',
              ),
              _InfoRow(
                icon: Icons.timeline_outlined,
                label: context.tr('Year level'),
                value: student?.yearLevel ?? 'N/A',
              ),
              _InfoRow(
                icon: Icons.info_outline_rounded,
                label: context.tr('Status'),
                value: student?.status ?? 'N/A',
              ),
            ],
          ),
        const SizedBox(height: 14),
        const _LockedNotice(),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.code,
    required this.photoUrl,
    required this.isUploading,
    required this.onChangePhoto,
  });

  final String name;
  final String code;
  final String photoUrl;
  final bool isUploading;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.brandBlue,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24145DA0),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: AppColors.surface,
                backgroundImage: photoUrl.isEmpty
                    ? null
                    : NetworkImage(photoUrl),
                child: photoUrl.isEmpty
                    ? Text(
                        _initials(name),
                        style: TextStyle(
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: IconButton.filled(
                  onPressed: isUploading ? null : onChangePhoto,
                  icon: isUploading
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.photo_camera_outlined, size: 18),
                  tooltip: context.tr('Change profile photo'),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.brandBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xDDEAF4FF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          for (final child in children) ...[
            child,
            if (child != children.last) const Divider(height: 18),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.brandBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.brandBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? 'N/A' : value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.lock_outline_rounded, color: AppColors.mutedText, size: 16),
      ],
    );
  }
}

class _LockedNotice extends StatelessWidget {
  const _LockedNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brandTeal.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: AppColors.brandTeal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr(
                'Profile details are read-only. Contact student support to correct your information.',
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

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_outlined,
              color: AppColors.mutedText,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('Could not load profile'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('Check your connection and try again.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded),
              label: Text(context.tr('Retry')),
            ),
          ],
        ),
      ),
    );
  }
}

String _resolveImageUrl(String value) {
  return ApiConfig.resolveUrl(value);
}

String _initials(String value) {
  final parts = value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final letters = parts.take(2).map((p) => p.characters.first).join();
  return letters.isEmpty ? 'SV' : letters.toUpperCase();
}
