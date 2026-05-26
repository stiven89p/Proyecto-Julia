#!/usr/bin/env julia
# Scaffold de entrenamiento — equivalente a salesight/modeling/train.py

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))

using ArgParse
using Logging
using ProgressMeter

function parsear_argumentos()
    s = ArgParseSettings(description="SaleSight - Entrenamiento de modelo")
    @add_arg_table! s begin
        "--features-path"
            default = joinpath(@__DIR__, "..", "..", "data", "processed", "features.csv")
        "--labels-path"
            default = joinpath(@__DIR__, "..", "..", "data", "processed", "labels.csv")
        "--model-path"
            default = joinpath(@__DIR__, "..", "..", "models", "model.jld2")
    end
    parse_args(s)
end

function main()
    args = parsear_argumentos()
    @info "Entrenando modelo..."

    @showprogress for i in 1:10
        i == 5 && @info "Algo ocurrió en la iteración 5."
        sleep(0.1)
    end

    @info "Entrenamiento del modelo completado."
end

main()
