# Checklist de Melhorias — FastFoodDelivery (Documentação)

> **Data:** Julho 2026  
> **Propósito:** Checklist graduado de melhorias **exclusivamente na documentação arquitetural**, sob a ótica de um engenheiro de software avaliando qualidade, completude e clareza dos designs.
> **Escopo:** Apenas documentação em `docs/`. Nada de implementação de código, CI/CD, infraestrutura ou testes automatizados.
> **Como usar:** Marque `[x]` à medida que cada item for concluído.

---

## 0 — Diagnóstico da Documentação Existente

### 0.1 Estrutura e navegação

- [x] **Revisar `docs/README.md`** — o índice central está consistente com os arquivos reais?
- [x] **Verificar links entre documentos** — diretório fantasma corrigido: docs/architecture/ agora versionado. README e roadmap já apontam para architecture/. Verificação sistemática de cross-references entre system designs ainda pendente.
- [x] **Verificar consistência de metadados** — todo system design tem header com Status, Fase, Jornada, Épico e Dependências?
- [x] **Validar convenção de pastas** — `NN-nome-do-dominio/system-design.md` + `architecture.mermaid` seguido em todos?

### 0.2 Qualidade dos diagramas

- [ ] **Diagramas Mermaid renderizam corretamente?** — testar cada ` ```mermaid ``` ` nos documentos
- [x] **Faltam diagramas `architecture.mermaid` avulsos?** — todos os 15 domínios agora possuem
- [x] **Diagramas têm legenda e contexto suficiente?** — a maioria tem legenda de fluxo síncrono/assíncrono
- [ ] **Há diagramas PNG exportados?** — para inclusão em documentos que não suportam Mermaid nativo

### 0.3 Lacunas transversais

- [x] **ADRs em documento separado** — consolidado em `docs/adr.md` (67 ADRs de 15 domínios)
- [x] **Especificação OpenAPI/Swagger** — disponível em `docs/openapi.yaml`, `docs/openapi.html`, `docs/openapi-swagger-ui.html`
- [x] **Diagrama ER global** — disponível em `docs/data-model/schema.dbml` (64 tabelas, 90 refs), `er-viewer.html`, `domain-dependencies.md`
- [x] **Glossário global consolidado** — disponível em `docs/glossario.md` (200+ termos A-Z com remissão a domínios)
- [x] **Documento de arquitetura de dados transversal** — criado em `docs/data-architecture.md` (9 seções, fluxos completos)

---

## 1 — System Design 00: Plataforma Transversal (Em progresso)

### 1.1 Pendências de conteúdo

- [x] **Decisão sobre API Gateway documentada** — matriz de decisão Kong vs AWS API Gateway vs Custom (6.1.1)
- [x] **Seção 9 (Contratos de API) preenchida** — padrão de erro global, health check, ready check, versionamento
- [x] **Seção 10 (Contratos de Eventos) preenchida** — envelope completo com exemplos, política de versionamento, topic naming
- [x] **Seção 11 (Segurança) detalhada** — TLS, KMS, RBAC, secrets management, proteções no Gateway
- [x] **Seção 12 (Escalabilidade) detalhada** — HPA, particionamento de tópicos, cache, estimativas de capacidade
- [x] **Seção 13 (Observabilidade) detalhada** — métricas por serviço, dashboard unificado, tracing, alertas
- [x] **Seção 14 (Resiliência) detalhada** — timeouts, retries com jitter, circuit breaker, bulkhead, graceful degradation, idempotência
- [x] **Seção 15 (Decisões Arquiteturais) expandida** — ADR-001 a ADR-006
- [x] **Criar `architecture.mermaid`** — diagrama detalhado da plataforma transversal

### 1.2 Melhorias de qualidade

