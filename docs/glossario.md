# Glossário Global — FastFoodDelivery

> **Propósito:** Definições padronizadas de termos técnicos e de domínio usados em toda a documentação arquitetural.
> **Organização:** Termos em ordem alfabética, com referência ao(s) domínio(s) onde são mais relevantes.
> **Convenção:** `snake_case` no banco de dados, `camelCase` nos eventos e APIs. A conversão entre os dois formatos é feita na camada de serialização de cada serviço.

---

## A

### Access Token
Token JWT (JSON Web Token) de curta duração (ex: 15 minutos) usado para autenticar requisições HTTP. Auto-contido: contém claims como `user_id`, `role` e `exp`. Validado localmente pelo API Gateway via cache de chave pública, sem round-trip ao Auth Service.
**Domínios:** 01 (Identidade), 00 (Plataforma Transversal)

### Aceite Atômico
Operação que garante que apenas um entregador seja vinculado a um pedido no momento do aceite, mesmo sob alta concorrência (N entregadores recebendo a mesma oferta simultaneamente). Implementado via Lua script atômico no Redis.
**Domínio:** 09 (Matching)

### ADR (Architecture Decision Record)
Registro de decisão arquitetural que documenta o contexto, a decisão tomada, as alternativas consideradas e as consequências. Mantido na seção 15 de cada system design.
**Domínios:** 00-15 (todos)

### Agregado (Rating)
Média das notas (1-5) de um restaurante ou entregador, mantida em Redis com atualização atômica via Lua script e replicada no PostgreSQL como source of truth. Consistência eventual < 1min.
**Domínio:** 13 (Avaliações)

### Analyzer (Brazilian)
Analisador de texto do Elasticsearch específico para o idioma português brasileiro. Lida com stemmer, stopwords e acentuação. Usado no índice de busca para melhorar a relevância dos resultados.
**Domínio:** 05 (Busca)

### API Gateway
Componente de infraestrutura que atua como porta de entrada única para todas as requisições. Responsável por roteamento, rate limiting, validação JWT, correlação e logging. Decisão MVP: Kong (open-source).
**Domínio:** 00 (Plataforma Transversal)

### ArgoCD
Ferramenta de GitOps para Kubernetes. Utilizada no pipeline de CD para deploy automatizado dos serviços.
**Domínio:** 00 (Plataforma Transversal)

### Argon2id
Algoritmo de hash de senha vencedor da competição PHC. Preferido ao bcrypt por ser resistente a ataques com GPU e ASIC. Padrão utilizado no Auth Service.
**Domínio:** 01 (Identidade)

### At-least-once Delivery
Modo de entrega de mensagens no Event Bus onde cada mensagem é entregue **pelo menos uma vez** ao consumidor. Para garantir isso, o produtor aguarda confirmação (publisher confirm) do RabbitMQ antes de considerar a mensagem como enviada. Consumidores devem ser idempotentes para lidar com possíveis duplicatas.
**Domínio:** 00 (Plataforma Transversal)

### Auditoria Imutável
Registro de dados em formato append-only, sem UPDATE ou DELETE permitidos. Exemplos: `order_status_history` (transições de estado), `moderation_audit_log` (ações de moderação), `ledger_entries` (lançamentos contábeis). Essencial para conformidade e resolução de disputas.
**Domínios:** 02 (Onboarding), 08 (Estados), 14 (Financeiro)

---

## B

### Backpressure
Mecanismo de controle de fluxo onde o produtor reduz a taxa de envio quando o consumidor está sobrecarregado. No Event Bus, implementado via publisher confirms e filas com TTL.
**Domínio:** 00 (Plataforma Transversal)

### Batch Write
Estratégia de escrita onde múltiplos registros são acumulados em buffer e persistidos em lote (ex: 50 pings de localização a cada 30s). Reduz a carga no banco de dados em ~98% comparado a escritas individuais.
**Domínio:** 10 (Roteirização)

### Blocklist (Moderação)
Lista de palavras e expressões regulares proibidas em comentários de avaliação. Comporta dois níveis de severidade: `block` (rejeita o comentário) e `flag` (marca para revisão manual).
**Domínio:** 13 (Avaliações)

### Boosting (Busca)
Técnica do Elasticsearch para aumentar o score de relevância de documentos que atendem certos critérios. Ex: `is_open = true` ganha boost de 1.5x, `avg_rating > 4.0` ganha boost de 1.2x.
**Domínio:** 05 (Busca)

