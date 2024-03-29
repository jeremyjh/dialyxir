defmodule LocalPltNoWarn.Mixfile do
  use Mix.Project

  def project do
    [
      app: :local_plt_no_warn,
      prune_code_paths: false,
      version: "1.0.0",
      dialyzer: [plt_file: {:no_warn, "local.plt"}]
    ]
  end
end
