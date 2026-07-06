# FastFoodDelivery — iFood Clone

> **Status:** Documentação arquitetural em progresso  
> **Stack planejada:** Node.js + TypeScript + PostgreSQL + Redis + RabbitMQ  
> **Licença:** MIT

---

## Visão Geral

Plataforma de delivery estilo iFood, estruturada como um ecossistema de três frentes interligadas em tempo real — **cliente**, **restaurante** e **entregador** — orquestrados por um **painel administrativo central**.

O projeto está em **fase de documentação arquitetural**. Todos os 16 domínios estão completos com system designs detalhados (modelo de dados, fluxos, contratos, ADRs, riscos), além de documentos transversais consolidados e scripts de migração do banco de dados.

### Status da Documentação

| Documento | Status |
|-----------|--------|
| 16 System Designs (00–15) | ✅ Completos (~19 seções cada) |
| ADRs consolidados | ✅ `docs/adr.md` (67 decisões arquiteturais) |
| Arquitetura de dados transversal | ✅ `docs/data-architecture.md` (9 seções) |
| Diagrama ER global | ✅ `docs/data-model/schema.dbml` (64 tabelas, 90 refs) |
| Glossário do projeto | ✅ `docs/glossario.md` (200+ termos A-Z) |
| Especificação OpenAPI/Swagger | ✅ `docs/openapi.yaml` + HTML viewer |
| Migrações SQL versionadas | ✅ `docs/migrations/` (Flyway) |
| Roteiro (roadmap) e dependências | ✅ `docs/roadmap/` |

> ✅ **~96% do checklist de documentação concluído** — detalhes em [`docs/improvements-checklist.md`](./docs/improvements-checklist.md)

---

## Estrutura do Repositório

```
FastFoodDelivery/
│
├── docs/                              # Documentação completa
│   ├── adr.md                         # ADRs consolidadas (67 decisões)
│   ├── architecture/                  # System designs por domínio
│   │   ├── 00-plataforma-transversal/
│   │   ├── 01-identidade-usuarios/
│   │   ├── ...
│   │   ├── 15-cupons-campanhas/
│   │   ├── architecture-overview.mermaid
│   │   └── class-diagram-global.puml
│   ├── data-architecture.md           # Fluxo de dados entre serviços
│   ├── data-model/                    # ER global + schema SQL + dependências
│   ├── epic-ifood-clone.md            # Requisitos do produto
│   ├── glossario.md                   # 200+ termos A-Z
│   ├── improvements-checklist.md      # Checklist de qualidade
│   ├── migrations/                    # Migrações Flyway versionadas
│   │   ├── V1__Initial_Schema.sql
│   │   └── V2__Seed_Data.sql
│   ├── README.md                      # Índice central
│   ├── roadmap/                       # Ordem das jornadas e dependências
│   ├── rollback/                      # Scripts de reversão
│   ├── templates/                     # Template de system design
│   └── openapi.yaml                   # Especificação OpenAPI/Swagger
│
├── scripts/                           # Scripts utilitários
│   └── sql-to-dbml.py                 # Geração automática de docs
├── LICENSE
└── README.md                          # ← Você está aqui
```

---

## Domínios da Arquitetura

| # | Domínio | Jornada | Fase |
|---|---------|---------|------|
| 00 | [Plataforma Transversal](./docs/architecture/00-plataforma-transversal/system-design.md) | RNF | 0 |
| 01 | [Identidade e Usuários](./docs/architecture/01-identidade-usuarios/system-design.md) | Cliente | 0 |
| 02 | [Onboarding Admin](./docs/architecture/02-onboarding-admin/system-design.md) | Admin | 1 |
| 03 | [Gestão de Cardápio](./docs/architecture/03-gestao-cardapio/system-design.md) | Restaurante | 1 |
| 04 | [Geolocalização e Cobertura](./docs/architecture/04-geolocalizacao-cobertura/system-design.md) | Cliente | 2 |
| 05 | [Busca e Filtros](./docs/architecture/05-busca-filtros/system-design.md) | Cliente | 2 |
| 06 | [Carrinho e Pedido](./docs/architecture/06-carrinho-pedido/system-design.md) | Cliente | 2 |
| 07 | [Pagamentos](./docs/architecture/07-pagamentos/system-design.md) | Cliente | 3 |
| 08 | [Estados do Pedido](./docs/architecture/08-estados-pedido-restaurante/system-design.md) | Restaurante | 3 |
| 09 | [Matching Entregador](./docs/architecture/09-matching-entregador/system-design.md) | Entregador | 4 |
| 10 | [Roteirização e Localização](./docs/architecture/10-roteirizacao-localizacao/system-design.md) | Entregador | 4 |
| 11 | [Rastreamento Tempo Real](./docs/architecture/11-rastreamento-tempo-real/system-design.md) | Cliente | 4 |
| 12 | [Confirmação de Entrega](./docs/architecture/12-confirmacao-entrega/system-design.md) | Entregador | 4 |
| 13 | [Avaliações](./docs/architecture/13-avaliacoes/system-design.md) | Cliente | 5 |
| 14 | [Painel Financeiro](./docs/architecture/14-painel-financeiro-restaurante/system-design.md) | Restaurante | 5 |
| 15 | [Cupons e Campanhas](./docs/architecture/15-cupons-campanhas/system-design.md) | Admin | 5 |