### Bulkhead
Padrão de isolamento de recursos onde pools de conexão e thread pools são separados por tipo de operação (leitura vs escrita) ou por serviço destino. Impede que um circuito sobrecarregado afete os demais.
**Domínio:** 00 (Plataforma Transversal)

---

## C

### Cache Warming
Carregamento antecipado de dados no cache (Redis) após uma operação de escrita, garantindo que a próxima leitura seja rápida. Ex: após publicação de cardápio, o snapshot é carregado no Redis automaticamente.
**Domínio:** 03 (Cardápio)

### Cache-aside
Padrão de cache onde a aplicação consulta o cache primeiro (ex: Redis); se não encontrar (cache miss), consulta o banco de dados e popula o cache para a próxima consulta.
**Domínio:** 03 (Cardápio)

### Campanha (Campaign)
Conjunto de cupons e regras de marketing com orçamento definido, período de validade e métricas de ROI. Gerenciada pelo admin no painel de campanhas.
**Domínio:** 15 (Cupons)

### Canary Deploy
Estratégia de deploy onde uma nova versão recebe uma pequena fração do tráfego (ex: 10%) antes de ser promovida para 100%. Usada para serviços críticos como Auth, Order e Payment.
**Domínio:** 00 (Plataforma Transversal)

### CAPTCHA Adaptativo
Desafio de verificação ("Não sou um robô") ativado seletivamente com base no comportamento do usuário: múltiplas tentativas de login, cadastro muito rápido, IP suspeito. Implementado como camada adicional após o rate limit ser violado.
**Domínio:** 01 (Identidade)

### CDN (Content Delivery Network)
Rede de servidores distribuídos geograficamente que armazena conteúdo estático em cache (imagens de cardápio, assets). Reduz latência para o cliente e carga no servidor de origem. URLs públicas para conteúdo não sensível.
**Domínios:** 03 (Cardápio), 04 (Geolocalização)

### Centavos (Precisão Financeira)
Padrão de armazenamento de valores monetários como inteiros em centavos (ex: R$ 29,90 = 2990 centavos). Elimina erros de arredondamento de ponto flutuante. Usado em todos os domínios financeiros.
**Domínios:** 03 (Cardápio), 06 (Pedido), 07 (Pagamento), 14 (Financeiro), 15 (Cupons)

### Chargeback
Contestação de cobrança feita pelo cliente junto à operadora do cartão. A plataforma precisa fornecer evidências da transação e do serviço prestado para contestar.
**Domínio:** 07 (Pagamentos)

### Circuit Breaker
Padrão de resiliência que interrompe temporariamente chamadas a um serviço ou provedor externo após um limiar de falhas, permitindo que o sistema se recupere. Estados: closed (normal), open (falhas), half-open (teste).
**Domínios:** 00 (Plataforma Transversal), 07 (Pagamentos), 09 (Matching)

### Completion Suggester
Funcionalidade do Elasticsearch que fornece sugestões de busca em tempo real (autocomplete) baseadas no que o usuário está digitando. Configurado com analyzer `brazilian` e contextos por `cuisine_type`.
**Domínio:** 05 (Busca)

### Compensação (Saga)
Padrão de consistência eventual onde cada operação tem uma operação compensatória para desfazê-la em caso de falha. Ex: liberar reserva de estoque se o pagamento expirar.
**Domínio:** 06 (Pedido)

### Constant-time Response
Técnica de segurança onde o endpoint retorna o mesmo body e status HTTP independentemente do resultado (ex: forgot-password retorna sempre 200, mesmo se o email não existir). Previne enumeração de usuários.
**Domínio:** 01 (Identidade)

### Correlation ID
Identificador único (UUID) propagado em toda requisição através do header `X-Correlation-Id`. Permite rastrear uma requisição ponta a ponta através de logs, eventos e tracing.
**Domínio:** 00 (Plataforma Transversal)

### Credential Stuffing
Ataque onde credenciais vazadas de outros serviços são testadas em massa contra o sistema. Mitigado por rate limiting, CAPTCHA adaptativo e bloqueio progressivo de IP.
**Domínio:** 01 (Identidade)

### Cursor-based Pagination
Estratégia de paginação que usa um cursor (token opaco) em vez de page/offset. Evita problemas de paginação profunda do Elasticsearch (limite de 10k com `from + size`) e mantém consistência mesmo com dados mudando entre páginas.
**Domínio:** 05 (Busca)

---

## D

