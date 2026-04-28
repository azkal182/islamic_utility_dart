# 07 - Error Codes

## Error Envelope

```json
{
  "error": {
    "code": "INVALID_QUERY",
    "message": "Parameter 'from' must be YYYY-MM-DD",
    "request_id": "req_abc123",
    "details": {
      "field": "from"
    }
  }
}
```

## HTTP Status Mapping

- `400 Bad Request`
  - invalid date format
  - `from > to`
- `401 Unauthorized`
  - missing/invalid token
- `403 Forbidden`
  - tier tidak punya akses endpoint
- `404 Not Found`
  - endpoint tidak ada
- `409 Conflict`
  - dataset revision conflict internal
- `429 Too Many Requests`
  - rate limit exceeded
- `500 Internal Server Error`
  - unexpected server failure

## Suggested Error Codes

- `INVALID_QUERY`
- `INVALID_DATE_RANGE`
- `UNAUTHORIZED`
- `FORBIDDEN_PLAN`
- `RATE_LIMITED`
- `CONFLICT_REVISION`
- `INTERNAL_ERROR`
