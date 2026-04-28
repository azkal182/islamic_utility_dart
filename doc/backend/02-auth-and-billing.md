# 02 - Auth and Billing

## Authentication

- Scheme: `Bearer` API key.
- Header wajib:

```http
Authorization: Bearer <api_key>
```

- Jika key invalid/expired -> `401`.
- Jika key valid tapi tidak punya akses fitur -> `403`.

## Billing Model (Suggested)

### Free Tier
- Rate limit kecil (mis. 60 req/jam).
- Endpoint terbatas (mis. `latest` dan range pendek).
- Tanpa SLA khusus.

### Pro Tier
- Rate limit lebih besar (mis. 2000 req/jam).
- Akses range panjang + histori revision.
- SLA update data resmi lebih cepat.

## Rate Limiting Headers

Disarankan API kirim:
- `X-RateLimit-Limit`
- `X-RateLimit-Remaining`
- `X-RateLimit-Reset`

Jika limit habis -> `429 Too Many Requests`.

## Key Management

- Key bisa rotate tanpa downtime (overlap valid key).
- Key disarankan dibatasi per aplikasi/environment.
- Simpan hash key di backend, bukan plaintext.
