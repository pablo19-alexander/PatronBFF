# PatronBFF — Backend del Taller 4

Backend distribuido en Python (FastAPI) con 3 microservicios y un BFF
agregador, pensado para el cliente Flutter del repositorio padre.

## Servicios

| Servicio       | Puerto | Endpoint         | Sleep |
|----------------|--------|------------------|-------|
| Perfil         | 8001   | `/perfil`        | 1 s   |
| Restaurantes   | 8002   | `/restaurantes`  | 1 s   |
| Pedidos        | 8003   | `/pedidos`       | 1 s   |
| BFF            | 8000   | `/home`          | —     |

El BFF orquesta los 3 microservicios **en paralelo** con `asyncio.gather`
y devuelve un JSON consolidado.

## Instalación

```bash
cd PatronBFF
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

## Ejecución

**Todo a la vez (recomendado para la demo):**
```bash
chmod +x start_all.sh
./start_all.sh
```

**Servicio por servicio (útil para apagar solo el BFF en la sustentación):**
```bash
python perfil.py        # terminal 1
python restaurantes.py  # terminal 2
python pedidos.py       # terminal 3
python bff.py           # terminal 4   <-- el profe te pedirá apagar este
```

## Verificación rápida

```bash
curl http://127.0.0.1:8001/perfil
curl http://127.0.0.1:8002/restaurantes
curl http://127.0.0.1:8003/pedidos
curl http://127.0.0.1:8000/home
```

## Red física (Fase 3)

- Todos los servicios escuchan en `0.0.0.0`, por lo que aceptan conexiones
  desde el celular físico o desde el emulador Android.
- **Emulador Android:** desde la app usa `10.0.2.2` como host.
- **Celular físico:** usa la IP Wi-Fi de tu computador (`192.168.1.X`),
  y verifica que celular y PC están en la misma red.
- **Firewall:** en Windows permite Python en redes privadas. En macOS,
  *Ajustes del Sistema → Red → Firewall* o autoriza la primera vez que
  el sistema pregunte.

Para encontrar tu IP:
```bash
# macOS / Linux
ipconfig getifaddr en0        # Wi-Fi en macOS
ip addr | grep inet           # Linux

# Windows
ipconfig
```

Luego actualiza `ApiConfig.host` en `lib/main.dart` del cliente.

## Contrato JSON

`GET /perfil` →
```json
{ "nombre": "...", "email": "...", "ciudad": "...", "rol": "..." }
```

`GET /restaurantes` →
```json
{ "restaurantes": [ { "nombre": "...", "rating": 4.7, "tiempo_entrega_min": 25 } ] }
```

`GET /pedidos` →
```json
{
  "pedidos_activos": [ { "id": "P-1042", "restaurante": "...", "estado": "...", "total": 38500 } ],
  "total_pedidos_mes": 14
}
```

`GET /home` (BFF) →
```json
{
  "perfil":  { ... },
  "restaurantes": [ ... ],      // lista desempaquetada, no objeto
  "pedidos": { ... }
}
```

## Demo de resiliencia

Apaga el BFF (Ctrl+C en su terminal) y pulsa **Carga BFF** en la app:
verás el mensaje amigable "¡Ups! La señal se perdió" con el botón de
reintentar (definido en `lib/main.dart`). Si apagas también los 3
microservicios, **Carga Directa** muestra el mismo error tras el
timeout de 5 s.
