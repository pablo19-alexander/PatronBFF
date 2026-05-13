# Taller 4 — Cliente Móvil: BFF vs Carga Directa

Cliente móvil en Flutter para comparar dos estrategias de consumo de microservicios:

1. **Carga Directa**: el cliente hace **3 peticiones HTTP en paralelo** a tres microservicios (`perfil`, `restaurantes`, `pedidos`).
2. **Carga BFF** (*Backend For Frontend*): el cliente hace **1 sola petición** a un servicio agregador que orquesta y compone la respuesta de los tres microservicios.

La app mide y muestra el tiempo total de cada estrategia para evidenciar las diferencias de latencia, número de round-trips y manejo de errores.

---

## Tabla de contenidos

- [Arquitectura](#arquitectura)
- [Requisitos](#requisitos)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Configuración de red](#configuración-de-red)
- [Ejecución](#ejecución)
- [Endpoints consumidos](#endpoints-consumidos)
- [Cómo usar la app](#cómo-usar-la-app)
- [Manejo de errores](#manejo-de-errores)
- [Solución de problemas](#solución-de-problemas)

---

## Arquitectura

```
┌──────────────────────┐       ┌────────────────────┐
│                      │  3x   │  perfil      :8001 │
│   Cliente Flutter    │──────▶│  restaurantes:8002 │   Carga Directa
│   (este repo)        │       │  pedidos     :8003 │
│                      │       └────────────────────┘
│                      │
│                      │  1x   ┌────────────────────┐
│                      │──────▶│  BFF   :8000/home  │   Carga BFF
└──────────────────────┘       └─────────┬──────────┘
                                         │
                                         ▼
                               (agrega los 3 servicios)
```

- **Carga Directa** mide la suma del peor caso entre las 3 peticiones (se hacen con `Future.wait`).
- **Carga BFF** mide una sola petición, donde la orquestación ocurre del lado del servidor.

El backend (microservicios + BFF) vive en el subdirectorio [`PatronBFF/`](PatronBFF/) (repositorio separado).

---

## Requisitos

- **Flutter SDK** `>=3.3.0 <4.0.0`
- **Dart** incluido con Flutter
- Backend del taller corriendo (microservicios `8001/8002/8003` y BFF `8000`)
- Dispositivo Android/iOS o emulador
- El móvil y el computador que sirve el backend deben estar en la **misma red Wi-Fi** si se prueba en dispositivo físico

Dependencias principales (ver [`pubspec.yaml`](pubspec.yaml)):

| Paquete           | Versión   | Uso                               |
|-------------------|-----------|-----------------------------------|
| `flutter`         | sdk       | Framework UI                      |
| `http`            | ^1.2.2    | Cliente HTTP para llamadas REST   |
| `cupertino_icons` | ^1.0.8    | Iconografía                       |

---

## Estructura del proyecto

```
Taller4-mobile_app/
├── lib/
│   └── main.dart           # Toda la app: ApiConfig, HomeScreen, widgets
├── PatronBFF/              # Backend (microservicios + BFF) — repo separado
├── android/                # Proyecto Android
├── ios/                    # Proyecto iOS
├── test/                   # Pruebas
├── pubspec.yaml            # Dependencias
└── README.md
```

---

## Configuración de red

La URL base del backend se define en la clase `ApiConfig` dentro de [`lib/main.dart`](lib/main.dart):

```dart
class ApiConfig {
  static String get host {
    if (!kIsWeb && Platform.isAndroid) {
      // return '10.0.2.2'; // <-- emulador Android (puente al host)
      return '192.168.1.53'; // celular físico en la misma Wi-Fi
    }
    return '192.168.1.53';
  }
  ...
}
```

Reglas según el entorno:

| Entorno                          | Host a usar                                |
|----------------------------------|--------------------------------------------|
| **Emulador Android**             | `10.0.2.2` (puente especial al `localhost` del host) |
| **Simulador iOS**                | `127.0.0.1` o `localhost`                  |
| **Celular físico (Android/iOS)** | IP Wi-Fi del computador (ej. `192.168.1.53`) |
| **Web (Chrome)**                 | `localhost` o IP local                     |

> ⚠️ Si tu IP cambia (otra red Wi-Fi, reinicio del router), **actualiza el valor en `ApiConfig.host`**.
>
> Para conocer tu IP en macOS/Linux: `ipconfig getifaddr en0` &nbsp;|&nbsp; en Windows: `ipconfig`.

---

## Ejecución

```bash
# 1. Instalar dependencias
flutter pub get

# 2. (opcional) verificar configuración
flutter doctor

# 3. Listar dispositivos disponibles
flutter devices

# 4. Correr la app
flutter run                  # selecciona dispositivo interactivamente
flutter run -d <deviceId>    # dispositivo específico
flutter run -d chrome        # en navegador
```

> Asegúrate de que **el backend esté arriba** (microservicios y BFF) antes de probar.

---

## Endpoints consumidos

| Modo           | Método | URL                                | Propósito                    |
|----------------|--------|------------------------------------|------------------------------|
| Carga Directa  | GET    | `http://<host>:8001/perfil`        | Datos del perfil del usuario |
| Carga Directa  | GET    | `http://<host>:8002/restaurantes`  | Listado de restaurantes      |
| Carga Directa  | GET    | `http://<host>:8003/pedidos`       | Pedidos del usuario          |
| Carga BFF      | GET    | `http://<host>:8000/home`          | Respuesta agregada de los 3  |

Timeout por petición: **5 segundos** (`ApiConfig.timeout`).

---

## Cómo usar la app

1. Abre la app — verás dos botones: **Carga Directa** (rojo) y **Carga BFF** (verde).
2. Pulsa cualquiera de los dos para ejecutar la estrategia correspondiente.
3. La app muestra:
   - **Tiempo (ms)** que tardó la operación.
   - **Modo usado** (Directa o BFF).
   - **Datos** organizados en tres secciones: *Perfil*, *Restaurantes* y *Pedidos activos*.
4. Repite la prueba alternando modos para comparar tiempos.

---

## Manejo de errores

La app contempla los siguientes escenarios:

| Situación                          | Comportamiento                                                |
|------------------------------------|---------------------------------------------------------------|
| Timeout (>5s)                      | Pantalla de error con mensaje y botón **Reintentar**          |
| Servidor inalcanzable              | Mensaje *"No fue posible contactar al servidor"*              |
| Respuesta HTTP ≠ 200               | Se lanza `HttpException` y se muestra error                   |
| Cualquier otra excepción           | Mensaje genérico con detalle técnico                          |

El botón **Reintentar** vuelve a ejecutar el último modo seleccionado (Directa o BFF).

---

## Solución de problemas

**No carga / timeout en celular físico**
- Verifica que el celular y el computador estén en la **misma red Wi-Fi**.
- Confirma la IP del computador y actualízala en `ApiConfig.host`.
- Revisa que el firewall del SO no esté bloqueando los puertos `8000–8003`.

**No carga en emulador Android**
- Cambia `ApiConfig.host` a `'10.0.2.2'` (descomenta la línea correspondiente).

**Errores `HTTP 404 / 500`**
- Verifica que **todos** los microservicios y el BFF estén corriendo (`PatronBFF/`).
- Confirma que las rutas (`/perfil`, `/restaurantes`, `/pedidos`, `/home`) coincidan con las del backend.

**Cleartext HTTP en Android (release)**
- La app usa `http://` (sin TLS). En modo *release* puede requerir habilitar `usesCleartextTraffic` en `AndroidManifest.xml` o configurar `network_security_config.xml`.

---

## Contexto académico

Proyecto del **Taller 4** de la asignatura *Sistemas Distribuidos*. Su objetivo pedagógico es comparar empíricamente el patrón **BFF (Backend For Frontend)** frente a la **carga directa de microservicios** desde el cliente, observando latencia, complejidad del cliente y acoplamiento.
