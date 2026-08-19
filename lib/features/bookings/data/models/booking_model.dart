import 'package:villaguest/core/utils/date_utils.dart';

class BookingModel {
  final String id;
  final String guestName;
  final String guestEmail;
  final String guestPhone;
  final DateTime checkIn;
  final DateTime checkOut;
  final double totalPrice;
  final double depositPaid; // señal
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.guestName,
    required this.guestEmail,
    required this.guestPhone,
    required this.checkIn,
    required this.checkOut,
    required this.totalPrice,
    required this.depositPaid,
    required this.status,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      guestName: json['guestName'] as String,
      guestEmail: json['guestEmail'] as String,
      guestPhone: json['guestPhone'] as String,
      checkIn: parseFlexibleDate(json['checkIn']),
      checkOut: parseFlexibleDate(json['checkOut']),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      depositPaid: (json['depositPaid'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: parseFlexibleDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guestName': guestName,
      'guestEmail': guestEmail,
      'guestPhone': guestPhone,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'totalPrice': totalPrice,
      'depositPaid': depositPaid,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  BookingModel copyWith({
    String? id,
    String? guestName,
    String? guestEmail,
    String? guestPhone,
    DateTime? checkIn,
    DateTime? checkOut,
    double? totalPrice,
    double? depositPaid,
    String? status,
    DateTime? createdAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      guestName: guestName ?? this.guestName,
      guestEmail: guestEmail ?? this.guestEmail,
      guestPhone: guestPhone ?? this.guestPhone,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      totalPrice: totalPrice ?? this.totalPrice,
      depositPaid: depositPaid ?? this.depositPaid,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}