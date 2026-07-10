-- Migration for existing databases (idempotent)
CREATE TABLE IF NOT EXISTS platform_uploads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID NOT NULL,
    file_path TEXT NOT NULL,
    platform VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    post_url TEXT,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP,
    UNIQUE (batch_id, platform)
);

CREATE INDEX IF NOT EXISTS idx_platform_uploads_batch_id ON platform_uploads(batch_id);
CREATE INDEX IF NOT EXISTS idx_platform_uploads_status ON platform_uploads(status);
CREATE INDEX IF NOT EXISTS idx_platform_uploads_platform ON platform_uploads(platform);
