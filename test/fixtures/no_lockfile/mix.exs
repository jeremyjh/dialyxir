defmodule NoLockfile.Mixfile do
  use Mix.Project

  def project do
    [
      app: :no_lockfile,
      prune_code_paths: false,
      version: "1.0.0"
    ]
  end
end
