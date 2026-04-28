# 04 - Endpoints

Base URL contoh:

```text
https://api.example.com
```

## 1) GET /v1/hijri/adjustments

Ambil daftar adjustment untuk rentang tanggal.

### Query Params

- `country` (required): default `ID`
- `from` (required): `YYYY-MM-DD`
- `to` (required): `YYYY-MM-DD`
- `authority` (optional): default `kemenag_ri`
- `region_scope` (optional): default `national`

### Request Example

```http
GET /v1/hijri/adjustments?country=ID&from=2027-01-01&to=2027-12-31&authority=kemenag_ri HTTP/1.1
Authorization: Bearer <api_key>
If-None-Match: "etag-previous"
```

### Responses

- `200`: return dataset
- `304`: not modified
- `400`: invalid query
- `401`: unauthorized
- `403`: forbidden
- `429`: rate limited

## 2) GET /v1/hijri/adjustments/latest

Ambil record terbaru untuk authority/scope tertentu.

### Query Params

- `country` (required)
- `authority` (optional)
- `region_scope` (optional)

### Response Example (200)

```json
{
  "schema_version": "1.0.0",
  "authority": "kemenag_ri",
  "generated_at": "2027-02-07T12:12:00Z",
  "records": [
    {
      "id": "adj_2027_1449_09_v1",
      "authority": "kemenag_ri",
      "country": "ID",
      "region_scope": "national",
      "effective_from": "2027-02-08",
      "effective_to": "2027-03-10",
      "adjustment_days": 1,
      "reason": "isbat_hilal",
      "revision": 3,
      "published_at": "2027-02-07T12:10:00Z"
    }
      ]
}
```

## TypeScript Handler Pattern (Framework-Agnostic)

Contoh alur handler (pseudo-code):

```ts
type Query = {
  country: string
  from?: string
  to?: string
  authority?: string
  region_scope?: string
}

async function getAdjustments(query: Query, ctx: RequestContext) {
  validateQuery(query)
  const data = await adjustmentService.getByRange(query)
  return ok(data, { etag: data.etag, cacheControl: "max-age=86400" })
}

async function getLatestAdjustments(query: Query, ctx: RequestContext) {
  validateLatestQuery(query)
  const data = await adjustmentService.getLatest(query)
  return ok(data)
}
```

Catatan:
- layer validasi query terpisah dari layer service.
- error mapping ke envelope standar (`doc/backend/07-error-codes.md`).
- jangan hardcode ke framework tertentu di domain/application layer.
