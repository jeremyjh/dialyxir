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
The apps included by default are `[ :erts, :kernel, :stdlib, :crypto, :public_key]`. 

If you don't want to include the default apps you can specify a `:plt_apps` key and list there only the apps you want in the PLT.

#### Dependencies
There is also a `:plt_add_deps` option you can set to automatically add dependencies to the PLT. You can set this key to either :project (or true) - which adds only your project's direct dependencies - or :transitive - which will pull in the project's full dependency tree.


```elixir
def project do
 [ app: :my_app,
   version: "0.0.1",
   deps: deps,
   dialyzer: [plt_add_deps: :transitive]
 ]
end
```

### Warning Flags

There are a number of warning flags used to enable or disable certain kinds of analysis features.
You may find yourself reaching a point where one of these warnings is bothering you much more than it is helping you.
In that case you can remove that warning by adjusting your flags.
The default flags are "-Wunmatched_returns", "-Werror_handling", "-Wrace_conditions", "-Wunderspecs". You can specify the full list in the flags key:

```elixir
def project do
 [ app: :my_app,
   version: "0.0.1",
   deps: deps,
   dialyzer: [plt_apps: [:erts, :kernel, :stdlib, :mnesia],
             flags: ["-Wunmatched_returns","-Werror_handling","-Wrace_conditions", "-Wno_opaque"]]
 ]
end
```

### Paths

By default only the ebin in the `_build` directory for the current mix environment of your project is included in paths to search for BEAM files to perform analysis on. You may well want to add your deps to the analysis, but I would recommend trying them one at a time. Also as the deps can significantly slow down your analysis you may want to add them to your PLT.

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
