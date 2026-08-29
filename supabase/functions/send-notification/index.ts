import { createRemoteJWKSet, jwtVerify } from 'npm:jose@5'

const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID') ?? ''
const SERVICE_ACCOUNT_JSON = Deno.env.get('GOOGLE_SERVICE_ACCOUNT_JSON') ?? ''

const FIREBASE_JWKS = createRemoteJWKSet(
  new URL(
    'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
  ),
)

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ServiceAccount {
  client_email: string
  private_key: string
}

async function verifyFirebaseToken(authHeader: string | null) {
  if (!authHeader?.startsWith('Bearer ')) throw new Error('Missing Authorization header')
  await jwtVerify(authHeader.slice(7), FIREBASE_JWKS, {
    issuer: `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`,
    audience: FIREBASE_PROJECT_ID,
  })
}

function pemToBuffer(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----[^-]+-----/g, '').replace(/\s/g, '')
  const binary = atob(b64)
  const buf = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) buf[i] = binary.charCodeAt(i)
  return buf.buffer
}

function toBase64Url(buf: ArrayBuffer): string {
  return btoa(String.fromCharCode(...new Uint8Array(buf)))
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  const header = { alg: 'RS256', typ: 'JWT' }
  const payload = {
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }

  const hb64 = toBase64Url(new TextEncoder().encode(JSON.stringify(header)))
  const pb64 = toBase64Url(new TextEncoder().encode(JSON.stringify(payload)))
  const signingInput = `${hb64}.${pb64}`

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToBuffer(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )
  const sig = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(signingInput),
  )

  const jwt = `${signingInput}.${toBase64Url(sig)}`

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })
  const json = await res.json()
  if (!json.access_token) throw new Error(`OAuth2 error: ${JSON.stringify(json)}`)
  return json.access_token as string
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders })

  try {
    await verifyFirebaseToken(req.headers.get('Authorization'))

    const { tokens, title, body, data } = (await req.json()) as {
      tokens: string[]
      title: string
      body: string
      data?: Record<string, string>
    }

    if (!tokens?.length) {
      return Response.json({ sent: 0 }, { headers: corsHeaders })
    }

    const sa: ServiceAccount = JSON.parse(SERVICE_ACCOUNT_JSON)
    const accessToken = await getAccessToken(sa)

    const results = await Promise.allSettled(
      tokens.map((token) =>
        fetch(
          `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
          {
            method: 'POST',
            headers: {
              Authorization: `Bearer ${accessToken}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              message: {
                token,
                notification: { title, body },
                ...(data && { data }),
              },
            }),
          },
        ),
      ),
    )

    const sent = results.filter((r) => r.status === 'fulfilled').length
    return Response.json({ sent }, { headers: corsHeaders })
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err)
    const isAuth =
      message.includes('Missing') ||
      message.includes('JWTExpired') ||
      message.includes('JWSInvalid')
    return Response.json({ error: message }, { status: isAuth ? 401 : 500, headers: corsHeaders })
  }
})
