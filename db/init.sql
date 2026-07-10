CREATE TABLE IF NOT EXISTS jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    prompt TEXT NOT NULL,
    duration INTEGER NOT NULL,
    style VARCHAR(50),
    format VARCHAR(20),
    video_url TEXT,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    webhook_url TEXT,
    completed_at TIMESTAMP
);

CREATE INDEX idx_jobs_agent_id ON jobs(agent_id);
CREATE INDEX idx_jobs_status ON jobs(status);
CREATE INDEX idx_jobs_created_at ON jobs(created_at DESC);

CREATE TABLE IF NOT EXISTS job_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    metric_name VARCHAR(255) NOT NULL,
    metric_value FLOAT,
    recorded_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_job_metrics_job_id ON job_metrics(job_id);

CREATE TABLE IF NOT EXISTS audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_name VARCHAR(255),
    action VARCHAR(255),
    actor VARCHAR(255),
    details JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_audit_log_service ON audit_log(service_name);
CREATE INDEX idx_audit_log_created_at ON audit_log(created_at DESC);

CREATE TABLE IF NOT EXISTS mcp_servers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) UNIQUE NOT NULL,
    endpoint VARCHAR(255) NOT NULL,
    port INTEGER,
    status VARCHAR(50) DEFAULT 'running',
    last_heartbeat TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS github_repos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    repo_name VARCHAR(255) UNIQUE NOT NULL,
    repo_url TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Per-platform upload status for cross-posting batches
CREATE TABLE IF NOT EXISTS platform_uploads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID NOT NULL,
    file_path TEXT NOT NULL,
    platform VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    post_url TEXT,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    execution_node VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP,
    UNIQUE (batch_id, platform)
);

CREATE INDEX idx_platform_uploads_batch_id ON platform_uploads(batch_id);
CREATE INDEX idx_platform_uploads_status ON platform_uploads(status);
CREATE INDEX idx_platform_uploads_platform ON platform_uploads(platform);
CREATE INDEX idx_platform_uploads_execution_node ON platform_uploads(execution_node);

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

CREATE INDEX idx_upload_history_batch_id ON upload_history(batch_id);
CREATE INDEX idx_upload_history_platform ON upload_history(platform);
CREATE INDEX idx_upload_history_archived_at ON upload_history(archived_at DESC);
