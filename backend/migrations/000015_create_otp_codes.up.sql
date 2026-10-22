CREATE TABLE otp_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider VARCHAR(50) NOT NULL,
    identifier VARCHAR(255) NOT NULL,
    code VARCHAR(10) NOT NULL,
    attempts_left INT NOT NULL DEFAULT 3,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_provider CHECK (provider IN ('email', 'phone'))
);

CREATE INDEX idx_otp_identifier ON otp_codes(identifier);
