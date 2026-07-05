import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/auth/entities/user_role.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../shell/home_shell.dart';
import '../../shell/owner_home_shell.dart';

/// Post-auth landing, split by role: a customer gets the marketplace shell
/// (C2a); an owner gets their own two-tab shell — catalog manager (S2) +
/// order desk (S3).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isOwner =
        context.watch<AuthBloc>().state.user?.role == UserRole.owner;
    return isOwner ? const OwnerHomeShell() : const HomeShell();
  }
}
