defmodule AltLocalPath.Mixfile do
  use Mix.Project

  def project do
    [app: :alt_local_path, version: "1.0.0", dialyzer: [plt_local_path: "dialyzer"]]
  end
end
