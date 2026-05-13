"""Microservicio Restaurantes - Puerto 8002."""
import asyncio
from fastapi import FastAPI
import uvicorn

app = FastAPI(title="Restaurantes Service")


@app.get("/restaurantes")
async def get_restaurantes():
    await asyncio.sleep(1)
    return {
        "restaurantes": [
            {"nombre": "La Trattoria", "rating": 4.7, "tiempo_entrega_min": 25},
            {"nombre": "Sushi Express", "rating": 4.5, "tiempo_entrega_min": 35},
            {"nombre": "Burger Lab", "rating": 4.3, "tiempo_entrega_min": 20},
            {"nombre": "Vegan Bowl", "rating": 4.8, "tiempo_entrega_min": 30},
            {"nombre": "Pollo Andino", "rating": 4.2, "tiempo_entrega_min": 28},
        ]
    }


@app.get("/health")
async def health():
    return {"service": "restaurantes", "status": "ok"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8002)
