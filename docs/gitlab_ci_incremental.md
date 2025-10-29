# GitLab CI with Incremental Mode

Incremental mode requires **OTP 26+** and caches Dialyzer's state in `_build` instead of separate PLT files.

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
        - _build/dev
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
        - _build
      policy: pull-push
  script:
    - mix dialyzer --format short
```

