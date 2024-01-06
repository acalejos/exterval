defmodule Exterval.MixProject do
  use Mix.Project

  def project do
    [
      app: :exterval,
      version: "0.2.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      preferred_cli_env: [
        docs: :docs,
        "hex.publish": :docs
      ],
      name: "Exterval",
      description: "Real-valued intervals with support for the `Enumerable` protocol."
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.29.0", only: :docs}
    ]
  end

  defp docs do
    [
      main: "Exterval"
    ]
  end

  defp package do
    [
      maintainers: ["Andres Alejos"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/acalejos/exterval"}
    ]
  end
end
