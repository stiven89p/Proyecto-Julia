module Config

using Logging

# Rutas base del proyecto (config.jl está en src/, la raíz está un nivel arriba)
const RUTA_RAIZ = dirname(@__DIR__)

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
