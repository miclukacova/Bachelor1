#Packages
library(tidyverse)
library(readr)
library(infer)
library(foreign)
library(xtable)
library(stargazer)


#Getting data
leafs <- read.csv('Data/leafs.csv')
wood <- read.csv("Data/wood.csv")
roots <- read.csv("Data/roots.csv")

#OLS estimates
par_ols_l <- c(0.2693082, 0.9441130)
par_ols_w <- c(3.944818, 1.106841)
par_ols_r <- c(0.8339087, 1.1730237)

#Loss function
MSE_NLR <- function(par, data){
  with(data, sum((Kgp-par[1]*Sc^par[2])^2)/nrow(data))
}



#c("Nelder-Mead", "BFGS", "CG", "L-BFGS-B", "SANN", "Brent")


#------------------------------------Heatmap------------------------------------

#Function for creating grid

creating_grid <- function(data, par_ols) {
  hej <- TRUE
  for (i in seq(0, par_ols[1]*7, length.out = 50)){
      if (hej){
        grid <- tibble(b = rep(i,50), a = seq(0.2, par_ols[2]*1.7, length.out = 50))
        hej <- FALSE
      }
      else {
        for (j in seq(0.2, par_ols[2]*1.7, length.out = 50)){
          grid <- add_row(grid, b = i, a = j)
        }
      }
    }
  return(grid)
}

heat_map <- function(data, par_ols, Title){
  my_grid <- creating_grid(data, par_ols)
  
  #Calculating MSE along grid
  mse <- c()
  for (i in (1:nrow(my_grid))){
    mse <- append(mse, MSE_NLR(data = data, par = c(my_grid$b[i], my_grid$a[i])))
  }
  
  #Finding breaks
  breaks_data <- sort(mse)[c(seq(1,length(mse)/3, length.out = 7),seq(length(mse)/3,length(mse), length.out = 2))]
  
  #Transforming data
  plot_data <- data.frame(a = my_grid$a, b = my_grid$b, mse = mse)
  
  #return(plot_data)
  
  #Plot
  p <- ggplot(data = plot_data, aes(x = a, y = b, z = mse)) +
    geom_point(aes(x=par_ols[2], y = par_ols[1]), color = "red", size = 3)+
    stat_contour_filled(breaks = breaks_data) +
    theme_bw()+
    xlab(expression(alpha))+
    ylab(expression(beta))+
    labs(title = Title)+
    theme(text = element_text(family = "serif"), plot.title = element_text(size = 19),
          axis.title = element_text(size = 15), axis.text = element_text(size = 13), legend.title = element_text(size = 13)
          ,aspect.ratio = 1)
  
  return(p)
}


heat_map(leafs, par_ols_l, "Leafs")
heat_map(wood, par_ols_w, "Wood")
heat_map(roots, par_ols_r, "Roots")


#-------------------Residual plots needed for bootstrap:

par_NLR_l <- model_NLR(leafs, starting_point_leafs)
par_NLR_w <- model_NLR(wood, starting_point_wood)
par_NLR_r <- model_NLR(roots, starting_point_roots)

fitted_NLR_l <- par_NLR_l$beta*leafs$Sc^par_NLR_l$alpha
fitted_NLR_w <- par_NLR_w$beta*wood$Sc^par_NLR_w$alpha
fitted_NLR_r <- par_NLR_r$beta*roots$Sc^par_NLR_r$alpha

res_NLR_l <- log(leafs$Kgp)-log(fitted_NLR_l)
res_NLR_w <- log(wood$Kgp/fitted_NLR_w)
res_NLR_r <- log(roots$Kgp/fitted_NLR_r)

res_plot_NLR_l <- data.frame(fitted = log(fitted_NLR_l), res = res_NLR_l)
res_plot_NLR_w <- data.frame(fitted = log(fitted_NLR_w), res = res_NLR_w)
res_plot_NLR_r <- data.frame(fitted = log(fitted_NLR_r), res = res_NLR_r)


#Residual plots

