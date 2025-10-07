# WallVagua Flutter

> 📱💻 Wallpapers multiplataforma — Android + Desktop (Windows) — con Flutter (Oct‑2025).

Este documento describe en profundidad la arquitectura, el flujo de datos, las decisiones de diseño, los endpoints consumidos, las reglas de normalización de imágenes (compatibles con la app Java original), el uso de Flutter + Flutter Desktop y el proceso de build/release. Está pensado para servir como referencia técnica y como guía práctica para operación/QA.

---

## ✨ Características (visibles)

- 🧭 Navegación por pestañas: Recent, Featured, Popular, Random, Live.
- 🖼️ Feed con `CachedNetworkImage`, pull‑to‑refresh e infinito.
- 🔎 Búsqueda segmentada (wallpapers / categorías) con historial persistente.
- ⭐ Favoritos con persistencia simple (SharedPreferences): añadir/eliminar desde grid y detalle.
- ⚙️ Ajustes: tema claro/oscuro, columnas de grid, limpiar caché, enlaces (privacidad/more apps), compartir app.
- 🧩 Detalle de wallpaper: descargar, compartir, hoja de información técnica (resolución, tamaño, tipo, tags, vistas, descargas), y actualización de contadores.
- 🧱 Desktop‑ready (Windows): rutas de descargas, normalización de host, UX adaptado.
- 🧿 Ícono de app unificado (Android + Windows) y como avatar en la AppBar.

## 🧱 Arquitectura (carpetas y responsabilidades)

```
lib/
├─ core/
│  ├─ constants.dart         # claves, defaults, aliases de acciones
│  ├─ theme/app_theme.dart   # Material 3, colorScheme, tipografía
│  └─ utils/base64_utils.dart# helpers de decodificación
│
├─ data/
│  ├─ models/                # contratos de datos (POJOs)
│  │  ├─ category.dart
│  │  ├─ menu_tab.dart
│  │  ├─ paged_response.dart
│  │  ├─ settings_payload.dart
│  │  └─ wallpaper.dart
│  │
│  ├─ services/
│  │  └─ api_service.dart    # Dio, baseUrl normalizada, rootBaseUrl
│  │
│  └─ repositories/
│     ├─ app_repository.dart       # decodificación de licencia, cache inicial
│     └─ wallpaper_repository.dart # acceso a endpoints + normalización de URLs
│
├─ providers/                 # Riverpod 2.6 (StateNotifier/Provider)
│  ├─ app_config_provider.dart       # bootstrap, cache, fallback offline/redirect
│  ├─ categories_provider.dart       # categorías (FutureProvider)
│  ├─ favorites_provider.dart        # favoritos persistentes
│  ├─ layout_provider.dart           # columnas de grid y layout de categorías
│  ├─ search_history_provider.dart   # historial de búsqueda
│  ├─ search_provider.dart           # estado de resultados (wallpapers/categorías)
│  ├─ theme_provider.dart            # tema (ThemeMode) persistido
│  └─ wallpaper_feed_provider.dart   # feed paginado/infinito
│
├─ features/
│  ├─ shell/shell_page.dart          # Scaffold, BottomNav, AppBar con avatar de app
│  ├─ splash/splash_page.dart        # arranque, escucha de app_config_provider
│  ├─ home/home_page.dart            # TabBar dinámico desde settings/menus
│  ├─ wallpapers/
│  │  ├─ wallpaper_tab.dart          # grid scrollable (paginado)
│  │  └─ category_wallpaper_page.dart# feed por categoría
│  ├─ details/wallpaper_detail_page.dart# acciones y ficha técnica
│  ├─ categories/categories_page.dart# lista/grilla (preferencia en Ajustes)
│  ├─ search/search_page.dart        # búsqueda + segmentos + historial
│  └─ settings/settings_page.dart    # ajustes de UI y utilidades
│
└─ tool/                            # utilidades de desarrollo
   └─ convert_icon.dart             # convierte app_icon.webp → app_icon.png
```

### 🔄 Flujo de datos (end‑to‑end)

1. `AppRepository.decodeServerKey()` decodifica la licencia (triple Base64) y resolve:
   - `baseUrl`: si viene con `localhost`, se adapta por plataforma (Android: `10.0.2.2`; Desktop/Web: `127.0.0.1`).
   - `applicationId`: comparado contra el package actual (en Desktop se permite override con el de la licencia).
2. `app_config_provider.initialize()`:
   - llama a `fetchSettings(baseUrl, packageName)` y cachea menús/settings/app info.
   - si el servidor responde `status=ok`, publica estado `isReady=true`.
   - si falla, intenta fallback desde caché (modo degradado); si no, expone `errorMessage`.
3. La `SplashPage` escucha cambios del provider y navega a:
   - `RedirectPage` si `app.status=0` y existe `redirectUrl`.
   - `ShellPage` en caso normal.
