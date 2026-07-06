# Architecture Decision Records (ADRs) — Consolidado

> **Propósito:** Este documento centraliza todas as Decisões Arquiteturais (ADRs) dos 16 domínios da plataforma FastFoodDelivery.  
> **Fonte:** Extraído das seções 15 de cada system design em `docs/architecture/*/system-design.md`.  
> **Atualização:** ADRs devem ser adicionados/modificados primeiro nos system designs de origem; este documento é um espelho consolidado.  
> **Total de ADRs:** 67  
> **Domínios com ADRs:** 15 de 16 (01-identidade-usuarios não possui seção de ADRs)

---

## Índice

| # | Domínio | ADRs |
|---|---------|------|
| 00 | [Plataforma Transversal](#00-plataforma-transversal) | ADR-001 a ADR-006 |
| 02 | [Onboarding Admin](#02-onboarding-admin) | ADR-001 a ADR-004 |
| 03 | [Gestão de Cardápio](#03-gestao-de-cardapio) | ADR-001 a ADR-004 |
| 04 | [Geolocalização e Cobertura](#04-geolocalizacao-e-cobertura) | ADR-001 a ADR-004 |
| 05 | [Busca e Filtros](#05-busca-e-filtros) | ADR-001 a ADR-004 |
| 06 | [Carrinho e Pedido](#06-carrinho-e-pedido) | ADR-001 a ADR-004 |
| 07 | [Pagamentos](#07-pagamentos) | ADR-001 a ADR-004 |
| 08 | [Estados do Pedido](#08-estados-do-pedido) | ADR-001 a ADR-004 |
| 09 | [Matching Entregador](#09-matching-entregador) | ADR-001 a ADR-005 |
| 10 | [Roteirização e Localização](#10-roteirizacao-e-localizacao) | ADR-001 a ADR-005 |
| 11 | [Rastreamento Tempo Real](#11-rastreamento-tempo-real) | ADR-001 a ADR-005 |
| 12 | [Confirmação de Entrega](#12-confirmacao-de-entrega) | ADR-001 a ADR-005 |
| 13 | [Avaliações](#13-avaliacoes) | ADR-001 a ADR-005 |
| 14 | [Painel Financeiro](#14-painel-financeiro) | ADR-001 a ADR-004 |
| 15 | [Cupons e Campanhas](#15-cupons-e-campanhas) | ADR-001 a ADR-004 |

---

## 00 — Plataforma Transversal

> Fonte: [`docs/architecture/00-plataforma-transversal/system-design.md`](./architecture/00-plataforma-transversal/system-design.md)

### ADR-001: Estratégia de Mensageria

| Campo | Valor |
|-------|-------|
| **Decisão** | RabbitMQ (MVP) com migração planejada para Kafka |
| **Contexto** | Necessário suportar EDA com at-least-once, DLQ e baixa latência |
| **Alternativas** | Kafka (mais complexo para MVP), SQS (vendor lock-in), Redis Stream (sem DLQ robusta) |
| **Consequências** | Positivas: simplicidade operacional, baixa latência, ecossistema maduro. Negativas: retenção limitada, replay de eventos requer ferramenta externa. Kafka postergado para quando houver necessidade de retenção longa e throughput > 100k msg/s. |
| **Status** | Aprovado |

### ADR-002: API Gateway

| Campo | Valor |
|-------|-------|
| **Decisão** | Kong Gateway (open-source) |
| **Contexto** | Necessário roteamento, rate limiting, validação JWT e correlação |
| **Alternativas** | AWS API Gateway (custo por request alto em escala), custom Node.js (maior esforço de manutenção) |
| **Consequências** | Positivas: middleware declarativo (rate-limit, JWT, CORS), comunidade grande, plugins extensivos. Negativas: mais um componente para operar. Migração futura para AWS API Gateway avaliada quando custo operacional > custo de requests. |
| **Status** | Aprovado |

### ADR-003: JWT Local Validation no Gateway

| Campo | Valor |
|-------|-------|
| **Decisão** | Gateway valida JWT localmente com cache de chave pública |
| **Contexto** | Evitar round-trip síncrono ao Auth Service em cada request reduz latência e carga |
| **Alternativas** | Delegar validação ao Auth Service (mais latência, ponto de falha único), stateless JWT sem revogação (menos seguro) |
| **Consequências** | Positivas: overhead < 5ms por request, Auth Service desacoplado do path crítico. Negativas: revogação de token requer blacklist no Redis consultada no gateway para tokens duvidosos. |
| **Status** | Aprovado |

### ADR-004: Postgres Único Inicial vs Múltiplos Bancos

| Campo | Valor |
|-------|-------|
| **Decisão** | Única instância física de PostgreSQL com separação lógica por schema |
| **Contexto** | Iniciar com 1M usuários e 2k RPS, sem justificativa inicial para bancos separados |
| **Alternativas** | Banco por serviço (maior complexidade operacional, latência de rede entre serviços) |
| **Consequências** | Positivas: operação simples, backups centralizados, joins entre schemas possíveis. Negativas: contenção de recursos, risco de um domínio sobrecarregar o pool. Read replica desde o início para mitigar contenção de leitura. Separação física reavaliada quando houver necessidade de isolamento de performance ou compliance. |
| **Status** | Aprovado |

### ADR-005: Eventos Assíncronos para Integrações Externas

| Campo | Valor |
|-------|-------|
| **Decisão** | Notificações (email/SMS), geocoding e analytics via eventos assíncronos |
| **Contexto** | Providers externos têm latência imprevisível e podem falhar. Bloquear o fluxo de cadastro no envio de email aumentaria a latência do endpoint para > 2s. |
| **Alternativas** | Chamada síncrona com timeout longo (bloqueia o request), batch processing noturno (delay muito grande) |
| **Consequências** | Positivas: latência de cadastro < 400ms, isolamento de falhas, retry via DLQ. Negativas: consistência eventual (email de boas-vindas pode chegar com alguns segundos de atraso), complexidade adicional de monitoramento. |
| **Status** | Aprovado |

### ADR-006: Estratégia de Idempotência

| Campo | Valor |
|-------|-------|
| **Decisão** | Header `Idempotency-Key` em endpoints de mutação, com cache em Redis por 24h |
| **Contexto** | Garantir que duplicatas de request (retry do cliente, rede instável) não criem efeitos colaterais duplicados |
| **Alternativas** | Idempotência baseada em estado (mais complexa para queries de verificação), optimistic locking (não protege contra duplicatas de rede) |
| **Consequências** | Positivas: proteção simples e eficaz contra duplicatas. Negativas: consumo de Redis (chave por request), necessidade de tratar `IDEMPOTENCY_REUSE`. |
| **Status** | Aprovado |

---

## 02 — Onboarding Admin

> Fonte: [`docs/architecture/02-onboarding-admin/system-design.md`](./architecture/02-onboarding-admin/system-design.md)

### ADR-001: Separação entre Onboarding e Moderation Service

| Campo | Valor |
|-------|-------|
| **Decisão** | Onboarding (self-service) e Moderation (operação interna) são serviços separados |
| **Contexto** | Onboarding é usado por restaurantes/entregadores (alto volume, auto-serviço). Moderação é usada por admins (baixo volume, operação interna). Cargas e requisitos de segurança diferentes. |
| **Alternativas** | Serviço único (acoplaria responsabilidades, risco de impacto na moderação se onboarding tiver pico) |
| **Consequências** | Positivas: isolamento de falhas, cada serviço escala independentemente. Negativas: maior complexidade de deploy e comunicação via eventos entre eles. |
| **Status** | Aprovado |

### ADR-002: Upload via Presigned URL

| Campo | Valor |
|-------|-------|
| **Decisão** | Upload de documentos via presigned URL diretamente para Object Storage |
| **Contexto** | Documentos podem ter até 10MB. Receber o binário no serviço e repassar ao storage consumiria largura de banda e CPU desnecessárias. |
| **Alternativas** | Proxy no serviço (mais simples para validação, mas sobrecarrega o serviço), upload chunked (mais complexo) |
| **Consequências** | Positivas: serviço não gerencia binários, redução de latência, escalabilidade horizontal. Negativas: validação de tipo/tamanho precisa ser feita antes de gerar a URL. |
| **Status** | Aprovado |

### ADR-003: Aprovação Dispara Evento, não Chamada Síncrona

| Campo | Valor |
|-------|-------|
| **Decisão** | Ao aprovar, Onboarding Service publica `onboarding.approved`; Auth, Menu e Notification consomem assincronamente |
| **Contexto** | Aprovação precisa: (1) atribuir role no Auth, (2) notificar usuário, (3) habilitar cardápio. Essas ações não precisam ser atômicas com a aprovação. |
| **Alternativas** | Chamada síncrona para Auth/Menu/Notification (maior latência, ponto de falha único), saga distribuída (mais complexo) |
| **Consequências** | Positivas: aprovação é rápida (< 200ms), falhas em serviços downstream não bloqueiam o fluxo. Negativas: consistência eventual — pode levar alguns segundos até o restaurante conseguir acessar o painel de cardápio. |
| **Status** | Aprovado |

### ADR-004: Reenvio com Vínculo à Solicitação Anterior

| Campo | Valor |
|-------|-------|
| **Decisão** | Ao reenviar após rejeição, criar nova solicitação vinculada à anterior via `resubmitted_from` |
| **Contexto** | Moderador precisa ver o histórico completo: o que foi rejeitado, o que mudou. Rejeitar e criar do zero perderia esse contexto. |
| **Alternativas** | Reabrir a mesma solicitação (mais simples, mas polui o histórico de estados), permitir edição direta (risco de alterar dados aprovados posteriormente) |
| **Consequências** | Positivas: auditoria clara, moderador vê o diff entre solicitações. Negativas: mais registros no banco, lógica de cópia de dados. |
| **Status** | Aprovado |

---

## 03 — Gestão de Cardápio

> Fonte: [`docs/architecture/03-gestao-cardapio/system-design.md`](./architecture/03-gestao-cardapio/system-design.md)

### ADR-001: Snapshot Versionado vs Leitura ao Vivo

| Campo | Valor |
|-------|-------|
| **Decisão** | Cardápio publicado é armazenado como snapshot versionado em `menu_snapshots` |
| **Contexto** | Clientes veem o cardápio no momento da publicação. Alterações em draft não devem afetar clientes até que o restaurante publique explicitamente. |
| **Alternativas** | Leitura ao vivo do banco (mais simples, mas draft vazaria para clientes), cache com flag `is_draft` (risco de leak) |
| **Consequências** | Positivas: isolamento claro entre draft e publicado, rollback possível (voltar versão anterior). Negativas: armazenamento adicional (JSONB por versão), complexidade de invalidação de cache. |
| **Status** | Aprovado |

### ADR-002: Propagação de Pausa via Evento vs Chamada Síncrona

| Campo | Valor |
|-------|-------|
| **Decisão** | Pausa de item é propagada via evento assíncrono para Search e Cart |
| **Contexto** | Requisito de propagação em < 5s. Consistência eventual é aceitável (4.9s de tolerância). |
| **Alternativas** | Chamada síncrona para Search + Cart (maior latência no painel do restaurante), polling (delay maior) |
| **Consequências** | Positivas: painel responde rápido (< 200ms), serviços downstream desacoplados. Negativas: janela de inconsistência de até 5s onde item pausado ainda aparece na busca. |
| **Status** | Aprovado |

### ADR-003: Cache Redis + CDN para Cardápio

| Campo | Valor |
|-------|-------|
| **Decisão** | Cardápio publicado cacheado em Redis (por `restaurant_id`) + CDN edge para alta escala |
| **Contexto** | Pico de 10k RPS em leituras de cardápio. Banco não sustentaria essa carga sem réplica. |
| **Alternativas** | Só Redis (CDN reduziria ainda mais a carga no Redis), só banco com read replica (mais lento) |
| **Consequências** | Positivas: latência < 5ms para clientes, banco protegido. Negativas: complexidade de invalidação, custo de CDN. |
| **Status** | Aprovado |

### ADR-004: Preço em Centavos (Inteiro)

| Campo | Valor |
|-------|-------|
| **Decisão** | Todos os preços armazenados como `price_cents` (inteiro), nunca como `float` ou `decimal` |
| **Contexto** | Erro de arredondamento em preços pode causar chargeback e insatisfação. |
| **Alternativas** | DECIMAL(10,2) no banco (preciso, mas mais custoso computacionalmente), FLOAT (impreciso) |
| **Consequências** | Positivas: sem erro de arredondamento, operações aritméticas exatas, fácil de serializar para API. Negativas: conversão para exibição (dividir por 100). |
| **Status** | Aprovado |

---

## 04 — Geolocalização e Cobertura

> Fonte: [`docs/architecture/04-geolocalizacao-cobertura/system-design.md`](./architecture/04-geolocalizacao-cobertura/system-design.md)

### ADR-001: Geohash para Cache de Cobertura

| Campo | Valor |
|-------|-------|
| **Decisão** | Cache de cobertura baseado em geohash com precisão 6 (~1km²) |
| **Contexto** | Consultar PostGIS a cada request tem latência > 50ms. Precisão de 1km é aceitável para determinar se um restaurante atende a região. |
| **Alternativas** | PostGIS em toda request (mais preciso, mas mais lento), grade de lat/lon fixa (menos flexível que geohash) |
| **Consequências** | Positivas: latência < 5ms no cache hit, cobertura de todo o planeta com hierarquia de precisão. Negativas: consultas em bordas de geohash podem retornar resultados ligeiramente diferentes (resolvido com overlap nas zonas). |
| **Status** | Aprovado |

### ADR-002: Google Places com Fallback para Busca Textual

| Campo | Valor |
|-------|-------|
| **Decisão** | Autocomplete via Google Places API com fallback para busca textual simples |
| **Contexto** | Google Places tem custo por request e pode ficar indisponível. Sem autocomplete, a experiência de digitar endereço é muito pior. |
| **Alternativas** | Só Google Places (sem fallback, experiência quebrada se API cair), OpenStreetMap Nominatim (gratuito, mas menos preciso no Brasil) |
| **Consequências** | Positivas: autocomplete de alta qualidade no dia a dia, fallback funcional em caso de falha. Negativas: custo operacional da Google Places, complexidade de manter dois providers. |
| **Status** | Aprovado |

### ADR-003: Zonas de Cobertura como Polígonos e Raios

| Campo | Valor |
|-------|-------|
| **Decisão** | Suportar dois tipos de zona: `radius` (raio a partir de ponto) e `polygon` (polígono arbitrário) |
| **Contexto** | Restaurantes menores usam raio simples. Redes e regiões administrativas precisam de polígonos personalizados. |
| **Alternativas** | Apenas raio (simples, mas limitado para zonas irregulares), apenas polígono (flexível, mas complexo para restaurantes pequenos) |
| **Consequências** | Positivas: atende tanto restaurantes simples quanto redes. Negativas: duas estratégias de cálculo de cobertura para manter e testar. |
| **Status** | Aprovado |

### ADR-004: Frete Calculado por Zona, não por Distância Linear

| Campo | Valor |
|-------|-------|
| **Decisão** | Frete calculado com base em faixas de distância dentro da zona de cobertura, não por distância linear pura |
| **Contexto** | Distância linear (haversine) não reflete a distância real de entrega (ruas, trânsito). Mas calcular rota real para cada consulta de cobertura seria muito lento. |
| **Alternativas** | Distância linear pura (simples, mas frete irrealista em zonas com geografia complexa), cálculo de rota em tempo real (muito lento para 5k RPS) |
| **Consequências** | Positivas: frete previsível para o cliente, rápido de calcular. Negativas: frete aproximado, pode ser maior ou menor que a distância real. Faixas configuradas pelo restaurante no painel admin. |
| **Status** | Aprovado |

---

## 05 — Busca e Filtros

> Fonte: [`docs/architecture/05-busca-filtros/system-design.md`](./architecture/05-busca-filtros/system-design.md)

### ADR-001: Elasticsearch como Índice Primário, PostgreSQL como Fallback

| Campo | Valor |
|-------|-------|
| **Decisão** | Elasticsearch como índice primário de busca com fallback para PostgreSQL (índice GIN + pg_trgm) |
| **Contexto** | Requisito de < 200ms p95 com busca full-text, geo_distance e filtros combinados. PostgreSQL não tem geo_distance nativo. |
| **Alternativas** | Apenas Elasticsearch (sem fallback, single point of failure), apenas PostgreSQL (lento para geo + full-text), Algolia (SaaS, vendor lock-in) |
| **Consequências** | Positivas: performance excelente, geo + full-text + aggregations, fallback funcional. Negativas: operar Elasticsearch adiciona complexidade, custo de infra. PostgreSQL como fallback tem funcionalidade reduzida (sem geo). |
| **Status** | Aprovado |

### ADR-002: Documento Único Denormalizado vs Joins no ES

| Campo | Valor |
|-------|-------|
| **Decisão** | Documento único `restaurant_search_doc` com categorias e itens aninhados (nested) |
| **Contexto** | Busca por nome de item precisa retornar o restaurante. Joins em tempo real no Elasticsearch (has_child, has_parent) são lentos. |
| **Alternativas** | Parent/child mapping (mais lento, mas sem duplicação de dados), dois índices separados com join no Search Service (mais complexo) |
| **Consequências** | Positivas: busca rápida com um único shard hit, nested queries para filtrar por item. Negativas: documento grande, reindexação completa quando qualquer item muda. |
| **Status** | Aprovado |

### ADR-003: Cache de Queries para Hot Queries

| Campo | Valor |
|-------|-------|
| **Decisão** | Cache de queries frequentes em Redis com TTL de 2 minutos |
| **Contexto** | Muitos usuários buscam os mesmos termos ("pizza", "esfiha", "japonês"). Cache reduz carga no ES e latência. |
| **Alternativas** | Sem cache (ES aguenta, mas latência maior), cache no Elasticsearch (shard query cache, menos controle) |
| **Consequências** | Positivas: queries populares em < 5ms, redução de carga no ES. Negativas: invalidação complexa (qualquer mudança no cardápio invalida o cache), clientes podem ver resultados ligeiramente desatualizados (até 2min). |
| **Status** | Aprovado |

### ADR-004: Paginação Cursor-based em vez de Offset-based

| Campo | Valor |
|-------|-------|
| **Decisão** | Paginação via cursor (search_after no ES) em vez de page/offset |
| **Contexto** | ES limita `from + size` a 10k documentos. Offset-based incentiva paginação profunda, que é cara e limitada. |
| **Alternativas** | Offset-based (simples, mas limitado a 10k resultados e caro em páginas profundas), scroll API (para exportação, não para UI) |
| **Consequências** | Positivas: sem limite de profundidade, performático, consistente mesmo com dados mudando entre páginas. Negativas: não permite pular para página X (apenas "próxima"), cursor precisa ser decodificado. |
| **Status** | Aprovado |

---

## 06 — Carrinho e Pedido

> Fonte: [`docs/architecture/06-carrinho-pedido/system-design.md`](./architecture/06-carrinho-pedido/system-design.md)

### ADR-001: Carrinho no Redis, Pedido no PostgreSQL

| Campo | Valor |
|-------|-------|
| **Decisão** | Carrinho armazenado em Redis (volátil, TTL); Pedido armazenado em PostgreSQL (persistente, transacional) |
| **Contexto** | Carrinho é temporário por natureza (TTL de 60min). Pedido precisa de garantias transacionais (ACID) para estoque e faturamento. |
| **Alternativas** | Carrinho no PostgreSQL (mais lento, sem TTL nativo), ambos no Redis (perda de dados se Redis falhar) |
| **Consequências** | Positivas: carrinho rápido (< 5ms), Redis ideal para TTL, pedido com ACID. Negativas: dois armazenamentos para gerenciar, perda de carrinho se Redis falhar (aceitável — é temporário). |
| **Status** | Aprovado |

### ADR-002: Lock de Estoque Otimista com SELECT FOR UPDATE

| Campo | Valor |
|-------|-------|
| **Decisão** | Lock de estoque via `SELECT ... FOR UPDATE` na tabela `inventory_reservations` |
| **Contexto** | Duas pessoas não podem comprar o último item simultaneamente. Transação curta esperada (< 500ms). |
| **Alternativas** | Lock pessimista (mais lento, bloqueia outras operações), fila de checkout (serializa, mas adiciona latência), optimistic locking com versão (pode perder ambos) |
| **Consequências** | Positivas: isolamento transacional, deadlock detection do PostgreSQL, simples de implementar. Negativas: transações longas podem escalar, requer conexão única por checkout. |
| **Status** | Aprovado |

### ADR-003: Snapshot de Preços no Pedido

| Campo | Valor |
|-------|-------|
| **Decisão** | Preços e modifiers copiados (snapshot) para `order_items` no momento do checkout |
| **Contexto** | Preço do cardápio pode mudar após o pedido. O valor cobrado deve ser o do momento da compra. |
| **Alternativas** | Referência viva ao cardápio (se preço mudar, pedido antigo reflete preço novo — errado), versionamento de cardápio (mais complexo) |
| **Consequências** | Positivas: faturamento correto, independência entre pedido e cardápio futuro. Negativas: duplicação de dados, pedido não reflete mudanças de cardápio (deliberado). |
| **Status** | Aprovado |

### ADR-004: Compensação de Estoque por Job Cron

| Campo | Valor |
|-------|-------|
| **Decisão** | Reservas de estoque expiradas são liberadas por job cron a cada 5 minutos |
| **Contexto** | Se o pagamento não for confirmado em 30min, o estoque precisa ser liberado para outros clientes. |
| **Alternativas** | TTL nativo do Redis (estoque no Redis, mas perde consistência transacional), evento de timeout (mais complexo, mas mais rápido) |
| **Consequências** | Positivas: simples, confiável, mesma lógica para expiração de pedidos. Negativas: janela de até 5min entre expiração e liberação efetiva. Aceitável para o volume. |
| **Status** | Aprovado |

---

## 07 — Pagamentos

> Fonte: [`docs/architecture/07-pagamentos/system-design.md`](./architecture/07-pagamentos/system-design.md)

### ADR-001: Tokenização no Gateway, NUNCA no Backend

| Campo | Valor |
|-------|-------|
| **Decisão** | Tokenização de cartão realizada exclusivamente pelo gateway (Stripe Elements / Adyen Drop-in). Backend nunca recebe PAN. |
| **Contexto** | PCI-DSS exige que sistemas que armazenam, processam ou transmitem PAN sigam controles rigorosos. Manter o backend fora do escopo PCI reduz drasticamente a complexidade de compliance. |
| **Alternativas** | Tokenização própria (escopo PCI completo), proxy de pagamento (backend vê PAN masked, ainda em escopo) |
| **Consequências** | Positivas: backend fora do escopo PCI, sem necessidade de QSA, tokenização gerida pelo gateway. Negativas: dependência do gateway para tokenização, frontend precisa integrar SDK do gateway. |
| **Status** | Aprovado |

### ADR-002: Webhook como Mecanismo Primário, Polling como Fallback

| Campo | Valor |
|-------|-------|
| **Decisão** | Confirmação de pagamento via webhook (primário) com job de polling como fallback |
| **Contexto** | Webhooks podem ser perdidos (rede, timeout). Pix leva segundos para confirmar, mas alguns bancos demoram mais. |
| **Alternativas** | Só webhook (risco de perda), só polling (lento, alto custo de API), webhook + polling (complexidade, mas confiável) |
| **Consequências** | Positivas: confirmação rápida via webhook (< 1s), fallback confiável via polling (5min). Negativas: job de polling adiciona custo de API calls ao gateway. |
| **Status** | Aprovado |

### ADR-003: Idempotência de Webhook via UNIQUE Constraint

| Campo | Valor |
|-------|-------|
| **Decisão** | Idempotência de webhook garantida por UNIQUE constraint em `payment_webhooks.idempotency_key` |
| **Contexto** | Gateway pode enviar o mesmo webhook múltiplas vezes (retry por rede). Processar duplicado atualizaria o pagamento incorretamente. |
| **Alternativas** | Redis lock (pode perder lock se Redis falhar), "já processado" check em aplicação (race condition) |
| **Consequências** | Positivas: garantia forte de idempotência, sem race condition, sem dependência de Redis. Negativas: write no banco mesmo para webhooks duplicados (mas UNIQUE constraint barra o insert). |
| **Status** | Aprovado |

### ADR-004: Gateway Único (MVP) com Provedor Secundário Planejado

| Campo | Valor |
|-------|-------|
| **Decisão** | Stripe como gateway único no MVP. Adyen como alternativa avaliada para pós-MVP (melhor suporte a vale-refeição no Brasil). |
| **Contexto** | Stripe tem boa cobertura de Pix e cartão no Brasil, SDK maduro e documentação extensa. Adyen tem suporte nativo a vale-refeição (Ticket, Sodexo). |
| **Alternativas** | Multi-gateway desde o início (mais complexidade operacional), apenas Adyen (menos documentação em português) |
| **Consequências** | Positivas: Stripe é simples de integrar, suporte a Pix via Stripe Treasury. Negativas: no futuro, pode ser necessário Adyen para vale-refeição, exigindo abstração de gateway (estrutura de `PaymentGatewayInterface`). |
| **Status** | Aprovado |

---

## 08 — Estados do Pedido

> Fonte: [`docs/architecture/08-estados-pedido-restaurante/system-design.md`](./architecture/08-estados-pedido-restaurante/system-design.md)

### ADR-001: Orquestrador de Estados vs Máquina de Estados Declarativa

| Campo | Valor |
|-------|-------|
| **Decisão** | Máquina de estados declarativa (tabela de transições válidas) em vez de orquestrador imperativo |
| **Contexto** | Regras de transição podem mudar (ex: permitir cancelamento após preparo). Orquestrador imperativo exigiria código novo para cada regra. |
| **Alternativas** | State machine via código (mais rígido), workflow engine (mais complexo) |
| **Consequências** | Positivas: adicionar nova transição é configuração, não código. Negativas: validação precisa ser robusta para evitar estados inválidos. |
| **Status** | Aprovado |

### ADR-002: SLA Monitorado via Redis em vez de Banco

| Campo | Valor |
|-------|-------|
| **Decisão** | Timeouts de SLA armazenados em Redis (hash com TTL), verificados por job cron |
| **Contexto** | SLA de preparo de 30min. Job cron a cada 2min consulta Redis para expirados. |
| **Alternativas** | Job cron consultando PostgreSQL (mais lento, carga desnecessária no banco), eventos agendados (mais complexo) |
| **Consequências** | Positivas: Redis é ideal para TTL, consulta rápida, sem carga no PG. Negativas: se Redis falhar, timeouts não são monitorados (graceful degradation). |
| **Status** | Aprovado |

### ADR-003: WebSocket como Canal Primário, Polling como Fallback

| Campo | Valor |
|-------|-------|
| **Decisão** | Notificação de novos pedidos via WebSocket (primário) com polling HTTP a cada 5s como fallback |
| **Contexto** | Requisito de < 3s após `payment.paid` até notificação no painel. Polling a cada 3s seria viável mas custoso. |
| **Alternativas** | Apenas polling (mais simples, mas menos responsivo), SSE (unidirecional, cliente precisa abrir conexão) |
| **Consequências** | Positivas: latência < 1s para notificação, fallback funcional. Negativas: gerenciamento de conexões WebSocket (5k simultâneas), reconexão. |
| **Status** | Aprovado |

### ADR-004: Auditoria Imutável em Tabela Separada

| Campo | Valor |
|-------|-------|
| **Decisão** | Histórico de transições armazenado em `order_status_history` (append-only, sem UPDATE ou DELETE) |
| **Contexto** | Auditoria precisa ser imutável para conformidade e resolução de disputas. |
| **Alternativas** | Histórico em JSONB dentro da tabela `orders` (mais simples, mas sem indexação), logs de aplicação (voláteis, sem garantia de retenção) |
| **Consequências** | Positivas: auditoria confiável, indexável, retenção por 5 anos. Negativas: write extra por transição, crescimento da tabela (~500k linhas/dia). |
| **Status** | Aprovado |

---

## 09 — Matching Entregador

> Fonte: [`docs/architecture/09-matching-entregador/system-design.md`](./architecture/09-matching-entregador/system-design.md)

### ADR-001: Matching por Proximidade via Redis Geoset

| Campo | Valor |
|-------|-------|
| **Decisão** | Posições dos entregadores armazenadas em Redis Geoset com busca `GEORADIUS` |
| **Contexto** | Atualização de localização a cada 3-5s exige escrita de alta frequência (1.5k writes/s). Busca por raio precisa ser < 200ms para matching em tempo real. |
| **Alternativas** | PostgreSQL com extensão PostGIS (escrita muito mais lenta, não adequado para 1.5k writes/s), Elasticsearch (overhead desnecessário), Grid de geohash em memória própria (mais complexo) |
| **Consequências** | Positivas: escrita O(1), busca O(log N), baixa latência, TTL nativo. Negativas: se Redis falhar, perde-se as posições em tempo real (fallback para PG). |
| **Status** | Aprovado |

### ADR-002: Aceite Atômico com Lua Script no Redis

| Campo | Valor |
|-------|-------|
| **Decisão** | Lock de concorrência implementado como Lua script atômico no Redis em vez de lock distribuído (Redlock) ou transação no banco |
| **Contexto** | Múltiplos entregadores recebem a mesma oferta. O primeiro que aceitar deve vencer atomicamente sem condição de corrida. |
| **Alternativas** | `SELECT ... FOR UPDATE` no PostgreSQL (mais lento, maior latência), Redlock (mais complexo, overhead de quorum), Optimistic locking com versão no PG (pode gerar mais conflitos) |
| **Consequências** | Positivas: latência < 5ms para o lock, atômico por design, simples de implementar. Negativas: dependência do Redis para a correção do matching (fallback precisa ser implementado para caso de falha do Redis). |
| **Status** | Aprovado |

### ADR-003: Timeout de Oferta de 30s com Job de Cleanup

| Campo | Valor |
|-------|-------|
| **Decisão** | Ofertas expiram em 30s (configurável), com job cron a cada 10s limpando ofertas expiradas e avançando para próximo candidato |
| **Contexto** | Janela de aceite precisa ser curta o suficiente para não atrasar o pedido, mas longa o suficiente para o entregador reagir. |
| **Alternativas** | TTL do Redis para expirar ofertas automaticamente (Redis não publica evento de expiração de forma confiável para acionar lógica de negócio), Kafka Streams windowing (mais complexo para MVP) |
| **Consequências** | Positivas: job simples, flexível (configurável), expiração registrada no PG para auditoria. Negativas: janela de até 10s entre expiração real e detecção pelo job. Aceitável vs tempo total de matching (< 10s target). |
| **Status** | Aprovado |

### ADR-004: Raio de Matching Progressivo

| Campo | Valor |
|-------|-------|
| **Decisão** | Raio de busca expande gradativamente: tentativa 1 = 3km, tentativa 2 = 5km, tentativa 3 = 8km. Após 3 tentativas sem sucesso, pedido vai para escalation queue. |
| **Contexto** | Começar com raio pequeno (entregador mais próximo = menor tempo de deslocamento) e expandir apenas se necessário. |
| **Alternativas** | Raio fixo de 5km (pode perder entregadores próximos em zonas densas, ou não encontrar ninguém em zonas remotas), Busca sem limite de raio (pode ofertar a entregadores muito distantes, aumentando tempo de espera do cliente) |
| **Consequências** | Positivas: balance entre tempo de deslocamento e chance de matching. Negativas: pedidos em zonas remotas podem exigir raios maiores (8km) ou escalonamento. Configurável por zona de cobertura. |
| **Status** | Aprovado |

### ADR-005: Fila de Ofertas em PG com Cache Redis vs Apenas Redis

| Campo | Valor |
|-------|-------|
| **Decisão** | Ofertas persistidas em PostgreSQL (source of truth) com cache Redis para estado ativo das ofertas pendentes |
| **Contexto** | Ofertas podem ser perdidas se apenas Redis for usado e ele falhar. PG garante durabilidade, Redis garante performance para matching. |
| **Alternativas** | Apenas Redis (mais rápido, mas risco de perda), apenas PG (garantia total, mas matching mais lento) |
| **Consequências** | Positivas: durabilidade dos dados, matching rápido via Redis, recuperação via job de reconciliação. Negativas: complexidade de manter dois stores sincronizados, latência adicional da escrita no PG (~10ms extra). |
| **Status** | Aprovado |

---

## 10 — Roteirização e Localização

> Fonte: [`docs/architecture/10-roteirizacao-localizacao/system-design.md`](./architecture/10-roteirizacao-localizacao/system-design.md)

### ADR-001: Redis para Posição em Tempo Real, PG para Persistência

| Campo | Valor |
|-------|-------|
| **Decisão** | Última posição mantida em Redis (Hash com TTL de 5min). Histórico persistido em PostgreSQL particionado por mês com batch write a cada 30s. |
| **Contexto** | 1.5k writes/s de ping. Cliente precisa da posição em < 5s. PG não suporta 1.5k writes/s individuais sem impacto em outros domínios. |
| **Alternativas** | Apenas Redis (risco de perda), apenas PG (não suporta throughput sem impacto), TimescaleDB (mais complexo para MVP) |
| **Consequências** | Positivas: Redis para baixa latência, PG para durabilidade e auditoria. Negativas: complexidade de manter dois stores, janela de 30s de perda potencial se Redis cair antes do batch. |
| **Status** | Aprovado |

### ADR-002: App Offline-First com Fila Local

| Campo | Valor |
|-------|-------|
| **Decisão** | App armazena pings e milestones em SQLite local e reenvia em batch ao restabelecer conexão |
| **Contexto** | Entregadores operam em áreas com sinal intermitente. Perder pings significa falha de rastreamento para o cliente. |
| **Alternativas** | Apenas online (perde dados com queda de rede), keepalive permanente (consome bateria), enviar via SMS (custo alto) |
| **Consequências** | Positivas: rastreamento contínuo mesmo offline, sem perda de dados. Negativas: complexidade adicional no app (fila, sync, reconciliação), consumo de armazenamento local (max 360 pings). |
| **Status** | Aprovado |

### ADR-003: Milestones Manuais (MVP) vs Geofence (Pós-MVP)

| Campo | Valor |
|-------|-------|
| **Decisão** | Milestones registrados manualmente pelo entregador no MVP, com geofence automático planejado para pós-MVP |
| **Contexto** | Geofence requer configuração de raio por restaurante/cliente, tratamento de falsos positivos (entregador passou perto mas não era o destino) e maior complexidade de implementação. |
| **Alternativas** | Apenas geofence (mais preciso mas complexo), apenas manual (simples, depende da ação do entregador) |
| **Consequências** | Positivas: MVP rápido, entregador já está com o app aberto para navegação. Negativas: entregador pode esquecer de marcar, gerando métricas imprecisas. Geofence automatiza e remove a fricção no pós-MVP. |
| **Status** | Aprovado |

### ADR-004: Batch Write vs Individual Write no PG

| Campo | Valor |
|-------|-------|
| **Decisão** | Pings acumulados em buffer em memória por 30s e persistidos em batch de 50 inserts, em vez de insert individual por ping |
| **Contexto** | 1.5k writes/s individuais no PG sobrecarregariam o banco compartilhado. Batch reduz writes para ~30/s. |
| **Alternativas** | Insert individual (1.5k/s, sobrecarrega PG), Kafka entre Tracking Service e PG (mais complexo, maior latência) |
| **Consequências** | Positivas: redução de 98% nos writes do PG, suficiente para MVP. Negativas: perda de até 30s de dados se o servidor cair antes do flush. Aceitável vs ganho de performance. |
| **Status** | Aprovado |

### ADR-005: WebSocket para Cliente, Polling como Fallback

| Campo | Valor |
|-------|-------|
| **Decisão** | Atualizações de tracking para o cliente via WebSocket (primário) com polling HTTP a cada 5s como fallback |
| **Contexto** | Requisito de latência < 5s entre ping do entregador e atualização no cliente. Polling a cada 3s seria viável mas custoso (60 requests/min por cliente). |
| **Alternativas** | Apenas polling (mais simples, maior custo de requests), SSE (unidirecional, cliente precisa reconectar), apenas WebSocket (perde atualizações se desconectar) |
| **Consequências** | Positivas: latência < 1s para atualização no cliente, fallback funcional, custo de requests reduzido. Negativas: gerenciamento de 5k conexões WebSocket simultâneas, implementação de reconexão. |
| **Status** | Aprovado |

---

## 11 — Rastreamento Tempo Real

> Fonte: [`docs/architecture/11-rastreamento-tempo-real/system-design.md`](./architecture/11-rastreamento-tempo-real/system-design.md)

### ADR-001: WebSocket vs SSE vs Polling

| Campo | Valor |
|-------|-------|
| **Decisão** | WebSocket como canal primário com polling REST como fallback. SSE (Server-Sent Events) descartado por limitação de headers customizados e bidirecionalidade. |
| **Contexto** | Requisito de latência < 5s entre ping do entregador e atualização no cliente. Polling puro a cada 3s geraria 60 requests/min/cliente → 300k requests/min no pico. |
| **Alternativas** | Polling puro (mais simples, mas custoso), SSE (unidirecional, sem heartbeat bidirecional), WebSocket + fallback (adotado) |
| **Consequências** | Positivas: latência < 1s para a maioria das mensagens, fallback funcional, heartbeat embutido. Negativas: complexidade de gerenciar 5k conexões simultâneas, necessidade de sticky sessions ou Redis Pub/Sub para broadcast horizontal. |
| **Status** | Aprovado |

### ADR-002: Redis Pub/Sub para Broadcast Horizontal

| Campo | Valor |
|-------|-------|
| **Decisão** | Realtime Service usa Redis Pub/Sub para distribuir mensagens entre pods em vez de sticky sessions ou Kafka |
| **Contexto** | Múltiplos pods do Realtime Service precisam receber eventos para clientes conectados em diferentes pods. Sticky sessions no load balancer seriam uma opção, mas criam afinidade que dificulta escalamento e deploy. |
| **Alternativas** | Sticky sessions (afinidade de conexão, problemas em deploy), Kafka (overhead desnecessário para pub/sub simples), Redis Pub/Sub (adotado) |
| **Consequências** | Positivas: simples, baixa latência, sem afinidade de pod. Negativas: Redis Pub/Sub não persiste mensagens (se um pod cai, perde mensagens), não há garantia de entrega. Aceitável pois o cliente tem fallback polling. |
| **Status** | Aprovado |

### ADR-003: Snapshot em Redis + PG

| Campo | Valor |
|-------|-------|
| **Decisão** | Último snapshot de tracking mantido em Redis (para latência < 10ms) e espelhado no PG (para durabilidade e fallback) |
| **Contexto** | Cliente precisa receber o estado atual ao conectar (ou reconectar). Ler do PG a cada conexão seria lento (1-5ms vs 10ms). Manter apenas em Redis arrisca perda. |
| **Alternativas** | Apenas Redis (perda se Redis falhar), apenas PG (lento para reconexão em massa) |
| **Consequências** | Positivas: reconexão rápida (< 10ms), durabilidade via PG. Negativas: escrita duplicada (Redis + PG), complexidade adicional. |
| **Status** | Aprovado |

### ADR-004: Rate Limit de Mensagens por Cliente

| Campo | Valor |
|-------|-------|
| **Decisão** | No máximo 1 mensagem de posição por segundo por cliente WebSocket |
| **Contexto** | Tracking Service publica posição a cada 3-5s. Se o cliente estiver com o app em foreground, receber updates mais frequentes que 1/s sobrecarrega o app (renderização do mapa) e consome dados móveis. |
| **Alternativas** | Sem rate limit (app recebe todas as mensagens, possível lag de UI), rate limit de 2/s (mais responsivo, maior consumo) |
| **Consequências** | Positivas: experiência suave no mapa, consumo de dados previsível (~3.6MB/hora). Negativas: cliente pode ver um pequeno salto na posição em vez de transição suave (mitigado por interpolação no pós-MVP). |
| **Status** | Aprovado |

### ADR-005: Heartbeat para Detecção de Sessões Mortas

| Campo | Valor |
|-------|-------|
| **Decisão** | Cliente envia ping a cada 30s. Servidor fecha conexão após 60s sem atividade. Job de cleanup a cada 5min para capturar sessões orphan. |
| **Contexto** | Sessões WebSocket podem ficar orphans (app fechou sem fechar conexão, rede caiu). Sem heartbeat, o servidor acumula conexões mortas. |
| **Alternativas** | Apenas TCP keepalive (não detecta app em background), apenas job de cleanup (janela de 5min de sessões mortas) |
| **Consequências** | Positivas: detecção rápida de sessões mortas (~60s), sem acúmulo de conexões. Negativas: tráfego adicional de heartbeat (1 msg a cada 30s, insignificante). |
| **Status** | Aprovado |

---

## 12 — Confirmação de Entrega

> Fonte: [`docs/architecture/12-confirmacao-entrega/system-design.md`](./architecture/12-confirmacao-entrega/system-design.md)

### ADR-001: Código de 6 Dígitos vs QR Code

| Campo | Valor |
|-------|-------|
| **Decisão** | Código numérico de 6 dígitos como método primário de confirmação no MVP. QR code como alternativa no pós-MVP. |
| **Contexto** | Código numérico é universal (qualquer celular com tela exibe, qualquer pessoa sabe digitar). QR code requer câmera, iluminação e pode falhar em condições adversas. |
| **Alternativas** | QR Code (mais rápido, mas requer câmera), NFC (requer hardware específico), Biometria do cliente (requer presença e disposição) |
| **Consequências** | Positivas: universal, simples, baixa barreira técnica. Negativas: requer digitar 6 dígitos (fricção), possível erro de digitação. |
| **Status** | Aprovado |

### ADR-002: Hash SHA-256 no Redis vs Criptografia Reversível

| Campo | Valor |
|-------|-------|
| **Decisão** | Código armazenado como SHA-256 hash (irreversível) no Redis, nunca em plaintext. Prefixo de 3 dígitos armazenado separadamente para confirmação visual no app do entregador. |
| **Contexto** | Se o Redis for comprometido, códigos em plaintext permitiriam que um atacante confirmasse entregas fraudulentamente. Hash impede que o código original seja recuperado mesmo com acesso ao Redis. |
| **Alternativas** | Criptografia AES (reversível, requer gerenciamento de chave), Plaintext (risco de segurança alto), Hash + salt (adotado) |
| **Consequências** | Positivas: mesmo com acesso ao Redis, código não pode ser recuperado. Negativas: não é possível exibir o código novamente ao cliente (apenas o prefixo). O cliente só vê o código uma vez, no momento da geração. |
| **Status** | Aprovado |

### ADR-003: Confirmação Online com Fallback Offline

| Campo | Valor |
|-------|-------|
| **Decisão** | Confirmação feita online (validação no servidor) com fallback offline (hash calculado no dispositivo, enviado em batch). |
| **Contexto** | Entregadores podem perder sinal no momento da entrega (subsolo, área remota). Confirmação offline é essencial para não travar o fluxo. |
| **Alternativas** | Apenas online (trava se sem internet), código exibido no app do entregador (menos seguro), confirmação por SMS (custo e latência) |
| **Consequências** | Positivas: entregador confirma mesmo offline, sem comprometer segurança (hash local, não plaintext). Negativas: complexidade adicional de sync e reconciliação. |
| **Status** | Aprovado |

### ADR-004: Bloqueio por Tentativas no Redis

| Campo | Valor |
|-------|-------|
| **Decisão** | Contador de tentativas e bloqueio gerenciados no Redis com TTL, em vez de PG. |
| **Contexto** | 5 tentativas incorretas → bloqueio de 10min. O contador é consultado em todo `POST /confirm` (caminho crítico). Redis oferece latência < 5ms vs PG ~50ms. |
| **Alternativas** | PG com `updated_at` (mais lento, carga desnecessária), Apenas Redis com risco de perda (aceitável — bloqueio expira em 10min) |
| **Consequências** | Positivas: validação ultra-rápida (< 5ms). Negativas: se Redis falhar, contador é resetado. Aceitável pois o bloqueio é de curta duração. |
| **Status** | Aprovado |

### ADR-005: Evidências Automáticas em Disputas

| Campo | Valor |
|-------|-------|
| **Decisão** | Ao abrir disputa, o sistema coleta automaticamente evidências (geolocalização, tentativas, logs) e as apresenta ao admin. |
| **Contexto** | Disputas de entrega são emocionais e sensíveis. Ter evidências automáticas reduz o tempo de resolução e remove o trabalho manual de buscar dados. |
| **Alternativas** | Admin busca dados manualmente (lento, propenso a erro), apenas depoimento das partes (sem prova técnica) |
| **Consequências** | Positivas: resolução rápida (< 24h), baseada em dados, reduz custo de suporte. Negativas: armazenamento de evidências (JSONB), complexidade de coleta. |
| **Status** | Aprovado |

---

## 13 — Avaliações

> Fonte: [`docs/architecture/13-avaliacoes/system-design.md`](./architecture/13-avaliacoes/system-design.md)

### ADR-001: Agregado em Redis com Lua Script vs Recalculo a Cada Leitura

| Campo | Valor |
|-------|-------|
| **Decisão** | Média agregada mantida em Redis (Hash) e atualizada atomicamente via Lua script a cada nova avaliação. PG como source of truth para reconciliação. |
| **Contexto** | Leitura de agregado é frequente (200/s em páginas de restaurante). Recalcular a média a cada leitura via PG seria lento (50ms vs 10ms no Redis) e escalaria mal. |
| **Alternativas** | Recalculo via PG a cada leitura (lento para o volume), Materialized view no PG (atualização pesada), Apenas Redis sem PG (risco de perda) |
| **Consequências** | Positivas: leitura < 10ms, escrita atômica. Negativas: complexidade de manter consistência Redis ↔ PG (job de reconciliação a cada 1h). |
| **Status** | Aprovado |

### ADR-002: Avaliações Separadas para Restaurante e Entregador

| Campo | Valor |
|-------|-------|
| **Decisão** | Duas avaliações independentes por pedido (restaurante + entregador), cada uma com nota e comentário próprios |
| **Contexto** | Restaurante e entregador são atores diferentes com métricas de qualidade diferentes. Misturar as notas prejudicaria a precisão dos rankings e bônus. |
| **Alternativas** | Avaliação única para o pedido todo (perde granularidade), Avaliação automática baseada em métricas de SLA (remove o feedback humano) |
| **Consequências** | Positivas: feedback específico para cada ator, rankings precisos. Negativas: cliente precisa dar duas notas (pequena fricção, mas aceitável). |
| **Status** | Aprovado |

### ADR-003: Moderação Básica com Blocklist vs ML

| Campo | Valor |
|-------|-------|
| **Decisão** | Moderação básica com lista de palavras bloqueadas + regex para MVP. ML (Google Perspective / OpenAI) para pós-MVP. |
| **Contexto** | Comentários ofensivos precisam ser filtrados. Uma lista de ~100 palavras em português é suficiente para bloquear ~95% dos casos. ML seria overkill e adicionaria latência (200ms vs 5ms). |
| **Alternativas** | Apenas denúncia do usuário (lento e reativo), ML desde o início (custo, latência, complexidade), Blocklist + flag para revisão manual (adotado) |
| **Consequências** | Positivas: rápido (< 5ms), simples, zero custo de API. Negativas: falsos positivos (palavras bloqueadas em contexto inofensivo), não detecta sarcasmo ou ofensas disfarçadas. |
| **Status** | Aprovado |

### ADR-004: Janela de 7 Dias para Avaliação

| Campo | Valor |
|-------|-------|
| **Decisão** | Cliente pode avaliar o pedido por até 7 dias após a entrega. Após esse período, a avaliação não é mais permitida. |
| **Contexto** | Avaliações muito tardias perdem relevância (cliente já não lembra dos detalhes). Janela de 7 dias equilibra conveniência do cliente com precisão do feedback. |
| **Alternativas** | Sem janela (avaliações meses depois perdem relevância), 3 dias (pressiona o cliente), 30 dias (muito longa para feedback operacional) |
| **Consequências** | Positivas: feedback na memória recente do cliente, médias refletem qualidade atual. Negativas: cliente que viaja ou demora a abrir o app perde a janela. |
| **Status** | Aprovado |

### ADR-005: Nota Imutável, Comentário Editável

| Campo | Valor |
|-------|-------|
| **Decisão** | Após submetida, a nota não pode ser alterada. O comentário pode ser editado dentro da janela de 7 dias, com nova moderação. |
| **Contexto** | Permitir alteração de nota permitiria manipulação da média (cliente pode ser influenciado por reembolso ou promoção). Comentário editável permite correção de erros ou atualização após resposta do restaurante. |
| **Alternativas** | Nota e comentário editáveis (risco de manipulação), Nem nota nem comentário editáveis (cliente não pode corrigir erro) |
| **Consequências** | Positivas: média confiável, cliente pode corrigir comentário. Negativas: cliente frustrado se digitou nota errada (raro). |
| **Status** | Aprovado |

---

## 14 — Painel Financeiro

> Fonte: [`docs/architecture/14-painel-financeiro-restaurante/system-design.md`](./architecture/14-painel-financeiro-restaurante/system-design.md)

### ADR-001: Ledger Append-Only com Rollups Pré-Agregados

| Campo | Valor |
|-------|-------|
| **Decisão** | Todos os lançamentos registrados em `ledger_entries` (append-only). Rollups diários pré-agregados em `daily_restaurant_rollups` para consultas rápidas. |
| **Contexto** | Ledger é a fonte da verdade (source of truth). Rollups são cache materializado para performance. Job de reconciliação garante consistência. |
| **Alternativas** | Apenas ledger (consultas lentas para somar milhares de lançamentos), Apenas rollups (perde detalhes por pedido) |
| **Consequências** | Positivas: auditoria completa, consultas rápidas. Negativas: duplicação de dados, complexidade de manter consistência. |
| **Status** | Aprovado |

### ADR-002: Valores em Centavos (INT) vs Float

| Campo | Valor |
|-------|-------|
| **Decisão** | Todos os valores financeiros armazenados em centavos (INT), nunca float ou DECIMAL. |
| **Contexto** | Erros de arredondamento com float (0.1 + 0.2 = 0.30000000000000004) são inaceitáveis em finanças. INT em centavos elimina esse problema. |
| **Alternativas** | DECIMAL(10,2) no PG (funciona, mas mais lento para soma), FLOAT (problemas de arredondamento), BIGINT centavos (adotado) |
| **Consequências** | Positivas: precisão exata, operações aritméticas simples e rápidas. Negativas: necessidade de converter para exibição (dividir por 100), risco de overflow (BIGINT mitiga). |
| **Status** | Aprovado |

### ADR-003: Ciclo de Repasse D+7 com Job Diário

| Campo | Valor |
|-------|-------|
| **Decisão** | Repasses processados em lote diário (job cron 03:00) com ciclo D+7 (configurável por restaurante). |
| **Contexto** | Restaurante precisa de fluxo de caixa previsível. D+7 é o padrão do mercado (iFood, Uber Eats). Processamento em lote reduz custo de transferência. |
| **Alternativas** | Tempo real (cada pedido gera transferência — centenas de transferências/dia, custo alto), D+14 (muito longo), D+1 (muito rápido para reserva de garantia) |
| **Consequências** | Positivas: previsível, custo de transferência baixo, reserva de garantia contra chargebacks. Negativas: restaurante espera 7 dias para receber. |
| **Status** | Aprovado |

### ADR-004: Conciliação com Gateway via Job vs Tempo Real

| Campo | Valor |
|-------|-------|
| **Decisão** | Conciliação financeira executada em job diário (04:00) comparando ledger interno com dados do gateway de pagamento. |
| **Contexto** | Discrepâncias entre o que a plataforma registrou e o que o gateway processou precisam ser detectadas e corrigidas. Conciliação em tempo real seria cara e desnecessária. |
| **Alternativas** | Tempo real (cada evento compara com gateway — lento e custoso), Sem conciliação (risco de discrepâncias não detectadas) |
| **Consequências** | Positivas: detecção diária de discrepâncias, baixo custo operacional. Negativas: janela de 24h para detectar problemas. |
| **Status** | Aprovado |

---

## 15 — Cupons e Campanhas

> Fonte: [`docs/architecture/15-cupons-campanhas/system-design.md`](./architecture/15-cupons-campanhas/system-design.md)

### ADR-001: Contador de Uso no Redis vs PG

| Campo | Valor |
|-------|-------|
| **Decisão** | Contador de uso do cupom mantido no Redis (`INCR` atômico) com fallback para PG |
| **Contexto** | Validação de cupom precisa ser < 50ms. `INCR` no Redis é atômico e < 5ms. UPDATE no PG levaria ~20ms e teria risco de lock de linha em alta concorrência. |
| **Alternativas** | PG com `SELECT ... FOR UPDATE` (lento, lock), PG com UPDATE `SET count = count + 1 WHERE count < max` (mais rápido mas não atômico em alta concorrência) |
| **Consequências** | Positivas: < 5ms, atômico, sem lock. Negativas: risco de inconsistência se PG falhar após INCR (corrigido por job de reconciliação). |
| **Status** | Aprovado |

### ADR-002: Snapshot de Regras no Resgate

| Campo | Valor |
|-------|-------|
| **Decisão** | No momento do resgate, um snapshot das regras do cupom é armazenado em `coupon_redemptions.rules_snapshot` |
| **Contexto** | Regras do cupom podem mudar após a criação (admin pode estender validade, aumentar limite). O valor do desconto e a elegibilidade devem ser calculados com base nas regras vigentes no momento do resgate, não nas regras atuais. |
| **Alternativas** | Sem snapshot (resgate fica vinculado a regras atuais — pode mudar retroativamente), Apenas valor do desconto (perde detalhes das regras) |
| **Consequências** | Positivas: auditoria precisa, disputas resolvidas com base nas regras originais. Negativa: armazenamento extra (JSONB, insignificante). |
| **Status** | Aprovado |

### ADR-003: Validação no Cart vs Validação no Order

| Campo | Valor |
|-------|-------|
| **Decisão** | Validação dupla: `POST /v1/cart/apply-coupon` (validação + cálculo) e `POST /v1/coupons/{id}/redeem` no fechamento (resgate atômico) |
| **Contexto** | Cliente pode aplicar o cupom no carrinho e só finalizar minutos depois. Nesse intervalo, o cupom pode esgotar. A validação no carrinho é informativa (mostra o desconto), o resgate no fechamento é a operação definitiva. |
| **Alternativas** | Apenas validação no carrinho (risco de prometer desconto que não existe mais), Apenas resgate no fechamento (cliente não sabe o desconto antes de finalizar) |
| **Consequências** | Positivas: experiência do cliente (vê o desconto antes), segurança (resgate atômico no fechamento). Negativa: dupla chamada, mas aceitável. |
| **Status** | Aprovado |

### ADR-004: Subsídio Plataforma vs Restaurante

| Campo | Valor |
|-------|-------|
| **Decisão** | Cupom pode ser subsidiado pela plataforma, pelo restaurante ou dividido (percentual configurado na criação) |
| **Contexto** | Campanhas podem ser custeadas totalmente pela plataforma (marketing) ou compartilhadas com restaurantes. O valor do subsídio impacta o ledger financeiro e o relatório do restaurante. |
| **Alternativas** | Apenas plataforma paga (custo alto para plataforma), Apenas restaurante paga (restaurante pode não aderir) |
| **Consequências** | Positivas: flexibilidade de negócios, modelos de campanha variados. Negativa: complexidade contábil (precisa calcular e registrar subsídio separadamente). |
| **Status** | Aprovado |

---

## Apêndice: Mapa de ADRs por Domínio

| ADR | Título | Domínio |
|-----|--------|---------|
| ADR-001 | Estratégia de Mensageria | 00 Plataforma Transversal |
| ADR-002 | API Gateway | 00 Plataforma Transversal |
| ADR-003 | JWT Local Validation no Gateway | 00 Plataforma Transversal |
| ADR-004 | Postgres Único Inicial vs Múltiplos Bancos | 00 Plataforma Transversal |
| ADR-005 | Eventos Assíncronos para Integrações Externas | 00 Plataforma Transversal |
| ADR-006 | Estratégia de Idempotência | 00 Plataforma Transversal |
| ADR-001 | Separação entre Onboarding e Moderation Service | 02 Onboarding Admin |
| ADR-002 | Upload via Presigned URL | 02 Onboarding Admin |
| ADR-003 | Aprovação Dispara Evento, não Chamada Síncrona | 02 Onboarding Admin |
| ADR-004 | Reenvio com Vínculo à Solicitação Anterior | 02 Onboarding Admin |
| ADR-001 | Snapshot Versionado vs Leitura ao Vivo | 03 Gestão de Cardápio |
| ADR-002 | Propagação de Pausa via Evento vs Chamada Síncrona | 03 Gestão de Cardápio |
| ADR-003 | Cache Redis + CDN para Cardápio | 03 Gestão de Cardápio |
| ADR-004 | Preço em Centavos (Inteiro) | 03 Gestão de Cardápio |
| ADR-001 | Geohash para Cache de Cobertura | 04 Geolocalização e Cobertura |
| ADR-002 | Google Places com Fallback para Busca Textual | 04 Geolocalização e Cobertura |
| ADR-003 | Zonas de Cobertura como Polígonos e Raios | 04 Geolocalização e Cobertura |
| ADR-004 | Frete Calculado por Zona, não por Distância Linear | 04 Geolocalização e Cobertura |
| ADR-001 | Elasticsearch como Índice Primário, PostgreSQL como Fallback | 05 Busca e Filtros |
| ADR-002 | Documento Único Denormalizado vs Joins no ES | 05 Busca e Filtros |
| ADR-003 | Cache de Queries para Hot Queries | 05 Busca e Filtros |
| ADR-004 | Paginação Cursor-based em vez de Offset-based | 05 Busca e Filtros |
| ADR-001 | Carrinho no Redis, Pedido no PostgreSQL | 06 Carrinho e Pedido |
| ADR-002 | Lock de Estoque Otimista com SELECT FOR UPDATE | 06 Carrinho e Pedido |
| ADR-003 | Snapshot de Preços no Pedido | 06 Carrinho e Pedido |
| ADR-004 | Compensação de Estoque por Job Cron | 06 Carrinho e Pedido |
| ADR-001 | Tokenização no Gateway, NUNCA no Backend | 07 Pagamentos |
| ADR-002 | Webhook como Mecanismo Primário, Polling como Fallback | 07 Pagamentos |
| ADR-003 | Idempotência de Webhook via UNIQUE Constraint | 07 Pagamentos |
| ADR-004 | Gateway Único (MVP) com Provedor Secundário Planejado | 07 Pagamentos |
| ADR-001 | Orquestrador de Estados vs Máquina de Estados Declarativa | 08 Estados do Pedido |
| ADR-002 | SLA Monitorado via Redis em vez de Banco | 08 Estados do Pedido |
| ADR-003 | WebSocket como Canal Primário, Polling como Fallback | 08 Estados do Pedido |
| ADR-004 | Auditoria Imutável em Tabela Separada | 08 Estados do Pedido |
| ADR-001 | Matching por Proximidade via Redis Geoset | 09 Matching Entregador |
| ADR-002 | Aceite Atômico com Lua Script no Redis | 09 Matching Entregador |
| ADR-003 | Timeout de Oferta de 30s com Job de Cleanup | 09 Matching Entregador |
| ADR-004 | Raio de Matching Progressivo | 09 Matching Entregador |
| ADR-005 | Fila de Ofertas em PG com Cache Redis vs Apenas Redis | 09 Matching Entregador |
| ADR-001 | Redis para Posição em Tempo Real, PG para Persistência | 10 Roteirização e Localização |
| ADR-002 | App Offline-First com Fila Local | 10 Roteirização e Localização |
| ADR-003 | Milestones Manuais (MVP) vs Geofence (Pós-MVP) | 10 Roteirização e Localização |
| ADR-004 | Batch Write vs Individual Write no PG | 10 Roteirização e Localização |
| ADR-005 | WebSocket para Cliente, Polling como Fallback | 10 Roteirização e Localização |
| ADR-001 | WebSocket vs SSE vs Polling | 11 Rastreamento Tempo Real |
| ADR-002 | Redis Pub/Sub para Broadcast Horizontal | 11 Rastreamento Tempo Real |
| ADR-003 | Snapshot em Redis + PG | 11 Rastreamento Tempo Real |
| ADR-004 | Rate Limit de Mensagens por Cliente | 11 Rastreamento Tempo Real |
| ADR-005 | Heartbeat para Detecção de Sessões Mortas | 11 Rastreamento Tempo Real |
| ADR-001 | Código de 6 Dígitos vs QR Code | 12 Confirmação de Entrega |
| ADR-002 | Hash SHA-256 no Redis vs Criptografia Reversível | 12 Confirmação de Entrega |
| ADR-003 | Confirmação Online com Fallback Offline | 12 Confirmação de Entrega |
| ADR-004 | Bloqueio por Tentativas no Redis | 12 Confirmação de Entrega |
| ADR-005 | Evidências Automáticas em Disputas | 12 Confirmação de Entrega |
| ADR-001 | Agregado em Redis com Lua Script vs Recalculo a Cada Leitura | 13 Avaliações |
| ADR-002 | Avaliações Separadas para Restaurante e Entregador | 13 Avaliações |
| ADR-003 | Moderação Básica com Blocklist vs ML | 13 Avaliações |
| ADR-004 | Janela de 7 Dias para Avaliação | 13 Avaliações |
| ADR-005 | Nota Imutável, Comentário Editável | 13 Avaliações |
| ADR-001 | Ledger Append-Only com Rollups Pré-Agregados | 14 Painel Financeiro |
| ADR-002 | Valores em Centavos (INT) vs Float | 14 Painel Financeiro |
| ADR-003 | Ciclo de Repasse D+7 com Job Diário | 14 Painel Financeiro |
| ADR-004 | Conciliação com Gateway via Job vs Tempo Real | 14 Painel Financeiro |
| ADR-001 | Contador de Uso no Redis vs PG | 15 Cupons e Campanhas |
| ADR-002 | Snapshot de Regras no Resgate | 15 Cupons e Campanhas |
| ADR-003 | Validação no Cart vs Validação no Order | 15 Cupons e Campanhas |
| ADR-004 | Subsídio Plataforma vs Restaurante | 15 Cupons e Campanhas |

---

> **Documentos relacionados:** [System Design 00 — Eventos Transversais](./architecture/00-plataforma-transversal/system-design.md#15-decisoes-arquiteturais-adrs) | [Template de System Design](./templates/system-design-template.md) | [Roadmap](./roadmap/ordem-das-jornadas.md)
