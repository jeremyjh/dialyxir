# GitHub Actions with Incremental Mode

Incremental mode requires **OTP 26+** and stores Dialyzer's analysis state in `_build/<MIX_ENV>` (typically `_build/test`). Cache this directory alongside `deps/` to realize incremental speedups.

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
      
      - name: Restore build cache (incremental state)
        uses: actions/cache@v4
        with:
          path: _build/test
          key: dialyzer-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-${{ github.ref_name }}-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            dialyzer-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-${{ github.ref_name }}-
            dialyzer-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-
      
      - name: Compile
        run: mix compile
      
      - name: Run Dialyzer
        run: mix dialyzer --format github

## Cache key strategy

- Paths: cache `deps/` and `_build/test`.
- Keys: include OS, OTP, Elixir, and branch; fall back by dropping branch, then lockfile.
- To refresh stale caches, consider saving on every run (e.g. with `github.run_number`) or cleaning on retries.
```

