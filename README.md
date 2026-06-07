# Cadastro de Usuários - FastFoodDelivery (estilo iFood)

## Visão Geral
Este repositório documenta o desenho de um domínio de identidade para uma plataforma de fastfood com alto volume de acessos.

O foco do sistema é suportar:
- Cadastro e autenticação de usuários
- Gestão de perfil e endereços
- Verificação de email e telefone (OTP)
- Consentimento e conformidade com LGPD
- Escalabilidade, resiliência e observabilidade

## Estado Atual do Repositório
O projeto está em fase de documentação arquitetural.

Atualmente, a base contém:
- Hub de documentação em [`docs/README.md`](docs/README.md)
- Roadmap de jornadas em [`docs/roadmap/ordem-das-jornadas.md`](docs/roadmap/ordem-das-jornadas.md)
- System designs numerados em [`docs/system-design/`](docs/system-design/) (01 completo, demais em esboço)
- `package.json` ainda mínimo, sem pipeline de build/test definido

## Resumo da Arquitetura
Arquitetura orientada a serviços, com separação clara entre identidade/autenticação e dados de usuário.

### Componentes principais
- **API Gateway**
	- Roteamento por domínio
	- Validação local de JWT por chave pública
	- Rate limiting e correlação por `requestId`
- **Auth Service**
	- Registro, login, refresh e logout
	- Hash de senha com Argon2id
	- Recuperação de senha
	- Verificação de email e telefone
- **User Service**
	- Perfil, preferências e estado de consentimento
- **Address Service**
	- CRUD de endereços e endereço padrão
	- Geocodificação assíncrona
- **Redis**
	- OTP, rate limit, revogação de token e apoio de sessão
- **PostgreSQL**
	- Persistência transacional principal
	- Read replica para cenários de leitura intensa
- **Event Bus + DLQ**
	- Integração assíncrona entre serviços
	- Reprocessamento de falhas com dead-letter queue

### Integrações externas
- Notification Service -> Email/SMS Provider
- Analytics/CDP
- Geocoding Provider

## Fluxos Críticos (MVP)
1. **Cadastro**: criação de credencial + perfil, publicação de `user.created`, envio assíncrono de verificação.
2. **Login**: validação de credencial, emissão de access token curto + refresh token rotativo.
3. **Recuperação de senha**: token de uso único e revogação opcional de sessões antigas.
4. **Endereço**: persistência imediata + geocoding assíncrono com atualização posterior.
5. **OTP de telefone**: geração no Auth, armazenamento com TTL no Redis e confirmação de `phone_verified_at`.

## Requisitos Não Funcionais
- Disponibilidade alvo: **99.9%** no domínio de identidade
- Latência p95:
	- Cadastro: **< 400 ms** (sem envio de email)
	- Login: **< 250 ms**
	- Leitura de perfil: **< 120 ms**
- Escala inicial: **1M usuários**
- Pico esperado: **2k RPS**

## Segurança e Privacidade
- Hash de senha com **Argon2id**
- Access token curto + refresh token rotativo e revogável
- Revogação em Redis e política de invalidade de sessão
- Proteções contra brute force, credential stuffing e enumeração
- Dados sensíveis com TLS, criptografia em repouso e mascaramento de PII em logs
- LGPD: consentimento versionado, exportação de dados, exclusão de conta e trilha de auditoria

## Modelo de Dados (visão resumida)
Entidades principais previstas:
- `users`
- `user_profiles`
- `user_addresses`
- `user_consents`
- `refresh_tokens`
- `user_devices`

Índices relevantes destacados no design:
- `users(email)`
- `refresh_tokens(user_id, revoked_at)`
- `user_addresses(user_id, is_default)`

## Contratos de API (resumo)
Endpoints previstos (prefixo `/v1`):
- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/refresh`
- `POST /auth/forgot-password`
- `POST /auth/reset-password`
- `POST /auth/logout`
- `POST /auth/verify-email`
- `GET /users/me`
- `PATCH /users/me`
- `GET /users/me/addresses`
- `POST /users/me/addresses`
- `PATCH /users/me/addresses/{addressId}`
- `DELETE /users/me/addresses/{addressId}`

## Eventos de Domínio
Eventos centrais no barramento:
- `user.created`
- `user.email.verified`
- `user.phone.verified`
- `user.profile.updated`
- `user.address.created`

## Observabilidade e Resiliência
- Logs estruturados com `requestId`, rota e `userId` quando autenticado
- Métricas de cadastro, conversão, falhas de login e latência por endpoint
- Tracing distribuído entre gateway e serviços
- Timeouts, retries com jitter, circuit breaker e fallback de provedores
- DLQ para reprocessar falhas assíncronas sem bloquear fluxo online

## Decisões Arquiteturais-Chave
- Separação de Auth e User para escalar e reduzir acoplamento
- Validação local de JWT no gateway para reduzir round trip síncrono
- PostgreSQL único no início com separação lógica e evolução progressiva
- Integração por eventos para desacoplamento entre core e serviços externos
- Endereços isolados em serviço próprio para evolução logística futura

## Próximos Passos de Implementação
1. Estruturar a API Node.js + TypeScript + Express em camadas.
2. Implementar autenticação (`register`, `login`, `refresh`, `logout`) com Argon2id e rotação de refresh token.
3. Implementar perfil e endereços com contratos HTTP e validação de entrada.
4. Adicionar Redis para OTP, revogação e rate limit.
5. Introduzir Event Bus e DLQ para fluxos assíncronos.
6. Definir observabilidade mínima (logs estruturados, métricas e health checks).

## Referências
- [`docs/README.md`](docs/README.md) — índice completo
- [`docs/system-design/01-identidade-usuarios/system-design.md`](docs/system-design/01-identidade-usuarios/system-design.md)
- [`docs/system-design/01-identidade-usuarios/architecture.mermaid`](docs/system-design/01-identidade-usuarios/architecture.mermaid)

## Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

Copyright (c) 2011-2026 The Bootstrap Authors
