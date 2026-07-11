import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/auth/entities/user_role.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/app_text_field.dart';
import '../auth_error_text.dart';
import '../auth_validators.dart';
import '../bloc/auth_bloc.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  UserRole _role = UserRole.customer;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthFormReset());
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthSignUpRequested(
              name: _name.text.trim(),
              email: _email.text,
              password: _password.text,
              role: _role,
              phone: _phone.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final v = AuthValidators(l10n);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authSignupTitle)),
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) => prev.form != curr.form,
          listener: (context, state) {
            if (state.form == FormStatus.failure && state.errorCode != null) {
              AppSnackBar.error(context, authErrorText(l10n, state.errorCode!));
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.roleQuestion, style: text.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _RoleCard(
                          icon: Icons.shopping_basket_outlined,
                          label: l10n.roleCustomer,
                          selected: _role == UserRole.customer,
                          onTap: () =>
                              setState(() => _role = UserRole.customer),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _RoleCard(
                          icon: Icons.storefront_outlined,
                          label: l10n.roleOwner,
                          selected: _role == UserRole.owner,
                          onTap: () => setState(() => _role = UserRole.owner),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _RoleCard(
                          icon: Icons.two_wheeler_outlined,
                          label: l10n.roleCourier,
                          selected: _role == UserRole.courier,
                          onTap: () =>
                              setState(() => _role = UserRole.courier),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.fieldName,
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    validator: v.required,
                    prefixIcon: Icons.person_outline,
                    autofillHints: const [AutofillHints.name],
                  ),
                  AppTextField(
                    label: l10n.fieldEmail,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: v.email,
                    prefixIcon: Icons.mail_outline,
                    autofillHints: const [AutofillHints.email],
                  ),
                  AppTextField(
                    label: l10n.fieldPhoneOptional,
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.phone_outlined,
                    autofillHints: const [AutofillHints.telephoneNumber],
                  ),
                  AppTextField(
                    label: l10n.fieldPassword,
                    controller: _password,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: v.password,
                    prefixIcon: Icons.lock_outline,
                    onFieldSubmitted: (_) => _submit(),
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BlocSelector<AuthBloc, AuthState, bool>(
                    selector: (state) => state.isSubmitting,
                    builder: (context, submitting) => AppButton(
                      label: l10n.actionSignup,
                      loading: submitting,
                      onPressed: _submit,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.haveAccountPrompt, style: text.bodyMedium),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: Text(l10n.actionLoginLink),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selectable role tile. Selection is shown by a mint border + tinted fill and
/// a check — never color alone (a label always names the role).
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = selected ? scheme.secondary : scheme.outline;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgAll,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: selected
              ? scheme.secondary.withValues(alpha: 0.10)
              : scheme.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 28,
                color: selected ? scheme.secondary : scheme.onSurface),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
