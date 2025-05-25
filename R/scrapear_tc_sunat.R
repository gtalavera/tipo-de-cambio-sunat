library(RSelenium)
library(rvest)
library(dplyr)
library(stringr)
library(purrr)
library(glue)
library(lubridate)

# Función para scrapear el tipo de cambio de SUNAT (año actual por defecto)
scrapear_tc_sunat <- function(anio = lubridate::year(Sys.Date())) {
    # Vector con nombres de meses en español
    meses_completos <- c("ene", "feb", "mar", "abr", "may", "jun",
                         "jul", "ago", "sep", "oct", "nov", "dic")
    
    # Determinar qué meses incluir según el año
    if (anio < year(Sys.Date())) {
        meses <- meses_completos
    } else {
        mes_actual <- month(Sys.Date())
        meses <- meses_completos[1:mes_actual]
    }
    
    
    # Iniciar navegador
    rD <- rsDriver(browser = "firefox", port = 4545L, verbose = FALSE)
    remDr <- rD[["client"]]
    
    url <- "http://www.sunat.gob.pe/cl-at-ittipcam/tcS01Alias"
    remDr$navigate(url)
    Sys.sleep(10)
    
    datos <- tibble()
    
    for (mes in meses) {
        cat("Procesando", mes, anio, "...\n")
        
        remDr$executeScript(glue("
      const el = document.getElementById('fecAsistenciaBusq');
      el.value = '{mes} {anio}';
      el.dispatchEvent(new Event('change', {{ bubbles: true }}));
    "))
        
        Sys.sleep(5)
        remDr$findElement("id", "btnBuscarAsistencias")$clickElement()
        Sys.sleep(5)
        
        page <- read_html(remDr$getPageSource()[[1]])
        
        dias <- page %>%
            html_elements(".calendar-day") %>%
            keep(~ !is.null(html_element(.x, ".event")))
        
        datos_mes <- map_dfr(dias, function(td) {
            fecha <- td %>% html_attr("data-date")
            eventos <- td %>% html_elements("div.event")
            
            compra <- eventos %>%
                keep(~ html_element(.x, "strong") %>% html_text2() == "Compra") %>%
                map_chr(html_text2) %>%
                str_extract("\\d+\\.\\d+") %>%
                first()
            
            venta <- eventos %>%
                keep(~ html_element(.x, "strong") %>% html_text2() == "Venta") %>%
                map_chr(html_text2) %>%
                str_extract("\\d+\\.\\d+") %>%
                first()
            
            tibble(
                fecha = fecha,
                compra = as.numeric(compra),
                venta = as.numeric(venta)
            )
        })
        
        datos <- bind_rows(datos, datos_mes)
    }
    
    remDr$close()
    rD$server$stop()
    
    datos_clean <- datos %>%
        group_by(fecha) %>%
        summarise(
            compra = if (all(is.na(compra))) NA_real_ else compra[which(!is.na(compra))[1]],
            venta  = if (all(is.na(venta))) NA_real_ else venta[which(!is.na(venta))[1]],
            .groups = "drop"
        ) %>%
        mutate(fecha = as.Date(substr(fecha, 1, 10)))
    
    todas_las_fechas <- tibble(
        fecha = seq(as.Date(paste0(anio, "-01-01")), as.Date(paste0(anio, "-12-31")), by = "day")
    )
    
    datos_completos <- todas_las_fechas %>%
        left_join(datos_clean, by = "fecha")
    
    write.csv(datos_completos, glue("data/tipo_cambio_sunat_{anio}.csv"), row.names = FALSE)
    
    return(datos_completos)
}