- [x] **Adicionar RNFs específicos da camada transversal** — latência de gateway (< 20ms), disponibilidade 99.99%
- [x] **Documentar estratégia de versionamento de schemas de evento** — major/minor, topicos separados, janela de migração
- [x] **Documentar política de retry da DLQ** — backoff exponencial (1s, 2s, 4s, 8s, 16s), max 5 tentativas, reprocessamento a cada 30min
- [x] **Adicionar fluxo de "publicação de evento com falha"** — fluxo detalhado em 8.1, com retry, DLQ, reprocessamento e alerta

---

## 2 — System Design 01: Identidade e Usuários (Em progresso)

### 2.1 Pendências de conteúdo

- [x] **Revisar se todas as seções do template foram preenchidas** — 21 seções, completamente preenchidas
- [x] **Seção 6.1 (API Gateway) — validar** — validação JWT local consistente com design 00
- [x] **Seção 8.6 (Estratégia de persistência) — revisar** — menciona read replica e failover
- [x] **Seção 8.7 (user_devices) — revisar** — device_id é unique por usuário, cardinalidade documentada
- [x] **Seção 9.1 (Cadastro) — nota sobre DLQ** — reprocessamento de `user.created` sem rollback da credencial
- [x] **Seção 11.1 (Envelope de evento) — consistente com 00?** — referencia explicitamente o doc 00 como single source of truth
- [x] **Seção 12 (Segurança) — revisar** — CAPTCHA adaptativo, device fingerprint, resposta idêntica no forgot-password
- [x] **Seção 14 (Escalabilidade) — expandir** — estratégia de cache: OTP, rate limit, blacklist, índices compostos
- [x] **Seção 19 (Roadmap Técnico) — alinhar com roadmap global** — 4 fases coerentes

### 2.2 Melhorias de qualidade

- [x] **Diagrama Mermaid no `system-design.md` e `architecture.mermaid` estão sincronizados?**
- [x] **Adicionar fluxo de "exclusão de conta LGPD"** — evento `user.deleted` com `retentionUntil`
- [x] **Adicionar cenário de "concorrência no registro"** — nota sobre UNIQUE email + validação
- [x] **Adicionar tempo de retenção para dados de auditoria** — logs de consentimento

---

## 3 — System Design 02: Onboarding Admin (Em progresso)

### 3.1 Pendências de conteúdo

- [x] **Modelo de dados completo** — `onboarding_applications`, `application_documents`, `restaurant_profiles`, `courier_profiles`, `moderation_audit_log` — todos com tipos, FKs, índices
- [x] **Adicionar índices** — application_id, status, user_id, e compostos
- [x] **Seções 11–16 preenchidas** — Segurança, Escalabilidade, Observabilidade, Resiliência, ADRs, Riscos
- [x] **Documentar fluxo de reenvio de documentos** — campo `resubmitted_from` vincula nova solicitação à anterior
- [x] **Documentar política de retenção de documentos rejeitados** — 90 dias por LGPD
- [x] **Documentar SLA de moderação** — 48h com escalonamento (24h → 48h → 72h)

### 3.2 Melhorias de qualidade

- [x] **Diagrama Mermaid existente é suficiente?** — mostra Onboarding Service, Moderation Service, Event Bus, Notification
- [x] **Adicionar fluxo de "expiração de solicitação"** — job de limpeza de solicitações `pending` > 7 dias
- [x] **Adicionar contratos de API detalhados** — request/response bodies para todos os endpoints
- [x] **Criar `architecture.mermaid`**

---

## 4 — System Design 03: Gestão de Cardápio (Em progresso)

### 4.1 Pendências de conteúdo

- [x] **Seções 11–16 preenchidas** — Segurança, Escalabilidade, Observabilidade, Resiliência, ADRs, Riscos
- [x] **Modelo de dados completo** — 6 tabelas com colunas, tipos, chaves, índices
- [x] **Adicionar política de cache** — TTL 5min no Redis, invalidação por evento `menu.published`
- [x] **Adicionar estratégia de CDN para imagens** — presigned URL para upload, CDN para distribuição
- [x] **Documentar concorrência** — dois admins editam simultaneamente → optimistic locking com 409
- [x] **Documentar versionamento de cardápio** — snapshots em `menu_snapshots` com versão incremental

