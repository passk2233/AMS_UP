import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utilities/assets.dart';
import '../../../widgets/widget.dart';
import '../controllers/auth_controller.dart';

/// Sign-in screen — the app's launch destination.
///
/// All form state lives in [AuthController]; this view only composes the
/// background, scroll constraints, and a [_LoginForm].
class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  /// Maximum width the form is allowed to occupy on tablets / desktop web.
  static const double _maxFormWidth = 400;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AssetImages.login1),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = constraints.maxWidth > 500
                  ? (constraints.maxWidth - _maxFormWidth) / 2
                  : AppSpacing.l;
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontal,
                  vertical: AppSpacing.xl,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - (AppSpacing.xl * 2),
                  ),
                  child: const IntrinsicHeight(child: _LoginForm()),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Vertical stack of header, fields, remember-me row, primary button, and
/// footer caption.
class _LoginForm extends GetView<AuthController> {
  const _LoginForm();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.xl),
        const _LoginHeader(),
        const SizedBox(height: AppSpacing.xl),
        _UsernameField(controller: controller),
        const SizedBox(height: AppSpacing.m),
        _PasswordField(controller: controller),
        const SizedBox(height: AppSpacing.xs),
        _RememberMeRow(controller: controller),
        const SizedBox(height: AppSpacing.l),
        _SubmitButton(controller: controller),
        const SizedBox(height: AppSpacing.l),
        const _FooterCaption(),
        const SizedBox(height: AppSpacing.m),
      ],
    );
  }
}

/// "ຍິນດີຕ້ອນຮັບ\nCEIT AMS" + subtitle.
class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ຍິນດີຕ້ອນຮັບ\nCEIT AMS',
          textAlign: TextAlign.center,
          style: AppTypography.title.copyWith(fontSize: 28, height: 1.25),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          'ກະລຸນາເຂົ້າສູ່ລະບົບເພື່ອສືບຕໍ່',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmallMuted,
        ),
      ],
    );
  }
}

/// Username [AppTextField] wired to the controller.
class _UsernameField extends StatelessWidget {
  /// Source controller.
  final AuthController controller;

  const _UsernameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'ຊື່ຜູ້ໃຊ້',
      hint: 'ກະລຸນາໃສ່ຊື່ຜູ້ໃຊ້',
      controller: controller.usernameController,
      prefixIcon: Icons.person_outline_rounded,
      textInputAction: TextInputAction.next,
      required: true,
    );
  }
}

/// Password [AppTextField] with a trailing show/hide eye icon.
class _PasswordField extends StatelessWidget {
  /// Source controller.
  final AuthController controller;

  const _PasswordField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AppTextField(
        label: 'ລະຫັດຜ່ານ',
        hint: 'ກະລຸນາໃສ່ລະຫັດຜ່ານ',
        controller: controller.passwordController,
        prefixIcon: Icons.lock_outline_rounded,
        obscureText: controller.isObscured.value,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) =>
            controller.isLoading.value ? null : controller.login(),
        required: true,
        suffix: _ObscureToggle(controller: controller),
      ),
    );
  }
}

/// Eye toggle that flips [AuthController.isObscured].
class _ObscureToggle extends StatelessWidget {
  /// Source controller.
  final AuthController controller;

  const _ObscureToggle({required this.controller});

  @override
  Widget build(BuildContext context) {
    final obscured = controller.isObscured.value;
    return SizedBox(
      width: AppColors.minTouchTarget,
      height: AppColors.minTouchTarget,
      child: IconButton(
        icon: Icon(
          obscured
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppColors.textSecondary,
        ),
        tooltip: obscured ? 'ສະແດງ' : 'ປິດບັງ',
        onPressed: controller.toggleObscured,
      ),
    );
  }
}

/// Right-aligned "remember me" checkbox + label.
class _RememberMeRow extends StatelessWidget {
  /// Source controller.
  final AuthController controller;

  const _RememberMeRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: AppColors.minTouchTarget,
            height: AppColors.minTouchTarget,
            child: Checkbox(
              value: controller.rememberMe.value,
              onChanged: controller.toggleRememberMe,
              activeColor: AppColors.primary,
              side: const BorderSide(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text('ຈົດຈຳຂ້ອຍ', style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}

/// Primary "Sign in" button bound to [AuthController.login].
class _SubmitButton extends StatelessWidget {
  /// Source controller.
  final AuthController controller;

  const _SubmitButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AppPrimaryButton(
        label: 'ເຂົ້າສູ່ລະບົບ',
        icon: Icons.login_rounded,
        isLoading: controller.isLoading.value,
        onPressed: controller.login,
      ),
    );
  }
}

/// Brand caption at the bottom of the form.
class _FooterCaption extends StatelessWidget {
  const _FooterCaption();

  @override
  Widget build(BuildContext context) {
    return Text(
      'CEIT · Academic Management System',
      textAlign: TextAlign.center,
      style: AppTypography.caption,
    );
  }
}
