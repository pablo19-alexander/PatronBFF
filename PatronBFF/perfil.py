"""Microservicio Perfil - Puerto 8001."""
import asyncio
from fastapi import FastAPI
import uvicorn

app = FastAPI(title="Perfil Service")


@app.get("/perfil")
async def get_perfil():
    await asyncio.sleep(1)
    return {
        "nombre": "Ana Maria Restrepo",
        "email": "ana.restrepo@example.com",
        "ciudad": "Medellin",
        "rol": "Cliente Premium",
    }


@app.get("/health")
async def health():
    return {"service": "perfil", "status": "ok"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