### 4.2 Melhorias de qualidade

- [x] **Adicionar fluxo "cardápio vazio no primeiro acesso"** — estado inicial, validação na publicação
- [x] **Adicionar fluxo de "horário de funcionamento"** — `restaurant.availability.changed` remove da busca
- [x] **Diagrama Mermaid mostra Search Indexer como consumidor** — Search e Cart como consumidores do Event Bus
- [x] **Criar `architecture.mermaid`**

---

## 5 — System Design 04: Geolocalização e Cobertura (Em progresso)

### 5.1 Pendências de conteúdo

- [x] **Seções 9–16 preenchidas** — API, Eventos, Segurança, Escalabilidade, Observabilidade, Resiliência, ADRs, Riscos
- [x] **Modelo de dados completo** — `delivery_zones`, `platform_regions`, `coverage_cache`, `address_geocoding_cache`, `delivery_fee_tiers` — com SRID, índices GiST
- [x] **Adicionar estratégia de cache geográfico** — geohash precisão 6, TTL 5min no Redis
- [x] **Documentar dependência do Google Places** — fallback para OpenStreetMap Nominatim, circuit breaker
- [x] **Documentar privacidade** — geohash em logs (nunca lat/lon bruto), TTL de 30 dias para cache de geocoding

### 5.2 Melhorias de qualidade

- [x] **Diagrama Mermaid mostra o Event Bus** — Coverage Service publica `coverage.checked` e `coverage.zone.updated`
- [x] **Adicionar fluxo de "mudança de endereço durante a busca"** — fluxo 8.3 (verificação no carrinho)
- [x] **Criar `architecture.mermaid`**

---

## 6 — System Design 05: Busca e Filtros (Em progresso)

### 6.1 Pendências de conteúdo

- [x] **Seções 9–16 preenchidas** — API, Eventos, Segurança, Escalabilidade, Observabilidade, Resiliência, ADRs, Riscos
- [x] **Modelo de dados completo** — documento `restaurant_search_doc` com todos os campos, mapping ES completo
- [x] **Adicionar estratégia de ranking** — boosting por rating (1.2), is_open (1.5), analyer brazilian
- [x] **Documentar degradação graceful** — fallback para PostgreSQL com índice GIN + pg_trgm
- [x] **Documentar observabilidade de latência** — métricas por query, slow queries, zero results

### 6.2 Melhorias de qualidade

- [x] **Adicionar fluxo de "indexação incremental"** — Search Indexer consome eventos e indexa em < 30s
- [x] **Adicionar fluxo de "busca sem resultados"** — sugestões de correção + categorias populares como fallback
- [x] **Criar `architecture.mermaid`**

---

## 7 — System Design 06: Carrinho e Pedido (Em progresso)

### 7.1 Pendências de conteúdo

- [x] **Seções 9–16 preenchidas** — API, Eventos, Segurança, Escalabilidade, Observabilidade, Resiliência, ADRs, Riscos
- [x] **Modelo de dados completo** — `carts` (Redis), `orders`, `order_items`, `inventory_reservations` com TTL
- [x] **Adicionar compensação de estoque** — job de expiração a cada 5min libera reservas expiradas (30min TTL)
- [x] **Documentar consistência do carrinho** — validação de preços no checkout, snapshot em `order_items`
- [x] **Documentar idempotência** — `Idempotency-Key` no `POST /v1/orders`, cache em Redis por 24h

### 7.2 Melhorias de qualidade

- [x] **Adicionar fluxo de "carrinho abandonado"** — job de expiração a cada 10min, evento `cart.abandoned`
- [x] **Diagrama Mermaid mostra o Event Bus** — Order Service publica `order.created`, `order.cancelled`, etc.
- [x] **Criar `architecture.mermaid`**

---

## 8 — System Design 07: Pagamentos (Em progresso)

### 8.1 Pendências de conteúdo

