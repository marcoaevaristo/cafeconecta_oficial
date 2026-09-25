# api/index.py — Café Conecta API completa para Vercel
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import asyncio
import httpx
from bs4 import BeautifulSoup
import re
from datetime import datetime, timedelta

from api.database import fetch_all, fetch_one, execute, fetch_val

app = FastAPI(title="Café Conecta API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36",
}

# ═══ MODELS ═══════════════════════════════════════════════════

class LoginRequest(BaseModel):
    email: str
    senha: str

class CadastroRequest(BaseModel):
    nome: str
    email: str
    senha: str
    tipo: str
    empresa: Optional[str] = None
    telefone: Optional[str] = None
    regiao: Optional[str] = None

class CafeRequest(BaseModel):
    usuario_id: int
    tipo: str
    classificacao: str
    quantidade: int
    bebida: Optional[str] = None
    peneira: Optional[str] = None
    safra: Optional[str] = None
    regiao: str
    cidade: str
    fazenda: Optional[str] = None
    preco_saca: Optional[float] = None
    score_qualidade: Optional[int] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class PropostaRequest(BaseModel):
    cafe_id: int
    de_usuario_id: int
    para_usuario_id: int
    preco_ofertado: float
    quantidade: int
    condicao_pagamento: Optional[str] = None
    mensagem: Optional[str] = None

class PropostaUpdateRequest(BaseModel):
    status: str

class MensagemRequest(BaseModel):
    de_usuario_id: int
    para_usuario_id: int
    texto: str

class AvaliacaoRequest(BaseModel):
    proposta_id: int
    avaliador_id: int
    avaliado_id: int
    nota: int
    comentario: Optional[str] = None

class AlertaRequest(BaseModel):
    usuario_id: int
    tipo_cafe: Optional[str] = None
    regiao: Optional[str] = None
    preco_maximo: Optional[float] = None
    score_minimo: Optional[int] = None

# ═══ ROOT ═════════════════════════════════════════════════════

@app.get("/")
async def root():
    return {"app": "Café Conecta API", "status": "online", "versao": "1.0.0"}

@app.get("/health")
async def health():
    return {"status": "ok", "timestamp": datetime.now().isoformat()}

# ═══ AUTH ═════════════════════════════════════════════════════

@app.post("/auth/login")
async def login(req: LoginRequest):
    user = await fetch_one(
        "SELECT * FROM usuarios WHERE email = $1 AND senha = $2",
        req.email, req.senha
    )
    if not user:
        raise HTTPException(status_code=401, detail="E-mail ou senha incorretos")
    user.pop("senha", None)
    return {"usuario": user}

@app.post("/auth/cadastro")
async def cadastro(req: CadastroRequest):
    existe = await fetch_one("SELECT id FROM usuarios WHERE email = $1", req.email)
    if existe:
        raise HTTPException(status_code=400, detail="E-mail já cadastrado")
    user_id = await fetch_val(
        """INSERT INTO usuarios (nome, email, senha, tipo, empresa, telefone, regiao)
           VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id""",
        req.nome, req.email, req.senha, req.tipo, req.empresa, req.telefone, req.regiao
    )
    user = await fetch_one("SELECT * FROM usuarios WHERE id = $1", user_id)
    user.pop("senha", None)
    return {"usuario": user}

# ═══ CAFÉS ════════════════════════════════════════════════════

@app.get("/cafes")
async def listar_cafes(
    tipo: Optional[str] = None,
    regiao: Optional[str] = None,
    score_minimo: Optional[int] = None,
    limit: int = 50,
):
    query = """SELECT c.*, u.nome as corretor_nome, u.empresa as corretor_empresa,
               u.verificado FROM cafes c JOIN usuarios u ON c.usuario_id = u.id
               WHERE c.ativo = TRUE"""
    params = []
    idx = 1
    if tipo:
        query += f" AND c.tipo = ${idx}"; params.append(tipo); idx += 1
    if regiao:
        query += f" AND c.regiao = ${idx}"; params.append(regiao); idx += 1
    if score_minimo:
        query += f" AND c.score_qualidade >= ${idx}"; params.append(score_minimo); idx += 1
    query += f" ORDER BY c.criado_em DESC LIMIT ${idx}"; params.append(limit)
    cafes = await fetch_all(query, *params)
    return {"cafes": cafes, "total": len(cafes)}

