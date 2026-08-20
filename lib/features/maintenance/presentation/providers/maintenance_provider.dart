import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/maintenance_ticket_model.dart';
import '../../data/repositories/maintenance_repository.dart';

class MaintenanceProvider extends ChangeNotifier {
  MaintenanceProvider({MaintenanceRepository? repository})
      : _repository = repository ?? MaintenanceRepository();

  final MaintenanceRepository _repository;
  StreamSubscription<List<MaintenanceTicketModel>>? _subscription;

  bool _hasAccess = false;
  String? _villaId;
  List<MaintenanceTicketModel> _tickets = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<MaintenanceTicketModel> get tickets => List.unmodifiable(_tickets);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<MaintenanceTicketModel> get openTickets =>
      _tickets.where((t) => t.status != 'resolved').toList();

  void updateAuthorization(bool hasAccess, String? villaId) {
    if (hasAccess == _hasAccess && villaId == _villaId) return;
    _hasAccess = hasAccess;
    _villaId = villaId;

    _subscription?.cancel();
    _subscription = null;

    if (hasAccess && villaId != null) {
      _isLoading = true;
      _errorMessage = null;
      _subscribe();
    } else {
      _tickets = [];
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _subscribe() {
    _subscription = _repository.streamTickets(_villaId!).listen(
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
    assert(_villaId != null);
    return _repository.createTicket(
      title: title,
      description: description,
      priority: priority,
      reportedBy: reportedBy,
      villaId: _villaId!,
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