### D+7
Ciclo de repasse financeiro onde o valor das vendas é transferido ao restaurante 7 dias após a confirmação da entrega. Configurável por restaurante via `payout_config`.
**Domínio:** 14 (Financeiro)

### Dead-Letter Queue (DLQ)
Fila onde mensagens do Event Bus são movidas após esgotarem todas as tentativas de reprocessamento (5 tentativas com backoff exponencial: 1s, 2s, 4s, 8s, 16s). Job de reprocessamento tenta a cada 30min. Após 3 reprocessamentos sem sucesso, alerta operacional é disparado.
**Domínio:** 00 (Plataforma Transversal)

### Deep Link
Link que abre um aplicativo externo (Google Maps, Waze) com coordenadas de destino pré-preenchidas. Usado pelo app do entregador para abrir a navegação turn-by-turn.
**Domínio:** 10 (Roteirização)

### Device Fingerprint
Conjunto de características do dispositivo (tipo de browser, resolução de tela, idioma, plugins) usado para identificar o dispositivo sem depender exclusivamente de cookies ou tokens. Coleta mínima de dados para evitar violação de privacidade.
**Domínio:** 01 (Identidade)

### Disputa
Contestação formal de uma entrega onde o cliente alega não ter recebido o pedido. O sistema coleta evidências automaticamente (geolocalização, tentativas de confirmação, logs) para resolução pelo admin.
**Domínio:** 12 (Confirmação)

### DLQ (Dead-Letter Queue)
Ver *Dead-Letter Queue*.

---

## E

### EDA (Event-Driven Architecture)
Arquitetura orientada a eventos onde serviços se comunicam através de eventos assíncronos publicados em um barramento de mensageria (Event Bus). Desacopla produtores de consumidores e permite maior escalabilidade e resiliência.
**Domínio:** 00 (Plataforma Transversal)

### Elasticsearch / OpenSearch
Mecanismo de busca e analytics distribuído, usado como índice primário de busca (full-text, geo_distance, filtros). OpenSearch é a alternativa open-source (fork do Elasticsearch após mudança de licença).
**Domínio:** 05 (Busca)

### Escalonamento (Escalation)
Processo automático que eleva a prioridade de um pedido não matchado após N tentativas sem sucesso. Admin é notificado para alocação manual.
**Domínio:** 09 (Matching)

### Event Bus
Infraestrutura de mensageria que encaminha eventos entre produtores e consumidores. MVP: RabbitMQ. Escala futura: Apache Kafka (quando throughput > 100k msg/s ou necessidade de replay de eventos).
**Domínio:** 00 (Plataforma Transversal)

### Event Storm
Cenário de pico onde um grande volume de eventos é publicado simultaneamente (ex: sexta-feira à noite). Mitigado por backpressure, rate limit, filas com TTL e HPA em consumidores.
**Domínio:** 00 (Plataforma Transversal)

### Evidência (Disputa)
Dados coletados automaticamente ao abrir uma disputa: geolocalização do entregador e cliente no momento da confirmação, distância entre ambos, histórico de tentativas de confirmação, logs de localização dos 10min anteriores.
**Domínio:** 12 (Confirmação)

---

## F

### Facet (Faceta)
Agregação de resultados de busca por categoria. Ex: ao buscar "pizza", o Elasticsearch retorna as categorias encontradas (pizzaria, italiana) com contagem de resultados. Usado para refinamento de filtros.
**Domínio:** 05 (Busca)

### Fused Location Provider
API do Google Play Services que combina sinais de GPS, Wi-Fi e torres de celular para fornecer localização com baixo consumo de bateria. Usado no app do entregador para redução de consumo energético.
**Domínio:** 10 (Roteirização)

---

## G

### Geofence
Cerca virtual que dispara eventos quando um dispositivo entra ou sai de uma área geográfica definida. Pos-MVP: usado para detectar automaticamente a chegada do entregador ao restaurante ou cliente, sem ação manual.
**Domínio:** 10 (Roteirização)

### Geohash
Sistema de codificação que converte coordenadas geográficas (lat/lon) em uma string alfanumérica. Quanto mais caracteres, maior a precisão:
- 1 char: ~5.000km
- 5 chars: ~5km
- 6 chars: ~1km (precisão usada no cache de cobertura)
- 7 chars: ~150m (precisão usada em logs)
Usado para cache de cobertura, agregação de localização em logs e queries espaciais.
**Domínio:** 04 (Geolocalização)

