-- Remote execution tracking for platform uploads (idempotent)
ALTER TABLE platform_uploads
    ADD COLUMN IF NOT EXISTS execution_node VARCHAR(100);

CREATE INDEX IF NOT EXISTS idx_platform_uploads_execution_node
    ON platform_uploads(execution_node);
