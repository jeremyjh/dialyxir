# CircleCI

```yaml
---
version: 2

jobs:
  build:
    docker:
      - image: cimg/elixir:1.14

    steps:
      - checkout

      # Compile steps omitted for simplicity

      # Cache key based on Erlang/Elixir version and the mix.lock hash
      - run:
          name: "Save Elixir and Erlang version for PLT caching"
          command: echo "$ELIXIR_VERSION $ERLANG_VERSION" > .elixir_otp_version

      - restore_cache:
          name: "Restore PLT cache"
          keys:
            - plt-{{ arch }}-{{ checksum ".elixir_otp_version" }}-{{ checksum "mix.lock" }}

      - run:
          name: "Create PLTs"
          command: mix dialyzer --plt

      - save_cache:
          name: "Save PLT cache"
          key: plt-{{ arch }}-{{ checksum ".elixir_otp_version" }}-{{ checksum "mix.lock" }}
          paths: "priv/plts"

      - run:
          name: "Run dialyzer"
          command: mix dialyzer
```

> **Incremental mode tip:** switch the final step to `mix dialyzer --incremental` to
> use OTP 27+'s incremental pipeline, and drop the separate `mix dialyzer --plt`
> step — the first incremental run builds its own PLT. Dialyzer writes the
> incremental PLT next to the classic one (the same `priv/plts` directory cached
> above), so the existing cache definition keeps it warm. For per-branch warm
> caches, append `-{{ .Branch }}` to the cache key.