### GeoJSON
Formato padrão para codificação de estruturas de dados geográficos. Usado nas regras de frete dinâmico (`delivery_fee_rules.region_geometry`) e zonas de cobertura.
**Domínios:** 04 (Geolocalização), 15 (Cupons)

### GEORADIUS
Comando do Redis Geoset que busca membros dentro de um raio geográfico. Usado pelo Dispatch Service para encontrar entregadores próximos ao restaurante. Operação O(log N).
**Domínio:** 09 (Matching)

### Geoset (Redis)
Estrutura de dados do Redis que armazena coordenadas geográficas e permite consultas por raio (`GEORADIUS`) e distância (`GEODIST`). Usado para manter as posições dos entregadores online.
**Domínio:** 09 (Matching)

### GiST (Generalized Search Tree)
Índice do PostgreSQL para dados geométricos. Obrigatório em colunas do tipo `GEOMETRY` (PostGIS) para queries espaciais como `ST_DWithin` e `ST_Contains`.
**Domínio:** 04 (Geolocalização)

### GitOps
Prática de deploy onde o estado desejado da infraestrutura é declarado em um repositório Git, e um operador (ArgoCD) mantém o cluster sincronizado com o repositório.
**Domínio:** 00 (Plataforma Transversal)

### Grace Period (Token Rotation)
Janela de tempo (ex: 30 segundos) durante a qual o refresh token anterior ainda é válido após a rotação. Tolerante a retransmissões em redes instáveis.
**Domínio:** 01 (Identidade)

### Graceful Degradation
Estratégia onde o sistema continua funcionando com funcionalidade reduzida quando um componente falha. Ex: se Elasticsearch cair, busca fallback para PostgreSQL com índice GIN (sem geo_distance, sem ranking full-text).
**Domínios:** 00 (Plataforma Transversal), 05 (Busca), 10 (Roteirização)

---

## H

### Haversine
Fórmula matemática para calcular a distância entre dois pontos em uma esfera (distância linear aproximada). Usada como fallback no PostgreSQL quando o Redis Geoset está indisponível para matching.
**Domínios:** 04 (Geolocalização), 09 (Matching)

### Heartbeat
Mensagem periódica (ping/pong) enviada entre cliente e servidor WebSocket para manter a conexão ativa e detectar desconexões. Intervalo: 30s no Realtime Service.
**Domínio:** 11 (Realtime)

### HMAC (Hash-based Message Authentication Code)
Código de autenticação de mensagem baseado em hash. Usado para validar a integridade e autenticidade de webhooks recebidos de gateways de pagamento e outros provedores externos.
**Domínio:** 07 (Pagamentos)

### HPA (Horizontal Pod Autoscaler)
Mecanismo do Kubernetes que ajusta automaticamente o número de réplicas de um serviço com base em métricas como CPU e RPS por rota.
**Domínio:** 00 (Plataforma Transversal)

---

## I

### Idempotency-Key
Header HTTP (`Idempotency-Key`) obrigatório em endpoints de mutação (register, create order, confirm payment). A chave é armazenada em Redis com TTL de 24h. Se a mesma chave chegar com o mesmo body, retorna a resposta original (cached). Se chegar com body diferente, retorna `422 IDEMPOTENCY_REUSE`.
**Domínios:** 00 (Plataforma Transversal), 06 (Pedido), 07 (Pagamentos)

### Istio / Linkerd
Malhas de serviço (service mesh) para Kubernetes. Pos-MVP: implementam mTLS entre serviços, roteamento avançado e observabilidade de tráfego.
**Domínio:** 00 (Plataforma Transversal)

---

## J

### Jaeger
Sistema de tracing distribuído open-source. Exportador padrão para OpenTelemetry no MVP. Alternativas futuras: AWS X-Ray, GCP Cloud Trace.
**Domínio:** 00 (Plataforma Transversal)

### JWT (JSON Web Token)
Token auto-contido com claims de autenticação (`user_id`, `role`) e autorização. Assinado com chave privada. Validado localmente pelo API Gateway via cache de chave pública (JWK), sem round-trip ao Auth Service.
**Domínio:** 00 (Plataforma Transversal)

---

## K

### KMS (Key Management Service)
Serviço de gerenciamento de chaves criptográficas (AWS KMS, GCP Cloud KMS, HashiCorp Vault). Usado para rotação automática de chaves de criptografia em repouso, certificados TLS e secrets.
**Domínio:** 00 (Plataforma Transversal)

