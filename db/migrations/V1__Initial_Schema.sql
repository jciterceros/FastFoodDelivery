-- =============================================================================
-- V1__Initial_Schema.sql
-- FastFoodDelivery — Esquema completo: 16 schemas, 64 tabelas, índices, triggers
-- Database: PostgreSQL 15+
-- =============================================================================

-- =============================================================================
-- EXTENSIONS
-- =============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- =============================================================================
-- SCHEMAS
-- =============================================================================
CREATE SCHEMA IF NOT EXISTS infra;
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS "user";
CREATE SCHEMA IF NOT EXISTS onboarding;
CREATE SCHEMA IF NOT EXISTS menu;
CREATE SCHEMA IF NOT EXISTS coverage;
CREATE SCHEMA IF NOT EXISTS search;
CREATE SCHEMA IF NOT EXISTS "order";
CREATE SCHEMA IF NOT EXISTS payment;
CREATE SCHEMA IF NOT EXISTS dispatch;
CREATE SCHEMA IF NOT EXISTS tracking;
CREATE SCHEMA IF NOT EXISTS realtime;
CREATE SCHEMA IF NOT EXISTS verification;
CREATE SCHEMA IF NOT EXISTS rating;
CREATE SCHEMA IF NOT EXISTS finance;
CREATE SCHEMA IF NOT EXISTS promotion;

-- ============================================================================
-- DOMÍNIO 00 — PLATAFORMA TRANSVERSAL (infra)
-- ============================================================================

CREATE TABLE infra.service_registry (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_name      VARCHAR(64) NOT NULL,
    base_url          VARCHAR(256) NOT NULL,
    health_endpoint   VARCHAR(128) NOT NULL DEFAULT '/health',
    health_status     VARCHAR(16) NOT NULL DEFAULT 'healthy',
    last_health_check TIMESTAMP WITH TIME ZONE,
    schema_version    VARCHAR(16),
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_service_registry_service_name UNIQUE (service_name)
);

COMMENT ON TABLE infra.service_registry IS 'Registro de serviços para health check e descoberta';

