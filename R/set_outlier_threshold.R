#' Set a threshold for outlier detection
#'
#' @description This function forecasts a boundary for the typical behaviour using a representative sample
#' of the typical behaviour of a given system. An approach based on extreme value theory is used for this boundary
#' prediction process.
#' @param pc_pcnorm The scores of the first two pricipal components returned by \code{\link{get_pc_space}}
#' @param p_rate False positive rate. Default value is set to 0.001
#' @param trials Number of trials to generate the extreme value distirbution. Default value is set to 500.
#' @return Returns a threshold to determine outlying series in the next window  consists with a collection of
#' time series.
#' @seealso \code{\link{get_pc_space}}
#' @export
#' @importFrom ks Hscv
#' @importFrom MASS mvrnorm
#' @references Clifton, D. A., Hugueny, S., & Tarassenko, L. (2011). Novelty detection with multivariate extreme value statistics.
#' Journal of signal processing systems, 65 (3),371-389.
#' @examples
set_outlier_threshold <- function(pc_pcnorm, p_rate = 0.001, trials = 500) {

    # Calculating the density region for typical data
    H_scv <- ks::Hscv(x = pc_pcnorm)
    fhat2 <- ks::kde(x = pc_pcnorm, H = H_scv, compute.cont = TRUE)

    # generating data to find the threshold value
    fun2 <- function(x) {
        return(MASS::mvrnorm(n = 1, mu = x, Sigma = H_scv))
    }
    m <- nrow(pc_pcnorm)
    xtreme_fx <- numeric(trials)
    for (i in 1:trials) {
        s <- sample(1:m, size = m, replace = T)
        mean_s <- pc_pcnorm[s, ]
        new_data_list <- lapply(as.list(data.frame(t(mean_s))), FUN = fun2)
        new_data <- data.frame(matrix(unlist(new_data_list), nrow = m, byrow = T), stringsAsFactors = FALSE)
        fhat <- kde(x = pc_pcnorm, H = H_scv, compute.cont = TRUE, eval.points = new_data)
        xtreme_fx[i] <- min(fhat$estimate)
    }
    # op <- par(mfrow = c(2, 1)) hist(xtreme_fx) Apply Psi transformation
    k <- 1/(2 * pi)
    psi_trans <- ifelse(xtreme_fx < k, (-2 * log(xtreme_fx) - 2 * log(2 * pi))^0.5, 0)
    p <- sum(!(psi_trans == 0))/length(psi_trans)
    # hist(psi_trans)
    y <- -log(-log(1 - p_rate * p))
    cm <- sqrt(2 * log(m)) - ((log(log(m)) + log(4 * pi))/(2 * sqrt(2 * log(m))))
    dm <- 1/(sqrt(2 * log(m)))
    t <- cm + y * dm
    threshold_fnx <- exp(-((t^2) + 2 * log(2 * pi))/2)

    return(threshold_fnx)
}