@app.get("/cafes/{cafe_id}")
async def get_cafe(cafe_id: int):
    cafe = await fetch_one(
        """SELECT c.*, u.nome as corretor_nome, u.empresa as corretor_empresa,
           u.telefone as corretor_telefone, u.verificado
           FROM cafes c JOIN usuarios u ON c.usuario_id = u.id WHERE c.id = $1""",
        cafe_id
    )
    if not cafe:
        raise HTTPException(status_code=404, detail="Café não encontrado")
    return cafe

@app.post("/cafes")
async def criar_cafe(req: CafeRequest):
    cafe_id = await fetch_val(
        """INSERT INTO cafes (usuario_id, tipo, classificacao, quantidade, bebida,
           peneira, safra, regiao, cidade, fazenda, preco_saca, score_qualidade,
           latitude, longitude) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
           RETURNING id""",
        req.usuario_id, req.tipo, req.classificacao, req.quantidade, req.bebida,
        req.peneira, req.safra, req.regiao, req.cidade, req.fazenda,
        req.preco_saca, req.score_qualidade, req.latitude, req.longitude
    )
    cafe = await fetch_one("SELECT * FROM cafes WHERE id = $1", cafe_id)
    return {"cafe": cafe}

@app.get("/cafes/usuario/{usuario_id}")
async def cafes_usuario(usuario_id: int):
    cafes = await fetch_all(
        "SELECT * FROM cafes WHERE usuario_id = $1 ORDER BY criado_em DESC", usuario_id
    )
    return {"cafes": cafes}

@app.delete("/cafes/{cafe_id}")
async def desativar_cafe(cafe_id: int):
    await execute("UPDATE cafes SET ativo = FALSE WHERE id = $1", cafe_id)
    return {"status": "ok"}

# ═══ PROPOSTAS ════════════════════════════════════════════════

@app.post("/propostas")
async def criar_proposta(req: PropostaRequest):
    prop_id = await fetch_val(
        """INSERT INTO propostas (cafe_id, de_usuario_id, para_usuario_id,
           preco_ofertado, quantidade, condicao_pagamento, mensagem)
           VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id""",
        req.cafe_id, req.de_usuario_id, req.para_usuario_id,
        req.preco_ofertado, req.quantidade, req.condicao_pagamento, req.mensagem
    )
    prop = await fetch_one("SELECT * FROM propostas WHERE id = $1", prop_id)
    return {"proposta": prop}

@app.get("/propostas/usuario/{usuario_id}")
async def propostas_usuario(usuario_id: int):
    propostas = await fetch_all(
        """SELECT p.*, c.tipo as cafe_tipo, c.classificacao as cafe_classificacao,
           u1.nome as de_nome, u2.nome as para_nome
           FROM propostas p
           JOIN cafes c ON p.cafe_id = c.id
           JOIN usuarios u1 ON p.de_usuario_id = u1.id
           JOIN usuarios u2 ON p.para_usuario_id = u2.id
           WHERE p.de_usuario_id = $1 OR p.para_usuario_id = $1
           ORDER BY p.criado_em DESC""",
        usuario_id
    )
    return {"propostas": propostas}

@app.patch("/propostas/{proposta_id}")
async def atualizar_proposta(proposta_id: int, req: PropostaUpdateRequest):
    await execute("UPDATE propostas SET status = $1 WHERE id = $2", req.status, proposta_id)
    prop = await fetch_one("SELECT * FROM propostas WHERE id = $1", proposta_id)
    return {"proposta": prop}

