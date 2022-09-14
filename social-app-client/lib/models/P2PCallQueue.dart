class P2PCallQueue {
  final String userUid;
  String? offer, answer, occBy;
  int? occ;

  P2PCallQueue({required this.userUid, required this.occ});

  P2PCallQueue.fromMap(Map map, {required this.userUid}) {
    this.occ = map["occ"];
    this.occBy = map["occBy"];
    this.offer = map["offer"];
    this.answer = map["answer"];
  }
}
