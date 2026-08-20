import { createClient } from 'jsr:@supabase/supabase-js@2'
import { createRemoteJWKSet, jwtVerify } from 'npm:jose@5'

const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID') ?? ''
const BUCKET = 'villaguest'
const ALLOWED_PREFIXES = ['cleaning_photos/', 'maintenance_photos/', 'villa_logos/']

const JWKS = createRemoteJWKSet(
  new URL(
    'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
  ),
)

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-storage-path, x-is-folder',
}

async function verifyFirebaseToken(authHeader: string | null) {
  if (!authHeader?.startsWith('Bearer ')) {
    throw new Error('Missing or invalid Authorization header')
  }
  await jwtVerify(authHeader.slice(7), JWKS, {
    issuer: `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`,
    audience: FIREBASE_PROJECT_ID,
  })
}

function validatedPath(storagePath: string | null): string {
  if (!storagePath) throw new Error('Missing x-storage-path header')
  if (storagePath.includes('..')) throw new Error('Path traversal not allowed')
  if (!ALLOWED_PREFIXES.some((p) => storagePath.startsWith(p))) {
    throw new Error(`Invalid path — must start with: ${ALLOWED_PREFIXES.join(', ')}`)
  }
  return storagePath
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  try {
    await verifyFirebaseToken(req.headers.get('Authorization'))
    const storagePath = validatedPath(req.headers.get('x-storage-path'))

    // ── Upload ───────────────────────────────────────────────────────────
    if (req.method === 'POST') {
      const bytes = new Uint8Array(await req.arrayBuffer())
      const contentType = req.headers.get('content-type') ?? 'image/jpeg'

      const { error } = await supabase.storage
        .from(BUCKET)
        .upload(storagePath, bytes, { contentType, upsert: true })

      if (error) {
        return Response.json({ error: error.message }, { status: 500, headers: corsHeaders })
      }

      const { data } = supabase.storage.from(BUCKET).getPublicUrl(storagePath)
      return Response.json({ url: data.publicUrl }, { headers: corsHeaders })
    }

    // ── Delete file or folder ────────────────────────────────────────────
    if (req.method === 'DELETE') {
      const isFolder = req.headers.get('x-is-folder') === 'true'

      if (isFolder) {
        const { data: files } = await supabase.storage.from(BUCKET).list(storagePath)
        if (files && files.length > 0) {
          const paths = files.map((f) => `${storagePath}/${f.name}`)
          await supabase.storage.from(BUCKET).remove(paths)
        }
      } else {
        await supabase.storage.from(BUCKET).remove([storagePath])
      }

      return Response.json({ ok: true }, { headers: corsHeaders })
    }

    return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders })
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err)
    const isAuthError = message.includes('Missing') || message.includes('Invalid') ||
      message.includes('JWTExpired') || message.includes('JWSInvalid')
    return Response.json({ error: message }, {
      status: isAuthError ? 401 : 500,
      headers: corsHeaders,
    })
  }
})
