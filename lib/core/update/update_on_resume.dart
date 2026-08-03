import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'update_service.dart';

/// Re-lance la vérification de mise à jour quand l'app revient au premier plan,
/// pour que la proposition apparaisse sans avoir à fermer/rouvrir l'app.
///
/// Throttlé : on ne rappelle pas GitHub à chaque bascule d'application. Le check
/// tourne déjà une fois au lancement (via [updateCheckProvider]).
class UpdateOnResume extends ConsumerStatefulWidget {
  const UpdateOnResume({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<UpdateOnResume> createState() => _UpdateOnResumeState();
}

class _UpdateOnResumeState extends ConsumerState<UpdateOnResume>
    with WidgetsBindingObserver {
  // Le provider est déjà chargé au 1er build → on part de « maintenant ».
  DateTime _lastCheck = DateTime.now();
  static const _minInterval = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    if (now.difference(_lastCheck) < _minInterval) return;
    _lastCheck = now;
    ref.invalidate(updateCheckProvider); // relance checkForUpdate()
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