CREATE TABLE infra.rate_limit_rules (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    route_pattern     VARCHAR(256) NOT NULL,
    limit_per_second  INT NOT NULL,
    limit_per_minute  INT NOT NULL,
    limit_per_hour    INT NOT NULL,
    scope             VARCHAR(32) NOT NULL,
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE infra.rate_limit_rules IS 'Regras de rate limiting por rota';

CREATE TABLE infra.dead_letter_log (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id        UUID NOT NULL,
    event_type      VARCHAR(64) NOT NULL,
    source_service  VARCHAR(64) NOT NULL,
    error_message   TEXT,
    error_code      VARCHAR(32),
    retry_count     INT NOT NULL DEFAULT 0,
    payload         JSONB,
    failed_at       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    reprocessed_at  TIMESTAMP WITH TIME ZONE,
    status          VARCHAR(16) NOT NULL DEFAULT 'pending'
);

COMMENT ON TABLE infra.dead_letter_log IS 'Log de mensagens não processadas do Event Bus';
CREATE INDEX idx_dlq_status ON infra.dead_letter_log(status);

-- ============================================================================
-- DOMÍNIO 01 — IDENTIDADE E USUÁRIOS (auth / user)
-- ============================================================================

CREATE TABLE auth.users (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email             VARCHAR(255) NOT NULL,
    email_verified_at TIMESTAMP WITH TIME ZONE,
    phone             VARCHAR(32),
    phone_verified_at TIMESTAMP WITH TIME ZONE,
    password_hash     VARCHAR(255) NOT NULL,
    status            VARCHAR(32) NOT NULL DEFAULT 'active',
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_users_email UNIQUE (email)
);

COMMENT ON TABLE auth.users IS 'Conta base do usuário — entidade central do ecossistema';
CREATE INDEX idx_users_status ON auth.users(status);

CREATE TABLE "user".user_profiles (
    user_id             UUID PRIMARY KEY,
    full_name           VARCHAR(255),
    birth_date          DATE,
    marketing_opt_in    BOOLEAN NOT NULL DEFAULT FALSE,
    preferred_language  VARCHAR(10) NOT NULL DEFAULT 'pt-BR',
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_user_profiles_user FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

COMMENT ON TABLE "user".user_profiles IS 'Dados do perfil do usuário';

CREATE TABLE "user".user_addresses (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL,
    label       VARCHAR(64),
    zip_code    VARCHAR(16),
    street      VARCHAR(255),
    number      VARCHAR(16),
    complement  VARCHAR(255),
    neighborhood VARCHAR(128),
    city        VARCHAR(128),
    state       VARCHAR(64),
    country     VARCHAR(64) NOT NULL DEFAULT 'Brasil',
    latitude    DECIMAL(10,7),
    longitude   DECIMAL(10,7),
    is_default  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_user_addresses_user FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

COMMENT ON TABLE "user".user_addresses IS 'Endereços do usuário';
CREATE INDEX idx_user_addresses_user_id ON "user".user_addresses(user_id);

CREATE TABLE "user".user_consents (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id       UUID NOT NULL,
    consent_type  VARCHAR(64) NOT NULL,
    version       VARCHAR(16) NOT NULL,
    accepted_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    source        VARCHAR(64),
    CONSTRAINT fk_user_consents_user FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

COMMENT ON TABLE "user".user_consents IS 'Registro de consentimento LGPD';
CREATE INDEX idx_user_consents_user_id ON "user".user_consents(user_id);

CREATE TABLE "user".refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL,
    token_hash  VARCHAR(255) NOT NULL,
    device_id   VARCHAR(128),
    expires_at  TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked_at  TIMESTAMP WITH TIME ZONE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

COMMENT ON TABLE "user".refresh_tokens IS 'Tokens de refresh rotativos';
CREATE INDEX idx_refresh_tokens_user_revoked ON "user".refresh_tokens(user_id, revoked_at);

CREATE TABLE "user".user_devices (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id       UUID NOT NULL,
    device_id     VARCHAR(255) NOT NULL,
    platform      VARCHAR(32),
    push_token    VARCHAR(512),
    last_seen_at  TIMESTAMP WITH TIME ZONE,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_user_devices_user FOREIGN KEY (user_id) REFERENCES auth.users(id),
    CONSTRAINT uq_user_devices_device_id UNIQUE (device_id)
);

COMMENT ON TABLE "user".user_devices IS 'Dispositivos do usuário';

-- ============================================================================
-- DOMÍNIO 02 — ONBOARDING ADMIN (onboarding)
-- ============================================================================

CREATE TABLE onboarding.onboarding_applications (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id           UUID NOT NULL,
    type              VARCHAR(32) NOT NULL,
    status            VARCHAR(32) NOT NULL DEFAULT 'pending',
    submitted_at      TIMESTAMP WITH TIME ZONE,
    reviewed_at       TIMESTAMP WITH TIME ZONE,
    reviewer_id       UUID,
    rejection_reason  VARCHAR(64),
    rejection_note    TEXT,
    resubmitted_from  UUID,
    metadata          JSONB,
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_onboarding_applications_user FOREIGN KEY (user_id) REFERENCES auth.users(id),
    CONSTRAINT fk_onboarding_applications_reviewer FOREIGN KEY (reviewer_id) REFERENCES auth.users(id),
    CONSTRAINT fk_onboarding_applications_resubmitted FOREIGN KEY (resubmitted_from) REFERENCES onboarding.onboarding_applications(id)
);

COMMENT ON TABLE onboarding.onboarding_applications IS 'Solicitação de entrada (restaurante/entregador)';
CREATE INDEX idx_oa_status_submitted ON onboarding.onboarding_applications(status, submitted_at);
CREATE INDEX idx_oa_type_status ON onboarding.onboarding_applications(type, status);

CREATE TABLE onboarding.application_documents (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id    UUID NOT NULL,
    doc_type          VARCHAR(64) NOT NULL,
    storage_key       VARCHAR(512) NOT NULL,
    original_filename VARCHAR(255),
    mime_type         VARCHAR(64),
    file_size_bytes   INT,
    checksum          VARCHAR(64),
    uploaded_at       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_ad_application FOREIGN KEY (application_id) REFERENCES onboarding.onboarding_applications(id),
    CONSTRAINT uq_ad_application_doc_type UNIQUE (application_id, doc_type)
);

COMMENT ON TABLE onboarding.application_documents IS 'Documentos enviados na solicitação';

CREATE TABLE onboarding.restaurant_profiles (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id      UUID NOT NULL,
    owner_user_id       UUID NOT NULL,
    legal_name          VARCHAR(255) NOT NULL,
    trading_name        VARCHAR(255),
    cnpj                VARCHAR(18) NOT NULL,
    cpf_responsavel     VARCHAR(14),
    address_id          UUID,
    phone               VARCHAR(32),
    operating_hours_json JSONB,
    status              VARCHAR(32) NOT NULL DEFAULT 'pending',
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_rp_application FOREIGN KEY (application_id) REFERENCES onboarding.onboarding_applications(id),
    CONSTRAINT fk_rp_owner FOREIGN KEY (owner_user_id) REFERENCES auth.users(id),
    CONSTRAINT fk_rp_address FOREIGN KEY (address_id) REFERENCES "user".user_addresses(id),
    CONSTRAINT uq_rp_application_id UNIQUE (application_id),
    CONSTRAINT uq_rp_cnpj UNIQUE (cnpj)
);

COMMENT ON TABLE onboarding.restaurant_profiles IS 'Perfil do restaurante (criado pós-aprovação)';
CREATE INDEX idx_rp_owner_user_id ON onboarding.restaurant_profiles(owner_user_id);

CREATE TABLE onboarding.courier_profiles (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id    UUID NOT NULL,
    user_id           UUID NOT NULL,
    vehicle_type      VARCHAR(32),
    license_number    VARCHAR(32) NOT NULL,
    license_expiry    DATE,
    license_category  VARCHAR(8),
    vehicle_plate     VARCHAR(16),
    vehicle_year      INT,
    vehicle_color     VARCHAR(32),
    status            VARCHAR(32) NOT NULL DEFAULT 'pending',
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_cp_application FOREIGN KEY (application_id) REFERENCES onboarding.onboarding_applications(id),
    CONSTRAINT fk_cp_user FOREIGN KEY (user_id) REFERENCES auth.users(id),
    CONSTRAINT uq_cp_application_id UNIQUE (application_id),
    CONSTRAINT uq_cp_license_number UNIQUE (license_number)
);

COMMENT ON TABLE onboarding.courier_profiles IS 'Perfil do entregador (criado pós-aprovação)';
CREATE INDEX idx_cp_user_id ON onboarding.courier_profiles(user_id);

CREATE TABLE onboarding.moderation_audit_log (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id  UUID NOT NULL,
    action          VARCHAR(64) NOT NULL,
    from_status     VARCHAR(32),
    to_status       VARCHAR(32),
    reviewer_id     UUID,
    comment         TEXT,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_mal_application FOREIGN KEY (application_id) REFERENCES onboarding.onboarding_applications(id),
    CONSTRAINT fk_mal_reviewer FOREIGN KEY (reviewer_id) REFERENCES auth.users(id)
);

COMMENT ON TABLE onboarding.moderation_audit_log IS 'Trilha de auditoria da moderação';
CREATE INDEX idx_mal_application_created ON onboarding.moderation_audit_log(application_id, created_at);

-- ============================================================================
-- DOMÍNIO 03 — GESTÃO DE CARDÁPIO (menu)
-- ============================================================================

CREATE TABLE menu.menu_categories (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id   UUID NOT NULL,
    name            VARCHAR(255) NOT NULL,
    description     VARCHAR(512),
    sort_order      INT NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_mc_restaurant FOREIGN KEY (restaurant_id) REFERENCES onboarding.restaurant_profiles(id)
);

COMMENT ON TABLE menu.menu_categories IS 'Categorias do cardápio';
CREATE INDEX idx_mc_restaurant_sort ON menu.menu_categories(restaurant_id, sort_order);
CREATE INDEX idx_mc_restaurant_active ON menu.menu_categories(restaurant_id, is_active);

CREATE TABLE menu.menu_items (
    id                        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id               UUID NOT NULL,
    name                      VARCHAR(255) NOT NULL,
    description               TEXT,
    price_cents               INT NOT NULL,
    image_url                 VARCHAR(512),
    is_available              BOOLEAN NOT NULL DEFAULT TRUE,
    preparation_time_seconds  INT,
    sort_order                INT NOT NULL DEFAULT 0,
    created_at                TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at                TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_mi_category FOREIGN KEY (category_id) REFERENCES menu.menu_categories(id)
);

COMMENT ON TABLE menu.menu_items IS 'Itens/produtos do cardápio';
CREATE INDEX idx_mi_category_sort ON menu.menu_items(category_id, sort_order);
CREATE INDEX idx_mi_category_available ON menu.menu_items(category_id, is_available);
CREATE INDEX idx_mi_name_gin ON menu.menu_items USING GIN (to_tsvector('portuguese', name));

CREATE TABLE menu.menu_modifiers (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    item_id         UUID NOT NULL,
    name            VARCHAR(255) NOT NULL,
    min_selections  INT NOT NULL DEFAULT 0,
    max_selections  INT NOT NULL DEFAULT 1,
    is_required     BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order      INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_mm_item FOREIGN KEY (item_id) REFERENCES menu.menu_items(id)
);

COMMENT ON TABLE menu.menu_modifiers IS 'Grupos de modificadores (ex: borda, ponto da carne)';
CREATE INDEX idx_mm_item_id ON menu.menu_modifiers(item_id);

CREATE TABLE menu.menu_modifier_options (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    modifier_id       UUID NOT NULL,
    name              VARCHAR(255) NOT NULL,
    price_delta_cents INT NOT NULL DEFAULT 0,
    is_default        BOOLEAN NOT NULL DEFAULT FALSE,
    is_available      BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order        INT NOT NULL DEFAULT 0,
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_mmo_modifier FOREIGN KEY (modifier_id) REFERENCES menu.menu_modifiers(id)
);

COMMENT ON TABLE menu.menu_modifier_options IS 'Opções de cada modificador';
CREATE INDEX idx_mmo_modifier_id ON menu.menu_modifier_options(modifier_id);

CREATE TABLE menu.restaurant_schedules (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID NOT NULL,
    day_of_week   SMALLINT NOT NULL,
    open_time     TIME NOT NULL,
    close_time    TIME NOT NULL,
    is_closed     BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_rs_restaurant FOREIGN KEY (restaurant_id) REFERENCES onboarding.restaurant_profiles(id),
    CONSTRAINT uq_rs_restaurant_day UNIQUE (restaurant_id, day_of_week)
);

COMMENT ON TABLE menu.restaurant_schedules IS 'Horários de funcionamento';

CREATE TABLE menu.menu_snapshots (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID NOT NULL,
    version       INT NOT NULL,
    snapshot      JSONB NOT NULL,
    published_at  TIMESTAMP WITH TIME ZONE,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_ms_restaurant FOREIGN KEY (restaurant_id) REFERENCES onboarding.restaurant_profiles(id)
);

COMMENT ON TABLE menu.menu_snapshots IS 'Snapshots versionados do cardápio publicado';
CREATE INDEX idx_ms_restaurant_version ON menu.menu_snapshots(restaurant_id, version);

-- ============================================================================
-- DOMÍNIO 04 — GEOLOCALIZAÇÃO E COBERTURA (coverage)
-- ============================================================================

CREATE TABLE coverage.delivery_zones (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id               UUID NOT NULL,
    zone_type                   VARCHAR(32) NOT NULL,
    geometry                    GEOMETRY NOT NULL,
    radius_km                   DECIMAL(8,2),
    base_fee_cents              INT NOT NULL DEFAULT 0,
    additional_fee_per_km_cents INT NOT NULL DEFAULT 0,
    min_order_cents             INT NOT NULL DEFAULT 0,
    is_active                   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_dz_restaurant FOREIGN KEY (restaurant_id) REFERENCES onboarding.restaurant_profiles(id)
);

COMMENT ON TABLE coverage.delivery_zones IS 'Zonas de cobertura (raio ou polígono)';
CREATE INDEX idx_dz_geometry ON coverage.delivery_zones USING GIST (geometry);

CREATE TABLE coverage.platform_regions (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        VARCHAR(255) NOT NULL,
    geometry    GEOMETRY NOT NULL,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE coverage.platform_regions IS 'Regiões da plataforma (ex: Zona Sul SP)';
CREATE INDEX idx_pr_geometry ON coverage.platform_regions USING GIST (geometry);

CREATE TABLE coverage.coverage_cache (
    geohash             VARCHAR(12) PRIMARY KEY,
    restaurant_ids      UUID[] NOT NULL,
    platform_region_id  UUID,
    base_fee_cents      INT NOT NULL DEFAULT 0,
    cached_at           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at          TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT fk_cc_platform_region FOREIGN KEY (platform_region_id) REFERENCES coverage.platform_regions(id)
);

COMMENT ON TABLE coverage.coverage_cache IS 'Cache de cobertura por geohash (fallback)';

CREATE TABLE coverage.address_geocoding_cache (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    address_hash      VARCHAR(64) NOT NULL,
    latitude          DECIMAL(10,7) NOT NULL,
    longitude         DECIMAL(10,7) NOT NULL,
    formatted_address VARCHAR(512),
    place_id          VARCHAR(255),
    provider          VARCHAR(32) NOT NULL DEFAULT 'openstreetmap',
    cached_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at        TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uq_agc_address_hash UNIQUE (address_hash)
);

COMMENT ON TABLE coverage.address_geocoding_cache IS 'Cache de geocoding (endereço → coordenada)';

CREATE TABLE coverage.delivery_fee_tiers (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id     UUID NOT NULL,
    zone_id           UUID NOT NULL,
    min_distance_km   DECIMAL(8,2) NOT NULL DEFAULT 0,
    max_distance_km   DECIMAL(8,2),
    fee_cents         INT NOT NULL,
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_dft_restaurant FOREIGN KEY (restaurant_id) REFERENCES onboarding.restaurant_profiles(id),
    CONSTRAINT fk_dft_zone FOREIGN KEY (zone_id) REFERENCES coverage.delivery_zones(id)
);

COMMENT ON TABLE coverage.delivery_fee_tiers IS 'Faixas de frete por distância';
CREATE INDEX idx_dft_restaurant_distance ON coverage.delivery_fee_tiers(restaurant_id, min_distance_km);

-- ============================================================================
-- DOMÍNIO 05 — BUSCA E FILTROS (search)
-- ============================================================================

CREATE TABLE search.restaurant_search_fallback (
    restaurant_id       UUID PRIMARY KEY,
    name                VARCHAR(255) NOT NULL,
    description         TEXT,
    cuisine_type        VARCHAR(64),
    avg_rating          DECIMAL(3,2),
    review_count        INT NOT NULL DEFAULT 0,
    delivery_fee_cents  INT NOT NULL DEFAULT 0,
    is_open             BOOLEAN NOT NULL DEFAULT FALSE,
    last_menu_version   INT NOT NULL DEFAULT 0,
    location            GEOGRAPHY(POINT),
    full_text           TSVECTOR,
    CONSTRAINT fk_rsf_restaurant FOREIGN KEY (restaurant_id) REFERENCES onboarding.restaurant_profiles(id)
);

COMMENT ON TABLE search.restaurant_search_fallback IS 'Espelho do documento ES em PostgreSQL (fallback)';
CREATE INDEX idx_rsf_name_trgm ON search.restaurant_search_fallback USING GIN (name gin_trgm_ops);
CREATE INDEX idx_rsf_fulltext ON search.restaurant_search_fallback USING GIN (full_text);

-- ============================================================================
-- DOMÍNIO 06 — CARRINHO E PEDIDO (order)
-- ============================================================================

CREATE TABLE "order".orders (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id                 UUID NOT NULL,
    restaurant_id           UUID NOT NULL,
    status                  VARCHAR(32) NOT NULL DEFAULT 'pending',
    subtotal_cents          INT NOT NULL DEFAULT 0,
    delivery_fee_cents      INT NOT NULL DEFAULT 0,
    discount_cents          INT NOT NULL DEFAULT 0,
    total_cents             INT NOT NULL DEFAULT 0,
    promotion_code          VARCHAR(64),
    delivery_latitude       DECIMAL(10,7),
    delivery_longitude      DECIMAL(10,7),
    delivery_address_snapshot JSONB,
    estimated_minutes       INT,
    idempotency_key         VARCHAR(255) NOT NULL,
    created_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES auth.users(id),
    CONSTRAINT fk_orders_restaurant FOREIGN KEY (restaurant_id) REFERENCES onboarding.restaurant_profiles(id),
    CONSTRAINT uq_orders_idempotency_key UNIQUE (idempotency_key)
);

COMMENT ON TABLE "order".orders IS 'Pedido confirmado — agregado central do fluxo transacional';
CREATE INDEX idx_orders_user_created ON "order".orders(user_id, created_at);
CREATE INDEX idx_orders_restaurant_status ON "order".orders(restaurant_id, status);

CREATE TABLE "order".order_items (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id            UUID NOT NULL,
    item_id             UUID NOT NULL,
    name                VARCHAR(255) NOT NULL,
    quantity            INT NOT NULL,
    unit_price_cents    INT NOT NULL,
    modifiers_snapshot  JSONB,
    total_price_cents   INT NOT NULL,
    notes               VARCHAR(512),
    CONSTRAINT fk_oi_order FOREIGN KEY (order_id) REFERENCES "order".orders(id),
    CONSTRAINT fk_oi_item FOREIGN KEY (item_id) REFERENCES menu.menu_items(id)
);

COMMENT ON TABLE "order".order_items IS 'Itens do pedido (snapshot de preços)';
CREATE INDEX idx_oi_order_id ON "order".order_items(order_id);

CREATE TABLE "order".inventory_reservations (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    item_id     UUID NOT NULL,
    order_id    UUID NOT NULL,
    quantity    INT NOT NULL,
    status      VARCHAR(32) NOT NULL DEFAULT 'reserved',
    expires_at  TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_ir_item FOREIGN KEY (item_id) REFERENCES menu.menu_items(id),
    CONSTRAINT fk_ir_order FOREIGN KEY (order_id) REFERENCES "order".orders(id)
);

COMMENT ON TABLE "order".inventory_reservations IS 'Reserva de estoque no checkout';
CREATE INDEX idx_ir_item_status ON "order".inventory_reservations(item_id, status);
CREATE INDEX idx_ir_status_expires ON "order".inventory_reservations(status, expires_at);

-- ============================================================================
-- DOMÍNIO 07 — PAGAMENTOS (payment)
-- ============================================================================

CREATE TABLE payment.payments (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id            UUID NOT NULL,
    method              VARCHAR(32) NOT NULL,
    amount_cents        INT NOT NULL,
    status              VARCHAR(32) NOT NULL DEFAULT 'pending',
    gateway             VARCHAR(32) NOT NULL,
    gateway_payment_id  VARCHAR(255),
    gateway_response    JSONB,
    pix_qr_code         TEXT,
    pix_qr_text         VARCHAR(512),
    pix_expires_at      TIMESTAMP WITH TIME ZONE,
    refunded_cents      INT NOT NULL DEFAULT 0,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES "order".orders(id)
);

COMMENT ON TABLE payment.payments IS 'Transação de pagamento';
CREATE INDEX idx_payments_order_id ON payment.payments(order_id);
CREATE INDEX idx_payments_gateway_id ON payment.payments(gateway_payment_id);
CREATE INDEX idx_payments_status_created ON payment.payments(status, created_at);

CREATE TABLE payment.payment_tokens (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL,
    gateway         VARCHAR(32) NOT NULL,
    gateway_token   VARCHAR(255) NOT NULL,
    brand           VARCHAR(32),
    last4           VARCHAR(4),
    cardholder_name VARCHAR(255),
    exp_month       SMALLINT,
    exp_year        SMALLINT,
    is_default      BOOLEAN NOT NULL DEFAULT FALSE,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_pt_user FOREIGN KEY (user_id) REFERENCES auth.users(id),
    CONSTRAINT uq_pt_gateway_token UNIQUE (gateway_token)
);

COMMENT ON TABLE payment.payment_tokens IS 'Cartões tokenizados';
CREATE INDEX idx_pt_user_active ON payment.payment_tokens(user_id, is_active);

CREATE TABLE payment.payment_webhooks (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    idempotency_key   VARCHAR(255) NOT NULL,
    gateway           VARCHAR(32) NOT NULL,
    event_type        VARCHAR(64) NOT NULL,
    payload_hash      VARCHAR(64) NOT NULL,
    raw_payload       JSONB NOT NULL,
    processed_at      TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_pw_idempotency_key UNIQUE (idempotency_key)
);

COMMENT ON TABLE payment.payment_webhooks IS 'Webhooks recebidos (idempotência)';

CREATE TABLE payment.refunds (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_id        UUID NOT NULL,
    amount_cents      INT NOT NULL,
    reason            VARCHAR(255),
    gateway_refund_id VARCHAR(255),
    created_by        UUID NOT NULL,
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_refunds_payment FOREIGN KEY (payment_id) REFERENCES payment.payments(id),
    CONSTRAINT fk_refunds_created_by FOREIGN KEY (created_by) REFERENCES auth.users(id)
);

COMMENT ON TABLE payment.refunds IS 'Reembolsos processados';
CREATE INDEX idx_refunds_payment_id ON payment.refunds(payment_id);

-- ============================================================================
-- DOMÍNIO 08 — ESTADOS DO PEDIDO (order)
-- ============================================================================

CREATE TABLE "order".order_sla_config (
    id                            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id                 UUID NOT NULL,
    preparation_timeout_minutes   INT NOT NULL DEFAULT 30,
    pickup_timeout_minutes        INT NOT NULL DEFAULT 15,
    auto_cancel_after_minutes     INT NOT NULL DEFAULT 60,
    created_at                    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at                    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_osc_restaurant FOREIGN KEY (restaurant_id) REFERENCES onboarding.restaurant_profiles(id),
    CONSTRAINT uq_osc_restaurant_id UNIQUE (restaurant_id)
);

COMMENT ON TABLE "order".order_sla_config IS 'Configuração de SLA por restaurante';

CREATE TABLE "order".order_status_history (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id        UUID NOT NULL,
    from_status     VARCHAR(32),
    to_status       VARCHAR(32) NOT NULL,
    changed_by      UUID,
    changed_by_role VARCHAR(32),
    reason          VARCHAR(255),
    elapsed_seconds INT,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_osh_order FOREIGN KEY (order_id) REFERENCES "order".orders(id),
    CONSTRAINT fk_osh_changed_by FOREIGN KEY (changed_by) REFERENCES auth.users(id)
);

COMMENT ON TABLE "order".order_status_history IS 'Histórico de transições de estado';
CREATE INDEX idx_osh_order_created ON "order".order_status_history(order_id, created_at);
CREATE INDEX idx_osh_status_created ON "order".order_status_history(to_status, created_at);

-- ============================================================================
-- DOMÍNIO 09 — MATCHING ENTREGADOR (dispatch)
-- ============================================================================

CREATE TABLE dispatch.delivery_offers (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id          UUID NOT NULL,
    courier_id        UUID NOT NULL,
    attempt           SMALLINT NOT NULL DEFAULT 1,
    status            VARCHAR(32) NOT NULL DEFAULT 'pending',
    expires_at        TIMESTAMP WITH TIME ZONE NOT NULL,
    responded_at      TIMESTAMP WITH TIME ZONE,
    rejection_reason  VARCHAR(64),
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_do_order FOREIGN KEY (order_id) REFERENCES "order".orders(id),
    CONSTRAINT fk_do_courier FOREIGN KEY (courier_id) REFERENCES auth.users(id)
);

COMMENT ON TABLE dispatch.delivery_offers IS 'Ofertas de corrida';
CREATE INDEX idx_do_order_attempt ON dispatch.delivery_offers(order_id, attempt);
CREATE INDEX idx_do_status_expires ON dispatch.delivery_offers(status, expires_at);

CREATE TABLE dispatch.delivery_assignments (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id            UUID NOT NULL,
    courier_id          UUID NOT NULL,
    offer_id            UUID,
    status              VARCHAR(32) NOT NULL DEFAULT 'assigned',
    assigned_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    picked_up_at        TIMESTAMP WITH TIME ZONE,
    completed_at        TIMESTAMP WITH TIME ZONE,
    cancelled_at        TIMESTAMP WITH TIME ZONE,
    cancellation_reason VARCHAR(255),
    CONSTRAINT fk_da_order FOREIGN KEY (order_id) REFERENCES "order".orders(id),
    CONSTRAINT fk_da_courier FOREIGN KEY (courier_id) REFERENCES auth.users(id),
    CONSTRAINT fk_da_offer FOREIGN KEY (offer_id) REFERENCES dispatch.delivery_offers(id),
    CONSTRAINT uq_da_order_id UNIQUE (order_id)
);

COMMENT ON TABLE dispatch.delivery_assignments IS 'Atribuição de entregador a pedido';
CREATE INDEX idx_da_courier_status ON dispatch.delivery_assignments(courier_id, status);
CREATE INDEX idx_da_status_assigned ON dispatch.delivery_assignments(status, assigned_at);

CREATE TABLE dispatch.courier_sessions (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    courier_id          UUID NOT NULL,
    is_online           BOOLEAN NOT NULL DEFAULT FALSE,
    current_geohash     VARCHAR(12),
    last_lat            DECIMAL(10,7),
    last_lon            DECIMAL(10,7),
    status              VARCHAR(32) NOT NULL DEFAULT 'offline',
    current_delivery_id UUID,
    battery_level       SMALLINT,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_cs_courier FOREIGN KEY (courier_id) REFERENCES auth.users(id),
    CONSTRAINT fk_cs_current_delivery FOREIGN KEY (current_delivery_id) REFERENCES dispatch.delivery_assignments(id),
    CONSTRAINT uq_cs_courier_id UNIQUE (courier_id)
);

COMMENT ON TABLE dispatch.courier_sessions IS 'Sessão de disponibilidade do entregador';
CREATE INDEX idx_cs_online_geohash ON dispatch.courier_sessions(is_online, current_geohash);
CREATE INDEX idx_cs_status_updated ON dispatch.courier_sessions(status, updated_at);

CREATE TABLE dispatch.escalation_queue (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id          UUID NOT NULL,
    attempts          SMALLINT NOT NULL DEFAULT 0,
    last_attempt_at   TIMESTAMP WITH TIME ZONE,
    escalated_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    status            VARCHAR(32) NOT NULL DEFAULT 'pending',
    resolved_by       UUID,
    resolved_at       TIMESTAMP WITH TIME ZONE,
    notes             TEXT,
    CONSTRAINT fk_eq_order FOREIGN KEY (order_id) REFERENCES "order".orders(id),
    CONSTRAINT fk_eq_resolved_by FOREIGN KEY (resolved_by) REFERENCES auth.users(id),
    CONSTRAINT uq_eq_order_id UNIQUE (order_id)
);

COMMENT ON TABLE dispatch.escalation_queue IS 'Pedidos não matchados (escalonamento)';
CREATE INDEX idx_eq_status_escalated ON dispatch.escalation_queue(status, escalated_at);

CREATE TABLE dispatch.courier_availability_history (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    courier_id      UUID NOT NULL,
    previous_status VARCHAR(32),
    new_status      VARCHAR(32) NOT NULL,
    reason          VARCHAR(255),
    geohash         VARCHAR(12),
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_cah_courier FOREIGN KEY (courier_id) REFERENCES auth.users(id)
);

COMMENT ON TABLE dispatch.courier_availability_history IS 'Histórico de online/offline do entregador';
CREATE INDEX idx_cah_courier_created ON dispatch.courier_availability_history(courier_id, created_at);

-- ============================================================================
-- DOMÍNIO 10 — ROTEIRIZAÇÃO E LOCALIZAÇÃO (tracking)
-- ============================================================================

CREATE TABLE tracking.delivery_tracking (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    delivery_id       UUID NOT NULL,
    courier_id        UUID NOT NULL,
    order_id          UUID NOT NULL,
    current_milestone VARCHAR(32) NOT NULL DEFAULT 'assigned',
    last_lat          DECIMAL(10,7),
    last_lon          DECIMAL(10,7),
    last_geohash      VARCHAR(12),
    started_at        TIMESTAMP WITH TIME ZONE,
    picked_up_at      TIMESTAMP WITH TIME ZONE,
    arrived_at        TIMESTAMP WITH TIME ZONE,
    completed_at      TIMESTAMP WITH TIME ZONE,
    estimated_eta     TIMESTAMP WITH TIME ZONE,
    updated_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_dt_delivery FOREIGN KEY (delivery_id) REFERENCES dispatch.delivery_assignments(id),
    CONSTRAINT fk_dt_courier FOREIGN KEY (courier_id) REFERENCES auth.users(id),
    CONSTRAINT fk_dt_order FOREIGN KEY (order_id) REFERENCES "order".orders(id),
    CONSTRAINT uq_dt_delivery_id UNIQUE (delivery_id)
);

COMMENT ON TABLE tracking.delivery_tracking IS 'Estado atual do tracking da corrida';
CREATE INDEX idx_dt_courier_milestone ON tracking.delivery_tracking(courier_id, current_milestone);
CREATE INDEX idx_dt_order_id ON tracking.delivery_tracking(order_id);

CREATE TABLE tracking.location_pings (
    id              UUID DEFAULT uuid_generate_v4(),
    delivery_id     UUID NOT NULL,
    courier_id      UUID NOT NULL,
    lat             DECIMAL(10,7) NOT NULL,
    lon             DECIMAL(10,7) NOT NULL,
    accuracy        SMALLINT,
    geohash         VARCHAR(12),
    battery_level   SMALLINT,
    recorded_at     TIMESTAMP WITH TIME ZONE NOT NULL,
    ingested_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    source          VARCHAR(32) NOT NULL DEFAULT 'app',
    CONSTRAINT pk_location_pings PRIMARY KEY (id, recorded_at),
    CONSTRAINT fk_lp_delivery FOREIGN KEY (delivery_id) REFERENCES dispatch.delivery_assignments(id),
    CONSTRAINT fk_lp_courier FOREIGN KEY (courier_id) REFERENCES auth.users(id)
) PARTITION BY RANGE (recorded_at);

COMMENT ON TABLE tracking.location_pings IS 'Pings de localização (particionada por mês, retenção 90 dias)';
CREATE INDEX idx_lp_delivery_recorded ON tracking.location_pings(delivery_id, recorded_at);
CREATE INDEX idx_lp_geohash_recorded ON tracking.location_pings(geohash, recorded_at);

CREATE TABLE tracking.location_pings_2026_01 PARTITION OF tracking.location_pings
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE tracking.location_pings_2026_02 PARTITION OF tracking.location_pings
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE tracking.location_pings_2026_03 PARTITION OF tracking.location_pings
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE tracking.location_pings_2026_04 PARTITION OF tracking.location_pings
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE tracking.location_pings_2026_05 PARTITION OF tracking.location_pings
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE tracking.location_pings_2026_06 PARTITION OF tracking.location_pings
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE tracking.location_pings_2026_07 PARTITION OF tracking.location_pings
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE tracking.location_pings_2026_08 PARTITION OF tracking.location_pings
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE tracking.location_pings_2026_09 PARTITION OF tracking.location_pings
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');
CREATE TABLE tracking.location_pings_2026_10 PARTITION OF tracking.location_pings
    FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
CREATE TABLE tracking.location_pings_2026_11 PARTITION OF tracking.location_pings
    FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');
CREATE TABLE tracking.location_pings_2026_12 PARTITION OF tracking.location_pings
    FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');

CREATE TABLE tracking.delivery_milestones (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    delivery_id   UUID NOT NULL,
    courier_id    UUID NOT NULL,
    milestone     VARCHAR(32) NOT NULL,
    lat           DECIMAL(10,7),
    lon           DECIMAL(10,7),
    geohash       VARCHAR(12),
    source        VARCHAR(32) NOT NULL DEFAULT 'app',
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_dm_delivery FOREIGN KEY (delivery_id) REFERENCES dispatch.delivery_assignments(id),
    CONSTRAINT fk_dm_courier FOREIGN KEY (courier_id) REFERENCES auth.users(id)
);

COMMENT ON TABLE tracking.delivery_milestones IS 'Marcos da corrida';
CREATE INDEX idx_dm_delivery_created ON tracking.delivery_milestones(delivery_id, created_at);

CREATE TABLE tracking.delivery_routes (
    id                        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    delivery_id               UUID NOT NULL,
    pickup_address            VARCHAR(512),
    pickup_lat                DECIMAL(10,7),
    pickup_lon                DECIMAL(10,7),
    dropoff_address           VARCHAR(512),
    dropoff_lat               DECIMAL(10,7),
    dropoff_lon               DECIMAL(10,7),
    polyline_encoded          TEXT,
    distance_km               DECIMAL(8,2),
    estimated_duration_minutes INT,
    cached_at                 TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at                TIMESTAMP WITH TIME ZONE,
    CONSTRAINT fk_dr_delivery FOREIGN KEY (delivery_id) REFERENCES dispatch.delivery_assignments(id),
    CONSTRAINT uq_dr_delivery_id UNIQUE (delivery_id)
);

COMMENT ON TABLE tracking.delivery_routes IS 'Rota cacheada (pickup → dropoff)';

CREATE TABLE tracking.courier_daily_tracks (
    id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    courier_id            UUID NOT NULL,
    date                  DATE NOT NULL,
    total_deliveries      INT NOT NULL DEFAULT 0,
    total_distance_km     DECIMAL(8,2) NOT NULL DEFAULT 0,
    total_active_minutes  INT NOT NULL DEFAULT 0,
    geohashes_visited     TEXT[],
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_cdt_courier FOREIGN KEY (courier_id) REFERENCES auth.users(id),
    CONSTRAINT uq_cdt_courier_date UNIQUE (courier_id, date)
);

COMMENT ON TABLE tracking.courier_daily_tracks IS 'Agregação diária por entregador (retenção 1 ano)';

-- ============================================================================
-- DOMÍNIO 11 — RASTREAMENTO TEMPO REAL (realtime)
-- ============================================================================

CREATE TABLE realtime.tracking_sessions (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id          UUID NOT NULL,
    user_id           UUID NOT NULL,
    device_id         VARCHAR(255),
    session_token     VARCHAR(255) NOT NULL,
    status            VARCHAR(32) NOT NULL DEFAULT 'connected',
    connected_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    disconnected_at   TIMESTAMP WITH TIME ZONE,
    last_activity_at  TIMESTAMP WITH TIME ZONE,
    messages_sent     INT NOT NULL DEFAULT 0,
    ip_address        VARCHAR(45),
    user_agent        VARCHAR(512),
    CONSTRAINT fk_ts_order FOREIGN KEY (order_id) REFERENCES "order".orders(id),
    CONSTRAINT fk_ts_user FOREIGN KEY (user_id) REFERENCES auth.users(id),
    CONSTRAINT uq_ts_session_token UNIQUE (session_token)
);

COMMENT ON TABLE realtime.tracking_sessions IS 'Sessões WebSocket do cliente';
CREATE INDEX idx_ts_order_status ON realtime.tracking_sessions(order_id, status);

CREATE TABLE realtime.tracking_snapshots (
    id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id              UUID NOT NULL,
    courier_lat           DECIMAL(10,7),
    courier_lon           DECIMAL(10,7),
    courier_geohash       VARCHAR(12),
    milestone             VARCHAR(32),
    milestone_changed_at  TIMESTAMP WITH TIME ZONE,
    estimated_eta         TIMESTAMP WITH TIME ZONE,
    pickup_lat            DECIMAL(10,7),
    pickup_lon            DECIMAL(10,7),
    dropoff_lat           DECIMAL(10,7),
    dropoff_lon           DECIMAL(10,7),
    polyline_encoded      TEXT,
    version               INT NOT NULL DEFAULT 1,
    updated_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_tsnap_order FOREIGN KEY (order_id) REFERENCES "order".orders(id),
    CONSTRAINT uq_tsnap_order_id UNIQUE (order_id)
);

COMMENT ON TABLE realtime.tracking_snapshots IS 'Último snapshot de tracking para reconexão';

-- ============================================================================
-- DOMÍNIO 12 — CONFIRMAÇÃO DE ENTREGA (verification)
-- ============================================================================

CREATE TABLE verification.delivery_verification_codes (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    delivery_id             UUID NOT NULL,
    order_id                UUID NOT NULL,
    code_hash               VARCHAR(255) NOT NULL,
    code_prefix             VARCHAR(8),
    status                  VARCHAR(32) NOT NULL DEFAULT 'active',
    generated_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at              TIMESTAMP WITH TIME ZONE NOT NULL,
    confirmed_at            TIMESTAMP WITH TIME ZONE,
    confirmed_by_courier_id UUID,
    confirmed_by_admin_id   UUID,
    revoked_at              TIMESTAMP WITH TIME ZONE,
    revocation_reason       VARCHAR(255),
    CONSTRAINT fk_dvc_delivery FOREIGN KEY (delivery_id) REFERENCES dispatch.delivery_assignments(id),
    CONSTRAINT fk_dvc_order FOREIGN KEY (order_id) REFERENCES "order".orders(id),
    CONSTRAINT fk_dvc_confirmed_courier FOREIGN KEY (confirmed_by_courier_id) REFERENCES auth.users(id),
    CONSTRAINT fk_dvc_confirmed_admin FOREIGN KEY (confirmed_by_admin_id) REFERENCES auth.users(id),
    CONSTRAINT uq_dvc_delivery_id UNIQUE (delivery_id)
);

COMMENT ON TABLE verification.delivery_verification_codes IS 'Código de confirmação (hash SHA-256)';
CREATE INDEX idx_dvc_status_expires ON verification.delivery_verification_codes(status, expires_at);

CREATE TABLE verification.delivery_verification_attempts (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    delivery_id             UUID NOT NULL,
    courier_id              UUID NOT NULL,
    code_submitted          VARCHAR(255) NOT NULL,
    code_submitted_prefix   VARCHAR(8),
    result                  VARCHAR(32) NOT NULL,
    courier_lat             DECIMAL(10,7),
    courier_lon             DECIMAL(10,7),
    geohash                 VARCHAR(12),
    ip_address              VARCHAR(45),
    created_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_dva_delivery FOREIGN KEY (delivery_id) REFERENCES dispatch.delivery_assignments(id),
    CONSTRAINT fk_dva_courier FOREIGN KEY (courier_id) REFERENCES auth.users(id)
);

COMMENT ON TABLE verification.delivery_verification_attempts IS 'Tentativas de confirmação';
CREATE INDEX idx_dva_delivery_created ON verification.delivery_verification_attempts(delivery_id, created_at);

CREATE TABLE verification.delivery_disputes (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    delivery_id   UUID NOT NULL,
    order_id      UUID NOT NULL,
    opened_by     VARCHAR(32) NOT NULL,
    reason        VARCHAR(255) NOT NULL,
    status        VARCHAR(32) NOT NULL DEFAULT 'open',
    resolution    VARCHAR(255),
    resolved_by   UUID,
    resolved_at   TIMESTAMP WITH TIME ZONE,
    evidence      JSONB,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_dd_delivery FOREIGN KEY (delivery_id) REFERENCES dispatch.delivery_assignments(id),
    CONSTRAINT fk_dd_order FOREIGN KEY (order_id) REFERENCES "order".orders(id),
    CONSTRAINT fk_dd_resolved_by FOREIGN KEY (resolved_by) REFERENCES auth.users(id),
    CONSTRAINT uq_dd_delivery_id UNIQUE (delivery_id)
);

COMMENT ON TABLE verification.delivery_disputes IS 'Disputas de entrega';
CREATE INDEX idx_dd_status_created ON verification.delivery_disputes(status, created_at);

-- ============================================================================
-- DOMÍNIO 13 — AVALIAÇÕES (rating)
-- ============================================================================

CREATE TABLE rating.order_ratings (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id          UUID NOT NULL,
    user_id           UUID NOT NULL,
    target_type       VARCHAR(32) NOT NULL,
    target_id         UUID NOT NULL,
    score             SMALLINT NOT NULL,
    comment           VARCHAR(1000),
    comment_status    VARCHAR(32) NOT NULL DEFAULT 'pending',
    moderation_result JSONB,
    is_edited         BOOLEAN NOT NULL DEFAULT FALSE,
    edited_at         TIMESTAMP WITH TIME ZONE,
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_or_order FOREIGN KEY (order_id) REFERENCES "order".orders(id),
    CONSTRAINT fk_or_user FOREIGN KEY (user_id) REFERENCES auth.users(id),
    CONSTRAINT uq_or_order_target UNIQUE (order_id, target_type)
);

COMMENT ON TABLE rating.order_ratings IS 'Avaliação individual (restaurante ou entregador)';
CREATE INDEX idx_or_target_created ON rating.order_ratings(target_type, target_id, created_at);

CREATE TABLE rating.rating_aggregates (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    target_type     VARCHAR(32) NOT NULL,
    target_id       UUID NOT NULL,
    avg_score       DECIMAL(3,2) NOT NULL DEFAULT 0,
    total_ratings   INT NOT NULL DEFAULT 0,
    distribution    JSONB,
    last_rating_at  TIMESTAMP WITH TIME ZONE,
    updated_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_ra_target UNIQUE (target_type, target_id)
);

COMMENT ON TABLE rating.rating_aggregates IS 'Média agregada por alvo (restaurante/entregador)';

CREATE TABLE rating.moderation_blocklist (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    word        VARCHAR(255) NOT NULL,
    category    VARCHAR(64),
    is_regex    BOOLEAN NOT NULL DEFAULT FALSE,
    severity    VARCHAR(32) NOT NULL DEFAULT 'low',
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_mb_word UNIQUE (word)
);

COMMENT ON TABLE rating.moderation_blocklist IS 'Palavras bloqueadas na moderação';

-- ============================================================================
-- DOMÍNIO 14 — PAINEL FINANCEIRO (finance)
-- ============================================================================

CREATE TABLE finance.bank_accounts (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id   UUID NOT NULL,
    bank_code       VARCHAR(8) NOT NULL,
    agency          VARCHAR(16) NOT NULL,
    account         VARCHAR(32) NOT NULL,
    account_digit   VARCHAR(4) NOT NULL,
    account_type    VARCHAR(16) DEFAULT 'corrente',
    pix_key         VARCHAR(255),
    holder_name     VARCHAR(255) NOT NULL,
    holder_document VARCHAR(18) NOT NULL,
    holder_type     VARCHAR(8) NOT NULL DEFAULT 'fisica',
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_ba_restaurant FOREIGN KEY (restaurant_id) REFERENCES onboarding.restaurant_profiles(id),
    CONSTRAINT uq_ba_restaurant_id UNIQUE (restaurant_id)
);

COMMENT ON TABLE finance.bank_accounts IS 'Contas bancárias dos restaurantes (dados sensíveis criptografados)';

CREATE TABLE finance.payout_config (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id           UUID NOT NULL,
    cycle_days              SMALLINT NOT NULL DEFAULT 7,
    next_payout_date        DATE NOT NULL,
    min_payout_cents        INT NOT NULL DEFAULT 0,
    auto_payout             BOOLEAN NOT NULL DEFAULT TRUE,
    default_bank_account_id UUID,
    created_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_pc_restaurant FOREIGN KEY (restaurant_id) REFERENCES onboarding.restaurant_profiles(id),
    CONSTRAINT fk_pc_default_account FOREIGN KEY (default_bank_account_id) REFERENCES finance.bank_accounts(id),
    CONSTRAINT uq_pc_restaurant_id UNIQUE (restaurant_id)
);

COMMENT ON TABLE finance.payout_config IS 'Configuração de ciclo de repasse';

CREATE TABLE finance.payouts (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id     UUID NOT NULL,
    period_start      DATE NOT NULL,
    period_end        DATE NOT NULL,
    gross_cents       INT NOT NULL DEFAULT 0,
    fees_cents        INT NOT NULL DEFAULT 0,
    net_cents         INT NOT NULL DEFAULT 0,
    status            VARCHAR(32) NOT NULL DEFAULT 'pending',
    payment_method    VARCHAR(32),
    bank_account_id   UUID,
    transfer_id       VARCHAR(255),
    transferred_at    TIMESTAMP WITH TIME ZONE,
    failure_reason    VARCHAR(512),
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_pay_restaurant FOREIGN KEY (restaurant_id) REFERENCES onboarding.restaurant_profiles(id),
    CONSTRAINT fk_pay_bank_account FOREIGN KEY (bank_account_id) REFERENCES finance.bank_accounts(id)
);

COMMENT ON TABLE finance.payouts IS 'Repasses financeiros';
CREATE INDEX idx_pay_restaurant_status ON finance.payouts(restaurant_id, status);
CREATE INDEX idx_pay_status_created ON finance.payouts(status, created_at);

CREATE TABLE finance.daily_restaurant_rollups (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id       UUID NOT NULL,
    date                DATE NOT NULL,
    gross_cents         INT NOT NULL DEFAULT 0,
    platform_fees_cents INT NOT NULL DEFAULT 0,
    delivery_fees_cents INT NOT NULL DEFAULT 0,
    net_cents           INT NOT NULL DEFAULT 0,
    refunds_cents       INT NOT NULL DEFAULT 0,
    adjustments_cents   INT NOT NULL DEFAULT 0,
    order_count         INT NOT NULL DEFAULT 0,
    payout_status       VARCHAR(32),
    payout_id           UUID,
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_drr_restaurant FOREIGN KEY (restaurant_id) REFERENCES onboarding.restaurant_profiles(id),
    CONSTRAINT fk_drr_payout FOREIGN KEY (payout_id) REFERENCES finance.payouts(id),
    CONSTRAINT uq_drr_restaurant_date UNIQUE (restaurant_id, date)
);

COMMENT ON TABLE finance.daily_restaurant_rollups IS 'Rollups diários pré-agregados';

CREATE TABLE finance.ledger_entries (
    id              UUID DEFAULT uuid_generate_v4(),
    restaurant_id   UUID NOT NULL,
    order_id        UUID,
    entry_type      VARCHAR(64) NOT NULL,
    amount_cents    INT NOT NULL,
    description     VARCHAR(512),
    reference_id    UUID,
    reference_type  VARCHAR(64),
    status          VARCHAR(32) NOT NULL DEFAULT 'pending',
    settled_at      TIMESTAMP WITH TIME ZONE,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_ledger_entries PRIMARY KEY (id, created_at),
    CONSTRAINT fk_le_restaurant FOREIGN KEY (restaurant_id) REFERENCES onboarding.restaurant_profiles(id),
    CONSTRAINT fk_le_order FOREIGN KEY (order_id) REFERENCES "order".orders(id)
) PARTITION BY RANGE (created_at);

COMMENT ON TABLE finance.ledger_entries IS 'Lançamentos contábeis append-only (particionada por mês)';
CREATE INDEX idx_le_restaurant_created ON finance.ledger_entries(restaurant_id, created_at);
CREATE INDEX idx_le_order_entry ON finance.ledger_entries(order_id, entry_type);

CREATE TABLE finance.ledger_entries_2026_01 PARTITION OF finance.ledger_entries
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE finance.ledger_entries_2026_02 PARTITION OF finance.ledger_entries
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE finance.ledger_entries_2026_03 PARTITION OF finance.ledger_entries
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE finance.ledger_entries_2026_04 PARTITION OF finance.ledger_entries
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE finance.ledger_entries_2026_05 PARTITION OF finance.ledger_entries
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE finance.ledger_entries_2026_06 PARTITION OF finance.ledger_entries
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE finance.ledger_entries_2026_07 PARTITION OF finance.ledger_entries
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE finance.ledger_entries_2026_08 PARTITION OF finance.ledger_entries
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE finance.ledger_entries_2026_09 PARTITION OF finance.ledger_entries
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');
CREATE TABLE finance.ledger_entries_2026_10 PARTITION OF finance.ledger_entries
    FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
CREATE TABLE finance.ledger_entries_2026_11 PARTITION OF finance.ledger_entries
    FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');
CREATE TABLE finance.ledger_entries_2026_12 PARTITION OF finance.ledger_entries
    FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');

CREATE TABLE finance.reconciliation_log (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date                    DATE NOT NULL,
    total_ledger_cents      INT NOT NULL DEFAULT 0,
    total_gateway_cents     INT NOT NULL DEFAULT 0,
    difference_cents        INT NOT NULL DEFAULT 0,
    status                  VARCHAR(32) NOT NULL DEFAULT 'pending',
    details                 JSONB,
    created_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_rl_date UNIQUE (date)
);

COMMENT ON TABLE finance.reconciliation_log IS 'Log de reconciliação com gateway';

-- ============================================================================
-- DOMÍNIO 15 — CUPONS E CAMPANHAS (promotion)
-- ============================================================================

CREATE TABLE promotion.campaigns (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name                VARCHAR(255) NOT NULL,
    description         TEXT,
    type                VARCHAR(32) NOT NULL,
    budget_cents        INT NOT NULL DEFAULT 0,
    budget_spent_cents  INT NOT NULL DEFAULT 0,
    starts_at           TIMESTAMP WITH TIME ZONE NOT NULL,
    ends_at             TIMESTAMP WITH TIME ZONE NOT NULL,
    status              VARCHAR(32) NOT NULL DEFAULT 'draft',
    target_metric       VARCHAR(64),
    roi_goal_percent    DECIMAL(5,2),
    created_by          UUID,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_camp_created_by FOREIGN KEY (created_by) REFERENCES auth.users(id)
);

COMMENT ON TABLE promotion.campaigns IS 'Campanhas de marketing';
CREATE INDEX idx_camp_status_starts ON promotion.campaigns(status, starts_at);

CREATE TABLE promotion.coupons (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code                        VARCHAR(64) NOT NULL,
    campaign_id                 UUID NOT NULL,
    type                        VARCHAR(32) NOT NULL,
    value_cents                 INT,
    value_percent               DECIMAL(5,2),
    max_discount_cents          INT,
    min_order_cents             INT NOT NULL DEFAULT 0,
    max_redemptions             INT,
    max_per_user                INT NOT NULL DEFAULT 1,
    starts_at                   TIMESTAMP WITH TIME ZONE NOT NULL,
    ends_at                     TIMESTAMP WITH TIME ZONE NOT NULL,
    restaurant_scope            VARCHAR(32),
    restaurant_ids              UUID[],
    region_scope                VARCHAR(32),
    region_geohashes            VARCHAR[],
    first_purchase_only         BOOLEAN NOT NULL DEFAULT FALSE,
    subsidy_type                VARCHAR(32),
    subsidy_platform_percent    DECIMAL(5,2),
    is_active                   BOOLEAN NOT NULL DEFAULT TRUE,
    created_by                  UUID,
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_cou_campaign FOREIGN KEY (campaign_id) REFERENCES promotion.campaigns(id),
    CONSTRAINT fk_cou_created_by FOREIGN KEY (created_by) REFERENCES auth.users(id),
    CONSTRAINT uq_cou_code UNIQUE (code)
);

COMMENT ON TABLE promotion.coupons IS 'Cupons de desconto';
CREATE INDEX idx_cou_validity ON promotion.coupons(starts_at, ends_at, is_active);

CREATE TABLE promotion.coupon_redemptions (
    id                        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    coupon_id                 UUID NOT NULL,
    user_id                   UUID NOT NULL,
    order_id                  UUID NOT NULL,
    discount_cents            INT NOT NULL,
    original_total_cents      INT NOT NULL,
    final_total_cents         INT NOT NULL,
    rules_snapshot            JSONB,
    subsidy_platform_cents    INT NOT NULL DEFAULT 0,
    subsidy_restaurant_cents  INT NOT NULL DEFAULT 0,
    created_at                TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_cr_coupon FOREIGN KEY (coupon_id) REFERENCES promotion.coupons(id),
    CONSTRAINT fk_cr_user FOREIGN KEY (user_id) REFERENCES auth.users(id),
    CONSTRAINT fk_cr_order FOREIGN KEY (order_id) REFERENCES "order".orders(id),
    CONSTRAINT uq_cr_order_id UNIQUE (order_id)
);

COMMENT ON TABLE promotion.coupon_redemptions IS 'Resgates de cupom';
CREATE INDEX idx_cr_coupon_created ON promotion.coupon_redemptions(coupon_id, created_at);
CREATE INDEX idx_cr_user_coupon ON promotion.coupon_redemptions(user_id, coupon_id);

CREATE TABLE promotion.delivery_fee_rules (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    zone_id                 UUID NOT NULL,
    region_geometry         JSONB,
    fee_cents               INT NOT NULL DEFAULT 0,
    min_order_cents         INT NOT NULL DEFAULT 0,
    free_delivery_above_cents INT,
    valid_from              TIMESTAMP WITH TIME ZONE NOT NULL,
    valid_to                TIMESTAMP WITH TIME ZONE,
    priority                INT NOT NULL DEFAULT 0,
    is_active               BOOLEAN NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_dfr_zone FOREIGN KEY (zone_id) REFERENCES coverage.delivery_zones(id)
);

COMMENT ON TABLE promotion.delivery_fee_rules IS 'Regras de frete dinâmico por região';
CREATE INDEX idx_dfr_active ON promotion.delivery_fee_rules(is_active);
CREATE INDEX idx_dfr_zone_validity ON promotion.delivery_fee_rules(zone_id, valid_from, valid_to);

CREATE TABLE promotion.campaign_daily_stats (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id       UUID NOT NULL,
    date              DATE NOT NULL,
    redemptions       INT NOT NULL DEFAULT 0,
    discount_cents    INT NOT NULL DEFAULT 0,
    gross_order_cents INT NOT NULL DEFAULT 0,
    new_users         INT NOT NULL DEFAULT 0,
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_cds_campaign FOREIGN KEY (campaign_id) REFERENCES promotion.campaigns(id),
    CONSTRAINT uq_cds_campaign_date UNIQUE (campaign_id, date)
);

COMMENT ON TABLE promotion.campaign_daily_stats IS 'Estatísticas diárias da campanha';

-- ============================================================================
-- TRIGGERS: updated_at automático
-- ============================================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOR tbl IN SELECT unnest(ARRAY[
        'infra.service_registry', 'infra.rate_limit_rules', 'auth.users',
        '"user".user_profiles', '"user".user_addresses',
        'onboarding.onboarding_applications', 'onboarding.restaurant_profiles',
        'onboarding.courier_profiles', 'menu.menu_categories',
        'menu.menu_items', 'menu.menu_modifiers', 'menu.menu_modifier_options',
        'coverage.delivery_zones', '"order".orders', 'payment.payments',
        '"order".order_sla_config', 'dispatch.courier_sessions',
        'tracking.delivery_tracking', 'finance.bank_accounts',
        'finance.payout_config', 'promotion.campaigns',
        'promotion.coupons', 'promotion.delivery_fee_rules'
    ])
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_%s_updated_at BEFORE UPDATE ON %s FOR EACH ROW EXECUTE FUNCTION set_updated_at();',
            replace(replace(tbl, '.', '_'), '"', ''), tbl
        );
    END LOOP;
END;
$$;
