# Tipo de Cambio SUNAT en R

Este repositorio contiene código en R para extraer automáticamente el tipo de cambio oficial publicado por SUNAT, así como archivos `.csv` con los datos recopilados.

## 📦 Requisitos

Instala las librerías necesarias:

```r
install.packages(c("RSelenium", "rvest", "dplyr", "stringr", "purrr", "glue", "lubridate"))
```

También necesitas tener Firefox y geckodriver instalados y accesibles desde tu PATH.

## 🚀 Uso

```r
source("R/scrapear_tc_sunat.R")

# Para obtener los tipos de cambio del año actual
scrapear_tc_sunat()

# Para obtener los tipos de cambio de otro año
scrapear_tc_sunat(2020)
```

El resultado se guarda automáticamente como un archivo `.csv`en el directorio `data/`

## 📁 Estructura del repo

 - `R/scrapear_tc_sunat.R`: función para scrapear los datos desde SUNAT.  
 - `data/`: contiene los archivos `.csv` por año.
