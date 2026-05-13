"""Backend For Frontend (BFF) - Puerto 8000.

Agrega en paralelo las respuestas de los 3 microservicios y devuelve
un JSON consolidado listo para el cliente movil.
"""
import asyncio
import os
import httpx
from fastapi import FastAPI, HTTPException
import uvicorn

app = FastAPI(title="BFF Home")

PERFIL_URL = os.getenv("PERFIL_URL", "http://127.0.0.1:8001/perfil")
RESTAURANTES_URL = os.getenv("RESTAURANTES_URL", "http://127.0.0.1:8002/restaurantes")
PEDIDOS_URL = os.getenv("PEDIDOS_URL", "http://127.0.0.1:8003/pedidos")

UPSTREAM_TIMEOUT = httpx.Timeout(4.0)


async def fetch_json(client: httpx.AsyncClient, url: str) -> dict:
    r = await client.get(url, timeout=UPSTREAM_TIMEOUT)
    r.raise_for_status()
    return r.json()


@app.get("/home")
async def home():
    async with httpx.AsyncClient() as client:
        try:
            perfil, restaurantes_raw, pedidos = await asyncio.gather(
                fetch_json(client, PERFIL_URL),
                fetch_json(client, RESTAURANTES_URL),
                fetch_json(client, PEDIDOS_URL),
            )
        except (httpx.HTTPError, httpx.TimeoutException) as exc:
            raise HTTPException(status_code=503, detail=f"upstream error: {exc}")

    return {
        "perfil": perfil,
        "restaurantes": restaurantes_raw.get("restaurantes", []),
        "pedidos": pedidos,
    }


@app.get("/health")
async def health():
    return {"service": "bff", "status": "ok"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
