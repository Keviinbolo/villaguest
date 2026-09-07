class VillaSettingsModel {
  const VillaSettingsModel({
    required this.villaId,
    required this.displayName,
    this.logoUrl,
    this.contactPhone,
    this.contactEmail,
    this.pricePerNight,
  });

  final String villaId;
  final String displayName;
  final String? logoUrl;
  final String? contactPhone;
  final String? contactEmail;
  final double? pricePerNight;

  factory VillaSettingsModel.initial(String villaId) => VillaSettingsModel(
        villaId: villaId,
        displayName: villaId,
      );

  factory VillaSettingsModel.fromJson(
      String villaId, Map<String, dynamic> data) =>
      VillaSettingsModel(
        villaId: villaId,
        displayName: data['displayName'] as String? ?? villaId,
        logoUrl: data['logoUrl'] as String?,
        contactPhone: data['contactPhone'] as String?,
        contactEmail: data['contactEmail'] as String?,
        pricePerNight: (data['pricePerNight'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'logoUrl': logoUrl,
        'contactPhone': contactPhone,
        'contactEmail': contactEmail,
        'pricePerNight': pricePerNight,
      };
}