4. `HomePage` construye `TabBar`/`TabBarView` a partir de `menus` (orden/filtro/categoría), creando `WallpaperTab`s.
5. `WallpaperTab` consume `wallpaper_feed_provider(request)` que usa `WallpaperRepository.fetchWallpapers`.
6. `WallpaperRepository` llama `ApiService.get('api.php', query)` y normaliza cada `Wallpaper`:
   - compone URLs absolutas (`rootBaseUrl + /upload/...` o `/upload/thumbs/...`) cuando el backend devuelve nombres de archivo.
   - replica reglas de la app Java para soportar `url`, `mp4`, `webp`, `bmp`, etc.
7. `WallpaperDetailPage` recupera detalle por `image_id`, actualiza vista (`update_view`) y permite acciones:
   - descargar (con ruta adaptada a plataforma)
   - compartir (SharePlus)
   - aplicar como wallpaper (solo Android; plugin nativo)

---

## 🧠 Manejo de plataformas (Android, Desktop, Web)

| Área | Android | Windows / Desktop | Web |
|------|---------|--------------------|-----|
| Host `localhost` | `10.0.2.2` | `127.0.0.1` | `127.0.0.1` |
| Descargas | `getExternalFilesDir`/Descargas | `getDownloadsDirectory` o Documentos | N/A (descargas navegador) |
| Aplicar wallpaper | ✅ plugin | ❌ (no soportado) | ❌ |
| Ícono app | mipmaps generados | `.ico` en runner | N/A |

La normalización de host se resuelve en `AppRepository` y la de rutas de imágenes en `WallpaperRepository`.

---

## 📦 Modelos y contratos (JSON → Dart)

### `Wallpaper`
Campos relevantes:

```json
{
  "image_id": 2009,
  "image_name": "Reach for the stars…",
  "image_upload": "1758700176_graphic‑iphone.png",
  "image_thumb": "1758700176_graphic‑iphone.png",
  "image_url": "",
  "type": "upload|url",
  "resolution": "506 x 900",
  "size": "319.05 KB",
  "mime": "image/png",
  "views": 14,
  "downloads": 0,
  "featured": "no",
  "tags": "Graphics",
  "category_id": 52,
  "category_name": "Graphics",
  "rewarded": 1,
  "last_update": "2025-09-24 02:49:36"
}
```

Normalización en `WallpaperRepository`:

- Si `image_url` viene vacío pero hay `image_upload`/`image_thumb`, se construye absoluta:
  - `rootBaseUrl + /upload/ + image_upload`
  - `rootBaseUrl + /upload/thumbs/ + image_thumb`
- Reglas por `type` y `mime` replican la app Java:
  - `type=url` y `mime ∈ {octet-stream, video/mp4}` → usar thumb.
  - `mime ∈ {webp, bmp}` → usar `/upload/`.
  - Si el valor ya es absoluto (`http(s)://`), se respeta sin tocar.

### `Category`

```json
{
  "category_id": "6",
  "category_name": "Anime",
  "category_image": "1757272473_images.png",
  "total_wallpaper": "120"
}
```

Se anexa `rootBaseUrl + /upload/category/ + category_image` si viene relativo.

### `SettingsPayload`

- `status`: `ok|error`
- `app`: `{ package_name, status, redirect_url }`
- `menus`: lista de `MenuTab` `{ id, title, order, filter, category }`
- `settings`: enlaces, providers, topic de notificaciones
- `ads*`: metadatos (no utilizados en desktop)

---

## 🔌 Servicios y tiempo de vida de red

### `ApiService` (Dio)

- `baseUrl` normalizado a `…/api/v1/` y almacenamiento de `rootBaseUrl` (dominio/host raíz) para componer rutas absolutas.
- Timeouts: connect 10s / send 20s / receive 30s.
- Cabeceras: `Data-Agent: Material Wallpaper`, `Cache-Control: max-age=0`.

### Retrys / Errores

- Los errores se exponen en `app_config_provider` y se muestran en `SplashPage`.
- Para feed/búsqueda, los estados `error` y acciones de reintento están presentes en las pantallas.

---

## 🧪 Estado con Riverpod (2.6)

- `app_config_provider`: `AppConfigState { isLoading, isReady, isUsingCache, errorMessage, baseUrl, menus, settings, app }`.
- `wallpaper_feed_provider(request)`: `WallpaperFeedState { items, page, totalPages, isLoading, isRefreshing, error }`.
- `favorites_provider`: lista persistida (serializada con `toJson()` de `Wallpaper`).
- `layout_provider`: controla columnas del grid y layout de categorías.
- `search_provider`: maneja segmento activo y resultados.

Diseño: providers pequeños y específicos, estados inmutables con `copyWith`, errores siempre limpian/establecen `errorMessage` de forma explícita (`clearError`).

---

## 🖥️ UI y Accesibilidad

- Material 3; colores claros/oscuros y contraste adecuado (`onPrimary`, `onSurfaceVariant`).
- Tipografía configurable (`fontFamily: 'WallVagua'`).
- Botones grandes en acciones de detalle, iconografía consistente y textos descriptivos.

---

## 🧰 Optimización práctica

