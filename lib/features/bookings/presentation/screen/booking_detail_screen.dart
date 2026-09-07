import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:villaguest/core/theme/app_theme.dart';
import 'package:villaguest/core/theme/gradient_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:villaguest/core/services/invoice_service.dart';
import 'package:villaguest/core/utils/date_utils.dart';
import 'package:villaguest/features/bookings/presentation/booking_provider.dart';
import 'package:villaguest/features/bookings/presentation/screen/invoice_preview_screen.dart';
import 'package:villaguest/features/bookings/presentation/widgets/edit_booking_dialog.dart';
import 'package:villaguest/features/bookings/presentation/widgets/register_payment_dialog.dart';
import 'package:villaguest/features/cleaning/presentation/cleaning_checklist_screen.dart';
import 'package:villaguest/features/cleaning/providers/cleaning_provider.dart';

import '../../data/models/booking_model.dart';
import 'bookings_list_screen.dart' show BookingsListScreen;

class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  static final _moneyFmt = NumberFormat('#,##0', 'en_US');
  static String _fmtMoney(double v) =>
      v == v.truncateToDouble() ? _moneyFmt.format(v.toInt()) : NumberFormat('#,##0.00', 'en_US').format(v);

  Future<void> _updateStatus(
    BuildContext context,
    BookingProvider provider,
    String newStatus,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.updateStatus(bookingId: bookingId, newStatus: newStatus);
      messenger.showSnackBar(SnackBar(
        content: Text(
            'Estado actualizado a "${BookingsListScreen.statusLabel(newStatus)}".'),
      ));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('No se pudo actualizar: $e')));
    }
  }

  Future<void> _confirmBooking(
    BuildContext context,
    BookingProvider provider,
    BookingModel booking,
  ) async {
    final cleaningProvider = context.read<CleaningProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.updateStatus(bookingId: bookingId, newStatus: 'confirmed');
      messenger.showSnackBar(
          const SnackBar(content: Text('Reserva confirmada.')));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('No se pudo confirmar: $e')));
      return;
    }
    try {
      await cleaningProvider.createChecklistForBooking(
        bookingId: booking.id,
        guestName: booking.guestName,
        checkOutDate: booking.checkOut,
      );
    } catch (_) {}
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BookingProvider provider,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cleaningProvider = context.read<CleaningProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar reserva'),
        content: const Text(
          'Esta acción no se puede deshacer. ¿Seguro que quieres eliminar esta reserva? '
          'También se eliminará su checklist de limpieza, si tiene uno.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton.tonal(
            style: FilledButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      try {
        await cleaningProvider.deleteChecklistsForBooking(bookingId);
      } catch (_) {}
      await provider.deleteBooking(bookingId);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Reserva eliminada.')));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('No se pudo eliminar: $e')));
    }
  }

  void _openConfirmationPreview(BuildContext context, BookingModel booking) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => InvoicePreviewScreen(
        title: 'Confirmación de Reserva',
        filename:
            'confirmacion_${booking.id.substring(0, booking.id.length.clamp(0, 12))}.pdf',
        buildBytes: (format) =>
            InvoiceService.buildConfirmationBytes(format, booking),
      ),
    ));
  }

  void _openFinalInvoicePreview(BuildContext context, BookingModel booking) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => InvoicePreviewScreen(
        title: 'Factura Final',
        filename:
            'factura_${booking.id.substring(0, booking.id.length.clamp(0, 12))}.pdf',
        buildBytes: (format) =>
            InvoiceService.buildFinalInvoiceBytes(format, booking),
      ),
    ));
  }

  Future<void> _openCleaningChecklist(
      BuildContext context, BookingModel booking) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cleaningProvider = context.read<CleaningProvider>();

    // Usa la caché local del provider para evitar el round-trip de red
    final cached = cleaningProvider.checklists
        .where((c) => c.bookingId == booking.id)
        .firstOrNull;
    if (cached != null) {
      navigator.push(MaterialPageRoute(
          builder: (_) => CleaningChecklistScreen(checklistId: cached.id)));
      return;
    }

    try {
      final id = await cleaningProvider.createChecklistForBooking(
        bookingId: booking.id,
        guestName: booking.guestName,
        checkOutDate: booking.checkOut,
      );
      navigator.push(MaterialPageRoute(
          builder: (_) => CleaningChecklistScreen(checklistId: id)));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('No se pudo abrir el checklist: $e')));
    }
  }

  Future<void> _launchWhatsApp(BuildContext context, String phone) async {
    final messenger = ScaffoldMessenger.of(context);
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await Clipboard.setData(ClipboardData(text: phone));
      messenger.showSnackBar(
        const SnackBar(content: Text('Número copiado al portapapeles.')),
      );
    }
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri(scheme: 'mailto', path: email);
    if (!await launchUrl(uri)) {
      await Clipboard.setData(ClipboardData(text: email));
      messenger.showSnackBar(
        const SnackBar(content: Text('Email copiado al portapapeles.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();

    BookingModel? matchingBooking;
    for (final b in provider.bookings) {
      if (b.id == bookingId) {
        matchingBooking = b;
        break;
      }
    }

    if (matchingBooking == null) {
      return Scaffold(
        appBar: const GradientAppBar(title: 'Reserva'),
        body: const Center(child: Text('Esta reserva ya no existe.')),
      );
    }

    final booking = matchingBooking;
    final nights = booking.checkOut.difference(booking.checkIn).inDays;
    final balanceDue = booking.totalPrice - booking.depositPaid;
    final statusColor = BookingsListScreen.statusColor(booking.status);

    return Scaffold(
      backgroundColor: AppTheme.surfacePage,
      appBar: GradientAppBar(
        title: booking.guestName,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => EditBookingDialog(booking: booking),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar',
            onPressed: () => _confirmDelete(context, provider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Estado ─────────────────────────────────────────────────────
          _SectionCard(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Estado',
                      style: _sectionLabelStyle(context)),
                  _StatusBadge(
                    label: BookingsListScreen.statusLabel(booking.status),
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildActions(context, provider, booking),
            ],
          ),

          // ── Fechas ─────────────────────────────────────────────────────
          _SectionCard(
            label: 'Fechas',
            children: [
              _InfoRow('Check-in', formatDate(booking.checkIn)),
              const Divider(height: 16),
              _InfoRow('Check-out', formatDate(booking.checkOut)),
              const Divider(height: 16),
              _InfoRow('Duración',
                  '$nights ${nights == 1 ? 'noche' : 'noches'}'),
            ],
          ),

          // ── Huésped ────────────────────────────────────────────────────
          _SectionCard(
            label: 'Huésped',
            children: [
              _InfoRow('Nombre', booking.guestName),
              const Divider(height: 16),
              _InfoRow('Email', booking.guestEmail,
                  onTap: () => _launchEmail(context, booking.guestEmail)),
              const Divider(height: 16),
              _InfoRow('WhatsApp', booking.guestPhone,
                  onTap: () => _launchWhatsApp(context, booking.guestPhone)),
              if (booking.guestCount != null) ...[
                const Divider(height: 16),
                _InfoRow('Personas', '${booking.guestCount}'),
              ],
              if (booking.source != null) ...[
                const Divider(height: 16),
                _InfoRow('Canal', booking.sourceLabel),
              ],
            ],
          ),

          // ── Notas internas ────────────────────────────────────────────
          if (booking.notes != null && booking.notes!.isNotEmpty)
            _SectionCard(
              label: 'Notas internas',
              children: [
                Text(
                  booking.notes!,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF3D4A5C), height: 1.5),
                ),
              ],
            ),

          // ── Pago ───────────────────────────────────────────────────────
          _SectionCard(
            label: 'Pago',
            children: [
              _InfoRow('Precio total',
                  'RD\$ ${_fmtMoney(booking.totalPrice)}'),
              const Divider(height: 16),
              _InfoRow('Señal pagada',
                  'RD\$ ${_fmtMoney(booking.depositPaid)}'),
              const Divider(height: 16),
              _InfoRow(
                'Saldo pendiente',
                'RD\$ ${_fmtMoney(balanceDue)}',
                valueColor: balanceDue > 0 && booking.status != 'cancelled'
                    ? const Color(0xFFE07B00)
                    : null,
              ),
              if (balanceDue > 0 && booking.status != 'cancelled') ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Registrar pago'),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) =>
                          RegisterPaymentDialog(booking: booking),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // ── Acciones adicionales ───────────────────────────────────────
          if (booking.status == 'confirmed' ||
              booking.status == 'completed') ...[
            _CleaningTile(
              bookingId: booking.id,
              onTap: () => _openCleaningChecklist(context, booking),
            ),
          ],

          if (booking.status != 'cancelled') ...[
            _ActionTile(
              icon: Icons.picture_as_pdf_outlined,
              label: 'Confirmación de reserva',
              onTap: () => _openConfirmationPreview(context, booking),
            ),
            if (booking.status == 'completed')
              _ActionTile(
                icon: Icons.receipt_long_outlined,
                label: 'Factura final',
                onTap: () => _openFinalInvoicePreview(context, booking),
              ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  TextStyle _sectionLabelStyle(BuildContext context) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.2,
      );

  Widget _buildActions(
    BuildContext context,
    BookingProvider provider,
    BookingModel booking,
  ) {
    final buttons = <Widget>[];

    switch (booking.status) {
      case 'pending':
        buttons.add(SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => _confirmBooking(context, provider, booking),
            child: const Text('Confirmar reserva'),
          ),
        ));
        buttons.add(SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red)),
            onPressed: () =>
                _updateStatus(context, provider, 'cancelled'),
            child: const Text('Cancelar reserva'),
          ),
        ));
        break;
      case 'confirmed':
        buttons.add(SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red)),
            onPressed: () =>
                _updateStatus(context, provider, 'cancelled'),
            child: const Text('Cancelar reserva'),
          ),
        ));
        break;
      case 'cancelled':
        buttons.add(SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () =>
                _updateStatus(context, provider, 'pending'),
            child: const Text('Reactivar como pendiente'),
          ),
        ));
        break;
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (final b in buttons) ...[b, const SizedBox(height: 8)],
      ],
    );
  }
}

