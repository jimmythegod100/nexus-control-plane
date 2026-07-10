-- Archive table for completed platform uploads
CREATE TABLE IF NOT EXISTS upload_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID NOT NULL,
    file_path TEXT NOT NULL,
    platform VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,
    post_url TEXT,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    execution_node VARCHAR(100),
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    completed_at TIMESTAMP,
    archived_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_upload_history_batch_id ON upload_history(batch_id);
CREATE INDEX IF NOT EXISTS idx_upload_history_platform ON upload_history(platform);
CREATE INDEX IF NOT EXISTS idx_upload_history_archived_at ON upload_history(archived_at DESC);
