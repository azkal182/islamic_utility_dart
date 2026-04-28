# 14 - Prisma + PostgreSQL Schema

## Prisma Models (Draft)

```prisma
model Adjustment {
  id             String   @id
  authority      String
  country        String   @db.Char(2)
  regionScope    String
  effectiveFrom  DateTime @db.Date
  effectiveTo    DateTime? @db.Date
  adjustmentDays Int
  reason         String
  revision       Int
  publishedAt    DateTime @db.Timestamptz(6)
  notes          String?
  isActive       Boolean  @default(true)
  createdAt      DateTime @default(now()) @db.Timestamptz(6)
  updatedAt      DateTime @updatedAt @db.Timestamptz(6)

  @@index([country, authority, regionScope, effectiveFrom])
  @@index([country, authority, regionScope, effectiveTo])
  @@index([country, authority, regionScope, revision, publishedAt])
}

model ApiKey {
  id               String   @id @default(uuid())
  keyHash          String   @unique
  label            String?
  plan             String
  isActive         Boolean  @default(true)
  rateLimitPerHour Int
  createdAt        DateTime @default(now()) @db.Timestamptz(6)
  expiresAt        DateTime? @db.Timestamptz(6)
  lastUsedAt       DateTime? @db.Timestamptz(6)
}

model AdjustmentAuditEvent {
  id            BigInt   @id @default(autoincrement())
  adjustmentId  String
  eventType     String
  actor         String
  beforePayload Json?
  afterPayload  Json?
  createdAt     DateTime @default(now()) @db.Timestamptz(6)
}
```

## Validation Rules (App-Level)

- `adjustmentDays` must be one of `-1,0,1`
- `revision >= 1`
- `effectiveTo == null || effectiveTo >= effectiveFrom`
