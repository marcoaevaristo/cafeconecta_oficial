# api/database.py
import os
import asyncpg
from typing import Optional

# Configure DATABASE_URL nas variáveis de ambiente do Vercel
# Formato Neon: postgresql://user:senha@host.neon.tech/cafe_conecta?sslmode=require
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:123456@localhost:5432/cafe_conecta"
)

_pool: Optional[asyncpg.Pool] = None

async def get_pool() -> asyncpg.Pool:
    global _pool
    if _pool is None:
        ssl = "require" if "neon.tech" in DATABASE_URL else None
        _pool = await asyncpg.create_pool(
            DATABASE_URL,
            min_size=1,
            max_size=5,
            command_timeout=10,
            ssl=ssl,
        )
    return _pool

async def fetch_all(query: str, *args):
    pool = await get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(query, *args)
        return [dict(r) for r in rows]

async def fetch_one(query: str, *args):
    pool = await get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(query, *args)
        return dict(row) if row else None

async def execute(query: str, *args):
    pool = await get_pool()
    async with pool.acquire() as conn:
        return await conn.execute(query, *args)

async def fetch_val(query: str, *args):
    pool = await get_pool()
    async with pool.acquire() as conn:
        return await conn.fetchval(query, *args)
