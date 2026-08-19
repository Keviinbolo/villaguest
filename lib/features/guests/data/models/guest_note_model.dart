import 'package:villaguest/core/utils/date_utils.dart';

/// Información adicional sobre un huésped que NO vive en las reservas:
/// notas del anfitrión y marca VIP. El ID del documento es el email del
/// huésped en minúsculas — así nunca se duplica ni desincroniza con los
/// datos de contacto que ya están en cada BookingModel.
class GuestNoteModel {
  const GuestNoteModel({
    required this.email,
    this.notes = '',
    this.isVip = false,
    required this.updatedAt,
  });

  final String email;
  final String notes;
  final bool isVip;
  final DateTime updatedAt;

  factory GuestNoteModel.fromJson(String email, Map<String, dynamic> json) {
    return GuestNoteModel(
      email: email,
      notes: json['notes'] as String? ?? '',
      isVip: json['isVip'] as bool? ?? false,
      updatedAt: parseFlexibleDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notes': notes,
      'isVip': isVip,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}