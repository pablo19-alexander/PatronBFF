"""Microservicio Pedidos - Puerto 8003."""
import asyncio
from fastapi import FastAPI
import uvicorn

app = FastAPI(title="Pedidos Service")


@app.get("/pedidos")
async def get_pedidos():
    await asyncio.sleep(1)
    return {
        "pedidos_activos": [
            {"id": "P-1042", "restaurante": "La Trattoria", "estado": "En camino", "total": 38500},
            {"id": "P-1043", "restaurante": "Sushi Express", "estado": "Preparando", "total": 52000},
            {"id": "P-1044", "restaurante": "Vegan Bowl", "estado": "Confirmado", "total": 27000},
        ],
        "total_pedidos_mes": 14,
    }


@app.get("/health")
async def health():
    return {"service": "pedidos", "status": "ok"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8003)
