# GitLab CI with Incremental Mode

Incremental mode requires **OTP 26+** and stores Dialyzer's analysis state in `_build/<MIX_ENV>` (typically `_build/test`). Cache this directory alongside `deps/`.

```yaml
image: elixir:1.16-otp-26

stages:
  - compile
  - check-elixir-types

build-dev:
  stage: compile
  cache:
    - key:
        files:
          - .tool-versions
          - mix.lock
      paths:
        - deps/
        - _build/test
      policy: pull-push
  script:
    - mix do deps.get, compile

dialyzer-check:
  stage: check-elixir-types
  needs:
    - build-dev
  cache:
    - key:
        files:
          - .tool-versions
          - mix.lock
          - "**/*.ex"
      paths:
        - _build/test
      policy: pull-push
  script:
    - mix dialyzer --format short
  # Optional: use a branch-aware cache key to avoid cross-branch pollution
  variables:
    GIT_STRATEGY: fetch

## Cache key strategy

- Paths: cache `deps/` and `_build/test`.
- Keys: include `.tool-versions`, `mix.lock`, and branch (e.g., `key: "dialyzer-${CI_COMMIT_REF_SLUG}"`).
- Use `policy: pull-push` so caches update on every run and capture incremental analysis.
```

