# CircleCI with Incremental Mode

Incremental mode requires **OTP 26+** and caches Dialyzer's state in `_build` instead of separate PLT files.

```yaml
---
version: 2

jobs:
  build:
    docker:
      - image: cimg/elixir:1.16-otp-26.2

    steps:
      - checkout

      - run:
          name: "Save version info for caching"
          command: echo "$ELIXIR_VERSION $ERLANG_VERSION" > .elixir_otp_version

      - restore_cache:
          name: "Restore dependencies cache"
          keys:
            - deps-{{ arch }}-{{ checksum ".elixir_otp_version" }}-{{ checksum "mix.lock" }}

      - run:
          name: "Install dependencies"
          command: mix deps.get

      - restore_cache:
          name: "Restore build cache"
          keys:
            - dialyzer-{{ arch }}-{{ checksum ".elixir_otp_version" }}-{{ checksum "mix.lock" }}-{{ checksum "**/*.ex" }}
            - dialyzer-{{ arch }}-{{ checksum ".elixir_otp_version" }}-{{ checksum "mix.lock" }}
            - dialyzer-{{ arch }}-{{ checksum ".elixir_otp_version" }}-

      - run:
          name: "Compile"
          command: mix compile

      - run:
          name: "Run dialyzer"
          command: mix dialyzer

      - save_cache:
          name: "Save build cache"
          key: dialyzer-{{ arch }}-{{ checksum ".elixir_otp_version" }}-{{ checksum "mix.lock" }}-{{ checksum "**/*.ex" }}
          paths:
            - _build
```

