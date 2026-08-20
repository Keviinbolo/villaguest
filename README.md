# VillaGuestRD

Aplicación móvil para la gestión operativa de villas de alquiler vacacional en República Dominicana. Diseñada para propietarios que operan de forma directa, sin depender de OTAs.

[![Flutter](https://img.shields.io/badge/Flutter-3.12+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20Storage-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)

---

## Características

### Reservas y Calendario
- Calendario interactivo con días reservados resaltados
- Crear, editar y eliminar reservas con validación de disponibilidad
- Soporte para múltiples villas con datos completamente aislados

### Pagos
- Registro de señal y pagos parciales
- La reserva se marca automáticamente como completada al cubrir el saldo total
- Historial de depósitos por reserva

### Huéspedes
- Perfil por huésped con notas internas y marca VIP
- Búsqueda y filtrado en la lista de reservas

### Limpieza
- Checklists de limpieza generados automáticamente al confirmar una reserva
- Subida de fotos por tarea (Firebase Storage)
- Vista de estado: pendiente, en progreso, completado

### Mantenimiento
- Tickets de averías con prioridad (baja / media / alta)
- Adjuntar foto al reporte
- Ciclo de vida: abierto → en progreso → resuelto

### Documentos PDF
- Confirmación de reserva descargable / compartible
- Factura final (disponible al completar la reserva)

### Dashboard
- Resumen de ocupación e ingresos
- Reservas activas, pendientes y completadas del período

### Multi-Villa
- Un usuario se asocia a una villa específica mediante el campo `villa` en Firestore
- Cada villa tiene sus propios datos de reservas, limpieza, mantenimiento y huéspedes
- Roles diferenciados: **admin** (acceso completo) y **staff** (limpieza y mantenimiento)

---

## Stack

| Capa | Tecnología |
|------|-----------|
| UI | Flutter (Material 3) |
| Estado | Provider + ChangeNotifier |
| Base de datos | Cloud Firestore |
| Autenticación | Firebase Auth |
| Archivos | Firebase Storage |
| PDFs | `pdf` + `printing` |

---

## Configuración

### Requisitos

- Flutter SDK `^3.12.2`
- Cuenta de Firebase con proyecto configurado
- Android Studio / Xcode para compilar en dispositivo

### Instalación

```bash
git clone https://github.com/tu-usuario/villaguest.git
cd villaguest
flutter pub get
```

### Firebase

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com)
2. Activa **Authentication** (correo/contraseña), **Firestore** y **Storage**
3. Descarga `google-services.json` (Android) y `GoogleService-Info.plist` (iOS) y colócalos en sus respectivas carpetas
4. Genera `lib/firebase_options.dart` con la CLI:

```bash
flutterfire configure
```

5. Despliega las reglas de seguridad:

```bash
firebase deploy --only firestore:rules,storage
```

### Usuarios

Los usuarios se crean manualmente desde Firebase Console → Authentication.  
Luego crea su documento en `users/{uid}`:

```json
{
  "role": "admin",
  "villa": "nombre_villa"
}
```

Roles disponibles: `admin` | `staff`

---

## Estructura del proyecto

```
lib/
├── core/
│   ├── services/          # FirebaseService, InvoiceService
│   ├── theme/             # AppTheme, GradientAppBar
│   └── utils/
├── features/
│   ├── auth/              # Login, AuthGate, HomeScreen, StaffHomeScreen
│   ├── bookings/          # Calendario, reservas, pagos, PDFs
│   ├── cleaning/          # Checklists de limpieza
│   ├── dashboard/         # Panel de estadísticas
│   ├── guests/            # Perfiles de huéspedes
│   └── maintenance/       # Tickets de averías
└── main.dart
```

---

## Roadmap

- [ ] Notificaciones push (check-in / check-out próximos)
- [ ] Exportar resumen financiero a CSV
- [ ] Vista de disponibilidad multi-villa para el administrador principal
- [ ] App pública para huéspedes (carpeta digital con QR)

---

## Licencia

MIT
