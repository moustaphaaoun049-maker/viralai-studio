# Supabase setup — ViralAI Studio

This repository contains the first secure database foundation for the product. It does not activate AI providers, billing, or social publishing.

## Apply the schema
1. Open your Supabase project.
2. Open **SQL Editor** → **New query**.
3. Copy and run the complete file `supabase/migrations/20261125000000_initial_schema.sql`.
4. In **Project Settings → API**, note the Project URL and the publishable/anon key. These are safe to use in a browser only when Row Level Security remains enabled.
5. Never put the `service_role` key in website JavaScript, GitHub, or public environment variables.

## Owner access (secure)
The owner console must be protected by a server-verified JWT claim. Do not use a client-editable user metadata field and do not grant owner access to the first person who signs up.

After creating your own account, copy its user UUID from **Authentication → Users**. In Supabase SQL Editor, run the following after replacing the placeholder with that UUID:

```sql
-- Replace the UUID with your own Auth user ID.
-- This sets a trusted app_metadata claim; it is not editable by the user in the browser.
update auth.users
set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"role":"owner"}'::jsonb
where id = 'REPLACE-WITH-YOUR-USER-UUID';
```

The user's next sign-in/refresh will receive the owner claim. The database policies use that claim to permit owner monitoring. Never share the UUID publicly.

## Tables created
- `profiles`: basic profile data.
- `projects`: user-owned creative projects.
- `generation_jobs`: server-managed AI job records.
- `usage_ledger`: immutable server-managed usage/credit history.
- `subscriptions`: server-managed plan and billing state.
- `audit_logs`: owner-only audit trail.

All tables have Row Level Security enabled. Users can only access their own records; the owner claim grants monitoring access. Jobs, usage, subscriptions, and audit writes are intentionally server-only.

## Not enabled yet
Authentication UI, email delivery configuration, server-side generation endpoints, provider API keys, payment checkout/webhooks, and social OAuth are separate integration tasks. No provider or payment is activated by this migration.
