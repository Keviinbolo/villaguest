import 'dart:async';


import 'package:flutter/foundation.dart';

import '../../data/models/maintenance_ticket_model.dart';
import '../../data/repositories/maintenance_repository.dart';

/// Mismo patrón que BookingProvider y CleaningProvider: NO se suscribe
/// a Firestore en el constructor. Se conecta a AuthProvider vía
/// ChangeNotifierProxyProvider en main.dart, que llama
/// updateAuthorization() cada vez que cambia la sesión.
class MaintenanceProvider extends ChangeNotifier {
  MaintenanceProvider({MaintenanceRepository? repository})
      : _repository = repository ?? MaintenanceRepository();

  final MaintenanceRepository _repository;
  StreamSubscription<List<MaintenanceTicketModel>>? _subscription;

  bool _hasAccess = false;
  List<MaintenanceTicketModel> _tickets = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<MaintenanceTicketModel> get tickets => List.unmodifiable(_tickets);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<MaintenanceTicketModel> get openTickets =>
      _tickets.where((t) => t.status != 'resolved').toList();

  /// Admin y staff tienen permiso sobre maintenance_tickets, así que
  /// basta con "¿hay sesión?".
  void updateAuthorization(bool hasAccess) {
    if (hasAccess == _hasAccess) return;
    _hasAccess = hasAccess;

    if (hasAccess) {
      _isLoading = true;
      _errorMessage = null;
      _subscribe();
    } else {
      _subscription?.cancel();
      _subscription = null;
      _tickets = [];
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _subscribe() {
    _subscription = _repository.streamTickets().listen(
      (data) {
        _tickets = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'No se pudieron cargar las averías: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<String> createTicket({
    required String title,
    required String description,
    required String priority,
    required String reportedBy,
    Uint8List? photoBytes,
  }) {
    return _repository.createTicket(
      title: title,
      description: description,
      priority: priority,
      reportedBy: reportedBy,
      photoBytes: photoBytes,
    );
  }

  Future<void> updateStatus({
    required String ticketId,
    required String newStatus,
  }) {
    return _repository.updateStatus(ticketId: ticketId, newStatus: newStatus);
  }

  Future<void> deleteTicket(String ticketId) {
    return _repository.deleteTicket(ticketId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}