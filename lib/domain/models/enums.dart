/// Contexte optionnel posé au moment du tap. Ancré dans le temps → nourrit le
/// `contexte_dominant` d'un Boss et son nommage (« le Café de 7 h 10 »).
/// Enum figée v1 (extensible). Stockée par index sur `Cigarettes.contextA`.
enum CigContext { cafe, repas, alcool }

/// Cycle de vie du parcours, journalisé dans `JourneyEvents.kind` (via `.name`).
enum JourneyEventKind {
  modeChanged,
  bossAssigned,
  delayStarted,
  delayHeld,
  delayBroken,
  badgeEarned,
  relapse,
  revealShown,
  backupPromptSeen,
}

/// Mode courant du parcours. `undecided` = 3ᵉ porte de la révélation : on ne
/// bloque JAMAIS l'utilisateur sur la question du mode.
enum JourneyMode { observing, reduction, coldTurkey, undecided }