ggplot(res_plot_NLR_l, aes(x = fitted, y = res)) + 
  geom_point(color = 'darkolivegreen', fill = 'darkolivegreen3', alpha = 0.6, shape = 21) +  
  theme_bw() +
  xlab('Fitted values') + 
  ylab('Residuals')+
  geom_smooth(method = lm, se = FALSE, formula = y ~ x, color = "hotpink")+
  labs(title = "Leafs")+
      theme(legend.position = "none", plot.title = element_text(size = 17),
          axis.title = element_text(size = 13))

ggplot(res_plot_NLR_w,aes(x = fitted, y = res)) + 
  geom_point(color = 'darkolivegreen', fill = 'darkolivegreen3', alpha = 0.6, shape = 21) +  
  theme_bw() +
  xlab('Fitted values') + 
  ylab('Residuals')+
  geom_smooth(method = lm, se = FALSE, formula = y ~ x, color = "hotpink")+
  labs(title = "Wood")+
  theme(legend.position = "none", plot.title = element_text(size = 17),
        axis.title = element_text(size = 13))

ggplot(res_plot_NLR_r, aes(x = fitted, y = res)) + 
  geom_point(color = 'darkolivegreen', fill = 'darkolivegreen3', alpha = 0.6, shape = 21) +  
  theme_bw() +
  xlab('Fitted values') + 
  ylab('Residuals')+
  geom_smooth(method = lm, se = FALSE, formula = y ~ x, color = "hotpink")+
  labs(title = "Roots")+
  theme(legend.position = "none", plot.title = element_text(size = 17),
        axis.title = element_text(size = 13))


#------------Standardized residual plots:
#Residual plots

sd_res_NLR_l <- res_NLR_l/sd(res_NLR_l)
sd_res_NLR_w <- res_NLR_w/sd(res_NLR_w)
sd_res_NLR_r <- res_NLR_r/sd(res_NLR_r)

sd_res_plot_NLR_l <- data.frame(fitted = log(fitted_NLR_l), res = sd_res_NLR_l)
sd_res_plot_NLR_w <- data.frame(fitted = fitted_NLR_w, res = sd_res_NLR_w)
sd_res_plot_NLR_r <- data.frame(fitted = fitted_NLR_r, res = sd_res_NLR_r)


ggplot(sd_res_plot_NLR_l, aes(x = fitted, y = res)) + 
  geom_point(color = 'darkolivegreen', fill = 'darkolivegreen3', alpha = 0.6, shape = 21) +  
  theme_bw() +
  xlab('Fitted values') + 
  ylab('Residuals')+
  geom_smooth(method = lm, se = FALSE, formula = y ~ x, color = "hotpink")+
  labs(title = "Standardized Residual plot")

ggplot(res_plot_NLR_w,aes(x = fitted, y = res)) + 
  geom_point(color = 'darkolivegreen', fill = 'darkolivegreen3', alpha = 0.6, shape = 21) +  
  theme_bw() +
  xlab('Fitted values') + 
  ylab('Residuals')+
  geom_smooth(method = lm, se = FALSE, formula = y ~ x, color = "hotpink")+
  labs(title = "Residual plot")

ggplot(res_plot_NLR_r, aes(x = fitted, y = res)) + 
  geom_point(color = 'darkolivegreen', fill = 'darkolivegreen3', alpha = 0.6, shape = 21) +  
  theme_bw() +
  xlab('Fitted values') + 
  ylab('Residuals')+
  geom_smooth(method = lm, se = FALSE, formula = y ~ x, color = "hotpink")+
  labs(title = "Residual plot")


#------------------------------------Nelson-Mead optimizer----------------------

grid_l <- creating_grid(leafs, par_ols_l)
grid_w <- creating_grid(wood, par_ols_w)
grid_r <- creating_grid(roots, par_ols_r)

ggplot(grid_r, aes(x = a, y = b)) +
  geom_point(size = 0.9)+
  geom_point(aes(x=par_ols_r[2], y = par_ols_r[1]), color = "red", size = 4)+
  geom_text(aes(x=par_ols_r[2], y = par_ols_r[1]), label = "OLS", hjust = -.5, color = "red", size = 5)+
  theme_bw()+
  labs(title = "Roots")