- [x] **Seções 9–16 preenchidas** — API, Eventos, Segurança (PCI-DSS detalhado), Escalabilidade, Observabilidade, Resiliência, ADRs, Riscos
- [x] **Modelo de dados completo** — `payments`, `payment_tokens`, `payment_webhooks`, `refunds`
- [x] **Adicionar matriz de reconciliação financeira** — job diário de reconciliação com gateway
- [x] **Documentar chargeback** — não como fluxo automático, mas evidências registradas para contestação
- [x] **Adicionar estratégia de webhook** — idempotência via UNIQUE constraint, HMAC signature, polling como fallback

### 8.2 Melhorias de qualidade

- [x] **Adicionar fluxo de "timeout do Pix"** — pedido expira em 30min, estoque liberado, job de polling
- [x] **Adicionar fluxo de "troca de método de pagamento"** — novo pagamento substitui o anterior
- [x] **Criar `architecture.mermaid`**

---

## 9 — System Design 08: Estados do Pedido (Em progresso)

### 9.1 Pendências de conteúdo

- [x] **Seções 9–16 preenchidas** — API, Eventos, Segurança, Escalabilidade, Observabilidade, Resiliência, ADRs, Riscos
- [x] **Modelo de dados completo** — `order_status_history` para auditoria, `order_sla_config`, timeouts no Redis
- [x] **Adicionar auditoria de transições** — `order_status_history` com `changed_by`, `changed_by_role`, `elapsed_seconds`
- [x] **Documentar timeout automático** — SLA de preparo 30min, job a cada 2min, escalonamento para admin em 45min
- [x] **Adicionar métricas** — tempo médio em cada estado, SLA breaches, cancelamentos por motivo

### 9.2 Melhorias de qualidade

- [x] **Diagrama Mermaid mostra todos os atores** — restaurante, sistema, admin, cliente
- [x] **Adicionar fluxo de "cancelamento antes do preparo"** — regras de cancelamento por estado e ator
- [x] **Criar `architecture.mermaid`**

---

## 10 — System Design 09: Matching Entregador (Em progresso)

### 10.1 Pendências de conteúdo

- [x] **Seções 9–16 preenchidas** — API, Eventos, Segurança, Escalabilidade, Observabilidade, Resiliência, ADRs, Riscos
- [x] **Modelo de dados completo** — `courier_sessions`, `delivery_offers`, `delivery_assignments`, `escalation_queue`, dados em Redis
- [x] **Documentar concorrência no aceite** — Lua script atômico no Redis garante que só um entregador aceita
- [x] **Adicionar escalonamento** — escalation queue após 3 tentativas, admin pode alocar manualmente
- [x] **Documentar fallback operacional** — admin pode alocar manualmente via painel

### 10.2 Melhorias de qualidade

- [x] **Adicionar métricas** — taxa de aceite, tempo até first offer, tempo até match, tentativas por matching
- [x] **Adicionar fluxo "entregador fica offline durante oferta"** — oferta expira em 30s, próxima tentativa
- [x] **Criar `architecture.mermaid`**

---

## 11 — System Design 10: Roteirização e Localização (Em progresso)

### 11.1 Pendências de conteúdo

- [x] **Seções 8–16 preenchidas** — todos os fluxos, contratos, modelo de dados
- [x] **Modelo de dados completo** — `delivery_tracking`, `location_pings` (particionada por mês), `delivery_milestones`, `delivery_routes`, `courier_daily_tracks`
- [x] **Adicionar estratégia de sync offline** — SQLite no app, batch de 60 pings, prioridade para milestones
- [x] **Documentar privacidade do trajeto** — LGPD: geohash em logs, retenção de 90 dias, precisão reduzida para cliente
- [x] **Documentar impacto na bateria** — ping a cada 3-5s em foreground, 10-15s em background, fused location provider

### 11.2 Melhorias de qualidade

