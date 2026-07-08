import '../generated/l10n/app_localizations.dart';

/// Extension to localize structural relation types without introducing UI state
/// or BuildContext dependencies into the core model layer.
extension RelationLocalizationExtension on String {
  String toLocalizedRelationLabel(AppLocalizations l10n) {
    switch (this) {
      case 'related':
        return l10n.vocabRelated;
      case 'about':
        return l10n.vocabAbout;
      case 'appears_in':
        return l10n.vocabAppearsIn;
      case 'created_by':
        return l10n.vocabCreatedBy;
      case 'part_of':
        return l10n.vocabPartOf;
      case 'member_of':
        return l10n.vocabMemberOf;
      case 'located_in':
        return l10n.vocabLocatedIn;
      case 'inspired_by':
        return l10n.vocabInspiredBy;
      case 'u:rival_of':
        return l10n.vocabRivalOf;
      case 'u:ally_of':
        return l10n.vocabAllyOf;
      case 'u:friend_of':
        return l10n.vocabFriendOf;
      case 'u:family_of':
        return l10n.vocabFamilyOf;
      case 'u:mentor_of':
        return l10n.vocabMentorOf;
      case 'u:subordinate_of':
        return l10n.vocabSubordinateOf;
      case 'u:successor_of':
        return l10n.vocabSuccessorOf;
      case 'u:protects':
        return l10n.vocabProtects;
      case 'u:loves':
        return l10n.vocabLoves;
      case 'u:enemy_of':
        return l10n.vocabEnemyOf;
      case 'u:adapted_from':
        return l10n.vocabAdaptedFrom;
      case 'u:symbolizes':
        return l10n.vocabSymbolizes;
      default:
        // Strip out 'u:' prefix for custom user-defined relations
        if (startsWith('u:')) {
          return substring(2);
        }
        return this;
    }
  }
}
