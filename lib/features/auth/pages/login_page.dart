import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/branding/controllers/branding_controller.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 760) {
            return _WideLoginLayout(constraints: constraints);
          }
          return const _NarrowLoginLayout();
        },
      ),
    );
  }
}

// ── Wide (desktop/tablet landscape): split pane ──────────────────────────────

class _WideLoginLayout extends StatelessWidget {
  const _WideLoginLayout({required this.constraints});
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        // Left brand panel — 42 % of width
        SizedBox(
          width: constraints.maxWidth * 0.42,
          child: _BrandPanel(c: c),
        ),
        // Right form panel
        Expanded(
          child: Container(
            color: c.background,
            alignment: Alignment.center,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xxl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: const _LoginForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Narrow (mobile / narrow browser): stacked ────────────────────────────────

class _NarrowLoginLayout extends StatelessWidget {
  const _NarrowLoginLayout();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      color: c.background,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Compact brand mark strip
            Container(
              width: double.infinity,
              color: c.sidebar,
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.xl,
                horizontal: AppSpacing.lg,
              ),
              child: _NarrowBrandMark(c: c),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: const _LoginForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Brand panel (wide left side) ──────────────────────────────────────────────

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.c});
  final AppPalette c;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: c.sidebar,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gold accent bar — editorial brand marker
          Container(
            width: AppSpacing.xl + AppSpacing.md,
            height: 2,
            color: AppColors.light.secondary,
          ),
          const SizedBox(height: AppSpacing.lg),
          GetBuilder<BrandingController>(
            builder: (branding) => Text(
              branding.draft.brandName,
              style: AppTextStyles.h1.copyWith(
                color: c.onSidebar,
                letterSpacing: 5,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'ADMIN DASHBOARD',
            style: AppTextStyles.overline.copyWith(
              color: AppColors.light.secondary,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'لوحة إدارة المتجر',
            style: AppTextStyles.body2.copyWith(
              color: c.onSidebar.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Narrow brand mark (compact strip) ────────────────────────────────────────

class _NarrowBrandMark extends StatelessWidget {
  const _NarrowBrandMark({required this.c});
  final AppPalette c;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BrandingController>(
      builder: (branding) => Row(
        children: [
          Container(width: 3, height: AppSpacing.xl, color: AppColors.light.secondary),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                branding.draft.brandName,
                style: AppTextStyles.h4.copyWith(
                  color: c.onSidebar,
                  letterSpacing: 4,
                ),
              ),
              Text(
                'ADMIN',
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.light.secondary,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Login form (shared between both layouts) ──────────────────────────────────

class _LoginForm extends StatelessWidget {
  const _LoginForm();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: GetBuilder<AuthController>(
        builder: (controller) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('تسجيل الدخول', style: AppTextStyles.h3.copyWith(color: c.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'ادخل بحساب الأدمن لإدارة المتجر',
              style: AppTextStyles.body2.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'البريد الإلكتروني',
              controller: controller.emailController,
              icon: AppIcons.email,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'كلمة المرور',
              controller: controller.passwordController,
              icon: AppIcons.lock,
              obscureText: true,
              textDirection: TextDirection.ltr,
              onSubmitted: (_) => controller.signIn(),
            ),
            if (controller.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 4),
                decoration: BoxDecoration(
                  color: c.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  controller.errorMessage!,
                  style: AppTextStyles.body2.copyWith(color: c.error),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'دخول',
              expanded: true,
              isLoading: controller.isLoading,
              onPressed: controller.signIn,
            ),
          ],
        ),
      ),
    );
  }
}