- [x] **Adicionar fluxo de "perda de sinal"** — app grava local, sync ao reconectar (batch)
- [x] **Adicionar fluxo de "rota alternativa"** — deep link para Google Maps/Waze
- [x] **Adicionar contratos de API completos** — batch de locations, milestones, WebSocket
- [x] **Criar `architecture.mermaid`**

---

## 12 — System Design 11: Rastreamento em Tempo Real (Em progresso)

### 12.1 Pendências de conteúdo

- [x] **Seções 8–16 preenchidas** — API, Segurança, Escalabilidade, Observabilidade, Resiliência, ADRs, Riscos
- [x] **Documentar autorização** — apenas o cliente dono do pedido recebe o stream (JWT validado)
- [x] **Adicionar estimativa de custo de conexões** — 5k WebSocket simultâneas, 300 msg/s
- [x] **Documentar degradação graceful** — fallback para polling REST a cada 5s se WebSocket falhar
- [x] **Adicionar estratégia de cache de última posição** — Redis `tracking:snapshot:{order_id}` + PG como fallback

### 12.2 Melhorias de qualidade

- [x] **Adicionar fluxo de "cliente fecha e reabre a tela"** — reconexão com snapshot completo via WebSocket ou polling
- [x] **Adicionar contrato WebSocket detalhado** — formato das mensagens, heartbeat (30s), reconexão
- [x] **Diagrama Mermaid mostra autenticação** — JWT no handshake, validação por user_id
- [x] **Criar `architecture.mermaid`**

---

## 13 — System Design 12: Confirmação de Entrega (Em progresso)

### 13.1 Pendências de conteúdo

- [x] **Seções 8–16 preenchidas** — API, Segurança, Escalabilidade, Observabilidade, Resiliência, ADRs, Riscos
- [x] **Modelo de dados completo** — `delivery_verification_codes`, `delivery_verification_attempts`, `delivery_disputes`
- [x] **Documentar disputas** — evidências coletadas automaticamente (geolocalização, tentativas, logs)
- [x] **Adicionar suporte manual** — admin pode confirmar entrega via `POST /v1/admin/disputes/{id}/resolve`
- [x] **Documentar fluxo offline** — hash SHA-256 calculado localmente, batch na reconexão

### 13.2 Melhorias de qualidade

- [x] **Adicionar métricas** — taxa de confirmação na primeira tentativa, taxa de falha
- [x] **Adicionar contratos de API completos** — confirm, batch, reissue, disputes
- [x] **Criar `architecture.mermaid`**

---

## 14 — System Design 13: Avaliações (Em progresso)

### 14.1 Pendências de conteúdo

- [x] **Seções 8–16 preenchidas** — API, Segurança (LGPD em comentários), Escalabilidade, Observabilidade, Resiliência, ADRs, Riscos
- [x] **Modelo de dados completo** — `order_ratings`, `rating_aggregates`, `moderation_blocklist`
- [x] **Adicionar política de moderação de comentários** — blocklist + regex, flag para revisão manual
- [x] **Documentar impacto no ranking de busca** — evento `restaurant.rating.updated` → Search Service
- [x] **Adicionar atualização de média agregada** — Lua script atômico no Redis, consistência eventual < 1min

### 14.2 Melhorias de qualidade

- [x] **Adicionar fluxo de "avaliação editada pelo cliente"** — apenas comentário editável (nota imutável), janela de 7 dias
- [x] **Adicionar fluxo de "resposta do restaurante"** — documentado como pos-MVP
- [x] **Criar `architecture.mermaid`**

---

## 15 — System Design 14: Painel Financeiro (Em progresso)

### 15.1 Pendências de conteúdo

- [x] **Seções 9–16 preenchidas** — API, Eventos, Segurança, Escalabilidade, Observabilidade, Resiliência, ADRs, Riscos
- [x] **Modelo de dados completo** — `ledger_entries` (append-only), `daily_restaurant_rollups`, `payouts`, `bank_accounts`, `reconciliation_log`, `payout_config`
- [x] **Documentar precisão decimal** — todos os valores em centavos (INT), nunca float
- [x] **Adicionar lógica de rollup** — pre-agregação diária, atualizada a cada lançamento, job de recálculo a cada 1h
- [x] **Documentar compliance fiscal** — retenção de 5 anos para dados financeiros

