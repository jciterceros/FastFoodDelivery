-- =============================================================================
-- Rollback V1 — Drop All Schemas
-- FastFoodDelivery
-- Execute após limpar seed data (V2 rollback)
-- =============================================================================

-- Ordem inversa: tabelas sem dependentes primeiro
DROP SCHEMA IF EXISTS promotion CASCADE;
DROP SCHEMA IF EXISTS finance CASCADE;
DROP SCHEMA IF EXISTS rating CASCADE;
DROP SCHEMA IF EXISTS verification CASCADE;
DROP SCHEMA IF EXISTS realtime CASCADE;
DROP SCHEMA IF EXISTS tracking CASCADE;
DROP SCHEMA IF EXISTS dispatch CASCADE;
DROP SCHEMA IF EXISTS payment CASCADE;
DROP SCHEMA IF EXISTS search CASCADE;
DROP SCHEMA IF EXISTS coverage CASCADE;
DROP SCHEMA IF EXISTS menu CASCADE;
DROP SCHEMA IF EXISTS onboarding CASCADE;
DROP SCHEMA IF EXISTS "order" CASCADE;
DROP SCHEMA IF EXISTS "user" CASCADE;
DROP SCHEMA IF EXISTS auth CASCADE;
DROP SCHEMA IF EXISTS infra CASCADE;

-- Remove extensions (opcional)
-- DROP EXTENSION IF EXISTS "btree_gin";
-- DROP EXTENSION IF EXISTS "pg_trgm";
-- DROP EXTENSION IF EXISTS "postgis";
-- DROP EXTENSION IF EXISTS "uuid-ossp";