// ── Widgets auxiliares ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children, this.label});

  final List<Widget> children;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null) ...[
              Text(
                label!.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.valueColor, this.onTap});
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7A99), fontSize: 13),
        ),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: valueColor ?? (onTap != null ? AppTheme.teal : const Color(0xFF1A1F36)),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.open_in_new_rounded,
                    size: 13, color: AppTheme.teal.withValues(alpha: 0.7)),
              ],
            ],
          ),
        ),
      ],
    );
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: content,
        ),
      );
    }
    return content;
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon,
            color: Theme.of(context).colorScheme.primary),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right,
            color: Color(0xFFBBC3D8)),
        onTap: onTap,
      ),
    );
  }
}

class _CleaningTile extends StatelessWidget {
  const _CleaningTile({required this.bookingId, required this.onTap});
  final String bookingId;
  final VoidCallback onTap;

  static const _statusColor = {
    'pending':     Color(0xFF6B7A99),
    'in_progress': AppTheme.lime,
    'completed':   AppTheme.teal,
  };
  static const _statusLabel = {
    'pending':     'Sin empezar',
    'in_progress': 'En progreso',
    'completed':   'Completado',
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CleaningProvider>();
    final checklist = provider.checklists
        .where((c) => c.bookingId == bookingId)
        .firstOrNull;

    final color = checklist != null
        ? (_statusColor[checklist.status] ?? const Color(0xFF6B7A99))
        : const Color(0xFF6B7A99);
    final statusText = checklist != null
        ? (_statusLabel[checklist.status] ?? checklist.status)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(Icons.cleaning_services_outlined, color: color),
        title: const Text('Checklist de limpieza',
            style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: statusText != null
            ? Text(statusText, style: TextStyle(color: color, fontSize: 12))
            : null,
        trailing: checklist != null && checklist.status == 'completed'
            ? const Icon(Icons.check_circle_rounded,
                color: AppTheme.teal, size: 22)
            : checklist != null && checklist.totalTasks > 0
                ? Text(
                    '${checklist.completedTasksCount}/${checklist.totalTasks}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  )
                : const Icon(Icons.chevron_right, color: Color(0xFFBBC3D8)),
        onTap: onTap,
      ),
    );
  }
}