### 15.2 Melhorias de qualidade

- [x] **Adicionar fluxo de "reembolso parcial"** — `refund` no ledger, atualização de rollups
- [x] **Adicionar fluxo de "antecipação de recebíveis"** — documentado como pos-MVP
- [x] **Criar `architecture.mermaid`**

---

## 16 — System Design 15: Cupons e Campanhas (Em progresso)

### 16.1 Pendências de conteúdo

- [x] **Seções 9–16 preenchidas** — API, Eventos, Segurança, Escalabilidade, Observabilidade, Resiliência, ADRs, Riscos
- [x] **Modelo de dados completo** — `coupons` com `rules_json`, `coupon_redemptions`, `campaigns`, `delivery_fee_rules`, `campaign_daily_stats`
- [x] **Adicionar prevenção de fraude de cupom** — contador atômico no Redis (INCR), UNIQUE constraints, snapshot de regras
- [x] **Documentar subsídio** — plataforma, restaurante ou split (configurável na criação)
- [x] **Adicionar relatório de ROI de campanha** — métricas: redemptions, discount, gross, new users, ROI%

### 16.2 Melhorias de qualidade

- [x] **Adicionar fluxo de "cupom expirado no checkout"** — validação dupla (carrinho + fechamento), resgate atômico
- [x] **Adicionar fluxo de "frete dinâmico por região"** — `delivery_fee_rules` com poligono GeoJSON e prioridade
- [x] **Criar `architecture.mermaid`**

---

## 17 — Novos Documentos a Criar

### 17.1 ADRs (Architecture Decision Records)

- [x] **ADR-001 a ADR-006** — documentados inline no documento 00 (Plataforma Transversal)
- [x] **ADRs específicos por domínio** — cada system design (02 a 15) possui seus próprios ADRs na seção 15
- [x] **Documento ADR consolidado** — criado em `docs/adr.md` (67 ADRs de 15 domínios, 17 páginas)

### 17.2 Documentos de arquitetura transversal

- [x] **Diagrama entidade-relacionamento (ER) global** — disponível em `docs/data-model/schema.dbml` + `er-viewer.html` + `domain-dependencies.md`
- [x] **Glossário do projeto** — disponível em `docs/glossario.md` (200+ termos A-Z com remissão a domínios)
- [x] **Documento de arquitetura de dados** — criado em `docs/data-architecture.md` (9 seções, 5 diagramas Mermaid)
- [x] **Especificação OpenAPI/Swagger consolidada** — disponível em `docs/openapi.yaml`, `docs/openapi.html`, `docs/openapi-swagger-ui.html`

### 17.3 Melhorias no repositório

- [ ] **README.md principal (raiz)** — refletir estado atual (documentação, não implementação)
- [ ] **Template de system design revisado** — está sendo seguido por todos os documentos? melhorias no template?
- [x] **docs/README.md atualizado** — tabela de status reflete a realidade de cada domínio (todos "Em progresso")

---

## 18 — Critérios de Qualidade por Documento

Cada `system-design.md` deve ser avaliado contra este checklist individual:

### Clareza e completude

- [x] **Objetivo claro** — 1-3 frases que qualquer desenvolvedor entende
- [x] **Escopo MVP vs pós-MVP** — linhas divisórias explícitas
- [x] **RNFs específicos** — latência, disponibilidade, escala do domínio
- [x] **Diagrama Mermaid** — presente em todos os 15 domínios
- [x] **Modelo de dados** — tabelas com colunas, tipos, PKs, FKs, índices
- [x] **Mínimo 2 fluxos** — passo a passo numerado (todos têm 3+)
- [x] **Contratos de API** — método, path, request body, response
- [x] **Eventos** — publicados e consumidos, com payload de exemplo
- [x] **Segurança** — RBAC, dados sensíveis, compliance

