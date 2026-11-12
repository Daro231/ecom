-- Optional map location for saved addresses; orders snapshot it at checkout (like the address text).
ALTER TABLE addresses ADD COLUMN latitude NUMERIC(9,6);
ALTER TABLE addresses ADD COLUMN longitude NUMERIC(9,6);
ALTER TABLE addresses ADD CONSTRAINT chk_addresses_location
    CHECK ((latitude IS NULL) = (longitude IS NULL)
       AND (latitude IS NULL OR (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)));

ALTER TABLE orders ADD COLUMN delivery_latitude NUMERIC(9,6);
ALTER TABLE orders ADD COLUMN delivery_longitude NUMERIC(9,6);
