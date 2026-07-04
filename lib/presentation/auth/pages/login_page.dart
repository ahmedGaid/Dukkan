import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/app_text_field.dart';
import '../auth_error_text.dart';
import '../auth_validators.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthFormReset());
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: _email.text,
              password: _password.text,
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
                  const SizedBox(height: AppSpacing.xl),
                  Image.asset('assets/brand/logo-light.png', height: 72),
                  const SizedBox(height: AppSpacing.xl),
                  Text(l10n.authWelcomeTitle,
                      style: text.titleLarge, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.authLoginSubtitle,
                      style: text.bodyMedium, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xl),
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
                    label: l10n.fieldPassword,
                    controller: _password,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: v.required,
                    prefixIcon: Icons.lock_outline,
                    onFieldSubmitted: (_) => _submit(),
                    autofillHints: const [AutofillHints.password],
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: () => context.push('/forgot'),
                      child: Text(l10n.actionForgot),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BlocSelector<AuthBloc, AuthState, bool>(
                    selector: (state) => state.isSubmitting,
                    builder: (context, submitting) => AppButton(
                      label: l10n.actionLogin,
                      loading: submitting,
                      onPressed: _submit,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.noAccountPrompt, style: text.bodyMedium),
                      TextButton(
                        onPressed: () => context.push('/signup'),
                        child: Text(l10n.actionSignupLink),
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
