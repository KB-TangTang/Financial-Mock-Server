# Implementation Conventions

These conventions define the target structure for new application code. If existing code later establishes a different local pattern, prefer the existing local pattern and update this file.

## Layer Placement

- Controllers go under `src/main/java/com/financial/mockserver/controller`.
- Services go under `src/main/java/com/financial/mockserver/service`.
- Service implementations go under `src/main/java/com/financial/mockserver/service/impl`.
- DTOs go under `src/main/java/com/financial/mockserver/dto`.
- MyBatis mapper interfaces go under `src/main/java/com/financial/mockserver/mapper`.
- MyBatis mapper XML files go under `src/main/resources/mapper`.

## API Implementation Order

When adding a new API, implement in this order:

1. DTO request/response models
2. Mapper interface
3. Mapper XML query
4. Service interface
5. Service implementation
6. Controller endpoint
7. Tests or verification

## MyBatis Rules

- Prefer mapper XML for SQL definitions.
- Use mapper interfaces for Java wiring.
- Do not use annotation SQL unless the existing local pattern already does.
- Keep SQL statement ids aligned with mapper method names.

## Naming Rules

- Controller classes end with `Controller`.
- Service interfaces end with `Service`.
- Service implementations end with `ServiceImpl`.
- Mapper interfaces end with `Mapper`.
- Request DTOs end with `Request`.
- Response DTOs end with `Response`.

## Scope Rules

- Follow existing package structure when present.
- If a package does not exist, create the smallest conventional package needed.
- Do not introduce new architectural patterns without PM approval.
- Keep unrelated refactors out of feature implementation work.

