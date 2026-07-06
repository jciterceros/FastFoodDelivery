-- =============================================================================
-- Rollback V2 — Clear Seed Data
-- FastFoodDelivery
-- Execute antes de dropar schemas (V1 rollback)
-- =============================================================================

-- Ordem inversa: tabelas com FK primeiro
TRUNCATE TABLE promotion.campaign_daily_stats CASCADE;
TRUNCATE TABLE promotion.delivery_fee_rules CASCADE;
TRUNCATE TABLE promotion.coupon_redemptions CASCADE;
TRUNCATE TABLE promotion.coupons CASCADE;
TRUNCATE TABLE promotion.campaigns CASCADE;

TRUNCATE TABLE finance.reconciliation_log CASCADE;
TRUNCATE TABLE finance.ledger_entries CASCADE;
TRUNCATE TABLE finance.daily_restaurant_rollups CASCADE;
TRUNCATE TABLE finance.payouts CASCADE;
TRUNCATE TABLE finance.payout_config CASCADE;
TRUNCATE TABLE finance.bank_accounts CASCADE;

TRUNCATE TABLE rating.moderation_blocklist CASCADE;
TRUNCATE TABLE rating.rating_aggregates CASCADE;
TRUNCATE TABLE rating.order_ratings CASCADE;

TRUNCATE TABLE verification.delivery_disputes CASCADE;
TRUNCATE TABLE verification.delivery_verification_attempts CASCADE;
TRUNCATE TABLE verification.delivery_verification_codes CASCADE;

TRUNCATE TABLE realtime.tracking_snapshots CASCADE;
TRUNCATE TABLE realtime.tracking_sessions CASCADE;

TRUNCATE TABLE tracking.courier_daily_tracks CASCADE;
TRUNCATE TABLE tracking.delivery_routes CASCADE;
TRUNCATE TABLE tracking.delivery_milestones CASCADE;
TRUNCATE TABLE tracking.location_pings CASCADE;
TRUNCATE TABLE tracking.delivery_tracking CASCADE;

TRUNCATE TABLE dispatch.courier_availability_history CASCADE;
TRUNCATE TABLE dispatch.escalation_queue CASCADE;
TRUNCATE TABLE dispatch.courier_sessions CASCADE;
TRUNCATE TABLE dispatch.delivery_assignments CASCADE;
TRUNCATE TABLE dispatch.delivery_offers CASCADE;

TRUNCATE TABLE payment.refunds CASCADE;
TRUNCATE TABLE payment.payment_webhooks CASCADE;
TRUNCATE TABLE payment.payment_tokens CASCADE;
TRUNCATE TABLE payment.payments CASCADE;

TRUNCATE TABLE "order".order_status_history CASCADE;
TRUNCATE TABLE "order".order_sla_config CASCADE;
TRUNCATE TABLE "order".inventory_reservations CASCADE;
TRUNCATE TABLE "order".order_items CASCADE;
TRUNCATE TABLE "order".orders CASCADE;

TRUNCATE TABLE search.restaurant_search_fallback CASCADE;

TRUNCATE TABLE coverage.delivery_fee_tiers CASCADE;
TRUNCATE TABLE coverage.address_geocoding_cache CASCADE;
TRUNCATE TABLE coverage.coverage_cache CASCADE;
TRUNCATE TABLE coverage.platform_regions CASCADE;
TRUNCATE TABLE coverage.delivery_zones CASCADE;

TRUNCATE TABLE menu.menu_snapshots CASCADE;
TRUNCATE TABLE menu.restaurant_schedules CASCADE;
TRUNCATE TABLE menu.menu_modifier_options CASCADE;
TRUNCATE TABLE menu.menu_modifiers CASCADE;
TRUNCATE TABLE menu.menu_items CASCADE;
TRUNCATE TABLE menu.menu_categories CASCADE;

TRUNCATE TABLE onboarding.moderation_audit_log CASCADE;
TRUNCATE TABLE onboarding.courier_profiles CASCADE;
TRUNCATE TABLE onboarding.restaurant_profiles CASCADE;
TRUNCATE TABLE onboarding.application_documents CASCADE;
TRUNCATE TABLE onboarding.onboarding_applications CASCADE;

TRUNCATE TABLE "user".user_devices CASCADE;
TRUNCATE TABLE "user".refresh_tokens CASCADE;
TRUNCATE TABLE "user".user_consents CASCADE;
TRUNCATE TABLE "user".user_addresses CASCADE;
TRUNCATE TABLE "user".user_profiles CASCADE;

TRUNCATE TABLE auth.users CASCADE;

TRUNCATE TABLE infra.dead_letter_log CASCADE;
TRUNCATE TABLE infra.rate_limit_rules CASCADE;
TRUNCATE TABLE infra.service_registry CASCADE;
