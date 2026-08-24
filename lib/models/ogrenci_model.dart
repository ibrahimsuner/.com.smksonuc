class OgrenciModel {
  final String tcno;
  final String adisoyadi;
  final String sinifi;
  final String numarasi;

  OgrenciModel({
    required this.tcno,
    required this.adisoyadi,
    required this.sinifi,
    required this.numarasi,
  });

  factory OgrenciModel.fromJson(Map<String, dynamic> json) {
    return OgrenciModel(
      tcno:      json['tcno']      ?? '',
      adisoyadi: json['adisoyadi'] ?? '',
      sinifi:    json['sinifi']    ?? '',
      numarasi:  json['numarasi']  ?? '',
    );
  }
}