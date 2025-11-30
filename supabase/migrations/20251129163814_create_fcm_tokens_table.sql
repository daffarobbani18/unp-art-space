-- FCM Tokens Table for Push Notifications
-- This table stores Firebase Cloud Messaging tokens for each user's device

CREATE TABLE public.fcm_tokens (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  user_id uuid NOT NULL,
  token text NOT NULL, -- FCM device token
  device_id text, -- Unique device identifier (optional)
  platform text, -- 'android', 'ios', 'web'
  is_active boolean DEFAULT true, -- For invalidating old tokens
  
  CONSTRAINT fcm_tokens_pkey PRIMARY KEY (id),
  CONSTRAINT fcm_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE,
  CONSTRAINT fcm_tokens_token_unique UNIQUE (token)
);

-- Create indexes for faster queries
CREATE INDEX idx_fcm_tokens_user_id ON public.fcm_tokens(user_id);
CREATE INDEX idx_fcm_tokens_token ON public.fcm_tokens(token);
CREATE INDEX idx_fcm_tokens_is_active ON public.fcm_tokens(is_active);

-- RLS (Row Level Security) Policies
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Users can only see and manage their own tokens
CREATE POLICY "Users can view their own tokens"
  ON public.fcm_tokens
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own tokens"
  ON public.fcm_tokens
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own tokens"
  ON public.fcm_tokens
  FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own tokens"
  ON public.fcm_tokens
  FOR DELETE
  USING (auth.uid() = user_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_fcm_tokens_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE TRIGGER fcm_tokens_updated_at_trigger
  BEFORE UPDATE ON public.fcm_tokens
  FOR EACH ROW
  EXECUTE FUNCTION update_fcm_tokens_updated_at();

-- Function to clean up old/inactive tokens (run periodically)
CREATE OR REPLACE FUNCTION cleanup_old_fcm_tokens()
RETURNS void AS $$
BEGIN
  -- Delete tokens older than 90 days and not active
  DELETE FROM public.fcm_tokens
  WHERE is_active = false
  AND updated_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ FCM tokens table created successfully!';
  RAISE NOTICE '📱 Users can now register their device tokens for push notifications';
END $$;
