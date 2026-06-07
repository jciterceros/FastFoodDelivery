# Epic - iFood Clone

Estou desenvolvendo um clone do iFood não apenas como um aplicativo de delivery, mas como um ecossistema de três frentes interligadas em tempo real: o cliente, o restaurante e o entregador, todos orquestrados por um painel administrativo central.

Para garantir que o sistema seja escalável, seguro e resiliente, dividi a arquitetura em Requisitos Funcionais (RF), agrupados por jornada do usuário, e Requisitos Não Funcionais (RNF).

## 1. Requisitos Funcionais (RF)

### 1.1 Jornada do Cliente (App Mobile / Web)

- Autenticação unificada: login via e-mail, redes sociais (Google/Apple) e validação de dois fatores (2FA) por SMS/WhatsApp.
- Geolocalização ativa: identificação automática do endereço do usuário via GPS e preenchimento manual com busca preditiva (Google Places API).
- Busca e filtros avançados: pesquisa por nome do prato, restaurante, categoria (pizza, japonês) e filtros por taxa de entrega, tempo e frete grátis.
- Carrinho dinâmico: adição de itens de um único restaurante por vez, com personalização de adicionais (ex: ponto da carne, borda recheada).
- Checkout e pagamento multi-meios: integração com gateways para pagamento via Pix, Cartão de Crédito (com tokenização de segurança) e Vale-Refeição.
- Rastreamento em tempo real: mapa interativo mostrando o deslocamento do entregador desde a coleta até o endereço de entrega via WebSocket ou SSE.
- Avaliação e feedback: sistema de nota (1 a 5 estrelas) e comentários para o restaurante e para o entregador de forma separada.

### 1.2 Jornada do Restaurante (Painel Web / Gestor de Pedidos)

- Gestão de cardápio: criação, edição e pausa de produtos, categorias, preços e horários de funcionamento em tempo real.
- Gerenciamento de pedidos: fluxo de estados do pedido: Pendente -> Em Preparo -> Pronto para Coleta -> Despachado.
- Painel financeiro: relatórios de vendas diárias, semanais e mensais, detalhando taxas da plataforma e valores a receber.

### 1.3 Jornada do Entregador (App Mobile)

- Aceite de corridas: sistema de correspondência de pedidos por proximidade (matching) com opção de aceitar ou rejeitar a rota em segundos.
- Roteirização inteligente: integração com mapas (Google Maps/Waze) para traçar a melhor rota até o restaurante e depois até o cliente.
- Confirmação segura: validação da entrega por código numérico gerado no app do cliente.

### 1.4 Painel Administrativo (Interno da Plataforma)

- Moderação e onboarding: aprovação de novos restaurantes e entregadores após checagem de documentos.
- Gestão de cupons: criação de campanhas de marketing, cupons de desconto e taxas de entrega dinâmicas por região.

## 2. Requisitos Não Funcionais (RNF)

- Disponibilidade (High Availability): o sistema deve operar em 99.99% do tempo (Four Nines), utilizando infraestrutura em nuvem (AWS/GCP) com auto-scaling para aguentar picos de acessos (ex: sexta-feira à noite).
- Desempenho e latência: o tempo de resposta das APIs de busca e listagem deve ser inferior a 200ms. Atualizações de localização devem ocorrer a cada 3-5 segundos.
- Consistência e concorrência: o sistema deve travar o estoque de um produto de forma atômica para evitar que dois clientes comprem o último item simultaneamente (isolamento de transações).
- Segurança e LGPD: criptografia de dados sensíveis em repouso e em trânsito (HTTPS/TLS). Mascaramento de dados de pagamento (conformidade PCI-DSS) e exclusão programada de dados pessoais a pedido do usuário.
- Arquitetura orientada a eventos (EDA): uso de mensageria (RabbitMQ ou Apache Kafka) para processar pedidos de forma assíncrona, garantindo que o app não trave se a API do restaurante demorar a responder.
- Offline-first parcial: o aplicativo do entregador deve armazenar os dados essenciais da rota localmente (SQLite/Room) para o caso de perda de sinal de internet durante o trajeto.

## 3. Documentacao e proximos passos

- **Indice da documentacao:** [docs/README.md](./README.md)
- **Ordem de desenho das jornadas:** [roadmap/ordem-das-jornadas.md](./roadmap/ordem-das-jornadas.md)
- **Proximo system design:** [02-onboarding-admin](./system-design/02-onboarding-admin/system-design.md)

### Proximos passos tecnicos

- Evoluir esbocos de system design fase a fase (ver roadmap).
- Consolidar modelagem de dados transversal (Usuarios, Pedidos, Produtos).
- Definir arquitetura de microsservicos e stack (Node.js, NestJS, etc.).