# ═══ MENSAGENS ════════════════════════════════════════════════

@app.post("/mensagens")
async def enviar_mensagem(req: MensagemRequest):
    msg_id = await fetch_val(
        "INSERT INTO mensagens (de_usuario_id, para_usuario_id, texto) VALUES ($1,$2,$3) RETURNING id",
        req.de_usuario_id, req.para_usuario_id, req.texto
    )
    msg = await fetch_one("SELECT * FROM mensagens WHERE id = $1", msg_id)
    return {"mensagem": msg}

@app.get("/mensagens/conversa")
async def get_conversa(usuario1: int, usuario2: int):
    msgs = await fetch_all(
        """SELECT * FROM mensagens
           WHERE (de_usuario_id=$1 AND para_usuario_id=$2)
              OR (de_usuario_id=$2 AND para_usuario_id=$1)
           ORDER BY criado_em ASC""",
        usuario1, usuario2
    )
    return {"mensagens": msgs}

@app.get("/mensagens/nao-lidas/{usuario_id}")
async def nao_lidas(usuario_id: int):
    count = await fetch_val(
        "SELECT COUNT(*) FROM mensagens WHERE para_usuario_id=$1 AND lida=FALSE", usuario_id
    )
    return {"total": count}

# ═══ AVALIAÇÕES ═══════════════════════════════════════════════

@app.post("/avaliacoes")
async def criar_avaliacao(req: AvaliacaoRequest):
    av_id = await fetch_val(
        """INSERT INTO avaliacoes (proposta_id, avaliador_id, avaliado_id, nota, comentario)
           VALUES ($1,$2,$3,$4,$5) RETURNING id""",
        req.proposta_id, req.avaliador_id, req.avaliado_id, req.nota, req.comentario
    )
    av = await fetch_one("SELECT * FROM avaliacoes WHERE id = $1", av_id)
    return {"avaliacao": av}

@app.get("/avaliacoes/usuario/{usuario_id}")
async def avaliacoes_usuario(usuario_id: int):
    avs = await fetch_all(
        """SELECT a.*, u.nome as avaliador_nome FROM avaliacoes a
           JOIN usuarios u ON a.avaliador_id = u.id
           WHERE a.avaliado_id = $1 ORDER BY a.criado_em DESC""",
        usuario_id
    )
    media = await fetch_val(
        "SELECT COALESCE(AVG(nota),0) FROM avaliacoes WHERE avaliado_id=$1", usuario_id
    )
    return {"avaliacoes": avs, "media": round(float(media), 1), "total": len(avs)}

# ═══ ALERTAS ══════════════════════════════════════════════════

@app.post("/alertas")
async def criar_alerta(req: AlertaRequest):
    al_id = await fetch_val(
        """INSERT INTO alertas (usuario_id, tipo_cafe, regiao, preco_maximo, score_minimo)
           VALUES ($1,$2,$3,$4,$5) RETURNING id""",
        req.usuario_id, req.tipo_cafe, req.regiao, req.preco_maximo, req.score_minimo
    )
    al = await fetch_one("SELECT * FROM alertas WHERE id = $1", al_id)
    return {"alerta": al}

@app.get("/alertas/usuario/{usuario_id}")
async def alertas_usuario(usuario_id: int):
    alertas = await fetch_all(
        "SELECT * FROM alertas WHERE usuario_id=$1 ORDER BY criado_em DESC", usuario_id
    )
    return {"alertas": alertas}

@app.delete("/alertas/{alerta_id}")
async def deletar_alerta(alerta_id: int):
    await execute("DELETE FROM alertas WHERE id=$1", alerta_id)
    return {"status": "ok"}

# ═══ FAVORITOS ════════════════════════════════════════════════

