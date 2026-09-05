# 💰 Gastoscopio - Gestor Financiero Personal

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=flat-square&logo=dart&logoColor=white)](https://dart.dev/)
[![Android](https://img.shields.io/badge/Android-3DDC84?style=flat-square&logo=android&logoColor=white)](https://developer.android.com/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)

<div align="center">
  <img src="assets/logo.png" alt="Gastoscopio Logo" width="120" height="120">
  
  **Una aplicación intuitiva y potente para gestionar tus finanzas personales con inteligencia artificial integrada.**
</div>

## 📱 Descripción

**Gastoscopio** es una aplicación móvil desarrollada con Flutter que te ayuda a tomar el control total de tus finanzas personales. Con una interfaz moderna e intuitiva, podrás registrar gastos e ingresos, crear movimientos fijos recurrentes, y obtener análisis detallados de tus patrones de gasto con la ayuda de inteligencia artificial.

### ✨ Características Principales

#### 💸 **Gestión de Movimientos**
- **Registro rápido** de gastos e ingresos con formularios intuitivos
- **Categorización automática** con IA para una mejor organización
- **Movimientos fijos** que se repiten automáticamente cada mes
- **Edición y eliminación** fácil de cualquier transacción

#### 📊 **Análisis y Estadísticas**
- **Dashboard visual** con gráficos de gastos por categoría
- **Resúmenes mensuales** con balance total y tendencias
- **Estadísticas detalladas** filtradas por mes y año
- **Análisis con IA** que proporciona insights personalizados sobre tus hábitos de gasto

#### 🎨 **Experiencia de Usuario**
- **Interfaz moderna** con Material Design 3
- **Modo oscuro/claro** con soporte para colores dinámicos del sistema
- **Animaciones suaves** y transiciones fluidas
- **Navegación intuitiva** con acceso rápido a todas las funciones

#### 🔐 **Privacidad y Seguridad**
- **Almacenamiento local** seguro con SQLite
- **Respaldo en Google Drive** opcional para sincronización
- **Autenticación con Google** para mayor seguridad
- **Control total** sobre tus datos financieros

## 🚀 Características Técnicas

### 🏗️ **Arquitectura**
- **Patrón Singleton** para servicios centralizados
- **Programación reactiva** con Streams y Listeners
- **Gestión de estado** eficiente con AnimatedBuilder
- **Separación de responsabilidades** con capas bien definidas

### 💾 **Almacenamiento**
- **Base de datos local** SQLite con Floor ORM
- **Respaldo automático** en Google Drive
- **Preferencias del usuario** con SharedPreferences
- **Gestión de archivos** para importación/exportación

## 📋 Funcionalidades Detalladas

### 🏠 **Pantalla Principal**
- Saludo personalizado con nombre del usuario
- Balance mensual destacado con colores indicativos
- Últimos movimientos del día
- Gráfico de gastos por categoría (top 3)
- Acceso rápido para añadir nuevos movimientos

### 📝 **Gestión de Movimientos**
- **Formulario inteligente** con categorización automática por IA
- **Lista filtrable** por mes y año
- **Búsqueda rápida** por descripción o categoría
- **Edición en línea** con validación de datos
- **Eliminación segura** con confirmación

### 🔄 **Movimientos Fijos**
- **Creación de gastos recurrentes** (alquiler, suscripciones, etc.)
- **Aplicación automática** al cambio de mes
- **Gestión flexible** con activación/desactivación
- **Categorización personalizada** para cada movimiento fijo

### 📈 **Análisis y Reportes**
- **Gráficos interactivos** de gastos por categoría
- **Tendencias mensuales** con comparativas
- **Resúmenes con IA** que analizan patrones de gasto
- **Exportación de datos** para análisis externos

### ⚙️ **Configuración**
- **Personalización de moneda** (€, $, £, etc.)
- **Configuración de avatar** con opciones SVG y PNG
- **Gestión de API Key** para servicios de IA
- **Términos y condiciones** con scroll obligatorio

## 🛠️ Instalación y Configuración

### Prerrequisitos
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / VS Code
- Cuenta de Google (opcional para respaldo)

### Pasos de Instalación

1. **Clonar el repositorio**
```bash
git clone https://github.com/tu-usuario/Gastoscopio.git
cd Gastoscopio
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Configurar Firebase (opcional)**
```bash
# Añadir google-services.json en android/app/
# Configurar autenticación con Google
```

4. **Compilar la aplicación**
```bash
# Para desarrollo
flutter run

# Para producción
flutter build apk --release
```

## 🎯 Configuración Inicial

### Primera Configuración
1. **Acepta los términos y condiciones**
2. **Configura tu moneda preferida**
3. **Personaliza tu avatar y colores**
4. **Opcionalmente inicia sesión con Google**

## 🔧 Opciones de Desarrollador

La aplicación incluye un menú de opciones de desarrollador que permite acceso a funciones avanzadas:

### 📥 Importar desde JSON
- Importa datos desde archivos JSON de Gastoscopio
- Funcionalidad oculta en opciones de desarrollador para evitar uso accidental
- Preserva la estructura de datos y categorías

### 🗑️ Limpiar Base de Datos
- **⚠️ PELIGRO**: Borra TODOS los datos de la aplicación permanentemente
- Incluye confirmación múltiple para prevenir borrado accidental
- Limpia: movimientos, categorías, movimientos fijos, configuraciones
- Requiere reinicio de la app después del borrado

### Acceso a Opciones de Desarrollador
1. Ve a Configuración
2. Busca la sección "Opciones de Desarrollador" 
3. Toca para expandir el menú
4. Usa las funciones con precaución

### Medidas de Seguridad
- Múltiples confirmaciones para operaciones destructivas
- Advertencias claras sobre irreversibilidad
- Recomendación de backup antes de limpiar datos
- Feedback visual claro para todas las operaciones

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -m 'Añadir nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.



---

<div align="center">
  <p>Hecho con ❤️ y Flutter</p>
  <p><em>Toma el control de tus finanzas con inteligencia</em></p>
</div>
