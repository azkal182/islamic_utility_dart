# 13 - TypeScript Service Architecture

## Layering

Disarankan memakai 4 layer:

1. `api`
- HTTP adapter: route/controller, auth guard, serialization.

2. `application`
- Use-case orchestration:
  - get adjustments by range
  - get latest adjustments
  - conflict resolution coordination

3. `domain`
- Entity and rules:
  - `AdjustmentRecord`
  - priority/merge rules

4. `infrastructure`
- Prisma repository
- Redis cache adapter
- API key repository

## Dependency Direction

- `api` -> `application`
- `application` -> `domain`
- `application` -> `infrastructure` via interfaces
- `domain` tidak boleh bergantung ke framework/ORM

## Suggested Project Layout

```text
src/
  api/
    routes/
    middleware/
    presenters/
  application/
    usecases/
    services/
  domain/
    entities/
    rules/
  infrastructure/
    prisma/
    redis/
    auth/
  shared/
    errors/
    logging/
    config/
```
