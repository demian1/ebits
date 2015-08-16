library(ggplot2)
library(reshape2)
library(gridExtra)
library(RColorBrewer)
library(pheatmap)
library(plotrix)
.b = import('../base')
import('./helpers', attach=TRUE)
color = import('./color')
label = import('./label')

#' Draw a volcano plot from calculated associations
#'
#' @param df         A data.frame obtained from the stats module
#' @param base.size  Scaling factor for the points drawn
#' @param p          Line between significant and insignificant associations
#' @param ceil       Minimum p-value to set top associations to; default: 0, no filter
#' @param xlim       Limits along the horizontal axis; default: fit data
#' @param ylim       Limits along the vertical axis; default: fit data
#' @param simplify   Drop some insignificant points and labels to reduce file size
#' @return           A ggplot2 object of the volcano plot
volcano = function(df, base.size=1, p=0.05, ceil = 0,
        xlim=c(NA,NA), ylim=c(NA,NA), simplify=TRUE) {
    if (!'label' %in% colnames(df))
        stop("Column 'label' not found. You need to specify a label for your points")
    if (!'color' %in% colnames(df))
        stop("Column 'color' not found. Did you call plt$color$...?")

    # remove insignificant points outside x limits, adjust size
    df = df %>%
        filter(.y < p | abs(.x)<max(abs(.x[.y<p]), na.rm=TRUE)) %>%
        mutate(size = size*base.size)

    # set very low p-values to the cutoff value and label point
    pmin = df$.y < ceil
    if (any(pmin)) {
        df[pmin,] = mutate(df[pmin,],
            label = paste0(label, " (p < 1e", ceiling(log10(.y)), ")"),
            .y = ceil)
    }

    # make sure we don't plot too many insignificant points
    if (simplify && sum(df$.y > p) > 300) {
        set.seed(123456)
        idx = which(df$.y > .b$minN(df$.y[df$.y > p], 100))
        keep = sample(idx, size=200, replace=FALSE, prob=1-df$.y[idx])
        df$.y[setdiff(idx, keep)] = NA
        df$label[idx] = ""
    }

    # and do the actual plot
    ggplot(df, aes(x = .x, y = .y)) + 
        scale_y_continuous(trans = reverselog_trans(10),
                           label = scientific_10,
                           limits = ylim) +
        scale_x_continuous(limits = xlim) +
        geom_point(size = sqrt(df$size), colour = df$color, na.rm = TRUE) +
        geom_vline(xintercept = 0, lwd = 0.3) +
        geom_hline(yintercept = p, lwd = 0.3, linetype = 2) +
#        annotate("text", x=min(df$.x), y=0.05, hjust=1, vjust=2, 
#                 size=3.5, label="0.05", colour="black") +
        xlab("Effect size") + 
        ylab("Adjusted P-value") +
        theme_bw() +
        geom_text(mapping = aes(x = .x, y = .y, label = label), 
                  colour = "#353535", size = 2, vjust = -1, na.rm = TRUE)
}