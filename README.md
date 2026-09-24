# ☕ Café Conecta — Deploy Completo no Vercel

## Estrutura do projeto

```
cafe_deploy/
├── api/
│   ├── index.py       ← API FastAPI completa (todas as rotas)
│   └── database.py    ← Conexão com PostgreSQL
├── vercel.json        ← Configuração do Vercel
├── requirements.txt   ← Dependências Python
└── setup_banco.sql    ← Script para criar tabelas no PostgreSQL
```

---

## PASSO 1 — Criar banco no Neon (gratuito)

1. Acesse **neon.tech** e crie uma conta (pode usar Google)
2. Clique em **"Create Project"**
3. Nome: `cafe-conecta`, Region: `São Paulo (sa-east-1)`
4. Copie a **Connection String** que aparece:
   ```
   postgresql://usuario:senha@ep-xxx.sa-east-1.aws.neon.tech/cafe_conecta?sslmode=require
   ```

---

## PASSO 2 — Criar as tabelas no Neon

1. No painel do Neon, clique em **"SQL Editor"**
2. Copie todo o conteúdo do arquivo `setup_banco.sql`
3. Cole no editor e clique **Run**
4. Deve aparecer as 7 tabelas criadas + dados de teste

---

## PASSO 3 — Deploy no Vercel

### Opção A — Via GitHub (recomendado)

1. Crie um repositório no GitHub e suba os arquivos desta pasta
2. Acesse **vercel.com** → **New Project**
3. Importe o repositório
4. Em **Environment Variables**, adicione:
   ```
   DATABASE_URL = postgresql://usuario:senha@ep-xxx.sa-east-1.aws.neon.tech/cafe_conecta?sslmode=require
   ```
5. Clique **Deploy** ✅

### Opção B — Via CLI

```bash
npm install -g vercel
vercel login
cd cafe_deploy
vercel
```

Quando perguntar sobre variáveis de ambiente, adicione `DATABASE_URL`.

---

## PASSO 4 — Testar a API no ar

Acesse:
```
https://seu-projeto.vercel.app/
```

Deve retornar:
```json
{"app": "Café Conecta API", "status": "online", "versao": "1.0.0"}
```

Documentação interativa:
```
https://seu-projeto.vercel.app/docs
```

---

## PASSO 5 — Conectar o Flutter

Abra `lib/screens/cotacoes_screen.dart` e altere:
```dart
static const _baseUrl = 'https://seu-projeto.vercel.app';
```

Para cada tela do Flutter que usa a API, use essa URL base.

---

## Rotas disponíveis

| Método | Rota | Descrição |
|---|---|---|
| GET | / | Status da API |
| GET | /health | Health check |
| POST | /auth/login | Login |
| POST | /auth/cadastro | Cadastro |
| GET | /cafes | Listar cafés |
| GET | /cafes/{id} | Detalhe café |
| POST | /cafes | Criar anúncio |
| GET | /cafes/usuario/{id} | Meus anúncios |
| DELETE | /cafes/{id} | Remover anúncio |
| POST | /propostas | Enviar proposta |
| GET | /propostas/usuario/{id} | Minhas propostas |
| PATCH | /propostas/{id} | Aceitar/Recusar |
| POST | /mensagens | Enviar mensagem |
| GET | /mensagens/conversa | Histórico chat |
| GET | /mensagens/nao-lidas/{id} | Contador msgs |
| POST | /avaliacoes | Avaliar negociação |
| GET | /avaliacoes/usuario/{id} | Minhas avaliações |
| POST | /alertas | Criar alerta |
| GET | /alertas/usuario/{id} | Meus alertas |
| DELETE | /alertas/{id} | Remover alerta |
| POST | /favoritos | Toggle favorito |
| GET | /favoritos/usuario/{id} | Meus favoritos |
| GET | /dashboard/{id} | KPIs do dashboard |
| GET | /cotacoes | Cotações em tempo real |
| GET | /cotacoes/historico | Histórico 24h |
| GET | /noticias | Notícias do mercado |

---

## Teste rápido de login

```bash
curl -X POST https://seu-projeto.vercel.app/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"joao@cafesuldeminas.com.br","senha":"123456"}'
```

Deve retornar os dados do usuário João Pedro. ✅
