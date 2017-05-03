# Dialyxir

Mix tasks to simplify use of Dialyzer in Elixir projects.

[![Build Status](https://travis-ci.org/jeremyjh/dialyxir.svg?branch=master)](https://travis-ci.org/jeremyjh/dialyxir)

## Changes in 0.4 and 0.5

If you've been using earlier versions of Dialyxir there are some changes you may need to make in the configuration of your existing projects. A summary of the most common issues and changes are found in the Wiki pages for [0.4](https://github.com/jeremyjh/dialyxir/wiki/Upgrading-to-0.4) and [0.5](https://github.com/jeremyjh/dialyxir/wiki/Upgrading-to-0.5).

## Quickstart
If you are planning to use Dialyzer with an application built with the [Phoenix Framework](http://www.phoenixframework.org/), check out the [Quickstart wiki](https://github.com/jeremyjh/dialyxir/wiki/Phoenix-Dialyxir-Quickstart).

## Installation

Dialyxir is available on [hex.pm](https://hex.pm/packages/dialyxir).

You can either add it as a dependency in your mix.exs, or install it globally as an archive task.

To add it to a mix project, just add a line like this in your deps function in mix.exs:

```elixir
defp deps do
  [{:dialyxir, "~> 0.5", only: [:dev], runtime: false}]
end
```

```console
mix do deps.get, deps.compile
```

To install globally as an archive:

```console
git clone https://github.com/jeremyjh/dialyxir
cd dialyxir
MIX_ENV=prod mix do compile, archive.build, archive.install
```

## Usage

Use dialyxir from the directory of the mix project you want to analyze; a PLT file will be created or updated if required and the project will be automatically compiled.

```console
mix dialyzer
```

### Command line options

  * `--no-compile`       - do not compile even if needed.
  * `--no-check`         - do not perform (quick) check to see if PLT needs updated.
  * `--halt-exit-status` - exit immediately with same exit status as dialyzer.
    useful for CI. do not use with `mix do`.
  * `--plt`              - only build the required plt(s) and exit.

Warning flags passed to this task are passed on to `:dialyzer`.

  e.g.
    `mix dialyzer --unmatched_returns`

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
the modules in the project PLT are checked against your dependencies to be sure they are up to date. If you do not want to use MIX_HOME to store your core Erlang and Elixir files, you can provide a :plt_core_path key with a file path. You can specify a different location for the project PLT file with the :plt_file keyword - this is deprecated because people were using it with the old `dialyxir` to have project-specific PLTs, which are now the default. To silence the deprecation warning, specify this value as `plt_file: {:no_warn, "/myproject/mypltfile"}`.

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
   dialyzer: [plt_add_deps: :apps_direct, plt_add_apps: [:wx]]
 ]
end
```

### Flags

Dialyzer supports a number of warning flags used to enable or disable certain kinds of analysis features. Until version 0.4, `dialyxir` used by default the additional warning flags shown in the example below. However some of these create warnings that are often more confusing than helpful, particularly to new users of Dialyzer. As of 0.4, there are no longer any flags used by default. To get the old behavior, specify them in your Mix project file. For compatibility reasons you can use eiher the `-Wwarning` convention of the dialyzer CLI, or (preferred) the `WarnOpts` atoms supported by the [API](http://erlang.org/doc/man/dialyzer.html#gui-1).  e.g.

```elixir
def project do
 [ app: :my_app,
   version: "0.0.1",
   deps: deps,
   dialyzer: [ flags: ["-Wunmatched_returns", :error_handling, :race_conditions, :underspecs]]
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
             flags: [:unmatched_returns,:error_handling,:race_conditions, :no_opaque],
             paths: ["_build/dev/lib/my_app/ebin", "_build/dev/lib/foo/ebin"]]
 ]
end
```

### Ignore Warnings

By default `dialyxir` has always included the `:unknown` warning option so that warnings about unknown functions are returned. This is usually a clue that the PLT is not complete and it may be best to leave it on, but it can be disabled entirely by specifying `remove_defaults: [:unknown]` in your config.

A better option is to ignore the specific warnings you can't fix (maybe due to a bug upstream, or a dependency you just don't want to include in your PLT due to time/memory in building the PLT file.)

If you want to ignore well-known warnings, you can specify a file path in `:ignore_warnings`.

```elixir
def project do
 [ app: :my_app,
   version: "0.0.1",
   deps: deps,
   dialyzer: [ignore_warnings: "dialyzer.ignore-warnings"]
 ]
end
```

Any line of dialyzer output (partially) matching a line in `"dialyzer.ignore-warnings"` is filtered.

For example, in project where `mix dialyzer` outputs:

```
  Proceeding with analysis...
config.ex:64: The call ets:insert('Elixir.MyApp.Config',{'Elixir.MyApp.Config',_}) might have an unintended effect due to a possible race condition caused by its combination withthe ets:lookup('Elixir.MyApp.Config','Elixir.MyApp.Config') call in config.ex on line 26
config.ex:79: Guard test is_binary(_@5::#{'__exception__':='true', '__struct__':=_, _=>_}) can never succeed
config.ex:79: Guard test is_atom(_@6::#{'__exception__':='true', '__struct__':=_, _=>_}) can never succeed
 done in 0m1.32s
done (warnings were emitted)
```

If you wanted to ignore the last two warnings about guard tests, you could add to `dialyzer.ignore-warnings`:

```
Guard test is_binary(_@5::#{'__exception__':='true', '__struct__':=_, _=>_}) can never succeed
Guard test is_atom(_@6::#{'__exception__':='true', '__struct__':=_, _=>_}) can never succeed
```

And then run `mix dialyzer` would output:

```
  Proceeding with analysis...
config.ex:64: The call ets:insert('Elixir.MyApp.Config',{'Elixir.MyApp.Config',_}) might have an unintended effect due to a possible race condition caused by its combination withthe ets:lookup('Elixir.MyApp.Config','Elixir.MyApp.Config') call in config.ex on line 26
 done in 0m1.32s
done (warnings were emitted)
```

`:ignore_warnings` works as you may expect with `--halt-exit-status` - by resetting the exit status to 0 if all warnings are filtered.
