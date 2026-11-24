// 4RXL generate-script Edge Function
// Deploy with: supabase functions deploy generate-script
// Required Supabase secret: GITHUB_TOKEN (fine-grained token with Contents: Read and write on this repo)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const OWNER = "4RLXX";
const REPO = "4rxl-clothing-sappe";
const BRANCH = "main";
const SOURCE_PATH = "scripts/4RXL-ClothingTester.client.lua";
const ALLOWED_ORIGIN = "https://4rlxx.github.io";

const corsHeaders = {
  "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Vary": "Origin",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function encodeBase64Utf8(value: string) {
  const bytes = new TextEncoder().encode(value);
  let binary = "";
  for (let i = 0; i < bytes.length; i += 0x8000) {
    binary += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  }
  return btoa(binary);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Connexion requise." }, 401);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const githubToken = Deno.env.get("GITHUB_TOKEN");
  if (!supabaseUrl || !supabaseAnonKey || !githubToken) {
    return json({ error: "Configuration serveur incomplète." }, 500);
  }

  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData.user) return json({ error: "Session invalide." }, 401);

  let body: { template?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Requête invalide." }, 400);
  }

  // Only the vetted Clothing Tester template is accepted.
  if (body.template !== "clothing") {
    return json({ error: "Ce modèle n'est pas encore disponible." }, 400);
  }

  const githubHeaders = {
    "Authorization": `Bearer ${githubToken}`,
    "Accept": "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
    "Content-Type": "application/json",
  };

  try {
    const sourceResponse = await fetch(
      `https://raw.githubusercontent.com/${OWNER}/${REPO}/${BRANCH}/${SOURCE_PATH}`,
      { headers: { "Cache-Control": "no-cache" } },
    );
    if (!sourceResponse.ok) throw new Error("Impossible de récupérer le script source.");
    const script = await sourceResponse.text();

    const id = crypto.randomUUID();
    const filePath = `generated/4RXL-ClothingTester-${authData.user.id.slice(0, 8)}-${id}.client.lua`;
    const createResponse = await fetch(
      `https://api.github.com/repos/${OWNER}/${REPO}/contents/${filePath}`,
      {
        method: "PUT",
        headers: githubHeaders,
        body: JSON.stringify({
          message: "Generate 4RXL Clothing Tester script",
          branch: BRANCH,
          content: encodeBase64Utf8(script),
        }),
      },
    );

    if (!createResponse.ok) {
      const detail = await createResponse.text();
      console.error("GitHub create failed:", createResponse.status, detail);
      throw new Error("GitHub n'a pas pu enregistrer le fichier.");
    }

    const rawUrl = `https://raw.githubusercontent.com/${OWNER}/${REPO}/${BRANCH}/${filePath}`;
    const loadstring = `loadstring(game:HttpGet("${rawUrl}"))()`;
    return json({ success: true, path: filePath, rawUrl, loadstring });
  } catch (error) {
    console.error("4RXL generation error:", error);
    return json({ error: error instanceof Error ? error.message : "Erreur de génération." }, 502);
  }
});
