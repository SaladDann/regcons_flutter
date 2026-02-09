# REGCONS 🏗️
**Gestión Inteligente para el Sector de la Construcción**

[![Version](https://img.shields.io/badge/Release-v1.0.0--mvp-orange?style=for-the-badge&logo=github)](https://github.com/SaladDann/regcons_flutter/releases/tag/v1.0.0-mvp)
[![Platform](https://img.shields.io/badge/Platform-Android-green?style=for-the-badge&logo=android)](https://github.com/SaladDann/regcons_flutter/releases/tag/v1.0.0-mvp)

REGCONS es una solución móvil diseñada para optimizar la supervisión técnica en obra. Permite el control de avances físicos y la gestión de seguridad industrial en tiempo real, garantizando la integridad de la información incluso en zonas con conectividad limitada.

---


## 📋 Características Principales

* 📸 **Evidencia Fotográfica:** Captura de imágenes vinculadas directamente a reportes y avances.
* ⚠️ **Gestión de Seguridad:** Reporte de incidentes y condiciones inseguras con niveles de severidad.
* 📶 **Arquitectura Offline-First:** Persistencia local mediante SQLite para trabajo en campo sin internet.
* 👥 **Multi-Cuenta:** Selector de perfiles integrado para alternar entre diferentes usuarios rápidamente.

---

## 🛠️ Stack Tecnológico
* **Framework:** Flutter 3.x (Dart)
* **Base de Datos:** SQLite (sqflite)
* **Estado & Persistencia:** SharedPreferences
* **Seguridad:** Encriptación SHA-256 + Salt dinámico

---

## 🧑‍💻 Instalación para Desarrolladores
Si deseas clonar el proyecto y ejecutarlo en tu entorno local:

1.  **Clonar repositorio:**
    `git clone https://github.com/SaladDann/regcons_flutter.git`
2.  **Instalar dependencias:**
    `flutter pub get`
3.  **Ejecutar:**
    `flutter run`
