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

> **Incremental mode tip:** Switch the final step to `mix dialyzer --incremental` to enable OTP 26's incremental pipeline. You can keep the same cache definition—Dialyzer stores its incremental PLT metadata inside `priv/plts`, so restoring that directory before the run preserves the incremental speedups. If you want per-branch warm caches, append `-{{ .Branch }}` to the cache key.
