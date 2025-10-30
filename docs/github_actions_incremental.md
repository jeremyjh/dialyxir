# GitHub Actions with Incremental Mode

Incremental mode requires **OTP 26+** and caches Dialyzer's state in `_build` instead of separate PLT files.

```yaml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - name: Check out source
        uses: actions/checkout@v4
      
      - name: Set up Elixir
        id: beam
        uses: erlef/setup-beam@v1
        with:
          otp-version: "26.2"
          elixir-version: "1.16.0"
      
      - name: Restore dependencies cache
        uses: actions/cache@v4
        with:
          path: deps
          key: deps-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            deps-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-
      
      - name: Install dependencies
        run: mix deps.get
      
      - name: Restore build cache
        uses: actions/cache@v4
        with:
          path: _build
          key: dialyzer-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-${{ hashFiles('**/mix.lock') }}-${{ hashFiles('**/*.ex') }}
          restore-keys: |
            dialyzer-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-${{ hashFiles('**/mix.lock') }}-
            dialyzer-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-
      
      - name: Compile
        run: mix compile
      
      - name: Run Dialyzer
        run: mix dialyzer --format github
```

