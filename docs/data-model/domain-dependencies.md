# Matriz de Dependência entre Domínios

> **Propósito:** Visualizar quais domínios se conectam entre si através de chaves estrangeiras.
> **Fonte:** [`domains/relationships.dbml`](./domains/relationships.dbml) (cross-domain) e [`schema.dbml`](./schema.dbml) (completo).
> **Gerado automaticamente em:** `2026-07-05 16:52`

---

## Matriz de Conexões

Cada linha mostra um domínio e para quais outros domínios ele aponta via FK.

| Domínio | → 01 | → 02 | → 03 | → 04 | → 06 | → 09 | Total Out |
|---------|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:---------:|
| **02 Onboarding** | 6 | — | — | — | — | — | **6** |
| **03 Cardápio** | — | 3 | — | — | — | — | **3** |
| **04 Geolocalizacao** | — | 2 | — | — | — | — | **2** |
| **05 Busca** | — | 1 | — | — | — | — | **1** |
| **06 Carrinho/Pedido** | 1 | 1 | 2 | — | — | — | **4** |
| **07 Pagamentos** | 2 | — | — | — | 1 | — | **3** |
| **08 Estados Pedido** | 1 | 1 | — | — | 1 | — | **3** |
| **09 Matching** | 5 | — | — | — | 3 | — | **8** |
| **10 Roteirizacao** | 4 | — | — | — | 1 | 4 | **9** |
| **11 Tempo Real** | 1 | — | — | — | 2 | — | **3** |
| **12 Confirmacao** | 4 | — | — | — | 2 | 3 | **9** |
| **13 Avaliacoes** | 1 | — | — | — | 1 | — | **2** |
| **14 Financeiro** | — | 5 | — | — | 1 | — | **6** |
| **15 Cupons** | 3 | — | — | 1 | 1 | — | **5** |

> **Legenda:** Número = quantidade de FKs entre os domínios. "—" = sem conexão direta.
> Total de referências cross-domain: **64**. Domínios sem FKs (ex: 00 infra) foram omitidos.

---

## Diagrama de Dependências

```
01 Identidade (auth/users)
    ↑  referenciado por: ('02', 'onboarding-admin')(6), ('09', 'matching-entregador')(5), ('10', 'roteirizacao-localizacao')(4), ('12', 'confirmacao-entrega')(4), ('15', 'cupons-campanhas')(3), ('07', 'pagamentos')(2), ('06', 'carrinho-pedido')(1), ('08', 'estados-pedido-restaurante')(1), ('11', 'rastreamento-tempo-real')(1), ('13', 'avaliacoes')(1)
    │
02 Onboarding (restaurant_profiles)  ← raiz do ecossistema de restaurantes
    │  referenciado por: 14(5), 03(3), 04(2), 05(1), 06(1), 08(1)
    ↓
03 Cardápio (menu)
    │  referenciado por: 06(2)
    ↓
06 Carrinho/Pedido (orders)  ← agregado central
    │  referenciado por: 09(3), 11(2), 12(2), 07(1), 08(1), 10(1), 13(1), 14(1), 15(1)
    ↓
    ├── 07 Pagamentos (payment)
    ├── 09 Matching (dispatch) ← também referenciado por: 10(4), 12(4)
    │       ↓
    │   └── 10 Roteirização (tracking)
    │   └── 12 Confirmação (verification)
    │
    ├── 08 Estados Pedido (order_state)
    ├── 11 Tempo Real (realtime)
    ├── 13 Avaliações (rating)
    ├── 14 Financeiro (finance) ← também referenciado por: 02(5)
    └── 15 Cupons (promotion) ← também referenciado por: 04(1)
```

---

## Entidades Centralizadoras

### `auth_users` (Domínio 01)
Tabela referenciada por **10 domínios**:

| Domínio | Tabelas que referenciam `auth_users` |
|---------|--------------------------------------|
| 02 Onboarding | `courier_profiles`, `moderation_audit_log`, `onboarding_applications`, `restaurant_profiles` |
| 06 Carrinho/Pedido | `orders` |
| 07 Pagamentos | `payment_tokens`, `refunds` |
| 08 Estados Pedido | `order_status_history` |
| 09 Matching | `courier_availability_history`, `courier_sessions`, `delivery_assignments`, `delivery_offers`, `escalation_queue` |
| 10 Roteirizacao | `courier_daily_tracks`, `delivery_milestones`, `delivery_tracking`, `location_pings` |
| 11 Tempo Real | `tracking_sessions` |
| 12 Confirmacao | `delivery_disputes`, `delivery_verification_attempts`, `delivery_verification_codes` |
| 13 Avaliacoes | `order_ratings` |
| 15 Cupons | `campaigns`, `coupon_redemptions`, `coupons` |

### `order_orders` (Domínio 06)
Tabela referenciada por **9 domínios**:

| Domínio | Tabelas que referenciam `order_orders` |
|---------|--------------------------------------|
| 07 Pagamentos | `payments` |
| 08 Estados Pedido | `order_status_history` |
| 09 Matching | `delivery_assignments`, `delivery_offers`, `escalation_queue` |
| 10 Roteirizacao | `delivery_tracking` |
| 11 Tempo Real | `tracking_sessions`, `tracking_snapshots` |
| 12 Confirmacao | `delivery_disputes`, `delivery_verification_codes` |
| 13 Avaliacoes | `order_ratings` |
| 14 Financeiro | `ledger_entries` |
| 15 Cupons | `coupon_redemptions` |

### `onboarding_restaurant_profiles` (Domínio 02)
Tabela referenciada por **6 domínios**:

| Domínio | Tabelas que referenciam `onboarding_restaurant_profiles` |
|---------|--------------------------------------|
| 03 Cardápio | `menu_categories`, `menu_snapshots`, `restaurant_schedules` |
| 04 Geolocalizacao | `delivery_fee_tiers`, `delivery_zones` |
| 05 Busca | `restaurant_search_fallback` |
| 06 Carrinho/Pedido | `orders` |
| 08 Estados Pedido | `order_sla_config` |
| 14 Financeiro | `bank_accounts`, `daily_restaurant_rollups`, `ledger_entries`, `payout_config`, `payouts` |

### `dispatch_delivery_assignments` (Domínio 09)
Tabela referenciada por **2 domínios**:

| Domínio | Tabelas que referenciam `dispatch_delivery_assignments` |
|---------|--------------------------------------|
| 10 Roteirizacao | `delivery_milestones`, `delivery_routes`, `delivery_tracking`, `location_pings` |
| 12 Confirmacao | `delivery_disputes`, `delivery_verification_attempts`, `delivery_verification_codes` |

### `user_user_addresses` (Domínio 01)
Tabela referenciada por **1 domínios**:

| Domínio | Tabelas que referenciam `user_user_addresses` |
|---------|--------------------------------------|
| 02 Onboarding | `restaurant_profiles` |

---

> **Documentos relacionados:** [`relationships.dbml`](./domains/relationships.dbml) | [`schema.dbml`](./schema.dbml) | [Visualizador ER](./er-viewer.html)