ggplot(grid_w, aes(x = a, y = b)) +
  geom_point(size = 0.9)+
  geom_point(aes(x=par_ols_w[2], y = par_ols_w[1]), color = "red", size = 4)+
  geom_text(aes(x=par_ols_w[2], y = par_ols_w[1]), label = "OLS", hjust = -.5, color = "red", size = 5)+
  theme_bw()


grid_values <- function(data, grid) {
  hej <- TRUE
  for (i in (1:nrow(grid))){
    c <- c(grid[i,1], grid[i,2])
    if (hej){
      NLR_loop <- optim(par = c, fn = MSE_NLR, data = data)
      par_grid <- data.frame(b = grid[i,1],
                             a = grid[i,2],
                             MSE = NLR_loop$value)
      hej <- FALSE
    }
    else{
      NLR_loop <- optim(par = c, fn = MSE_NLR, data = data)
      par_grid <- par_grid %>% add_row(b = as.numeric(grid[i,1]),
                                       a = as.numeric(grid[i,2]),
                                       MSE = NLR_loop$value)
    }
  }
  
  return(par_grid)
}

a <- grid_values(leafs, grid_l)
breaks_leaf <- c(min(a$MSE), 4, 4.1, 4.2, 4.3, max(a$MSE))
ggplot(data = a, aes(x = a, y = b, z = MSE)) +
  stat_contour_filled(breaks = breaks_leaf) +
  theme_bw()+
  labs(title = "Leafs")
  
b <- grid_values(wood, grid_w)
breaks_wood <- c(min(b$MSE), 6589, 6595, 7000, 7300, max(b$MSE))
ggplot(data = b, aes(x = a, y = b, z = MSE)) +
  stat_contour_filled(breaks = breaks_wood) +
  theme_bw()+
  labs(title = "Wood")

c <- grid_values(roots, grid_r)
breaks_roots <- c(min(c$MSE), 1412, 1420, 1500, 1600, 1700, max(c$MSE))
ggplot(data = c, aes(x = a, y = b, z = MSE)) +
  stat_contour_filled(breaks = breaks_roots) +
  theme_bw()+
  labs(title = "Roots")


#Usuccesfuldt forsøg med sejere heat maps

b <- heat_map(leafs, par_ols_l, "Leafs")
d <-  heat_map(leafs, par_ols_l, "Leafs")

breaks_data <- sort(d$mse)[c(seq(1,nrow(d)/3, length.out = 10),seq(nrow(d)/2,nrow(d), length.out = 2))]

ggplot(data = d, aes(x = a, y = b, z = mse))  + 
  geom_raster(aes(fill = mse)) +
  geom_contour(colour = "white", breaks = breaks_data)

?geom_contour
+
  theme_bw()+
  geom_raster(aes(fill = density)) +
  geom_contour(colour = "white")

heat_map(wood, par_ols_w, "Wood")
heat_map(roots, par_ols_r, "Roots")

?stat_contour_filled

#Appendix plots


ggplot(creating_grid(leafs,par_ols_l), aes(x = a, y = b)) +
  geom_point(size = 0.9)+
  geom_point(aes(x=par_ols_l[2], y = par_ols_l[1]), color = "red", size = 4)+
  geom_text(aes(x=par_ols_l[2], y = par_ols_l[1]), label = "OLS", hjust = -.5, color = "red", size = 5)+
  theme_bw()+
  labs(title = "Leafs")

ggplot(creating_grid(wood,par_ols_w), aes(x = a, y = b)) +
  geom_point(size = 0.9)+
  geom_point(aes(x=par_ols_w[2], y = par_ols_w[1]), color = "red", size = 4)+
  geom_text(aes(x=par_ols_w[2], y = par_ols_w[1]), label = "OLS", hjust = -.5, color = "red", size = 5)+
  theme_bw()+
  labs(title = "Wood")


ggplot(creating_grid(roots,par_ols_w), aes(x = a, y = b)) +
  geom_point(size = 0.9)+
  geom_point(aes(x=par_ols_r[2], y = par_ols_r[1]), color = "red", size = 4)+
  geom_text(aes(x=par_ols_r[2], y = par_ols_r[1]), label = "OLS", hjust = -.5, color = "red", size = 5)+
  theme_bw()+
  labs(title = "Roots")
