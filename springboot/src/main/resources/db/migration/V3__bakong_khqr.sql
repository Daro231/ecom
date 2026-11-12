ALTER TABLE payments ADD COLUMN khqr_string TEXT;
ALTER TABLE payments ADD COLUMN khqr_md5 VARCHAR(64);
ALTER TABLE payments ADD COLUMN khqr_expires_at TIMESTAMP(6);
ALTER TABLE payments ADD COLUMN bakong_hash VARCHAR(128);
ALTER TABLE payments ADD COLUMN from_account_id VARCHAR(100);
ALTER TABLE payments ADD COLUMN last_checked_at TIMESTAMP(6);
ALTER TABLE payments ADD COLUMN check_count INT NOT NULL DEFAULT 0;
ALTER TABLE payments ADD COLUMN failure_reason VARCHAR(255);

ALTER TABLE payments ADD CONSTRAINT uk_payments_khqr_md5 UNIQUE (khqr_md5);
CREATE INDEX idx_payments_khqr_pending ON payments (status, khqr_expires_at);
