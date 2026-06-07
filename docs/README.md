# Documentacao - FastFoodDelivery (iFood Clone)

Hub central da documentacao arquitetural do ecossistema.

## Como navegar

| Pasta | Conteudo |
|-------|----------|
| [`epic-ifood-clone.md`](./epic-ifood-clone.md) | Visao do produto, RFs por jornada e RNFs |
| [`roadmap/`](./roadmap/) | Ordem recomendada de desenho e dependencias |
| [`templates/`](./templates/) | Modelo padrao para novos system designs |
| [`system-design/`](./system-design/) | Um documento por dominio, numerado por fase |

## Convencao de pastas

Cada dominio fica em `system-design/NN-nome-do-dominio/`:

```
system-design/
  NN-nome-do-dominio/
    system-design.md    # documento principal (obrigatorio)
    architecture.mermaid # diagrama tecnico (quando existir)
    architecture.png     # export visual (opcional)
```

- **NN** = ordem de execucao (00, 01, 02...)
- **Status** no topo de cada `system-design.md`: `Esboço` | `Em progresso` | `Completo`

## Roadmap de system design

| # | Dominio | Jornada | Status |
|---|---------|---------|--------|
| 00 | [Plataforma transversal](./system-design/00-plataforma-transversal/system-design.md) | RNF (EDA, gateway, HA) | Esboço |
| 01 | [Identidade e usuarios](./system-design/01-identidade-usuarios/system-design.md) | Cliente §1.1 | **Em progresso** |
| 02 | [Onboarding admin](./system-design/02-onboarding-admin/system-design.md) | Admin §1.4 | Esboço |
| 03 | [Gestao de cardapio](./system-design/03-gestao-cardapio/system-design.md) | Restaurante §1.2 | Esboço |
| 04 | [Geolocalizacao e cobertura](./system-design/04-geolocalizacao-cobertura/system-design.md) | Cliente §1.1 | Esboço |
| 05 | [Busca e filtros](./system-design/05-busca-filtros/system-design.md) | Cliente §1.1 | Esboço |
| 06 | [Carrinho e pedido](./system-design/06-carrinho-pedido/system-design.md) | Cliente §1.1 | Esboço |
| 07 | [Pagamentos](./system-design/07-pagamentos/system-design.md) | Cliente §1.1 | Esboço |
| 08 | [Estados do pedido](./system-design/08-estados-pedido-restaurante/system-design.md) | Restaurante §1.2 | Esboço |
| 09 | [Matching entregador](./system-design/09-matching-entregador/system-design.md) | Entregador §1.3 | Esboço |
| 10 | [Roteirizacao e localizacao](./system-design/10-roteirizacao-localizacao/system-design.md) | Entregador §1.3 + RNF | Esboço |
| 11 | [Rastreamento tempo real](./system-design/11-rastreamento-tempo-real/system-design.md) | Cliente §1.1 | Esboço |
| 12 | [Confirmacao de entrega](./system-design/12-confirmacao-entrega/system-design.md) | Entregador §1.3 | Esboço |
| 13 | [Avaliacoes](./system-design/13-avaliacoes/system-design.md) | Cliente §1.1 | Esboço |
| 14 | [Painel financeiro](./system-design/14-painel-financeiro-restaurante/system-design.md) | Restaurante §1.2 | Esboço |
| 15 | [Cupons e campanhas](./system-design/15-cupons-campanhas/system-design.md) | Admin §1.4 | Esboço |

Detalhes de dependencias e fases: [`roadmap/ordem-das-jornadas.md`](./roadmap/ordem-das-jornadas.md).

## Como criar um novo system design

1. Copie [`templates/system-design-template.md`](./templates/system-design-template.md) para a pasta do dominio.
2. Preencha metadados (status, fase, dependencias, RF do epico).
3. Escreva secoes na ordem do template — comece por objetivo, fluxos e modelo de dados.
4. Adicione diagrama Mermaid na pasta do dominio.
5. Atualize a tabela de status neste README.

## Proximo passo

Desenhar **[02-onboarding-admin](./system-design/02-onboarding-admin/system-design.md)** — sem onboarding aprovado, restaurantes e entregadores nao entram no ecossistema.