> Detalhes das fases e dependências: [`docs/roadmap/ordem-das-jornadas.md`](./docs/roadmap/ordem-das-jornadas.md)

---

## Resumo da Arquitetura

Arquitetura orientada a eventos (EDA) com serviços desacoplados via Event Bus (RabbitMQ MVP, Kafka em escala).

### Componentes principais

| Camada | Componente | Função |
|--------|-----------|--------|
| **Gateway** | Kong (MVP) | Roteamento, rate limiting, validação JWT local |
| **Serviços** | Auth, User, Order, Payment, Dispatch, Tracking | Domínios independentes e stateless |
| **Cache** | Redis | OTP, rate limit, sessões, cardápio, geolocalização |
| **Banco** | PostgreSQL único (schemas separados) | Persistência transacional + read replica |
| **Mensageria** | RabbitMQ -> Kafka (futuro) | Eventos assíncronos com DLQ e reprocessamento |
| **Busca** | Elasticsearch | Full-text, geo_distance, ranking e autocomplete |

### Decisões Arquiteturais-Chave

- **Validação JWT local** no gateway sem round-trip ao Auth Service
- **Separação lógica** de domínios em schemas PostgreSQL, com evolução para bancos independentes
- **Integração assíncrona** via eventos para desacoplamento entre serviços
- **Cache-aside** com Redis e invalidação por evento para dados quentes
- **Offline-first parcial** no app do entregador (SQLite local, sync em batch)

---

## Fluxos Críticos (MVP)

1. **Cadastro e Login** — registro com Argon2id, refresh token rotativo, OTP
2. **Onboarding** — KYC de restaurantes e entregadores com SLA de 48h
3. **Cardápio** — criação, versionamento (snapshots) e publicação em tempo real
4. **Busca** — full-text com Elasticsearch, boosting por rating, fallback PostgreSQL
5. **Carrinho e Pedido** — lock atômico de estoque, idempotência, snapshot de preços
6. **Pagamento** — Pix (QR dinâmico), cartão tokenizado (PCI-DSS out of scope)
7. **Matching** — oferta por georádio, aceite atômico (Lua no Redis), escalonamento
8. **Rastreamento** — WebSocket com heartbeat, fallback para polling REST
9. **Confirmação** — código OTP com hash SHA-256, disputas com evidências
10. **Financeiro** — ledger append-only, rollups diários, repasse D+7

---

## Requisitos Não Funcionais

| Requisito | Alvo |
|-----------|------|
| Disponibilidade | 99.99% (four nines) |
| Latência busca | < 200ms p95 |
| Latência login | < 250ms p95 |
| Latência leitura perfil | < 120ms p95 |
| Escala inicial | 1M usuários |
| Pico esperado | 2k RPS |
| Segurança | TLS 1.3, Argon2id, LGPD, PCI-DSS |

---

## Comece por aqui

1. [`docs/README.md`](./docs/README.md) — Índice completo da documentação
2. [`docs/epic-ifood-clone.md`](./docs/epic-ifood-clone.md) — Visão do produto e requisitos
3. [`docs/roadmap/ordem-das-jornadas.md`](./docs/roadmap/ordem-das-jornadas.md) — Ordem de desenho e dependências
4. [`docs/architecture/00-plataforma-transversal/system-design.md`](./docs/architecture/00-plataforma-transversal/system-design.md) — Fundação transversal
5. [`docs/data-model/er-viewer.html`](./docs/data-model/er-viewer.html) — 🗄️ Visualizador ER interativo do schema (abrir no navegador)

---

## Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

Copyright (c) 2026 Fernando Flores Terceros
