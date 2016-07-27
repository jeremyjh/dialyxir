defmodule LocalPlt.Mixfile do
  use Mix.Project

  def project do
    [app: :local_plt,
     version: "1.0.0",
     dialyzer: [plt_file: "local.plt"]]
  end

end
