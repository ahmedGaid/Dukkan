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

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthFormReset());
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context
          .read<AuthBloc>()
          .add(AuthPasswordResetRequested(_email.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final v = AuthValidators(l10n);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.forgotTitle)),
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) => prev.form != curr.form,
          listener: (context, state) {
            if (state.form == FormStatus.success) {
              AppSnackBar.success(context, l10n.resetSent);
              context.pop();
            } else if (state.form == FormStatus.failure &&
                state.errorCode != null) {
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
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.forgotSubtitle, style: text.bodyLarge),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.fieldEmail,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: v.email,
                    prefixIcon: Icons.mail_outline,
                    onFieldSubmitted: (_) => _submit(),
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BlocSelector<AuthBloc, AuthState, bool>(
                    selector: (state) => state.isSubmitting,
                    builder: (context, submitting) => AppButton(
                      label: l10n.actionSendReset,
                      loading: submitting,
                      onPressed: _submit,
                    ),
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
