# Dialyxir

Mix tasks to simplify use of Dialyzer in Elixir projects.

## Installation

Dialyxir is available on [hex.pm](https://hex.pm/packages/dialyxir). 

You can either add it as a dependency in your mix.exs, or install it globally as an archive task.

To add it to a mix project, just add a line like this in your deps function in mix.exs:

```elixir
defp deps do
  [{:dialyxir, "~> 0.3", only: [:dev]}]
end
```

```console
mix deps.get
mix deps.compile
```
 
To install globally as an archive:

```console
git clone https://github.com/jeremyjh/dialyxir
cd dialyxir
mix archive.build
mix archive.install
```

## Usage

The first time you use Dialyxir, or each time that you upgrade your Erlang or Elixir version you will need to rebuild the PLT.

```console
mix dialyzer.plt
```


Use it from directory of the mix project you want to analyze; the project will be automatically compiled if needed (pass `--no-compile` to disable this).

```console
mix dialyzer
```

## With Explaining Stuff

[Dialyzer](http://www.erlang.org/doc/apps/dialyzer/dialyzer_chapter.html) is a static analysis tool for Erlang and other languages that compile to BEAM bytecode for the Erlang VM. It can analyze the BEAM files and provide warnings about problems in your code including type mismatches and other issues that are commonly detected by static language compilers. The analysis can be improved by inclusion of type hints (called [specs](http://elixir-lang.org/docs/stable/elixir/typespecs.html)) but it can be useful even without those. For more information I highly recommend the [Success Typings](http://user.it.uu.se/~kostis/Papers/succ_types.pdf) paper that describes the theory behind the tool.


Usage is straightforward but you should be aware of the available configuration settings you may wish to add to your mix.exs file.

### PLT

The Persistent Lookup Table (PLT) is basically a cached output of the analysis. This is important because you'd probably stab yourself in the eye with
a fork if you had to wait for Dialyzer to analyze all the standard library and OTP modules you are using everytime you ran it.
Running the mix task dialyzer.plt builds a PLT in `HOME/.dialyxir_core_[OTP Version]_[Elixir Version].plt`.

If you don't want all your projects to share a PLT you can specify a :plt_file key with a string containing the filename you want e.g. `dialyzer: plt_file: ".local.plt"`.

The default PLT includes a basic set of OTP applications, as well as all of the Elixir standard libraries.
This may well meet your needs, but if you are using additional OTP applications in your project you'll want to add those as well.
The apps included by default are `[ :erts, :kernel, :stdlib, :crypto, :public_key]`. If you need additional ones, add them to a `dialyzer: plt_add_apps: key` in your mix.exs (you can also add individual project dependencies this way):

```elixir
def project do
 [ app: :my_app,
   version: "0.0.1",
   deps: deps,
   dialyzer: [plt_add_apps: [:mnesia, :ecto]]
 ]
end
```

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


You can re-run the dialyzer.plt task at any time. It will check all the libraries to see if they need to be updated in the PLT, and it will add any new apps you've added to your
project config. It will only rebuild the PLT if you delete it or if you upgrade your Erlang or Elixir version.

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
   dialyzer: [plt_apps: ["erts","kernel", "stdlib", "crypto", "public_key", "mnesia"],
             flags: ["-Wunmatched_returns","-Werror_handling","-Wrace_conditions", "-Wno_opaque"],
             paths: ["_build/dev/lib/my_app/ebin", "_build/dev/lib/foo/ebin"]]
 ]
end
```
