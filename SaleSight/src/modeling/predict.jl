#!/usr/bin/env julia
# Scaffold de inferencia — equivalente a salesight/modeling/predict.py

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))

using ArgParse
using Logging
using ProgressMeter

function parsear_argumentos()
    s = ArgParseSettings(description="SaleSight - Inferencia del modelo")
    @add_arg_table! s begin
        "--features-path"
            default = joinpath(@__DIR__, "..", "..", "data", "processed", "test_features.csv")
        "--model-path"
            default = joinpath(@__DIR__, "..", "..", "models", "model.jld2")
        "--predictions-path"
            default = joinpath(@__DIR__, "..", "..", "data", "processed", "test_predictions.csv")
    end
    parse_args(s)
end

function main()
    args = parsear_argumentos()
    @info "Realizando inferencia del modelo..."

    @showprogress for i in 1:10
        i == 5 && @info "Algo ocurrió en la iteración 5."
        sleep(0.1)
    end

    @info "Inferencia completada."
end

main()
