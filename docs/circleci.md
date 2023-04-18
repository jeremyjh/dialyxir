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

      # Don't cache PLTs based on mix.lock hash, as Dialyzer can incrementally update even old ones
      # Cache key based on Elixir & Erlang version (also useful when running in matrix)
      - run:
          name: "Save Elixir and Erlang version for PLT caching"
          command: echo "$ELIXIR_VERSION $ERLANG_VERSION" > .elixir_otp_version

      - restore_cache:
          name: "Restore PLT cache"
          keys:
            - {{ arch }}-{{ checksum ".elixir_otp_version" }}-plt

      - run:
          name: "Create PLTs"
          command: mix dialyzer --plt

      - save_cache:
          name: "Save PLT cache"
          key: {{ arch }}-{{ checksum ".elixir_otp_version" }}-plt
          paths: "priv/plts"

      - run:
          name: "Run dialyzer"
          command: mix dialyzer
```
