# System Design - [Nome do Dominio]

> **Status:** Esboço | Em progresso | Completo  
> **Fase:** [0-5]  
> **Jornada:** [Cliente | Restaurante | Entregador | Admin | Transversal]  
> **Epico:** [link para secao em epic-ifood-clone.md]  
> **Dependencias:** [links para outros system designs que precisam existir antes]

## 1. Objetivo

[1-3 frases: o que este dominio resolve e por que existe]

## 2. Escopo Funcional

### 2.1 MVP

- [ ] ...

### 2.2 Pos-MVP

- [ ] ...

## 3. Requisitos Nao Funcionais

- Disponibilidade: ...
- Latencia p95: ...
- Escala: ...
- Seguranca / compliance: ...

## 4. Contexto de Negocio

[Impacto no funil, picos, stakeholders]

## 5. Arquitetura de Alto Nivel

```mermaid
flowchart TD
  %% substituir pelo diagrama do dominio
```

## 6. Componentes

### 6.1 [Servico A]

- Responsabilidades
- Persistencia
- Integracoes

## 7. Modelo de Dados

### 7.1 Tabela [nome]

| Coluna | Tipo | Notas |
|--------|------|-------|
| id | UUID | PK |

## 8. Fluxos Principais

### 8.1 [Fluxo principal]

1. ...
2. ...

## 9. Contratos de API

- `POST /v1/...`
- `GET /v1/...`

## 10. Contratos de Eventos

### 10.1 `[dominio.evento]`

```json
{
  "eventType": "dominio.evento",
  "payload": {}
}
```

## 11. Seguranca

- Autenticacao / autorizacao (RBAC)
- Dados sensiveis

## 12. Escalabilidade

- Cache, indices, particionamento

## 13. Observabilidade

- Metricas, logs, alertas

## 14. Resiliencia

- Timeouts, retries, circuit breaker, idempotencia

## 15. Decisoes Arquiteturais

- ADR resumidas

## 16. Riscos e Mitigacoes

| Risco | Mitigacao |
|-------|-----------|
| ... | ... |
