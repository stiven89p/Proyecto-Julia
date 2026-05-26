################################################################################
# GLOBALES                                                                      #
################################################################################

PROJECT_NAME = SaleSight
JULIA = julia --project=.

################################################################################
# COMANDOS                                                                      #
################################################################################

## Instalar dependencias del proyecto con Julia
.PHONY: requirements
requirements:
	$(JULIA) setup.jl

## Limpiar archivos temporales y compilados
.PHONY: clean
clean:
	rm -rf Manifest.toml
	find . -name "*.ji" -delete
	find . -name "*.so" -delete

## Ejecutar tests unitarios
.PHONY: test
test:
	$(JULIA) -e "using Pkg; Pkg.test()"

################################################################################
# REGLAS DEL PROYECTO                                                           #
################################################################################

## Ejecutar Pipeline ETL completo (Extraer, Transformar/EDA, Cargar)
.PHONY: data
data:
	$(JULIA) src/pipeline/main.jl --modo completo

## Solo fase de Ingesta (Extracción)
.PHONY: ingesta
ingesta:
	$(JULIA) src/pipeline/main.jl --modo ingesta

## Solo fase de Transformación + EDA
.PHONY: transformacion
transformacion:
	$(JULIA) src/pipeline/main.jl --modo transformacion

## Solo fase de Carga
.PHONY: carga
carga:
	$(JULIA) src/pipeline/main.jl --modo carga

## Iniciar el dashboard interactivo (Dash.jl en puerto 8050)
.PHONY: dashboard
dashboard:
	$(JULIA) -e "using SaleSight; SaleSight.Dashboard.iniciar_dashboard()"

################################################################################
# AYUDA                                                                         #
################################################################################

.DEFAULT_GOAL := help

help:
	@echo ""
	@echo "Reglas disponibles:"
	@echo ""
	@echo "  requirements     Instalar dependencias Julia"
	@echo "  data             Pipeline ETL completo"
	@echo "  ingesta          Solo fase de Extracción"
	@echo "  transformacion   Solo fase de Transformación + EDA"
	@echo "  carga            Solo fase de Carga"
	@echo "  dashboard        Iniciar dashboard web"
	@echo "  test             Ejecutar tests"
	@echo "  clean            Limpiar archivos temporales"
	@echo ""
