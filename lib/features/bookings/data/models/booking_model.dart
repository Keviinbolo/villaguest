import 'package:villaguest/core/utils/date_utils.dart';

class BookingModel {
  final String id;
  final String guestName;
  final String guestEmail;
  final String guestPhone;
  final DateTime checkIn;
  final DateTime checkOut;
  final double totalPrice;
  final double depositPaid;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final DateTime createdAt;
  final String? source; // 'direct', 'airbnb', 'booking_com', 'vrbo', 'other'
  final String? notes;

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
    this.source,
    this.notes,
  });

  static const Map<String, String> sourceLabels = {
    'direct':      'Directo',
    'airbnb':      'Airbnb',
    'booking_com': 'Booking.com',
    'vrbo':        'VRBO',
    'other':       'Otro',
  };

  String get sourceLabel => sourceLabels[source] ?? source ?? '—';

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
      source: json['source'] as String?,
      notes: json['notes'] as String?,
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
      'source': source,
      'notes': notes,
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
    Object? source = _sentinel,
    Object? notes = _sentinel,
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
      source: source == _sentinel ? this.source : source as String?,
      notes: notes == _sentinel ? this.notes : notes as String?,
    );
  }
}

const _sentinel = Object();
