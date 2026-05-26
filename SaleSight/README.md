# 📊 SaleSight – Retail Data Engineering (Julia)

**SaleSight** es un ecosistema de ingeniería de datos para el procesamiento de transacciones retail, implementado íntegramente en **Julia**. Es la traducción directa de la versión Python, conservando la misma arquitectura ETL.

---

## 🗂️ Equivalencias Python → Julia

| Python              | Julia                        |
|---------------------|------------------------------|
| `pandas`            | `DataFrames.jl` + `CSV.jl`  |
| `matplotlib/seaborn`| `Plots.jl` + `StatsPlots.jl`|
| `sqlite3`           | `SQLite.jl` + `DBInterface.jl` |
| `loguru`            | `Logging` (stdlib)           |
| `typer` (CLI)       | `ArgParse.jl`                |
| `tqdm`              | `ProgressMeter.jl`           |
| `kaggle` API        | `HTTP.jl` + `JSON3.jl`      |
| `streamlit`         | `Dash.jl`                    |
| `plotly-express`    | `PlotlyJS.jl`                |
| `zipfile`           | `ZipFile.jl`                 |

---

## 🏗️ Arquitectura del Pipeline (ETL)

```
1. Extracción  → Kaggle API (HTTP.jl)  → data/raw/*.csv
2. Transforma  → Limpieza + Imputación → DataFrames.jl
               → EDA (Gráficos)        → reports/figures/
3. Carga       → SQLite DB             → data/processed/*.db
               → CSV procesado         → data/processed/*.csv
```

---

## 🚀 Inicio Rápido

### 1. Instalar dependencias

```bash
make requirements
# o directamente:
julia --project=. setup.jl
```

### 2. Ejecutar Pipeline

```bash
# Pipeline completo
make data

# Por fases
make ingesta
make transformacion
make carga
```

### 3. Iniciar Dashboard

```bash
make dashboard
# Abre http://localhost:8050 en el navegador
```

### 4. Ejecutar directamente con Julia

```bash
julia --project=. src/pipeline/main.jl --modo completo
julia --project=. src/pipeline/main.jl --modo ingesta
julia --project=. src/pipeline/main.jl --modo transformacion
julia --project=. src/pipeline/main.jl --modo carga
```

---

## 📂 Organización del Proyecto

```
├── src/
│   ├── SaleSight.jl      ← Módulo principal
│   ├── config.jl         ← Rutas y configuración
│   ├── ingest.jl         ← Descarga de Kaggle (E)
│   ├── features.jl       ← Limpieza e imputación (T)
│   ├── graficos.jl       ← Visualizaciones EDA
│   ├── dataset.jl        ← Lectura/escritura SQLite + CSV
│   ├── dashboard.jl      ← Dashboard interactivo (Dash.jl)
│   ├── pipeline/
│   │   └── main.jl       ← Orquestador CLI
│   └── modeling/
│       ├── train.jl      ← Scaffold entrenamiento
│       └── predict.jl    ← Scaffold inferencia
├── data/
│   ├── raw/              ← Datos originales de Kaggle
│   └── processed/        ← processed_data.csv + ventas.db
├── reports/figures/      ← Gráficos PNG generados
├── test/runtests.jl      ← Tests unitarios
├── setup.jl              ← Instalador de dependencias
├── Project.toml
└── Makefile
```

---

## 🎯 Hoja de Ruta

- [x] Ingestión automatizada (Kaggle API).
- [x] Limpieza e imputación de valores faltantes.
- [x] Generación de reportes visuales (EDA).
- [x] Dashboard interactivo (Dash.jl).
- [ ] Implementación de Segmentación RFM.
- [ ] Modelo predictivo de Fuga de Clientes (Churn).

---

*Desarrollado por Josue Ribero Duarte & Stiven Posada Casadiego.*
