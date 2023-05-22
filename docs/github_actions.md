# Github Actions

```yaml
steps:
  - name: Check out source
    uses: actions/checkout@v2

  - name: Set up Elixir
    id: beam
    uses: erlef/setup-beam@v1
    with:
      otp-version: "24.1" # Define the OTP version
      elixir-version: "1.12.3" # Define the Elixir version

   # Cache key based on Erlang/Elixir version and the mix.lock hash
  - name: Restore PLT cache
    id: plt_cache
    uses: actions/cache/restore@v3
    with:
      key: |
        plt-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-${{ hashFiles('**/mix.lock') }}
      restore-keys: |
        plt-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-
      path: |
        priv/plts

  # Create PLTs if no cache was found
  - name: Create PLTs
    if: steps.plt_cache.outputs.cache-hit != 'true'
    run: mix dialyzer --plt
     
  # By default, the GitHub Cache action will only save the cache if all steps in the job succeed,
  # so we separate the cache restore and save steps in case running dialyzer fails.
  - name: Save PLT cache
    id: plt_cache_save
    uses: actions/cache/save@v3
    if: steps.plt_cache.outputs.cache-hit != 'true'
    with:
      key: |
        plt-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-${{ hashFiles('**/mix.lock') }}
      path: |
        priv/plts

  - name: Run dialyzer
    run: mix dialyzer --format github

# ...
```