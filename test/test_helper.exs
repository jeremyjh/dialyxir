case System.get_env("OUTPUT_TESTS") do
  "true" -> ExUnit.start(exclude: :test, include: :output_tests)
  _ -> ExUnit.start(exclude: :output_tests)
end
