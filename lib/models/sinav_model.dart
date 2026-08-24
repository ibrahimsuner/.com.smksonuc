class SinavModel {
  final String sinavadi;
  final String sinavtarihi;
  final String sinavyayini;
  final String sinifi;

  // Türkçe
  final int turkced;
  final int turkcey;
  final double turkcen;

  // Sosyal
  final int sosd;
  final int sosy;
  final double sosn;

  // Din
  final int dind;
  final int diny;
  final double dinn;

  // İngilizce
  final int ingd;
  final int ingy;
  final double ingn;

  // Matematik
  final int matd;
  final int maty;
  final double matn;

  // Fen
  final int fend;
  final int feny;
  final double fenn;

  // Toplam
  final int tod;
  final int toy;
  final double ton;

  // LGS & Sıralamalar
  final double lgs;
  final int dereces;
  final int dereceo;
  final int dereceilce;
  final int dereceil;
  final int dereceg;

  // Soru sayıları (ders bazlı) ve sınav türü — düşüş trendi hesabında
  // farklı formatlı sınavların (bursluluk gibi) yanlış "düşüş" olarak
  // algılanmaması için kullanılıyor. "sinavlar" tablosunda kayıt yoksa
  // backend bu alanları standart LGS formatı (20/20/20/20/10/10) ve
  // sinavTuru='lgs' olarak dolduruyor.
  final int turkceSoru;
  final int sosSoru;
  final int dinSoru;
  final int ingSoru;
  final int matSoru;
  final int fenSoru;
  final String sinavTuru; // 'lgs' | 'bursluluk' | 'diger'

  SinavModel({
    required this.sinavadi,
    required this.sinavtarihi,
    required this.sinavyayini,
    required this.sinifi,
    required this.turkced,
    required this.turkcey,
    required this.turkcen,
    required this.sosd,
    required this.sosy,
    required this.sosn,
    required this.dind,
    required this.diny,
    required this.dinn,
    required this.ingd,
    required this.ingy,
    required this.ingn,
    required this.matd,
    required this.maty,
    required this.matn,
    required this.fend,
    required this.feny,
    required this.fenn,
    required this.tod,
    required this.toy,
    required this.ton,
    required this.lgs,
    required this.dereces,
    required this.dereceo,
    required this.dereceilce,
    required this.dereceil,
    required this.dereceg,
    required this.turkceSoru,
    required this.sosSoru,
    required this.dinSoru,
    required this.ingSoru,
    required this.matSoru,
    required this.fenSoru,
    required this.sinavTuru,
  });

  factory SinavModel.fromJson(Map<String, dynamic> json) {
    return SinavModel(
      sinavadi:    json['sinavadi']    ?? '',
      sinavtarihi: json['sinavtarihi'] ?? '',
      sinavyayini: json['sinavyayini'] ?? '',
      sinifi:      json['sinifi']      ?? '',
      turkced:     (json['turkced']    ?? 0).toInt(),
      turkcey:     (json['turkcey']    ?? 0).toInt(),
      turkcen:     (json['turkcen']    ?? 0.0).toDouble(),
      sosd:        (json['sosd']       ?? 0).toInt(),
      sosy:        (json['sosy']       ?? 0).toInt(),
      sosn:        (json['sosn']       ?? 0.0).toDouble(),
      dind:        (json['dind']       ?? 0).toInt(),
      diny:        (json['diny']       ?? 0).toInt(),
      dinn:        (json['dinn']       ?? 0.0).toDouble(),
      ingd:        (json['ingd']       ?? 0).toInt(),
      ingy:        (json['ingy']       ?? 0).toInt(),
      ingn:        (json['ingn']       ?? 0.0).toDouble(),
      matd:        (json['matd']       ?? 0).toInt(),
      maty:        (json['maty']       ?? 0).toInt(),
      matn:        (json['matn']       ?? 0.0).toDouble(),
      fend:        (json['fend']       ?? 0).toInt(),
      feny:        (json['feny']       ?? 0).toInt(),
      fenn:        (json['fenn']       ?? 0.0).toDouble(),
      tod:         (json['tod']        ?? 0).toInt(),
      toy:         (json['toy']        ?? 0).toInt(),
      ton:         (json['ton']        ?? 0.0).toDouble(),
      lgs:         (json['lgs']        ?? 0.0).toDouble(),
      dereces:     (json['dereces']    ?? 0).toInt(),
      dereceo:     (json['dereceo']    ?? 0).toInt(),
      dereceilce:  (json['dereceilce'] ?? 0).toInt(),
      dereceil:    (json['dereceil']   ?? 0).toInt(),
      dereceg:     (json['dereceg']    ?? 0).toInt(),
      turkceSoru:  (json['turkceSoru'] ?? 20).toInt(),
      sosSoru:     (json['sosSoru']    ?? 20).toInt(),
      dinSoru:     (json['dinSoru']    ?? 10).toInt(),
      ingSoru:     (json['ingSoru']    ?? 10).toInt(),
      matSoru:     (json['matSoru']    ?? 20).toInt(),
      fenSoru:     (json['fenSoru']    ?? 20).toInt(),
      sinavTuru:   json['sinavTuru'] ?? 'lgs',
    );
  }
}