### Arquitetura e riscos

- [x] **Decisões arquiteturais documentadas** — ADRs por domínio (seção 15)
- [x] **Riscos e mitigações** — tabela com matriz probabilidade x impacto (seção 16)
- [x] **Estratégia de escalabilidade** — cache, índices, estimativas de capacidade
- [x] **Resiliência** — timeouts, retries, circuit breaker, degradação, idempotência
- [x] **Observabilidade** — métricas, logs, alertas específicos do domínio

---

## 19 — Resumo do Status Atual

| Domínio | Status | Seções faltando | Prioridade |
|---------|--------|-----------------|------------|
| 00 — Plataforma Transversal | **Em progresso** | Nenhuma (completo, 19 seções) | 🟢 **Baixa** (revisão fina) |
| 01 — Identidade e Usuários | **Em progresso** | Nenhuma (completo, 21 seções) | 🟢 **Baixa** (revisão fina) |
| 02 — Onboarding Admin | **Em progresso** | Nenhuma (completo, 17 seções) | 🟢 **Baixa** (revisão fina) |
| 03 — Gestão de Cardápio | **Em progresso** | Nenhuma (completo, 16 seções) | 🟢 **Baixa** (revisão fina) |
| 04 — Geolocalização e Cobertura | **Em progresso** | Nenhuma (completo, 16 seções) | 🟢 **Baixa** (revisão fina) |
| 05 — Busca e Filtros | **Em progresso** | Nenhuma (completo, 16 seções) | 🟢 **Baixa** (revisão fina) |
| 06 — Carrinho e Pedido | **Em progresso** | Nenhuma (completo, 16 seções) | 🟢 **Baixa** (revisão fina) |
| 07 — Pagamentos | **Em progresso** | Nenhuma (completo, 16 seções) | 🟢 **Baixa** (revisão fina) |
| 08 — Estados do Pedido | **Em progresso** | Nenhuma (completo, 16 seções) | 🟢 **Baixa** (revisão fina) |
| 09 — Matching Entregador | **Em progresso** | Nenhuma (completo, 16 seções) | 🟢 **Baixa** (revisão fina) |
| 10 — Roteirização e Localização | **Em progresso** | Nenhuma (completo, 16 seções) | 🟢 **Baixa** (revisão fina) |
| 11 — Rastreamento em Tempo Real | **Em progresso** | Nenhuma (completo, 16 seções) | 🟢 **Baixa** (revisão fina) |
| 12 — Confirmação de Entrega | **Em progresso** | Nenhuma (completo, 16 seções) | 🟢 **Baixa** (revisão fina) |
| 13 — Avaliações | **Em progresso** | Nenhuma (completo, 16 seções) | 🟢 **Baixa** (revisão fina) |
| 14 — Painel Financeiro | **Em progresso** | Nenhuma (completo, 16 seções) | 🟢 **Baixa** (revisão fina) |
| 15 — Cupons e Campanhas | **Em progresso** | Nenhuma (completo, 16 seções) | 🟢 **Baixa** (revisão fina) |

### Legendas de prioridade

| Prioridade | Critério |
|------------|----------|
| 🔴 Alta | Documento em esboço com seções críticas faltando |
| 🟡 Média | Documento em progresso, precisa de revisão de qualidade e consistência |
| 🟢 Baixa | Documento completo, apenas ajustes finos |

---

## Ordem Recomendada de Execução (Atualizada)

1. **Documentos transversais restantes** — ADR consolidado ✅, glossário global ✅, ER global ✅, OpenAPI ✅, arquitetura de dados ✅
2. **Exportar diagramas PNG** — para documentos que não suportam Mermaid nativo
3. **README.md principal (raiz)** — atualizar com o estado atual da documentação
4. **Revisão final de consistência** — validar cross-references e sincronização de diagramas
