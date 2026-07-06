# Documentacao - FastFoodDelivery (iFood Clone)

Hub central da documentacao arquitetural do ecossistema.

## Como navegar

| Pasta | Conteudo |
|-------|----------|
| [`epic-ifood-clone.md`](./epic-ifood-clone.md) | Visao do produto, RFs por jornada e RNFs |
| [`roadmap/`](./roadmap/) | Ordem recomendada de desenho e dependencias |
| [`templates/`](./templates/) | Modelo padrao para novos system designs |
| [`architecture/`](./architecture/) | Um documento por dominio, numerado por fase |
| [`data-model/er-viewer.html`](./data-model/er-viewer.html) | Visualizador ER interativo (abrir no navegador) |
| [`data-model/schema.dbml`](./data-model/schema.dbml) | Schema em DBML (dbdiagram.io / VS Code) |

## Convencao de pastas

Cada dominio fica em `architecture/NN-nome-do-dominio/`:

```
architecture/
  NN-nome-do-dominio/
    system-design.md    # documento principal (obrigatorio)
    architecture.mermaid # diagrama tecnico (quando existir)
    architecture.svg     # diagrama vetorial (opcional)
```

- **NN** = ordem de execucao (00, 01, 02...)
- **Status** no topo de cada `system-design.md`: `Esboço` | `Em progresso` | `Completo`

## Roadmap de system design

| # | Dominio | Jornada | Status |
|---|---------|---------|--------|
| 00 | [Plataforma transversal](./architecture/00-plataforma-transversal/system-design.md) | RNF (EDA, gateway, HA) | **Em progresso** |
| 01 | [Identidade e usuarios](./architecture/01-identidade-usuarios/system-design.md) | Cliente §1.1 | **Em progresso** |
| 02 | [Onboarding admin](./architecture/02-onboarding-admin/system-design.md) | Admin §1.4 | **Em progresso** |
| 03 | [Gestao de cardapio](./architecture/03-gestao-cardapio/system-design.md) | Restaurante §1.2 | **Em progresso** |
| 04 | [Geolocalizacao e cobertura](./architecture/04-geolocalizacao-cobertura/system-design.md) | Cliente §1.1 | **Em progresso** |
| 05 | [Busca e filtros](./architecture/05-busca-filtros/system-design.md) | Cliente §1.1 | **Em progresso** |
| 06 | [Carrinho e pedido](./architecture/06-carrinho-pedido/system-design.md) | Cliente §1.1 | **Em progresso** |
| 07 | [Pagamentos](./architecture/07-pagamentos/system-design.md) | Cliente §1.1 | **Em progresso** |
| 08 | [Estados do pedido](./architecture/08-estados-pedido-restaurante/system-design.md) | Restaurante §1.2 | **Em progresso** |
| 09 | [Matching entregador](./architecture/09-matching-entregador/system-design.md) | Entregador §1.3 | **Em progresso** |
| 10 | [Roteirizacao e localizacao](./architecture/10-roteirizacao-localizacao/system-design.md) | Entregador §1.3 + RNF | **Em progresso** |
| 11 | [Rastreamento tempo real](./architecture/11-rastreamento-tempo-real/system-design.md) | Cliente §1.1 | **Em progresso** |
| 12 | [Confirmacao de entrega](./architecture/12-confirmacao-entrega/system-design.md) | Entregador §1.3 | **Em progresso** |
| 13 | [Avaliacoes](./architecture/13-avaliacoes/system-design.md) | Cliente §1.1 | **Em progresso** |
| 14 | [Painel financeiro](./architecture/14-painel-financeiro-restaurante/system-design.md) | Restaurante §1.2 | **Em progresso** |
| 15 | [Cupons e campanhas](./architecture/15-cupons-campanhas/system-design.md) | Admin §1.4 | **Em progresso** |

Detalhes de dependencias e fases: [`roadmap/ordem-das-jornadas.md`](./roadmap/ordem-das-jornadas.md).

## Como criar um novo system design

1. Copie [`templates/system-design-template.md`](./templates/system-design-template.md) para a pasta do dominio.
2. Preencha metadados (status, fase, dependencias, RF do epico).
3. Escreva secoes na ordem do template — comece por objetivo, fluxos e modelo de dados.
4. Adicione diagrama Mermaid na pasta do dominio.
5. Atualize a tabela de status neste README.

## Schema do banco

O schema completo do banco de dados PostgreSQL (64 tabelas, 16 schemas) esta disponivel em:

- **[Visualizador ER Interativo](./data-model/er-viewer.html)** — Diagrama interativo com busca, zoom e modo escuro (abrir no navegador)
- **[DBML](./data-model/schema.dbml)** — Schema mestre em DBML para [dbdiagram.io](https://dbdiagram.io) ou VS Code
- **[Domínios](./data-model/domains/)** — DBML por domínio (16 arquivos) + relacionamentos cross-domínio
- **[Matriz de Dependência](./data-model/domain-dependencies.md)** — Quais domínios se conectam, entidades centralizadoras e diagrama de fluxo
- **[Cache Redis](./data-model/cache-redis.md)** — Estruturas não-relacionais (Redis, SQLite offline)

## Proximo passo

Revisar e preencher secoes faltantes de **[02-onboarding-admin](./architecture/02-onboarding-admin/system-design.md)** — sem onboarding aprovado, restaurantes e entregadores nao entram no ecossistema.
