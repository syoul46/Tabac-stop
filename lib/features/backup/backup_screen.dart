import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/crypto/vault.dart';
import '../../data/backup_service.dart';

/// Écran de sauvegarde chiffrée. Export → un fichier `.enc` opaque que
/// l'utilisateur enregistre où il veut. Import → on choisit un fichier + la
/// passphrase. Rien ne quitte l'appareil sans action explicite.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _export() async {
    final pass = await _askPassphrase(confirm: true);
    if (pass == null) return;
    setState(() => _busy = true);
    try {
      final env = await ref.read(backupServiceProvider).exportEncrypted(pass);
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().toIso8601String().split('T').first;
      final file = File('${dir.path}/cairn-$stamp.enc');
      await file.writeAsString(env);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/octet-stream')],
        text: 'Sauvegarde Cairn (chiffrée)',
      );
    } catch (_) {
      _toast('Échec de l’export.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final picked = await FilePicker.platform.pickFiles(withData: false);
    final path = picked?.files.single.path;
    if (path == null) return;
    final content = await File(path).readAsString();
    final pass = await _askPassphrase(confirm: false);
    if (pass == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(backupServiceProvider).importEncrypted(content, pass);
      _toast('Sauvegarde restaurée.');
      if (mounted) Navigator.of(context).maybePop();
    } on VaultException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Fichier de sauvegarde illisible.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askPassphrase({required bool confirm}) {
    return showDialog<String>(
      context: context,
      builder: (_) => _PassphraseDialog(confirm: confirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sauvegarde')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tes données restent sur ton téléphone. Une sauvegarde est un '
                'fichier chiffré avec ta passphrase — illisible sans elle, à '
                'enregistrer où tu veux.',
                style: TextStyle(
                    height: 1.4, color: c.onSurface.withValues(alpha: 0.75)),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _busy ? null : _export,
                style: FilledButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: c.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Exporter (chiffré)'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _import,
                style: OutlinedButton.styleFrom(
                    foregroundColor: c.onSurface,
                    side: BorderSide(color: c.onSurface.withValues(alpha: 0.25)),
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                icon: const Icon(Icons.file_open_outlined),
                label: const Text('Importer une sauvegarde'),
              ),
              const SizedBox(height: 20),
              if (_busy) const Center(child: CircularProgressIndicator()),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: c.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Un import remplace les données actuelles. Garde ta '
                      'passphrase : elle ne peut pas être récupérée.',
                      style: TextStyle(
                          fontSize: 12,
                          color: c.onSurface.withValues(alpha: 0.55)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PassphraseDialog extends StatefulWidget {
  const _PassphraseDialog({required this.confirm});
  final bool confirm;

  @override
  State<_PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<_PassphraseDialog> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _submit() {
    final a = _a.text;
    if (a.length < 6) {
      setState(() => _error = 'Au moins 6 caractères.');
      return;
    }
    if (widget.confirm && a != _b.text) {
      setState(() => _error = 'Les passphrases diffèrent.');
      return;
    }
    Navigator.of(context).pop(a);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.confirm ? 'Choisis une passphrase' : 'Ta passphrase'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _a,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Passphrase'),
            onSubmitted: (_) => widget.confirm ? null : _submit(),
          ),
          if (widget.confirm)
            TextField(
              controller: _b,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirme'),
              onSubmitted: (_) => _submit(),
            ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler')),
        FilledButton(onPressed: _submit, child: const Text('OK')),
      ],
    );
  }
}
