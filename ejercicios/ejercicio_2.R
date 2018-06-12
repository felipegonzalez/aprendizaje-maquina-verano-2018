
library(tidyverse)

# leer datos
housing <- read_table('./datos/housing/housing.data', 
                      col_names = FALSE)
lineas <- readLines('./datos/housing/housing.names', n = -1)
lineas
lineas_1 <- str_subset(lineas, '\\s+[0-9]+.\\s')
nombres <- str_match(lineas_1, pattern = '\\s+[0-9]+.\\s(\\w+)')[4:17,2]
names(housing) <- nombres
housing


# cálculo de error
rss_calc <- function(x, y){
  # x es un data.frame o matrix con entradas
  # y es la respuesta
  rss_fun <- function(beta){
    # esta funcion debe devolver rss
    y_hat <- as.matrix(cbind(1,x)) %*% beta
    e <- y - y_hat
    rss <- 0.5*sum(e^2)
    rss
  }
  rss_fun
}

# cálculo de gradiente
grad_calc <- function(x, y){
  # devuelve una función que calcula el gradiente para 
  # parámetros beta   
  # x es un data.frame o matrix con entradas
  # y es la respuesta
  grad_fun <- function(beta){
      f_beta <- as.matrix(cbind(1, x)) %*% beta
      e <- y - f_beta
      gradiente <- -apply(t(cbind(1,x)) %*% e, 1, sum)
      names(gradiente)[1] <- 'Intercept'
      gradiente
    }
   grad_fun
}

# función para hacer descenso
descenso <- function(n, z_0, eta, h_grad){
  # esta función calcula n iteraciones de descenso en gradiente 
  z <- matrix(0,n, length(z_0))
  z[1, ] <- z_0
  for(i in 1:(n-1)){
    z[i+1,] <- z[i,] - eta*h_grad(z[i,])
  }
  z
}

# separar muestra de entrenamiento y prueba

set.seed(923)
housing$unif <- runif(nrow(housing), 0, 1)
housing <- arrange(housing, unif)
housing$id <- 1:nrow(housing)
dat_e <- housing[1:400,]
dat_p <- housing[400:nrow(housing),]
dim(dat_e)
dim(dat_p)


# Normalizar entradas


dat_norm <- housing %>% select(-id, -MEDV, -unif) %>%
  gather(variable, valor, CRIM:LSTAT) %>%
  group_by(variable) %>% summarise(m = mean(valor), s = sd(valor))
dat_norm

normalizar <- function(datos, dat_norm){
  datos_salida <- datos %>% select(-unif) %>%
    gather(variable, valor, CRIM:LSTAT) %>%
    left_join(dat_norm) %>%
    mutate(valor_s = (valor - m)/s) %>%
    select(id, MEDV, variable, valor_s) %>%
    spread(variable, valor_s)
}
dat_e_norm <- normalizar(dat_e, dat_norm)
dat_p_norm <- normalizar(dat_p, dat_norm)


# Ajustar modelos

# preparación
x_ent <- dat_e_norm %>% select(-id, -MEDV)
y_ent <- dat_e_norm$MEDV
rss <- rss_calc(x_ent, y_ent)
grad <- grad_calc(x_ent, y_ent) 

# Iteraciones de descenso - selecciona valores de paso y número
# de iteraciones apropiado
eta <- 0.0 # pon algo mayor que cero
n_iteraciones <- 10 # incrementa
iteraciones <- descenso(n_iteraciones, rep(0, ncol(x_ent)+1), eta, grad)
rss_iteraciones <- apply(iteraciones, 1, rss)
plot(rss_iteraciones)


# tomamos última iteración
beta <- iteraciones[nrow(iteraciones), ]
dat_coef <- data_frame(variable = c('Intercept',colnames(x_ent)), beta = beta)
quantile(y_ent)
dat_coef %>% mutate(beta = round(beta, 2)) %>% arrange(desc(abs(beta)))


# Comparamos con *lm* para checar nuestro trabajo:


lm(MEDV ~ ., data= dat_e_norm %>% select(-id))



# Ahora evaluamos con la muestra de prueba:


calcular_preds <- function(x, beta){
  cbind(1, as.matrix(x))%*%beta
}
x_pr <- dat_p_norm %>% select(-id, -MEDV)
y_pr <- dat_p_norm$MEDV
preds <- calcular_preds(x_pr, beta)
qplot(x = preds, y = y_pr) + geom_abline(intercept = 0, slope = 1)
error_prueba <- mean((y_pr-preds)^2)
sqrt(error_prueba)


#Este número podemos interpretarlo en la escala de la variable que queremos predecir
#(está en miles de dólares).

#También podemos evaluar otro tipo de errores que pueden interpretarse
#más fácilmente, por ejemplo, la media del
#las diferencias en valores absolutos:

mean(abs(y_pr-preds))

