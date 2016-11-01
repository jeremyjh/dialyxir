# Dialyxir

Mix tasks to simplify use of Dialyzer in Elixir projects.

## Quickstart
If you are planning to use Dialyzer with an application built with the [Phoenix Framework](http://www.phoenixframework.org/), check out the [Quickstart wiki](https://github.com/jeremyjh/dialyxir/wiki/Phoenix-Dialyxir-Quickstart).

## Installation

Dialyxir is available on [hex.pm](https://hex.pm/packages/dialyxir). 

You can either add it as a dependency in your mix.exs, or install it globally as an archive task.

To add it to a mix project, just add a line like this in your deps function in mix.exs:

```elixir
defp deps do
  [{:dialyxir, "~> 0.4", only: [:dev]}]
end
```

```console
mix do deps.get, deps.compile
```
 
To install globally as an archive:

```console
git clone https://github.com/jeremyjh/dialyxir
cd dialyxir
mix do compile, archive.build, archive.install
```

## Usage

Use dialyxir from directory of the mix project you want to analyze; a PLT file will be created or updated if required and the project will be automatically compiled (pass command arguments `--no-compile` to disable compilation and --no-check to skip the PLT check).

```console
mix dialyzer
```

## With Explaining Stuff

[Dialyzer](http://www.erlang.org/doc/apps/dialyzer/dialyzer_chapter.html) is a static analysis tool for Erlang and other languages that compile to BEAM bytecode for the Erlang VM. It can analyze the BEAM files and provide warnings about problems in your code including type mismatches and other issues that are commonly detected by static language compilers. The analysis can be improved by inclusion of type hints (called [specs](http://elixir-lang.org/docs/stable/elixir/typespecs.html)) but it can be useful even without those. For more information I highly recommend the [Success Typings](http://user.it.uu.se/~kostis/Papers/succ_types.pdf) paper that describes the theory behind the tool.


Usage is straightforward but you should be aware of the available configuration settings you may wish to add to your mix.exs file.

### PLT

The Persistent Lookup Table (PLT) is basically a cached output of the analysis. This is important because you'd probably stab yourself in the eye with
a fork if you had to wait for Dialyzer to analyze all the standard library and OTP modules you are using everytime you ran it.
Running the mix task `dialyzer` by default builds several PLT files:
    * A core Erlang file in $MIX_HOME/dialyxir_erlang-[OTP Version].plt
    * A core Elixir file in $MIX_HOME/dialyxir_erlang-[OTP Version]_elixir-[Elixir Version].plt
    * A project environment specific file in _build/env/dialyze_erlang-[OTP Version]_elixir-[Elixir Version]_deps-dev.plt

The core files are simply copied to your project folder when you run `dialyxir` for the first time with a given version of Erlang and Elixir. By default, all
the modules in the project PLT are checked against your dependencies to be sure they are up to date. If you do not want to use MIX_HOME to store your core Erlang and Elixir files, you can provide a :plt_core_path key with a file path.

The core PLTs include a basic set of OTP applications, as well as all of the Elixir standard libraries.
The apps included by default are `[ :erts, :kernel, :stdlib, :crypto]`. 

If you don't want to include the default apps you can specify a `:plt_apps` key and list there only the apps you want in the PLT. Using this option will mean dependencies are not added automatically (see below). If you want to just add an application to the list of defaults and dependencies you can use the `:plt_add_apps` key.

#### Dependencies
OTP application dependencies are (transitively) added to your PLT by default. The applications added are the same as you would see displayed with the command `mix app.tree`. There is also a `:plt_add_deps` option you can set to control the dependencies added. The following options are supported:
  * :project - Direct Mix and OTP dependencies
  * :apps_direct - Only Direct OTP application dependencies - not the entire tree
  * :transitive - Include Mix and OTP application dependencies recursively
  * :app_tree - Transitive OTP application dependencies e.g. `mix app.tree` (default)


The example below changes the default to include only direct OTP dependencies, and adds another specific dependency to the list. This can be helpful if a large dependency tree is creating memory issues and only some of the transitive dependencies are required for analysis.

```elixir
def project do
 [ app: :my_app,
   version: "0.0.1",
   deps: deps,
   dialyzer: [plt_add_deps: :apps_direct, plt_add_apps: :wx]
 ]
end
```

### Flags

You can specify any `dialyzer` command line argument with the :flags keyword.

Dialyzer supports a number of warning flags used to enable or disable certain kinds of analysis features. Until version 0.4, `dialyxir` used by default the additional warning flags shown in the example below. However some of these create warnings that are often more confusing than helpful, particularly to new users of Dialyzer. As of 0.4, there are no longer any flags used by default. To get the old behavior, specify them in your Mix project file e.g.

```elixir
def project do
 [ app: :my_app,
   version: "0.0.1",
   deps: deps,
   dialyzer: [ flags: ["-Wunmatched_returns", "-Werror_handling", "-Wrace_conditions", "-Wunderspecs"]]
 ]
end
```

### Paths

By default only the ebin in the `_build` directory for the current mix environment of your project is included in paths to search for BEAM files to perform analysis on. You can specify a list of locations to find BEAMS for analysis with :paths keyword.

```elixir
def project do
 [ app: :my_app,
   version: "0.0.1",
   deps: deps,
   dialyzer: [plt_add_apps: [:mnesia],
             flags: ["-Wunmatched_returns","-Werror_handling","-Wrace_conditions", "-Wno_opaque"],
             paths: ["_build/dev/lib/my_app/ebin", "_build/dev/lib/foo/ebin"]]
 ]
end
```