- Imágenes: `CachedNetworkImage` + placeholders sólidos para evitar layout shifts.
- Paginado: `WallpaperFeedController` sólo pide siguiente página cuando el scroll se aproxima al final.
- Caché/limpieza: desde Ajustes, `flutter_cache_manager` + limpieza del `ImageCache` de Flutter.
- Normalización de rutas: evita 404 por rutas relativas del backend.

---

## 🧿 Iconos unificados (Android + Windows)

1) Fuente del icono: `assets/images/app_icon.webp` (extraído del mipmap Android).
2) Conversión a PNG para generadores:

```bash
dart run tool/convert_icon.dart
```

3) Regenerar iconos nativos:

```bash
flutter pub run flutter_launcher_icons
```

Genera:
- Android → mipmaps (`android/app/src/main/res/mipmap-*`)
- Windows → `windows/runner/resources/app_icon.ico`

---

## 🚀 Ejecución & Build

### Requisitos
- Flutter 3.19+ estable.
- Android SDK (para Android) / habilitar Desktop para Windows (`flutter config --enable-windows-desktop`).

### Desarrollo

```bash
flutter pub get
# Android
flutter run -d android
# Windows
flutter config --enable-windows-desktop
flutter run -d windows
```

### QA rápida

```bash
flutter analyze
flutter test
```

### Release (orientativo)

- Android:

```bash
flutter build apk --release
flutter build appbundle --release
```

- Windows:

```bash
flutter build windows
```

---

## 🔗 Endpoints consumidos

- `GET api.php?get_new_wallpapers` (paginado: `page`, `count`, `filter`, `order`, `category`)
- `GET api.php?get_wallpaper_details&id=...`
- `GET api.php?get_categories`
- `GET api.php?get_search` (wallpapers)
- `GET api.php?get_search_category` (categorías)
- `POST api.php?update_view` (`image_id`)
- `POST api.php?update_download` (`image_id`)

---

## 🛡️ Permisos y notas de plataforma

- Android: `SET_WALLPAPER`, `SET_WALLPAPER_HINTS`, `READ_MEDIA_IMAGES` (y `READ_EXTERNAL_STORAGE` para ≤ SDK 32).
- Aplicar como wallpaper sólo está disponible en Android (plugin nativo `flutter_wallpaper_manager`).
- En Desktop, las descargas usan `getDownloadsDirectory()` (si está disponible) o documentos.

---

## 🧩 Decisiones técnicas clave

- Mantener `rootBaseUrl` en `ApiService` para componer URLs absolutas de imágenes.
- Replicar reglas de la app Java en `WallpaperRepository` para fidelidad de diseño/función.
- Riverpod 2.6 por estabilidad: código preparado para migración a 3.x (futuro `Notifier`).
- Sin dependencia a DB nativa en Desktop: persistencia simple en `SharedPreferences`.

---

## 🧪 Pruebas y cobertura

- `test/widget_test.dart` incluye placeholder y patrón de arranque; la estructura admite tests de providers y repos.
- Recomendado: mocks para `ApiService` con `DioAdapter`/`http_mock_adapter` y pruebas de normalización en `WallpaperRepository`.

---

## 🛠️ Scripts y utilidades

- Convertir icono: `dart run tool/convert_icon.dart`.
- Regenerar iconos: `flutter pub run flutter_launcher_icons`.
- Lint: `flutter analyze`.
- Tests: `flutter test`.

---

## 🧑‍🎨 Estilo de código

- Preferir funciones puras en normalización.
- `copyWith` en estados; `clearError` para limpiar errores.
- Evitar UI blocking: cargas y toasts/snackbars bien delimitados.

---

## 🧯 Troubleshooting (FAQ)

**No se ven imágenes en Desktop**
- Comprueba que el backend sea accesible desde Windows.
- Verifica que el host resultante sea `127.0.0.1` (no `10.0.2.2`).
- Activa logs de red en `ApiService` si fuese necesario.

**El detalle muestra imagen rota**
- Revisa `mime` y `type` del item. Las reglas empujan a `thumbs` en `mp4`/`octet-stream`.
- Confirma que exista el archivo en `/upload/` o `/upload/thumbs/`.

**El botón Aplicar no aparece en Desktop**
- Correcto: sólo Android tiene esa acción.

**Cambiar el ícono de la app**
- Reemplaza `assets/images/app_icon.webp`.
- Ejecuta: `dart run tool/convert_icon.dart` y luego `flutter pub run flutter_launcher_icons`.

---

## 📝 Changelog (resumen)

- Migración de la app Java a Flutter conservando modelo visual y reglas de negocio.
- Normalización de rutas de imágenes para sólido soporte Multiplataforma.
- Íconos unificados, ajustes avanzados, favoritos y búsqueda segmentada.

---

## 🤝 Contribución

1) Crea rama desde `main`.
2) Asegura `flutter analyze` y `flutter test` en verde.
3) Incluye notas breves en PR sobre cambios y decisiones.

---

## ⚖️ Licencia

Este proyecto integra un backend/licencia externa (clave de servidor). Asegúrate de cumplir los términos del proveedor del admin panel y de los assets.

---

Hecho con ❤️ en Flutter — listo para Android y Windows.