### Kong
API Gateway open-source baseado em Nginx. Decisão MVP para roteamento, rate limiting, validação JWT e correlação. Alternativa futura: AWS API Gateway.
**Domínio:** 00 (Plataforma Transversal)

---

## L

### Ledger (Append-only)
Livro contábil onde todas as entradas são registradas em modo append-only. Nenhum registro é alterado ou excluído — apenas novas entradas de ajuste são adicionadas. Fonte da verdade para todo o financeiro.
**Domínio:** 14 (Financeiro)

### Lock de Estoque
Mecanismo que impede que dois clientes comprem o último item simultaneamente. Implementado via `SELECT ... FOR UPDATE` no PostgreSQL dentro de uma transação curta (< 500ms).
**Domínio:** 06 (Pedido)

### Lua Script (Redis)
Script executado atomicamente no Redis, sem interrupção. Usado no aceite de ofertas (matching) para garantir que apenas um entregador seja vinculado ao pedido, mesmo sob concorrência.
**Domínio:** 09 (Matching)

---

## M

### Máquina de Estados
Modelo que define os estados válidos de um pedido (`draft`, `pending`, `preparing`, `ready_for_pickup`, `dispatched`, `delivered`, `cancelled`) e as transições permitidas entre eles. Implementada de forma declarativa (tabela de transições), não imperativa.
**Domínio:** 08 (Estados)

### MFA (Multi-Factor Authentication)
Autenticação de múltiplos fatores. Obrigatório para admins via TOTP (aplicativo autenticador). Previsto para clientes como opcional (pos-MVP), via SMS ou app.
**Domínios:** 00 (Plataforma Transversal), 01 (Identidade)

### Média Móvel
Técnica de cálculo de média onde o novo valor é calculado a partir da média anterior e do novo dado, sem necessidade de reprocessar todo o histórico. Usada na atualização atômica do agregado de avaliações no Redis.
**Domínio:** 13 (Avaliações)

### Milestone
Marco de uma corrida de entrega. Sequência: `heading_to_restaurant` → `at_restaurant` → `heading_to_customer` → `arrived`. Cada milestone é registrado com geolocalização e pode ser acionado manualmente (MVP) ou por geofence (pos-MVP).
**Domínio:** 10 (Roteirização)

### Moderação (Comentários)
Processo de filtragem de comentários de avaliações. MVP: blocklist de palavras ofensivas + regex. Pos-MVP: ML (Google Perspective / OpenAI) para detecção de sarcasmo e ofensas disfarçadas.
**Domínio:** 13 (Avaliações)

### mTLS (Mutual TLS)
TLS mútuo onde cliente e servidor se autenticam mutuamente com certificados. Previsto para pos-MVP via service mesh (Istio/Linkerd).
**Domínio:** 00 (Plataforma Transversal)

---

## N

### Nested Query
Tipo de consulta do Elasticsearch que permite buscar em documentos com campos aninhados (nested). Usado para buscar por nome de item dentro de `categories.items[].name` no documento `restaurant_search_doc`.
**Domínio:** 05 (Busca)

---

## O

### Object Storage
Armazenamento de objetos (S3, GCS) para documentos de onboarding. Upload via presigned URL (TTL 15min). Documentos nunca passam pelo servidor de aplicação.
**Domínio:** 02 (Onboarding)

### OCR (Optical Character Recognition)
Reconhecimento óptico de caracteres. Pos-MVP: usado para validação automática de documentos de onboarding (CNH, identidade).
**Domínio:** 02 (Onboarding)

### Offline-first
Estratégia onde o app do entregador funciona offline com dados cacheados localmente (SQLite/Room) e sincroniza quando a conexão é restaurada. Prioriza envio de milestones sobre pings.
**Domínio:** 10 (Roteirização)

### OpenTelemetry
Padrão único de instrumentação para logs, métricas e tracing. Propagação de contexto via headers HTTP (W3C Trace Context). Exportadores: Jaeger (MVP), AWS X-Ray/GCP Cloud Trace (escala).
**Domínio:** 00 (Plataforma Transversal)

### Optimistic Locking
Estratégia de controle de concorrência onde o conflito é detectado no momento da escrita (versão), não prevenido com locks preventivos. Ex: dois admins editam o cardápio → o segundo recebe `409 CONFLICT`.
**Domínio:** 03 (Cardápio)

### OTP (One-Time Password)
Código de uso único e curta duração (5min) enviado por SMS para verificação de telefone. Armazenado como hash no Redis.
**Domínio:** 01 (Identidade)

