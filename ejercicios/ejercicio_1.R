set.seed(280572)

x <- c(1,7,10,0,0,5,9,13,2,4,17,18,1,2)

f <- function(x){
    ifelse(x < 10, 1000*sqrt(x), 1000*sqrt(10))
}

# para gráfica de función f verdadera 
x_g <- seq(0,20,0.5)
y_g <- f(x_g)
dat_g <- data.frame(x = x_g, y = y_g)

# simular errores
error <- rnorm(length(x), 0, 500)
y <- f(x) + error
datos_entrena <- data.frame(x=x, y=y)
head(datos_entrena)

#### cambia el valor de span y selecciona una curva
span <- 0.2

curva_1 <- geom_smooth(data=datos_entrena,
                       method = "loess", se=FALSE, color="red", 
                       span=span, 
                       size=1.1, method.args = list(degree = 1))
ggplot(datos_entrena, aes(x=x, y=y)) + geom_point() + curva_1 

### ¿ Cuál es el error?
### Simulamos otra muestra, la de prueba
set.seed(218052272)
x_0 <- sample(0:13, 100, replace = T)
error <- rnorm(length(x_0), 0, 500)
y_0 <- f(x_0) + error
datos_prueba <- data_frame(x = x_0, y = y_0)
datos_prueba

mod_rojo <- loess(y ~ x, data = datos_entrena, span =  span, degree = 1)

preds <- predict(mod_rojo, datos_prueba)
sqrt(mean((preds - datos_prueba$y)^2))
