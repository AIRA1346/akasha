class FranchiseGroup {
  final String id;
  final String displayName;
  final List<String> members;
  final String primaryWorkId;

  const FranchiseGroup({
    required this.id,
    required this.displayName,
    required this.members,
    required this.primaryWorkId,
  });

  factory FranchiseGroup.fromJson(String id, Map<String, dynamic> json) {
    final members = (json['members'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];

    return FranchiseGroup(
      id: id,
      displayName: json['displayName']?.toString() ?? id,
      members: members,
      primaryWorkId: json['primaryWorkId']?.toString() ?? members.first,
    );
  }
}