### OWASP ASVS
Application Security Verification Standard — padrão de segurança para aplicações web. Baseline usado para definir os controles de segurança do domínio de identidade.
**Domínio:** 01 (Identidade)

---

## P

### p95 / p99
Percentil 95 / 99. Medidas de latência usadas como SLA: p95 significa que 95% das requisições têm latência igual ou inferior a este valor. Ex: busca < 200ms p95.
**Domínio:** 00 (Plataforma Transversal)

### PAN (Primary Account Number)
Número completo do cartão (16 dígitos). **Nunca armazenado** no backend. A tokenização é feita exclusivamente pelo gateway (Stripe Elements / Adyen Drop-in) para manter o backend fora do escopo PCI-DSS.
**Domínio:** 07 (Pagamentos)

### PCI-DSS (Payment Card Industry Data Security Standard)
Conjunto de requisitos de segurança para organizações que processam, armazenam ou transmitem dados de cartão de crédito. O backend da plataforma está fora do escopo PCI-DSS pois nunca armazena PAN ou CVV.
**Domínio:** 07 (Pagamentos)

### Pix
Sistema de pagamento instantâneo brasileiro. Integrado via QR code dinâmico com expiração de 30 minutos. Confirmação via webhook do gateway.
**Domínio:** 07 (Pagamentos)

### Polling
Técnica onde o cliente consulta periodicamente um endpoint REST para obter atualizações. Usado como fallback para WebSocket: cliente faz polling a cada 5s se a conexão WebSocket cair.
**Domínios:** 10 (Roteirização), 11 (Realtime)

### PostGIS
Extensão do PostgreSQL que adiciona suporte a tipos geométricos (`GEOMETRY`, `GEOGRAPHY`), índices GiST e funções espaciais (`ST_DWithin`, `ST_Contains`, `ST_MakePoint`). Obrigatório para o domínio de geolocalização.
**Domínio:** 04 (Geolocalização)

### Presigned URL
URL temporária (TTL de 15min) que concede acesso direto a um objeto no Object Storage. Usada para upload de documentos de onboarding e imagens de cardápio. O servidor nunca recebe o conteúdo binário.
**Domínios:** 02 (Onboarding), 03 (Cardápio)

### Publisher Confirm
Mecanismo do RabbitMQ onde o produtor aguarda confirmação do broker de que a mensagem foi recebida e persistida antes de considerar o envio como bem-sucedido. Essencial para garantir *at-least-once delivery* e prevenir perda de mensagens.
**Domínio:** 00 (Plataforma Transversal)

### Pub/Sub (Publish/Subscribe) (Payment Card Industry Data Security Standard)
Conjunto de requisitos de segurança para organizações que processam, armazenam ou transmitem dados de cartão de crédito. O backend da plataforma está fora do escopo PCI-DSS pois nunca armazena PAN ou CVV.
**Domínio:** 07 (Pagamentos)

### Pix
Sistema de pagamento instantâneo brasileiro. Integrado via QR code dinâmico com expiração de 30 minutos. Confirmação via webhook do gateway.
**Domínio:** 07 (Pagamentos)

### Polling
Técnica onde o cliente consulta periodicamente um endpoint REST para obter atualizações. Usado como fallback para WebSocket: cliente faz polling a cada 5s se a conexão WebSocket cair.
**Domínios:** 10 (Roteirização), 11 (Realtime)

### PostGIS
Extensão do PostgreSQL que adiciona suporte a tipos geométricos (`GEOMETRY`, `GEOGRAPHY`), índices GiST e funções espaciais (`ST_DWithin`, `ST_Contains`, `ST_MakePoint`). Obrigatório para o domínio de geolocalização.
**Domínio:** 04 (Geolocalização)

### Presigned URL
URL temporária (TTL de 15min) que concede acesso direto a um objeto no Object Storage. Usada para upload de documentos de onboarding e imagens de cardápio. O servidor nunca recebe o conteúdo binário.
**Domínios:** 02 (Onboarding), 03 (Cardápio)

### Pub/Sub (Publish/Subscribe)
Padrão de mensageria onde mensagens são publicadas em canais e distribuídas a todos os assinantes. No Redis Pub/Sub, usado para distribuir eventos de tracking entre pods do Realtime Service.
**Domínio:** 11 (Realtime)

---

## Q

### QR Code Dinâmico
QR code gerado sob demanda para pagamento Pix, contendo valor, descrição e chave de destino. Expira em 30 minutos. O código muda a cada transação (diferente de QR code estático, que é fixo).
**Domínio:** 07 (Pagamentos)

