# FastFoodDelivery — Data Model

> **Propósito:** Este diretório contém a representação completa do schema de banco de dados do ecossistema FastFoodDelivery (iFood Clone), incluindo diagramas ER, documentação em DBML e visualizador interativo.
>
> **Fonte primária:** [`db/migrations/V1__Initial_Schema.sql`](../../db/migrations/V1__Initial_Schema.sql) (DDL oficial do PostgreSQL)
>
> **Regeneração automática:** `python scripts/sql-to-dbml.py` atualiza todos os arquivos gerados abaixo.

---

## Arquivos

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| [`schema.dbml`](./schema.dbml) | 🟢 Gerado | Schema mestre combinando **64 tabelas** de **16 schemas** com todas as relações (intra + cross-domínio). Compatível com [dbdiagram.io](https://dbdiagram.io) e extensão VS Code DBML. |
| [`er-diagram.mmd`](./er-diagram.mmd) | 🟢 Gerado | Diagrama ER completo em sintaxe [Mermaid.js](https://mermaid.js.org/syntax/entityRelationshipDiagram.html). Contém todas as tabelas, colunas e relacionamentos. |
| [`er-diagram.svg`](./er-diagram.svg) | 🟢 Gerado | Versão renderizada do diagrama ER (1.9 MB). Pode ser visualizada em qualquer navegador. |
| [`er-viewer.html`](./er-viewer.html) | 🟢 Gerado | **Visualizador ER interativo.** Abra no navegador para explorar o diagrama com zoom, pan, busca, filtro por tabela e modal com detalhes das colunas e relacionamentos (FKs). |
| [`cache-redis.md`](./cache-redis.md) | 🔵 Manual | Documentação das estruturas **não-relacionais**: Redis (cache, sessão, tempo real) e SQLite (offline do entregador). |
| [`domain-dependencies.md`](./domain-dependencies.md) | 🟢 Gerado | Matriz de dependência entre domínios: quantas FKs conectam cada par, diagrama de fluxo e entidades centralizadoras. |
| [`domains/`](./domains/) | 🟢 Gerado | DBML por domínio (16 arquivos) + relacionamentos cross-domínio. |

### Domínios DBML

| # | Arquivo | Schema(s) | Tabelas |
|:-:|---------|-----------|:-------:|
| 00 | [`00-plataforma-transversal.dbml`](./domains/00-plataforma-transversal.dbml) | `infra` | 3 |
| 01 | [`01-identidade-usuarios.dbml`](./domains/01-identidade-usuarios.dbml) | `auth`, `user` | 6 |
| 02 | [`02-onboarding-admin.dbml`](./domains/02-onboarding-admin.dbml) | `onboarding` | 5 |
| 03 | [`03-gestao-cardapio.dbml`](./domains/03-gestao-cardapio.dbml) | `menu` | 6 |
| 04 | [`04-geolocalizacao-cobertura.dbml`](./domains/04-geolocalizacao-cobertura.dbml) | `coverage` | 5 |
| 05 | [`05-busca-filtros.dbml`](./domains/05-busca-filtros.dbml) | `search` | 1 |
| 06 | [`06-carrinho-pedido.dbml`](./domains/06-carrinho-pedido.dbml) | `order` | 3 |
| 07 | [`07-pagamentos.dbml`](./domains/07-pagamentos.dbml) | `payment` | 4 |
| 08 | [`08-estados-pedido-restaurante.dbml`](./domains/08-estados-pedido-restaurante.dbml) | *(extraído de order)* | 2 |
| 09 | [`09-matching-entregador.dbml`](./domains/09-matching-entregador.dbml) | `dispatch` | 5 |
| 10 | [`10-roteirizacao-localizacao.dbml`](./domains/10-roteirizacao-localizacao.dbml) | `tracking` | 5 |
| 11 | [`11-rastreamento-tempo-real.dbml`](./domains/11-rastreamento-tempo-real.dbml) | `realtime` | 2 |
| 12 | [`12-confirmacao-entrega.dbml`](./domains/12-confirmacao-entrega.dbml) | `verification` | 3 |
| 13 | [`13-avaliacoes.dbml`](./domains/13-avaliacoes.dbml) | `rating` | 3 |
| 14 | [`14-painel-financeiro-restaurante.dbml`](./domains/14-painel-financeiro-restaurante.dbml) | `finance` | 7 |
| 15 | [`15-cupons-campanhas.dbml`](./domains/15-cupons-campanhas.dbml) | `promotion` | 5 |
| — | [`relationships.dbml`](./domains/relationships.dbml) | *(cross-domain)* | 64 refs |

---

## Como usar

### Visualizar o diagrama

Abra **[`er-viewer.html`](./er-viewer.html)** no navegador (clique duplo ou arraste para o browser).

Funcionalidades:
- 🔍 Busca por nome de tabela na sidebar
- 🖱️ Clique em uma tabela para ver colunas + FKs
- 🔗 Modal mostra "Chaves Estrangeiras" e "Referenciado por" com domínios
- 🔍 Foco em tabela mostra apenas ela e relacionadas
- 🔄 Zoom, pan e fit-to-screen
- 🌙 Modo escuro/claro

### Regenerar tudo

```bash
python scripts/sql-to-dbml.py
```

Gera todos os arquivos a partir do DDL em `db/migrations/V1__Initial_Schema.sql`.

### Visualizar um domínio específico

```bash
python scripts/sql-to-dbml.py --domain 03
```

Gera Mermaid + SVG apenas para o domínio 03 (Cardápio).

### Relação com outros diretórios

| Diretório | Relação |
|-----------|---------|
| [`db/migrations/`](../../db/migrations/) | **Fonte** do DDL — os scripts de migração PostgreSQL |
| [`scripts/sql-to-dbml.py`](../../scripts/sql-to-dbml.py) | **Gerador** — produz todos os arquivos daqui |
| [`scripts/verify-er-model.py`](../../scripts/verify-er-model.py) | **Validador** — verifica consistência do modelo gerado |
| [`docs/architecture/`](../architecture/) | **System designs** — documentação arquitetural de cada domínio |

---

> Última atualização: gerado automaticamente por `scripts/sql-to-dbml.py`
