-- Late payments: KHQR orders auto-cancelled for non-payment keep being checked with Bakong until this moment.
ALTER TABLE payments ADD COLUMN late_watch_until TIMESTAMP(6);
CREATE INDEX idx_payments_late_watch ON payments (late_watch_until) WHERE late_watch_until IS NOT NULL;

-- High-priority admin notifications (payment.status is a plain VARCHAR(30), so PAID_AFTER_CANCEL needs no DDL).
ALTER TABLE notifications ADD COLUMN priority VARCHAR(10) NOT NULL DEFAULT 'NORMAL';
