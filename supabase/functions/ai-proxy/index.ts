import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type" };

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const authHeader = request.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) return json({ error: "unauthorized" }, 401);
    const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, { global: { headers: { Authorization: authHeader } } });
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return json({ error: "unauthorized" }, 401);
    const { data: entitlement } = await supabase.from("entitlements").select("tier, expires_at").eq("user_id", user.id).maybeSingle();
    const premium = entitlement?.tier === "premium" && (!entitlement.expires_at || new Date(entitlement.expires_at) > new Date());
    if (!premium) return json({ error: "premium_required" }, 403);
    const body = await request.json();
    if (typeof body.question !== "string" || body.question.length < 3 || body.question.length > 4000) return json({ error: "invalid_question" }, 400);
    const openAIResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: { "Authorization": `Bearer ${Deno.env.get("OPENAI_API_KEY")}`, "Content-Type": "application/json" },
      body: JSON.stringify({ model: Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini", temperature: 0.2, response_format: { type: "json_object" }, messages: [
        { role: "system", content: "Responde en español. Devuelve JSON con text y concepts (array de strings). No inventes experiencia personal." },
        { role: "user", content: body.question }
      ] })
    });
    if (!openAIResponse.ok) return json({ error: "provider_unavailable" }, 502);
    const payload = await openAIResponse.json();
    const content = payload.choices?.[0]?.message?.content;
    if (!content) return json({ error: "invalid_provider_response" }, 502);
    return new Response(content, { headers: { ...cors, "Content-Type": "application/json" } });
  } catch { return json({ error: "internal_error" }, 500); }
});

function json(value: unknown, status: number) { return new Response(JSON.stringify(value), { status, headers: { ...cors, "Content-Type": "application/json" } }); }
