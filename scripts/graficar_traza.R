acumular <- function(datos){
    acumulados <- datos %>% select(tipo) %>%
        group_by(tipo) %>%
        mutate(num = 1:n()) %>%
        mutate(n = map(num, ~1:.x)) %>%
        unnest %>% select(tipo, num,n)
    datos_n <- datos %>% group_by(tipo) %>%
        mutate(n = 1:n())
    acumulados <- acumulados %>% left_join(datos_n) %>% 
        select(-n)
    acumulados
}

graficar_traza <- function(iteraciones){
    iter <- acumular(iteraciones)
    p <- iter %>%
         plot_ly(
            x = ~beta_1,
            y = ~beta_2,
            color = ~tipo,
            frame = ~num,
            type = 'scatter',
            mode = 'lines+markers',
            showlegend = T,
            marker = list(size = 8)) %>%
        layout(
            xaxis = list(
                zeroline = FALSE),
            yaxis = list(
                zeroline = FALSE)
        ) %>%
        animation_opts(
            frame = 100, 
            transition = 0, 
            redraw = FALSE
        ) 
    p
}


graficar_devianza <- function(iter, dev_ent, dev_valid){
    dat_dev <- iter %>% 
        group_by(tipo) %>% mutate(iteracion = 1:n()) %>%
        ungroup %>%
        mutate(entrena = apply(iter %>% select(-tipo), 1, dev_ent)) %>%
        mutate(valida = apply(iter %>% select(-tipo), 1, dev_valid)) %>%
        gather(muestra, devianza, entrena:valida)
    
    p <- ggplot(dat_dev, 
                aes(x=iteracion, y=devianza, colour=tipo)) + geom_line() +
        geom_point() + facet_wrap(~muestra, ncol = 1)
    plot(p)
    dat_dev
}