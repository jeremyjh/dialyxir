# Github Actions

```yaml
steps:
  - name: Check out source
    uses: actions/checkout@v2

  - name: Set up Elixir
    id: beam
    uses: erlef/setup-beam@v1
    with:
      elixir-version: "1.12.3" # Define the Elixir version
      otp-version: "24.1" # Define the OTP version

   # Don't cache PLTs based on mix.lock hash, as Dialyzer can incrementally update even old ones
   # Cache key based on Elixir & Erlang version (also useful when running in matrix)
  - name: Restore PLT cache
    id: plt_cache
    uses: actions/cache/restore@v3
    with:
      key: |
        ${{ runner.os }}-${{ steps.beam.outputs.elixir-version }}-${{ steps.beam.outputs.otp-version }}-plt
      restore-keys: |
        ${{ runner.os }}-${{ steps.beam.outputs.elixir-version }}-${{ steps.beam.outputs.otp-version }}-plt
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
        ${{ runner.os }}-${{ steps.beam.outputs.elixir-version }}-${{ steps.beam.outputs.otp-version }}-plt
      path: |
        priv/plts

  - name: Run dialyzer
    run: mix dialyzer --format github

# ...
```