---

## R

### Raio Progressivo (Matching)
Estratégia de matching onde o raio de busca por entregadores expande gradativamente entre tentativas: tentativa 1 = 3km, tentativa 2 = 5km, tentativa 3 = 8km. Após 3 tentativas sem sucesso, o pedido vai para a fila de escalonamento. Balanceia tempo de deslocamento e chance de matching.
**Domínio:** 09 (Matching)

### Rate Limiting
Controle de taxa de requisições para proteger serviços contra abuso. Implementado no API Gateway com contadores no Redis por escopo (`ip`, `user_id`, `device_id`). Limites por rota (ex: login: 10/min, register: 5/min).
**Domínio:** 00 (Plataforma Transversal)

### RBAC (Role-Based Access Control)
Controle de acesso baseado em papéis. Quatro roles no sistema: `customer`, `restaurant_owner`, `courier`, `admin`. Cada role tem permissões específicas validadas no JWT.
**Domínio:** 00 (Plataforma Transversal)

### Read Replica
Cópia do banco de dados principal usada exclusivamente para consultas de leitura, reduzindo a carga no primário. Configurada desde o início para leituras de perfil e relatórios financeiros.
**Domínio:** 00 (Plataforma Transversal)

### Reconciliação Financeira
Processo diário que compara os valores registrados no ledger interno com os valores processados pelo gateway de pagamento. Discrepâncias são registradas para investigação manual.
**Domínio:** 14 (Financeiro)

### Refresh Token Rotativo
Token de longa duração usado para renovar o access token expirado. É rotacionado a cada renovação: o token antigo é revogado e um novo é emitido. Armazenado como hash no banco.
**Domínio:** 01 (Identidade)

### Repasse (Payout)
Transferência financeira do valor líquido das vendas para a conta bancária do restaurante. Processado em lote diário com ciclo D+7 (configurável).
**Domínio:** 14 (Financeiro)

### Resgate (Redemption)
Ação de utilizar um cupom em um pedido. Cada resgate é registrado com snapshot das regras do cupom no momento, valor do desconto e subsídio (plataforma vs restaurante).
**Domínio:** 15 (Cupons)

### Review Bombing
Ataque onde múltiplas contas avaliam um restaurante com notas baixas simultaneamente para prejudicar sua reputação. Mitigado por alerta de queda brusca de média > 0.5 em 1 hora.
**Domínio:** 13 (Avaliações)

### ROI (Return on Investment)
Métrica de retorno sobre investimento de uma campanha. Calculado como `(gross_order - discount) / discount * 100`. Ex: campanha com ROI de 400% gerou 4x o valor investido em vendas brutas.
**Domínio:** 15 (Cupons)

### Rollup
Agregação pré-calculada de dados financeiros por dia para consultas rápidas no painel. Atualizado a cada novo lançamento e verificado por job de recálculo a cada 1h.
**Domínio:** 14 (Financeiro)

---

## S

### Service Mesh
Camada de infraestrutura para comunicação entre serviços (service-to-service). Adiciona mTLS, roteamento, observabilidade e resiliência sem modificar o código da aplicação. Istio e Linkerd são as opções avaliadas para pos-MVP.
**Domínio:** 00 (Plataforma Transversal)

### SHA-256
Algoritmo de hash criptográfico da família SHA-2. Usado para armazenar o código de confirmação de entrega (nunca em plaintext) e o checksum de documentos no upload.
**Domínios:** 02 (Onboarding), 12 (Confirmação)

### Sharding (Elasticsearch)
Distribuição de documentos do índice em partições (shards) para escalabilidade horizontal. 3 shards primários, 1 réplica cada. Distribuição por `restaurant_id`.
**Domínio:** 05 (Busca)

### SLA (Service Level Agreement)
Acordo de nível de serviço. Exemplos: moderação de onboarding em < 48h, preparo de pedido < 30min, primeira oferta de matching < 10s. Monitorado por jobs e alertas.
**Domínios:** 02 (Onboarding), 08 (Estados), 09 (Matching)

### Snapshot de Preços
Cópia dos preços e modifiers de cada item no momento do checkout, armazenada em `order_items`. Garante que o valor cobrado seja o do momento da compra, independentemente de mudanças futuras no cardápio.
**Domínio:** 06 (Pedido)

### Snapshot Versionado (Cardápio)
Cardápio completo serializado em JSONB a cada publicação, armazenado em `menu_snapshots` com versão incremental. Permite rollback e rastreamento de alterações.
**Domínio:** 03 (Cardápio)

