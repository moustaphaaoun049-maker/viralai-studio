# Supabase authentication setup

The website now uses Supabase Auth in the browser with the project's **publishable** key. This key is intended for client use; never put a secret/service-role key in this repository.

## 1. Configure allowed URLs

In Supabase, open **Authentication → URL Configuration**.

Set **Site URL** to:

`https://viralai-studio.moustaphaa049.workers.dev`

Add these **Redirect URLs**:
- `https://viralai-studio.moustaphaa049.workers.dev/**`
- `http://localhost:8787/**` (local testing only)

If your Cloudflare URL differs, use the exact deployed URL instead. The previous deployment address recorded for this project was `https://viralai-studio.moustaphaa049.workers.dev`; verify it in Cloudflare before saving.

## 2. Email confirmation

The sign-up flow asks Supabase to send an email confirmation. Configure SMTP under **Authentication → SMTP Settings** before public launch; Supabase's default email service is rate-limited and intended for testing.

## 3. Give your account owner access

First create your own account through the website and confirm its email. In Supabase **SQL Editor**, replace the UUID below with your account's Auth user ID (Authentication → Users):

```sql
update auth.users
set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb)
  || jsonb_build_object('role', 'owner')
where id = 'REPLACE-WITH-YOUR-AUTH-USER-UUID';
```

Sign out and sign back in so the refreshed JWT includes the owner role. The Owner console uses this server-managed `app_metadata.role = owner` claim and the existing row-level security policies. Never grant this role through user-editable `user_metadata`.

## 4. Deploy the website update

The GitHub change must be deployed to Cloudflare before it appears on the public URL. From the repository root, run:

```bash
npx wrangler deploy
```

No AI provider, payment processor, or social publishing integration is enabled by this authentication update.
