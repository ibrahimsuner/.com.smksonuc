class OgretmenModel {
  final String tcno;
  final String adisoyadi;
  final String brans;

  OgretmenModel({
    required this.tcno,
    required this.adisoyadi,
    required this.brans,
  });

  factory OgretmenModel.fromJson(Map<String, dynamic> json) {
    return OgretmenModel(
      tcno:      json['tcno']      ?? '',
      adisoyadi: json['adisoyadi'] ?? '',
      brans:     json['brans']     ?? '',
    );
  }
}