#!/usr/bin/env bash
# Levanta los 3 microservicios + el BFF.
# Ctrl+C los apaga a todos.
set -euo pipefail

cd "$(dirname "$0")"

PIDS=()
cleanup() {
  echo
  echo "Apagando servicios..."
  for pid in "${PIDS[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
  wait 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "Iniciando microservicios + BFF en 0.0.0.0..."
python perfil.py        & PIDS+=($!)
python restaurantes.py  & PIDS+=($!)
python pedidos.py       & PIDS+=($!)
sleep 1
python bff.py           & PIDS+=($!)

echo
echo "Servicios activos:"
echo "  - Perfil       http://0.0.0.0:8001/perfil"
echo "  - Restaurantes http://0.0.0.0:8002/restaurantes"
echo "  - Pedidos      http://0.0.0.0:8003/pedidos"
echo "  - BFF          http://0.0.0.0:8000/home"
echo
echo "Ctrl+C para detener todo."
wait
