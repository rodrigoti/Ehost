import 'package:flutter/material.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'funcoes.dart';
import 'config.dart';

/// Classe responsável por verificar e mostrar atualização do app
class AppVersionChecker {
  static Future<void> checkAndPromptUpdate(BuildContext context) async {
    final newVersion = NewVersionPlus(
      androidId: AppSettings.androidId, // coloque seu applicationId
      iOSId: AppSettings.iOSId,             // coloque o id da App Store
    );

    try {
      final status = await newVersion.getVersionStatus();

      if (status != null && status.canUpdate && context.mounted) {
        newVersion.showUpdateDialog(
          context: context,
          versionStatus: status,
          dialogTitle: 'Atualização Disponível',
          dialogText:
              'Uma nova versão do app está disponível!\n\n'
              'Versão atual: ${status.localVersion}\n'
              'Nova versão: ${status.storeVersion}',
          updateButtonText: 'Atualizar',
          dismissButtonText: 'Depois',
        );
      }
    } catch (e) {
      debugPrint("Erro ao verificar atualização: $e");
    }
  }
}

/// Widget que verifica atualização automaticamente
class UpdateChecker extends StatefulWidget {
  final Widget child;

  const UpdateChecker({super.key, required this.child});

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppVersionChecker.checkAndPromptUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