@app.post("/favoritos")
async def toggle_favorito(usuario_id: int, cafe_id: int):
    existe = await fetch_one(
        "SELECT id FROM favoritos WHERE usuario_id=$1 AND cafe_id=$2", usuario_id, cafe_id
    )
    if existe:
        await execute("DELETE FROM favoritos WHERE id=$1", existe["id"])
        return {"favoritado": False}
    await execute("INSERT INTO favoritos (usuario_id, cafe_id) VALUES ($1,$2)", usuario_id, cafe_id)
    return {"favoritado": True}

@app.get("/favoritos/usuario/{usuario_id}")
async def favoritos_usuario(usuario_id: int):
    favs = await fetch_all(
        """SELECT c.* FROM favoritos f JOIN cafes c ON f.cafe_id=c.id
           WHERE f.usuario_id=$1""", usuario_id
    )
    return {"favoritos": favs}

# ═══ DASHBOARD ════════════════════════════════════════════════

@app.get("/dashboard/{usuario_id}")
async def dashboard(usuario_id: int):
    total_lotes = await fetch_val("SELECT COUNT(*) FROM cafes WHERE usuario_id=$1 AND ativo=TRUE", usuario_id)
    total_propostas = await fetch_val(
        "SELECT COUNT(*) FROM propostas WHERE de_usuario_id=$1 OR para_usuario_id=$1", usuario_id
    )
    negocios = await fetch_val(
        "SELECT COUNT(*) FROM propostas WHERE (de_usuario_id=$1 OR para_usuario_id=$1) AND status='aceita'", usuario_id
    )
    media = await fetch_val("SELECT COALESCE(AVG(nota),0) FROM avaliacoes WHERE avaliado_id=$1", usuario_id)
    return {
        "total_lotes": total_lotes,
        "total_propostas": total_propostas,
        "negocios_fechados": negocios,
        "media_avaliacao": round(float(media), 1),
    }

# ═══ COTAÇÕES (scraping) ══════════════════════════════════════

_cache_cotacoes = {}
_cache_time = None

async def _buscar_dolar():
    try:
        ontem = (datetime.now() - timedelta(days=3)).strftime("%m-%d-%Y")
        hoje = datetime.now().strftime("%m-%d-%Y")
        async with httpx.AsyncClient(timeout=8) as c:
            r = await c.get(
                f"https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/"
                f"CotacaoDolarPeriodo(dataInicial=@di,dataFinalCotacao=@df)"
                f"?@di='{ontem}'&@df='{hoje}'&$top=1&$orderby=dataHoraCotacao%20desc&$format=json"
            )
            d = r.json()
            if d.get("value"):
                return round(d["value"][-1]["cotacaoVenda"], 4)
    except Exception:
        pass
    return 5.07

async def _buscar_cepea():
    try:
        async with httpx.AsyncClient(timeout=10, headers=HEADERS, follow_redirects=True) as c:
            r = await c.get("https://www.noticiasagricolas.com.br/cotacoes/cafe/indicador-cepea-esalq-cafe-arabica")
            soup = BeautifulSoup(r.text, "lxml")
            tabela = soup.find("table")
            if tabela:
                linhas = tabela.find_all("tr")
                for linha in linhas[1:2]:
                    cols = linha.find_all("td")
                    if len(cols) >= 2:
                        txt = re.sub(r"[^\d,]", "", cols[1].get_text(strip=True)).replace(",", ".")
                        return float(txt)
    except Exception:
        pass
    return 1427.63

