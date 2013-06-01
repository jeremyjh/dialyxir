# Dialyxir

Mix tasks to simplify use of Dialyzer in Elixir projects.

## TL;DR

Clone this repository. Then from the local repository:
```console
mix compile
mix install
mix dialyzer.plt     
```

Now, change to the directory of the project you want to analyze:

```console
cd ~/my_project
mix compile
mix dialyzer 
```

## With Explaining Stuff

[Dialyzer](http://www.erlang.org/doc/apps/dialyzer/dialyzer_chapter.html) is static analysis tool for Erlang and other languages that compile to BEAM bytecode for the Erlang VM. It can analyze the BEAM files and provide warnings about problems in your code including type mismatches and other issues that are commonly detected by static language compilers. The analysis can be improved by inclusion of type hints (called specs) but it can be useful even without those. For more information I highly recommend the [Success Typings](http://user.it.uu.se/~kostis/Papers/succ_types.pdf) paper that describes the theory behind the tool.


Beyond the TL;DR for these tasks, the main things to be aware of are the settings you may need to add to your mix.exs.

### PLT

The Persistent Lookup Table (PLT) is basically a cached output of the analysis. This is important because you'd probably stab yourself in the eye with a fork if you had to wait for Dialyzer to complete this for all the standard library and OTP functions you are using everytime you ran it. Running the mix task dialyzer.plt builds a PLT in HOME/.dialyxir_core_[OTP Version]_[Elixir Version].plt which includes a basic set of OTP applications, as well as all of the Elixir standard libraries. This may well meet your needs, but if you are using additional OTP applications in your project you'll want to add those as well. The apps included by default are ["erts","kernel", "stdlib", "crypto", "public_key"]. If you need additional ones, add the full list to a dialyxir: plt_apps: key in your mix.exs:

```elixir
def project do
 [ app: :my_app,
   version: "0.0.1",
   deps: deps,
   dialyzer: [plt_apps: ["erts","kernel", "stdlib", "crypto", "public_key", "mnesia"]]
 ]
end
```

### Warning Flags

There are a number of warning flags used to enable or disable certain kinds of analysis features. You may find yourself reaching a point where one of these warnings is bothering you much more than it is helping you. In that case you can remove that warning by adjusting your flags. The default flags are "-Wunmatched_returns","-Werror_handling","-Wrace_conditions","-Wunderspecs". You can specify the full list in the flags key:

```elixir
def project do
 [ app: :my_app,
   version: "0.0.1",
   deps: deps,
   dialyzer: [plt_apps: ["erts","kernel", "stdlib", "crypto", "public_key", "mnesia"],
             flags: ["-Wunmatched_returns","-Werror_handling","-Wrace_conditions", "-Wno_opaque"]]
 ]
end
```

### Paths

By default only the ebin for the root of your project is included in paths to search for BEAM files to perform analysis on. You may well want to add your deps to the analysis, but I would recommend trying them one at a time. Also as the deps can significantly slow down your analysis you may want to add them them to your PLT.

```elixir
def project do
 [ app: :my_app,
   version: "0.0.1",
   deps: deps,
   dialyzer: [plt_apps: ["erts","kernel", "stdlib", "crypto", "public_key", "mnesia"],
             flags: ["-Wunmatched_returns","-Werror_handling","-Wrace_conditions", "-Wno_opaque"],
             paths: ["ebin", "deps/foo/ebin"]]
 ]
end
```
