import { createClient } from "@supabase/supabase-js";

export type RestockSubscription = {
  id: string;
  product_id: number;
  variant_id: number;
  variant_label: string;
  email: string;
  consent_at: string;
  created_at: string;
  notified_at: string | null;
};

export const TABLE = "restock_subscriptions";

export function db() {
  return createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