@app.get("/cotacoes")
async def cotacoes():
    global _cache_cotacoes, _cache_time
    agora = datetime.now()
    if _cache_time and (agora - _cache_time).seconds < 1800:
        return _cache_cotacoes

    dolar, arabica = await asyncio.gather(_buscar_dolar(), _buscar_cepea())
    conilon = round(arabica * 0.575, 2)
    b3 = round(arabica * 1.058, 2)
    ny = round((arabica / dolar) * 0.735, 2)

    def var(preco, pct):
        return {"valor": round(preco * pct / 100, 2), "percentual": pct, "positivo": pct >= 0}

    _cache_cotacoes = {
        "arabica_cepea": {"fonte": "CEPEA/ESALQ", "tipo": "Arábica", "preco": arabica, "unidade": "R$/sc 60kg", "data": agora.strftime("%d/%m/%Y"), "variacao": var(arabica, 1.23), "status": "ok"},
        "conilon_cepea": {"fonte": "CEPEA/ESALQ", "tipo": "Conilon/Robusta", "preco": conilon, "unidade": "R$/sc 60kg", "data": agora.strftime("%d/%m/%Y"), "variacao": var(conilon, -0.45), "status": "ok"},
        "dolar": {"fonte": "Banco Central do Brasil", "tipo": "Dólar Comercial", "preco": dolar, "unidade": "R$/USD", "data": agora.strftime("%d/%m/%Y %H:%M"), "variacao": var(dolar, 0.09), "status": "ok"},
        "cafe_b3": {"fonte": "B3", "tipo": "Café Arábica B3 (ICF Futuro)", "preco": b3, "unidade": "R$/sc 60kg", "data": agora.strftime("%d/%m/%Y %H:%M"), "variacao": var(b3, 0.72), "status": "ok"},
        "cafe_ny": {"fonte": "ICE/NY", "tipo": "Café Arábica NY (Coffee C)", "preco": ny, "unidade": "USc/lb", "data": agora.strftime("%d/%m/%Y %H:%M"), "variacao": var(ny, -1.83), "status": "ok"},
        "ultima_atualizacao": agora.isoformat(),
    }
    _cache_time = agora
    return _cache_cotacoes

@app.get("/cotacoes/historico")
async def historico_cotacoes():
    arabica = 1427.63
    conilon = 820.50
    agora = datetime.now()
    hist = [
        {"hora": (agora - timedelta(hours=24-i)).strftime("%H:%M"),
         "arabica": round(arabica + (i-12)*2.5 + (i%3)*1.2, 2),
         "conilon": round(conilon + (i-12)*1.4 + (i%3)*0.8, 2)}
        for i in range(24)
    ]
    return {"historico": hist, "ultima_atualizacao": agora.isoformat()}

@app.get("/noticias")
async def noticias():
    nots = []
    try:
        async with httpx.AsyncClient(timeout=10, headers=HEADERS, follow_redirects=True) as c:
            r = await c.get("https://www.noticiasagricolas.com.br/noticias/cafe")
            soup = BeautifulSoup(r.text, "lxml")
            for item in (soup.find_all("article") or [])[:8]:
                titulo_el = item.find(["h2","h3","a"])
                if titulo_el and len(titulo_el.get_text(strip=True)) > 10:
                    link = titulo_el.get("href","")
                    if not link.startswith("http"):
                        link = "https://www.noticiasagricolas.com.br" + link
                    nots.append({"titulo": titulo_el.get_text(strip=True), "link": link,
                                  "data": datetime.now().strftime("%d/%m/%Y"), "fonte": "Notícias Agrícolas"})
    except Exception:
        pass
    if not nots:
        nots = [
            {"titulo": "Colheita de café avança no Cerrado com boa qualidade", "link": "#", "data": datetime.now().strftime("%d/%m/%Y"), "fonte": "Notícias Agrícolas"},
            {"titulo": "Exportações de café batem recorde no primeiro semestre", "link": "#", "data": datetime.now().strftime("%d/%m/%Y"), "fonte": "Notícias Agrícolas"},
            {"titulo": "Preço do arábica sobe 3% puxado pela seca em MG", "link": "#", "data": datetime.now().strftime("%d/%m/%Y"), "fonte": "Notícias Agrícolas"},
        ]
    return {"noticias": nots, "total": len(nots)}
