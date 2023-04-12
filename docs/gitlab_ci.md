# GitLab CI

```yaml
# Some of the duplication can be reduced with YAML anchors:
# https://docs.gitlab.com/ee/ci/yaml/yaml_optimization.html

image: elixir:1.14

stages:
  - compile
  - check-elixir-types

# You'll want to cache based on your Erlang/Elixir version.

# The example jobs below uses asdf's config file as the cache key:
# https://asdf-vm.com/manage/configuration.html

# An example build job with cache, to prevent dialyzer from needing to compile your project first
build-dev:
  stage: compile
  cache:
    - key:
      files:
        - mix.lock
        - .tool-versions
      paths:
        - deps/
        - _build/dev
      policy: pull-push
  script:
    - mix do deps.get, compile

# The main difference between the following jobs is their cache policy:
# https://docs.gitlab.com/ee/ci/yaml/index.html#cachepolicy

dialyzer-plt:
  stage: check-elixir-types
  needs:
    - build-dev
  cache:
    - key:
      files:
        - .tool-versions
      paths:
        - priv/plts
      # Pull cache at start, push updated cache after completion
      policy: pull-push
  script:
    - mix dialyzer --plt

dialyzer-check:
  stage: check-elixir-types
  needs:
    - dialyzer-plt
  cache:
    - key:
      files:
        - .tool-versions
      paths:
        - priv/plts
      # Pull cache at start, don't push cache after completion
      policy: pull
  script:
    - mix dialyzer --format short

# ...
```
