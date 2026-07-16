# 🏡 VillaGest RD - Vacation Rental Management PWA

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-10.0+-FFCA28?logo=firebase)](https://firebase.google.com)
[![PWA](https://img.shields.io/badge/PWA-Instalable-5A0FC8?logo=pwa)](https://web.dev/progressive-web-apps/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**VillaGest RD** es una aplicación web progresiva (PWA) diseñada específicamente para propietarios de villas en **República Dominicana** que desean gestionar su propiedad por fuera de plataformas OTA (Airbnb, Booking). Centraliza la operativa, automatiza la comunicación y optimiza el control financiero y logístico.

## 🎯 Filosofía del Proyecto
> *"No necesito un marketplace para que me encuentren; necesito un piloto automático que gestione mi negocio mientras yo disfruto del proceso."*

Esta app nace para solucionar el caos del **alquiler directo**: múltiples llamadas de WhatsApp, dobles reservas en el calendario, pérdida de documentos y falta de control sobre el estado de la propiedad.

---

## ✨ Características Principales (MVP)

### 📆 Módulo de Reservas y Calendario
- **Calendario interactivo** con vistas diarias/semanales/mensuales (usando `timetide`).
- **Sincronización iCalendar** para evitar dobles reservas si se publica en otros portales.
- **Motor de disponibilidad** en tiempo real conectado a Firebase Firestore.
- **Generación automática de contratos** de alquiler con firma digital (integración con Signaturit o similar).

### 💳 Pasarela de Pagos (Adaptada a RD)
- Integración con **Stripe** para cobros en USD (señal + saldo restante).
- Soporte para múltiples divisas (USD/DOP).
- Gestión de **fianzas (depósitos)** con liberación automática post-checkout.

### 📱 Comunicación Hiperlocal (WhatsApp API)
- Integración con **WhatsApp Cloud API** (usando `whatsapp_cloud_flutter`).
- **Disparadores automáticos** de mensajes:
  - *Día -7:* Instrucciones de llegada y recomendaciones locales (restaurantes, excursiones).
  - *Día -1:* Código de acceso a la cerradura inteligente.
  - *Día +1:* Check-in virtual y oferta de servicios adicionales (chef privado, transporte).
  - *Día de salida:* Recordatorio de horarios y checklist de devolución.

### 🧹 Logística y Mantenimiento (Módulo Team)
- **Checklist de limpieza post-salida** con obligación de subir **fotos** (evita reclamaciones).
- **Inventario de consumibles** (gel, café, bolsas) que se actualiza según la duración de la estancia.
- **Registro de incidencias** para asignar tareas a mantenimiento externo.

### 📊 Finanzas y Dashboards
- Panel de control con **% de ocupación mensual** y **ingresos proyectados**.
- Histórico de cobros y envío de facturas digitales (PDF).
- Alertas de vencimiento de pagos pendientes.

### 👨‍💻 Experiencia del Huésped (Guest App)
- **Carpeta Digital** accesible vía QR dentro de la villa: WiFi, tutoriales del aire acondicionado, horario de la piscina, números de emergencia.
- Botón de "Solicitar asistencia" que deriva directamente al chat de la propiedad.

---

## 🛠️ Stack Tecnológico

| Capa | Tecnología | Justificación |
| :--- | :--- | :--- |
| **Frontend** | Flutter (Web) | Multiplataforma; se compila a PWA instalable en el móvil del huésped sin pasar por App Store/Google Play. |
| **Backend** | Firebase (Auth, Firestore, Cloud Functions) | Sin servidor; ideal para escalar desde 1 villa hasta 10+; tiempo real para disponibilidad. |
| **Pagos** | Stripe API | Soporte nativo para USD, documentación robusta y fácil integración con Flutter. |
| **Mensajería** | WhatsApp Cloud API | Canal principal en RD; permite notificaciones push sin coste de SMS. |
| **Hosting** | Vercel / Netlify | Despliegue continuo desde GitHub; CDN global para rápido acceso en RD. |

---

## 🚀 Hoja de Ruta (Roadmap)

- [x] Configuración inicial del proyecto Flutter + PWA manifest.
- [ ] Integración con Firebase Firestore.
- [ ] Módulo de Calendario y creación de reservas.
- [ ] Pasarela de pago con Stripe (Checkout Session).
- [ ] Conexión con WhatsApp Cloud API (webhooks).
- [ ] Panel de administración (dashboard financiero).
- [ ] Generador de QR para el huésped.
- [ ] Módulo de limpieza con cámara (usando `image_picker`).

---
