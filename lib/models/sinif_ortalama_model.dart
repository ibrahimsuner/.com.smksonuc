class SinifOrtalamaModel {
  final String sinavadi;
  final String sinifi;
  final double turkcen;
  final double sosn;
  final double dinn;
  final double ingn;
  final double matn;
  final double fenn;
  final double ton;
  final double lgs;
  final int ogrenciSayisi;

  SinifOrtalamaModel({
    required this.sinavadi,
    required this.sinifi,
    required this.turkcen,
    required this.sosn,
    required this.dinn,
    required this.ingn,
    required this.matn,
    required this.fenn,
    required this.ton,
    required this.lgs,
    required this.ogrenciSayisi,
  });

  factory SinifOrtalamaModel.fromJson(Map<String, dynamic> json) {
    return SinifOrtalamaModel(
      sinavadi:      json['sinavadi']      ?? '',
      sinifi:        json['sinifi']        ?? '',
      turkcen:       (json['turkcen']      ?? 0.0).toDouble(),
      sosn:          (json['sosn']         ?? 0.0).toDouble(),
      dinn:          (json['dinn']         ?? 0.0).toDouble(),
      ingn:          (json['ingn']         ?? 0.0).toDouble(),
      matn:          (json['matn']         ?? 0.0).toDouble(),
      fenn:          (json['fenn']         ?? 0.0).toDouble(),
      ton:           (json['ton']          ?? 0.0).toDouble(),
      lgs:           (json['lgs']          ?? 0.0).toDouble(),
      ogrenciSayisi: (json['ogrencisayisi'] ?? 0).toInt(),
    );
  }
}