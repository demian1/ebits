#' GGplot2 PCA plot of different base R objects
#'
#' @param obj    A PCA object (e.g. from prcomp function)
#' @param aes    Aesthetics mapping; use "PC<num>" for principal components
#' @param annot  Additional data.frame with sample annotation
#' @return       ggplot2 object including PCs and sample annotations
pca = function(obj, aes, annot=NULL, biplot=FALSE, ...) {
    UseMethod("pca")
}

pca.DESeqDataSet = function(eset, ...) {
    vst = DESeq2::varianceStabilizingTransformation(eset)
    pca(vst, ...)
}

pca.DESeqTransform = function(vst, aes=ggplot2::aes(x=PC1, y=PC2), annot=NULL, ...) {
    if (is.null(annot))
        annot = as.data.frame(SummarizedExperiment::colData(vst))
    pr = prcomp(t(SummarizedExperiment::assay(vst)))
    pca(pr, aes, annot, ...)
}

pca.prcomp = function(obj, aes=ggplot2::aes(x=PC1, y=PC2), annot=NULL, repel=TRUE,
                      biplot=FALSE, bi_color="red", bi_size=5, bi_arrow=0.2, bi_alpha=0.4) {
    # adapted: https://stackoverflow.com/questions/6578355/plotting-pca-biplot-with-ggplot2
    data = cbind(annot, obj$x)
    rot = data.frame(varnames=rownames(obj$rotation), obj$rotation)
    x = rlang::quo_text(aes[["x"]])
    y = rlang::quo_text(aes[["y"]])
    summ = summary(obj)$importance

    mult = min(
        (max(data[,y]) - min(data[,y])/(max(rot[,y])-min(rot[,y]))),
        (max(data[,x]) - min(data[,x])/(max(rot[,x])-min(rot[,x])))
    )
    rot = transform(rot,
        v1 = .7 * mult * rot[[x]],
        v2 = .7 * mult * rot[[y]]
    )

    p = ggplot(data=data, mapping=aes)
    if (grepl("^PC[0-9]+$", x))
        p = p + xlab(sprintf("%s (%.0f%%)", x, 100*summ["Proportion of Variance", x]))
    if (grepl("^PC[0-9]+$", y))
        p = p + ylab(sprintf("%s (%.0f%%)", y, 100*summ["Proportion of Variance", y]))

    if (repel) {
        textfun = function(...) ggrepel::geom_text_repel(..., min.segment.length=Inf)
    } else {
        textfun = geom_text
    }

    if (biplot) {
        p = p + textfun(data=rot, aes(x=v1, y=v2, label=varnames),
                size = bi_size, vjust=1, color=bi_color) +
            geom_segment(data=rot, aes(x=0, y=0, xend=v1, yend=v2), alpha=bi_alpha,
                arrow=arrow(length=unit(bi_arrow,"cm")), color=bi_color)
    }

    p
}

pca.default = function(...) {
    stop("only `prcomp` and DESeq2 supported for now")
}

if (is.null(module_name())) {
    library(ggplot2)
    obj = prcomp(iris[1:4])
    pca(obj, aes(x=PC1, y=PC2, color=Species), annot=iris["Species"], biplot=TRUE) +
        geom_point()
}
