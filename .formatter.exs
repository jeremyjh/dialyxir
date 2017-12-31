export_locals_without_parens = []

[
  inputs: ["mix.exs", "lib/**/*.{ex,exs}", "test/**/*.{ex,exs}"],
  locals_without_parens: export_locals_without_parens,
  export: [
    locals_without_parens: export_locals_without_parens
  ]
]
