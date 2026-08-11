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

  /// Un palier santé (altitude du cairn) a été révélé. Payload
  /// `{afterMinutes}` = le seuil du palier ; on ne compte que ceux journalisés
  /// depuis la dernière cigarette (une rechute rejoue les paliers).
  milestoneRevealed,

  /// Un Boss a été vaincu (un gros rocher hissé au sommet). Payload
  /// `{bossKey}`, pour ne célébrer la victoire qu'une fois.
  bossDefeated,

  /// Pierre bonus : tenir au-delà des 10 min sans fumer (une à 20 min, une à
  /// 30 min ; plafond +2 par manche). Ne compte QUE pour le cairn — jamais pour
  /// les PV du Boss (un Boss ne se blesse qu'une fois/jour).
  bonusStone,

  /// L'utilisateur déclare n'avoir **rien tapé** ce jour-là. Payload
  /// `{day: 'AAAA-MM-JJ'}` (jour logique, bascule 04:00).
  ///
  /// Sans ça, un jour sans tap est indiscernable d'un jour sans tabac : il
  /// serait compté **propre** et pourrait offrir un faux record d'écart — or ce
  /// sont les deux seuls compteurs qui ne redescendent jamais. Un jour déclaré
  /// devient **neutre** : ni propre, ni fumé. Le cairn se met en pause, comme
  /// pour une rechute — il ne gagne pas de pierre, il n'en perd pas.
  dayNotLogged,

  /// L'utilisateur a remis l'observation à zéro : les cigarettes enregistrées
  /// jusque-là ont été effacées. Payload `{deleted}` = combien.
  ///
  /// Des premiers jours mal tapés produisent un **faux portrait** — et la
  /// détection des Boss, elle, sera prise au sérieux. Mieux vaut repartir d'une
  /// semaine vraie que nommer un Boss tiré de données fausses. Cet événement
  /// reste au journal : c'est la trace que la fenêtre a été redémarrée.
  observationReset,
}

/// Mode courant du parcours. `undecided` = 3ᵉ porte de la révélation : on ne
/// bloque JAMAIS l'utilisateur sur la question du mode.
enum JourneyMode { observing, reduction, coldTurkey, undecided }
