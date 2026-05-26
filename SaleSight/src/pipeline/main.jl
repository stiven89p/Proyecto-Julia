#!/usr/bin/env julia
# Orquestador ETL — equivalente a salesight/pipeline/main.py
# Uso: julia --project=../.. src/pipeline/main.jl --modo completo

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))

push!(LOAD_PATH, joinpath(@__DIR__, ".."))

using ArgParse
using Logging
using SaleSight
using SaleSight.Config: DATOS_PROCESADOS, DATOS_BRUTOS, NOMBRE_DB
using SaleSight.Ingest: descargar_datos
using SaleSight.Features: procesar_caracteristicas
using SaleSight.Graficos: ejecutar_graficacion
using SaleSight.Dataset: guardar_datos_db, obtener_datos_raw
import CSV

# ─── CLI ──────────────────────────────────────────────────────────────────────

function parsear_argumentos()
    s = ArgParseSettings(description="SaleSight - Orquestador ETL (Extraer, Transformar, Cargar)")

    @add_arg_table! s begin
        "--modo"
            help    = "Fase del pipeline: completo | ingesta | transformacion | carga"
            default = "completo"
        "--dataset-id"
            help    = "ID del dataset de Kaggle"
            default = "sahilprajapati143/retail-analysis-large-dataset"
        "--bd-ventas"
            help    = "Nombre del archivo de base de datos SQLite"
            default = NOMBRE_DB
    end

    return parse_args(s)
end

# ─── Orquestador ──────────────────────────────────────────────────────────────

function orquestar_pipeline()
    args       = parsear_argumentos()
    modo       = args["modo"]
    dataset_id = args["dataset-id"]
    bd_ventas  = args["bd-ventas"]

    modos_validos = ["completo", "ingesta", "transformacion", "carga"]
    if !(modo in modos_validos)
        @error "Modo inválido: '$modo'. Use uno de: $(join(modos_validos, ", "))"
        exit(1)
    end

    archivo_csv_procesado = joinpath(DATOS_PROCESADOS, "processed_data.csv")
    df_cache = nothing

    # ── 1. Extracción (E) ────────────────────────────────────────────────────
    if modo in ["ingesta", "completo"]
        @info "ETAPA 1: EXTRACCIÓN (E)..."
        ok = descargar_datos(dataset_id, DATOS_BRUTOS)
        if !ok
            @error "La extracción falló."
            exit(1)
        end
    end

    # ── 2. Transformación (T) + EDA ──────────────────────────────────────────
    if modo in ["transformacion", "completo"]
        @info "ETAPA 2: TRANSFORMACIÓN (T) + EDA..."
        df_cache = procesar_caracteristicas("new_retail_data.csv")

        if isnothing(df_cache)
            @error "No se pudo completar la transformación."
            exit(1)
        end

        @info "Generando Análisis Exploratorio de Datos (EDA)..."
        ejecutar_graficacion(df_cache)
    end

    # ── 3. Carga (L) ─────────────────────────────────────────────────────────
    if modo in ["carga", "completo"]
        @info "ETAPA 3: CARGA (L)..."

        # Si venimos de transformacion en el mismo pipeline, df_cache ya está listo.
        # Si se ejecuta 'carga' de forma independiente, transformamos de nuevo.
        df_para_cargar = if !isnothing(df_cache)
            df_cache
        else
            @info "Modo carga independiente: recuperando datos..."
            procesar_caracteristicas("new_retail_data.csv")
        end

        if isnothing(df_para_cargar)
            @error "No hay datos disponibles para cargar."
            exit(1)
        end

        # Guardar CSV procesado
        mkpath(DATOS_PROCESADOS)
        CSV.write(archivo_csv_procesado, df_para_cargar)
        @info "Archivo CSV guardado en: $archivo_csv_procesado"

        # Guardar en base de datos SQLite
        guardar_datos_db(df_para_cargar, bd_ventas)
    end

    @info "Pipeline ejecutado correctamente en modo: $modo"
end

orquestar_pipeline()
