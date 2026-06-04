module Config
using Logging, DotEnv

# Rutas base del proyecto (config.jl está en src/, la raíz está un nivel arriba)
const RUTA_RAIZ = dirname(@__DIR__)

function __init__()
    env_path = joinpath(RUTA_RAIZ, ".env")
    if isfile(env_path)
        DotEnv.load!(env_path)
        @info "Variables de entorno cargadas desde .env"
    else
        @warn "No se encontró archivo .env en $RUTA_RAIZ"
    end
end

function kaggle_token()::String
    token = get(ENV, "KAGGLE_API_TOKEN", "")
    isempty(token) && error("KAGGLE_API_TOKEN no está definido en .env")
    return token
end

# Directorios de datos
const CARPETA_DATOS     = joinpath(RUTA_RAIZ, "data")
const DATOS_BRUTOS      = joinpath(CARPETA_DATOS, "raw")
const DATOS_INTERMEDIOS = joinpath(CARPETA_DATOS, "interim")
const DATOS_PROCESADOS  = joinpath(CARPETA_DATOS, "processed")
const DATOS_EXTERNOS    = joinpath(CARPETA_DATOS, "external")

# Modelos y reportes
const CARPETA_MODELOS  = joinpath(RUTA_RAIZ, "models")
const CARPETA_REPORTES = joinpath(RUTA_RAIZ, "reports")
const RUTA_GRAFICOS    = joinpath(CARPETA_REPORTES, "figures")

# Configuración de base de datos
const NOMBRE_DB = "ventas_procesadas.db"

@info "Ruta raíz del proyecto: $RUTA_RAIZ"

end
