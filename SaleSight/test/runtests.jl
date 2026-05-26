using Test
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using SaleSight
using SaleSight.Config
using SaleSight.Features: _a_float, _a_fecha
using Dates

@testset "SaleSight Tests" begin

    @testset "Config - Rutas" begin
        @test isdir(Config.RUTA_RAIZ)
        @test endswith(Config.NOMBRE_DB, ".db")
    end

    @testset "Features - Conversión de tipos" begin
        @test _a_float("3.14")  === 3.14
        @test _a_float("abc")   === missing
        @test _a_float(missing) === missing
        @test _a_float(42)      === 42.0

        @test _a_fecha("2023-01-15") == Date(2023, 1, 15)
        @test _a_fecha("no-es-fecha") === missing
        @test _a_fecha(missing)       === missing
    end

end