### Soft Delete
Ocultação lógica de um registro (marcação de status) sem exclusão física. Usado na exclusão de conta (janela de retenção LGPD) e documentos de onboarding.
**Domínio:** 01 (Identidade)

### SSE (Server-Sent Events)
Tecnologia de push unidirecional do servidor para o cliente via HTTP. Descartado em favor de WebSocket pela necessidade de comunicação bidirecional (heartbeat) e headers customizados.
**Domínio:** 11 (Realtime)

### Sticky Session
Técnica onde o load balancer direciona todas as requisições de um cliente para o mesmo servidor (pod). Descartada no Realtime Service em favor de Redis Pub/Sub para escalabilidade horizontal sem afinidade.
**Domínio:** 11 (Realtime)

### Streaming Replication
Mecanismo do PostgreSQL onde um servidor primário replica continuamente as alterações para um ou mais servidores secundários (read replicas). Configurado desde o início.
**Domínio:** 01 (Identidade)

### Subsídio (Cupom)
Definição de quem arca com o custo do desconto: plataforma (`platform`), restaurante (`restaurant`) ou dividido (`split`). O valor do subsídio impacta o ledger financeiro e o relatório do restaurante.
**Domínio:** 15 (Cupons)

### Surge Pricing
Ajuste dinâmico de preços (taxa de entrega) com base na relação entre demanda e oferta de entregadores. Pos-MVP.
**Domínio:** 09 (Matching)

---

## T

### Three-DS (3D Secure)
Protocolo de autenticação adicional para pagamentos com cartão de crédito, onde o cliente é redirecionado ao banco emissor para verificação. Reduz risco de chargeback e fraudes. Obrigatório no Brasil para transações com cartão não presentes (e-commerce).
**Domínio:** 07 (Pagamentos)

### TLS (Transport Layer Security)
Protocolo de criptografia em trânsito. TLS 1.3 obrigatório entre todos os serviços. Certificados gerenciados por KMS/cert-manager com rotação a cada 90 dias.
**Domínio:** 00 (Plataforma Transversal)

### TOAST (The Oversized-Attribute Storage Technique)
Mecanismo do PostgreSQL que comprime e armazena valores grandes (> 2KB) em tabelas separadas. Usado para o campo `snapshot` (JSONB) em `menu_snapshots` e outros campos de dados volumosos.
**Domínio:** 03 (Cardápio)

### Tokenização (Cartão)
Processo onde o gateway de pagamento substitui o PAN do cartão por um token único. O backend nunca vê o número completo do cartão. A tokenização é feita no frontend via Stripe Elements ou Adyen Drop-in.
**Domínio:** 07 (Pagamentos)

### TOTP (Time-based One-Time Password)
Código de uso único baseado em tempo, gerado por aplicativo autenticador (Google Authenticator, Authy). Usado como MFA obrigatório para admins.
**Domínio:** 01 (Identidade)

### TTL (Time-To-Live)
Tempo de vida de um dado em cache ou armazenamento temporário. Ex: carrinho expira em 60min, código de confirmação em 30min, snapshot de tracking em 5min.
**Domínio:** 00 (Plataforma Transversal)

---

## V

### Vault (HashiCorp)
Ferramenta de gerenciamento de segredos (secrets). MVP para armazenamento de credenciais de banco, chaves de API e certificados. Alternativa: AWS Secrets Manager.
**Domínio:** 00 (Plataforma Transversal)

---

## W

### Webhook
Callback HTTP enviado por um provedor externo (gateway de pagamento) para notificar eventos assíncronos (ex: pagamento confirmado). Validado por assinatura HMAC e processado com idempotência.
**Domínio:** 07 (Pagamentos)

### WebSocket
Protocolo de comunicação bidirecional full-duplex sobre TCP. Usado para:
- Painel do restaurante: notificação de novos pedidos em < 3s
- App do cliente: rastreamento do entregador em tempo real
- App do entregador: recebimento de ofertas de corrida
**Domínios:** 08 (Estados), 11 (Realtime), 09 (Matching)

---

## Referências

- [Diagrama ER Global](./data-model/er-global.md) — modelo de dados consolidado
- [Plataforma Transversal](./architecture/00-plataforma-transversal/system-design.md#19-glossario-transversal) — glossário original do domínio 00
- [Epico iFood Clone](./epic-ifood-clone.md) — visão do produto e requisitos funcionais
