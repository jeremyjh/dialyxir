export_locals_without_parens = [error: 1, info: 1]

[
  inputs: ["mix.exs", "lib/**/*.{ex,exs}", "test/**/*.{ex,exs}"],
  locals_without_parens: export_locals_without_parens,
  export: [
    locals_without_parens: export_locals_without_parens
  ]
]
