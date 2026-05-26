using Pkg

Pkg.activate(@__DIR__)

paquetes = [
    "ArgParse",
    "CSV",
    "DataFrames",
    "HTTP",
    "JSON3",
    "Plots",
    "GR",
    "SQLite",
    "DBInterface",
    "StatsBase",
    "StatsPlots",
    "ZipFile",
    "ProgressMeter",
    "Dash",
    "PlotlyJS",
    "Statistics",
]

println("Instalando dependencias...")
Pkg.add(paquetes)
Pkg.instantiate()
println("✓ Todas las dependencias instaladas correctamente.")
