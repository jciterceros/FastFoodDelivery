# Cache e Armazenamento Não-Relacional

> **Propósito:** Documentar estruturas fora do PostgreSQL: Redis (cache, sessão, tempo real) e SQLite (offline do entregador).
> **Fonte:** As tabelas relacionais estão em [`schema.dbml`](./schema.dbml) e no [visualizador ER](./er-viewer.html).

---

## Redis

### Domínio 01 — Identidade

| Chave | Tipo | TTL | Descrição |
|-------|------|-----|-----------|
| `otp:{user_id}` | String | 5min | Código OTP para verificação |
| `revoked:{token}` | String | TTL do access token | Blacklist de tokens revogados |

### Domínio 03 — Cardápio

| Chave | Tipo | TTL | Descrição |
|-------|------|-----|-----------|
| `menu:{restaurant_id}` | Hash | 5min | Cardápio publicado (cache) |

### Domínio 04 — Geolocalização

| Chave | Tipo | TTL | Descrição |
|-------|------|-----|-----------|
| `coverage:{geohash}` | Hash | 5min | Cobertura por região |

### Domínio 05 — Busca

| Chave | Tipo | TTL | Descrição |
|-------|------|-----|-----------|
| `search:query:{hash}` | String | 2min | Cache de queries quentes |

### Domínio 06 — Carrinho e Pedido

| Chave | Tipo | TTL | Descrição |
|-------|------|-----|-----------|
| `cart:{user_id}` | Hash | 60min | Carrinho do usuário |
| `idempotency:{key}` | String | 24h | Chave de idempotência |

### Domínio 08 — Estados do Pedido

| Chave | Tipo | TTL | Descrição |
|-------|------|-----|-----------|
| `order_timeout:{order_id}:{status}` | Hash | SLA + 5min | Timeout de SLA |

### Domínio 09 — Matching Entregador

| Chave | Tipo | TTL | Descrição |
|-------|------|-----|-----------|
| `courier:positions` | Geoset | — | Posições dos entregadores |
| `offer:lock:{order_id}` | String | 30s | Lock de matching |
| `delivery:assigned:{order_id}` | String | 5min | Lock de aceite |

### Domínio 10 — Tracking

| Chave | Tipo | TTL | Descrição |
|-------|------|-----|-----------|
| `tracking:position:{delivery_id}` | Hash | 5min | Última posição da corrida |
| `tracking:client:{order_id}` | Hash | 5min | Posição simplificada para cliente |

### Domínio 11 — Tempo Real

| Chave | Tipo | TTL | Descrição |
|-------|------|-----|-----------|
| `tracking:snapshot:{order_id}` | Hash | 5min | Snapshot para reconexão |
| `tracking:sessions:{order_id}` | Set | — | Sessões ativas por pedido |

### Domínio 12 — Confirmação

| Chave | Tipo | TTL | Descrição |
|-------|------|-----|-----------|
| `delivery:code:{delivery_id}` | String | 35min | Hash do código de confirmação |
| `delivery:attempts:{delivery_id}` | String | 10min | Contador de tentativas |
| `delivery:blocked:{delivery_id}` | String | 10min | Lock de bloqueio |

### Domínio 13 — Avaliações

| Chave | Tipo | TTL | Descrição |
|-------|------|-----|-----------|
| `rating:aggregate:{type}:{id}` | Hash | — | Média agregada |
| `rating:lock:{type}:{id}` | String | 5s | Lock de atualização |

### Domínio 14 — Financeiro

| Chave | Tipo | TTL | Descrição |
|-------|------|-----|-----------|
| `finance:rollup:{restaurant_id}:{date}` | Hash | 48h | Rollup do dia |
| `finance:balance:{restaurant_id}` | Hash | 1h | Saldo disponível |

### Domínio 15 — Cupons

| Chave | Tipo | TTL | Descrição |
|-------|------|-----|-----------|
| `coupon:redemptions:{coupon_id}` | String | — | Contador de uso do cupom |
| `coupon:user:{coupon_id}:{user_id}` | String | — | Contador por usuário |
| `coupon:active:{code}` | Hash | 5min | Cache de cupons ativos |

---

## App do Entregador (SQLite/Room — Offline)

| Tabela | Descrição | TTL |
|--------|-----------|-----|
| `pending_pings` | Pings não enviados (lat, lon, recorded_at) | Até sync |
| `pending_milestones` | Milestones não enviados | Até sync |
| `cached_routes` | Rotas cacheadas | 24h |
| `cached_addresses` | Endereços de entregas recentes | 7 dias |
| `delivery_code` | Código de confirmação (hash) | Até entrega |

---

## Fluxo de Dados entre Domínios (Ciclo de Vida do Pedido)

```
01. Identidade                   02. Onboarding
    └── users ──────────────────────└── restaurant_profiles
         │                                 │
         │   03. Cardápio                  │
         │       └── menu_items            │
         │            │                    │
         ▼            ▼                    ▼
    ┌──────────────────────────────────────────┐
    │        06. Carrinho e Pedido             │
    │              orders                      │
    └──┬───────────────────────┬───────────────┘
       │                       │
       ▼                       ▼
  07. Pagamentos          08. Estados
   payments                order_status_history
       │                        │
       │                  ┌─────┘
       ▼                  ▼
    ┌──────────────────────────┐
    │   09. Matching           │
    │   delivery_assignments   │
    └──────────────────────────┘
       │
       ├──────────────────────┐
       ▼                      ▼
  10. Tracking            12. Confirmação
   delivery_tracking       delivery_verification_codes
   location_pings               │
                                ▼
    ┌──────────────────────────────┐
    │   13. Avaliações             │
    │   order_ratings              │
    └──────────┬───────────────────┘
               │
               ▼
    ┌──────────────────────────────┐
    │   14. Financeiro             │
    │   ledger_entries → payouts   │
    └──────────────────────────────┘

    (11. Realtime — paralelo ao tracking, consome eventos)
    (15. Cupons — aplicado no checkout do pedido)
    (04. Geolocalização — consultado no início do fluxo)
    (05. Busca — indexa cardápio + ratings)
```

---

> **Documentos relacionados:** [`schema.dbml`](./schema.dbml) | [`er-viewer.html`](./er-viewer.html) | System designs em [`../architecture/`](../architecture/)
