# Shared, inspectable classroom helpers. Dependencies: base R and ggplot2.
# Each function is intentionally small; its analytical choices are documented.
course_stopwords <- strsplit(paste(
  "a an the and or but if then else of in on at to for from by with as",
  "is am are was were be been being it its this that these those",
  "i me my we us our you your he him his she her they them their",
  "have has had do does did will would can could shall should may might",
  "there here which who whom what when where how also very just so than",
  "into about over under up down out all some any each both other such",
  "it's i'm you're he's she's they're we've i've don't doesn't didn't mr"
), " +")[[1]]
# Deliberately retain no/not/never: stopword removal is not sentiment analysis.

word_tokens <- function(text, numbers = FALSE, stop_words = character()) {
  text <- tolower(gsub("\u2019", "'", enc2utf8(text), fixed = TRUE))
  pattern <- if (numbers) "[a-z]+(?:'[a-z]+)?|[0-9]+" else "[a-z]+(?:'[a-z]+)?"
  out <- regmatches(text, gregexpr(pattern, text, perl = TRUE))
  lapply(out, function(x) x[(nchar(x) >= 2 | grepl("^[0-9]+$", x)) &
                           !x %in% stop_words])
}

load_text_docs <- function(file) {
  d <- read.csv(file, stringsAsFactors = FALSE, encoding = "UTF-8")
  stopifnot(all(c("document_id", "category", "text", "source_id") %in% names(d)),
            !anyNA(d), !anyDuplicated(d$document_id), !anyDuplicated(d$text),
            all(nzchar(d$text)))
  d$category <- factor(d$category)
  d$raw_tokens <- lengths(word_tokens(d$text))
  d
}

term_counts <- function(tokens) {
  z <- sort(table(unlist(tokens, use.names = FALSE)), decreasing = TRUE)
  data.frame(term = names(z), count = as.integer(z), row.names = NULL)
}

make_dtm <- function(tokens, ids, min_df = 2L) {
  stopifnot(length(tokens) == length(ids), !anyDuplicated(ids), min_df >= 1)
  df <- table(unlist(lapply(tokens, unique), use.names = FALSE))
  vocabulary <- sort(names(df)[df >= min_df])
  if (!length(vocabulary)) stop("No terms survive this document-frequency threshold")
  C <- matrix(0, length(ids), length(vocabulary), dimnames = list(ids, vocabulary))
  for (i in seq_along(tokens)) {
    tab <- table(factor(tokens[[i]], levels = vocabulary))
    C[i, ] <- as.numeric(tab)
  }
  C
}

text_representation <- function(C) {
  if (any(rowSums(C) == 0)) stop("Empty document after vocabulary filtering")
  P <- C / rowSums(C)
  idf <- log(nrow(C) / colSums(C > 0))
  W <- sweep(P, 2, idf, "*")
  norms <- sqrt(rowSums(W^2))
  if (any(norms == 0)) stop("Zero TF-IDF vector: no distinctive retained term")
  list(C = C, P = P, idf = idf, W = W, U = W / norms,
       H = sqrt(P) / sqrt(2))
}

prepare_text <- function(docs, min_df = 2L) {
  tok <- word_tokens(docs$text, stop_words = course_stopwords)
  C <- make_dtm(tok, docs$document_id, min_df)
  # All comparisons use the same retained rows and vocabulary. Document exclusions
  # occur once, before any representation or distance is compared.
  good <- rowSums(C) > 0
  removed <- docs$document_id[!good]
  C <- C[good, , drop = FALSE]
  if (length(removed)) message("Empty documents excluded: ", paste(removed, collapse = ", "))
  if (nrow(C) < 3L) stop("Need at least three nonempty documents")
  list(docs = docs[good, , drop = FALSE], tokens = tok[good],
       removed = removed, representation = text_representation(C))
}

sentence_ngrams <- function(text, n = 2L, filter_stop = TRUE) {
  stopifnot(n >= 2L)
  sentences <- unlist(strsplit(text, "(?<=[.!?])\\s+|[\\r\\n]+", perl = TRUE))
  sequences <- lapply(word_tokens(sentences), function(w) {
    if (length(w) < n) return(character())
    vapply(seq_len(length(w) - n + 1L), function(i) {
      chunk <- w[i:(i + n - 1L)]
      if (filter_stop && any(chunk %in% course_stopwords)) return(NA_character_)
      paste(chunk, collapse = " ")
    }, character(1))
  })
  out <- unlist(sequences, use.names = FALSE)
  out[!is.na(out)]
}

top_bars <- function(values, title = "", n = 15L, ylab = "Weight") {
  values <- sort(values[is.finite(values) & values > 0], decreasing = TRUE)
  values <- head(values, n)
  d <- data.frame(term = factor(names(values), levels = rev(names(values))),
                  weight = as.numeric(values))
  ggplot2::ggplot(d, ggplot2::aes(term, weight)) +
    ggplot2::geom_col(fill = "#0072B2") + ggplot2::coord_flip() +
    ggplot2::labs(title = title, x = NULL, y = ylab)
}

draw_cloud <- function(values, n = 25L, seed = 13L) {
  z <- head(sort(values[is.finite(values) & values > 0], decreasing = TRUE), n)
  if (!length(z)) stop("No positive word weights")
  old <- par(mar = c(0, 0, 1, 0)); on.exit(par(old))
  plot.new(); plot.window(xlim = c(-1, 1), ylim = c(-1, 1), asp = 1)
  set.seed(seed)
  boxes <- matrix(numeric(), ncol = 4)
  for (j in seq_along(z)) {
    size <- 0.6 + 1.4 * sqrt(z[j] / max(z))
    w <- strwidth(names(z)[j], cex = size) * 1.18
    h <- strheight(names(z)[j], cex = size) * 1.5
    offset <- runif(1, 0, 2 * pi)
    placed <- FALSE
    for (step in 0:4000) {
      theta <- step * 0.16 + offset; radius <- 0.00025 * step
      x <- radius * cos(theta); y <- radius * sin(theta)
      b <- c(x - w/2, x + w/2, y - h/2, y + h/2)
      collision <- nrow(boxes) && any(b[1] < boxes[,2] & b[2] > boxes[,1] &
                                      b[3] < boxes[,4] & b[4] > boxes[,3])
      if (all(abs(b) < 0.98) && !collision) {
        text(x, y, names(z)[j], cex = size, col = "#0072B2")
        boxes <- rbind(boxes, b); placed <- TRUE; break
      }
    }
    if (!placed) warning("Word did not fit: ", names(z)[j])
  }
  invisible(z)
}

map_diagnostics <- function(D, fit) {
  ev <- fit$eig; tol <- max(abs(ev)) * 1e-9
  original <- as.vector(D); mapped <- as.vector(dist(fit$points))
  data.frame(positive_inertia_2D = sum(ev[1:2]) / sum(ev[ev > tol]),
             negative_inertia_fraction = sum(abs(ev[ev < -tol])) / sum(abs(ev)),
             distance_correlation = cor(original, mapped),
             relative_RMSE = sqrt(mean((mapped-original)^2) / mean(original^2)))
}

text_maps <- function(rep) {
  distances <- list(Counts = dist(rep$C), Proportions = dist(rep$P),
                    TFIDF_chord = dist(rep$U), Hellinger = dist(rep$H))
  fits <- lapply(distances, function(D) cmdscale(D, k = 2, eig = TRUE))
  diagnostics <- do.call(rbind, lapply(names(fits), function(nm)
    cbind(Method = nm, map_diagnostics(distances[[nm]], fits[[nm]]))))
  list(distances = distances, fits = fits, diagnostics = diagnostics)
}

plot_text_map <- function(fit, docs, variable = "category", title = "") {
  stopifnot(identical(rownames(fit$points), docs$document_id))
  d <- data.frame(x = fit$points[,1], y = fit$points[,2],
                  group = docs[[variable]])
  ggplot2::ggplot(d, ggplot2::aes(x, y, colour = group)) +
    ggplot2::geom_point(alpha = 0.7, size = 1.8) + ggplot2::coord_equal() +
    ggplot2::labs(x = "Dimension 1", y = "Dimension 2", colour = variable,
                  title = title)
}

nearest_ids <- function(D, id, k = 3L) {
  z <- as.matrix(D)[id, ]; z <- z[names(z) != id]
  head(sort(z), k)
}

ca_from_counts <- function(C) {
  stopifnot(all(C >= 0), all(rowSums(C) > 0), all(colSums(C) > 0))
  Q <- C / sum(C); r <- rowSums(Q); q <- colSums(Q)
  S <- (Q - outer(r, q)) / sqrt(outer(r, q))
  decomp <- svd(S, nu = min(dim(S)), nv = min(dim(S)))
  k <- sum(decomp$d > max(decomp$d) * 1e-9)
  if (k < 2) stop("Need at least two nontrivial CA dimensions")
  sing <- decomp$d[seq_len(k)]
  row_standard <- sweep(decomp$u[,seq_len(k),drop=FALSE], 1, sqrt(r), "/")
  col_standard <- sweep(decomp$v[,seq_len(k),drop=FALSE], 1, sqrt(q), "/")
  F <- sweep(row_standard, 2, sing, "*")
  G <- sweep(col_standard, 2, sing, "*")
  rownames(F) <- rownames(C); rownames(G) <- colnames(C)
  rownames(col_standard) <- colnames(C)
  list(F = F, G = G, col_standard = col_standard, eigenvalues = sing^2,
       row_mass = r, col_mass = q,
       column_contributions = sweep(G^2 * q, 2, sing^2, "/"))
}


# Directed adjacency networks built from already extracted, genuine bigrams.
bigram_edges <- function(ngrams, min_count = 2L, top_n = 40L) {
  tab <- term_counts(ngrams)
  tab <- tab[tab$count >= min_count, , drop = FALSE]
  pieces <- strsplit(tab$term, " ", fixed = TRUE)
  stopifnot(all(lengths(pieces) == 2L))
  out <- data.frame(from = vapply(pieces, `[`, character(1), 1),
                    to = vapply(pieces, `[`, character(1), 2),
                    count = tab$count, stringsAsFactors = FALSE)
  out$documents <- vapply(tab$term, function(pair)
    sum(vapply(ngrams, function(z) pair %in% z, logical(1))), integer(1))
  # Repeated-word self-loops remain in the count table, but are omitted here.
  out <- out[out$from != out$to, , drop = FALSE]
  head(out[order(-out$count, out$from, out$to), ], top_n)
}

plot_bigram_network <- function(edges, max_components = 3L,
                                title = "Directed bigram network") {
  if (!nrow(edges)) stop("No edges survive this display threshold")
  all_nodes <- sort(unique(c(edges$from, edges$to)))
  component <- setNames(integer(length(all_nodes)), all_nodes)
  k <- 0L
  for (start in all_nodes) {
    if (component[start] > 0L) next
    k <- k + 1L; queue <- start; component[start] <- k
    while (length(queue)) {
      current <- queue[1]; queue <- queue[-1]
      neighbours <- unique(c(edges$to[edges$from == current],
                              edges$from[edges$to == current]))
      new <- neighbours[component[neighbours] == 0L]
      component[new] <- k; queue <- c(queue, new)
    }
  }
  sizes <- table(component)
  # At least three nodes are needed to display a nontrivial two-edge walk.
  eligible <- names(sizes)[sizes >= 3L]
  selected <- head(eligible[order(-sizes[eligible], as.integer(eligible))],
                   max_components)
  if (!length(selected)) stop("No component has at least three words")
  chosen <- all_nodes[component %in% as.integer(selected)]
  edges <- edges[edges$from %in% chosen & edges$to %in% chosen, , drop = FALSE]
  layouts <- lapply(seq_along(selected), function(j) {
    words <- all_nodes[component == as.integer(selected[j])]
    n <- length(words)
    theta <- seq(0, 2*pi, length.out = n + 1)[-1]
    xy <- cbind(cos(theta), sin(theta))
    adjacency <- matrix(0, n, n, dimnames = list(words, words))
    local_edges <- edges[edges$from %in% words, , drop = FALSE]
    adjacency[cbind(match(local_edges$from, words), match(local_edges$to, words))] <- 1
    adjacency <- pmax(adjacency, t(adjacency))
    # Deterministic force layout. Geometry helps separate labels, not semantics.
    for (iteration in 1:350) {
      dx <- outer(xy[,1], xy[,1], "-")
      dy <- outer(xy[,2], xy[,2], "-")
      r2 <- pmax(dx^2 + dy^2, 0.025)
      repulsion <- 0.45/r2; diag(repulsion) <- 0
      attraction <- adjacency * sqrt(r2) * 0.18
      fx <- rowSums(dx * (repulsion-attraction)) - xy[,1] * 0.12
      fy <- rowSums(dy * (repulsion-attraction)) - xy[,2] * 0.12
      step <- min(0.04, 0.2/sqrt(iteration))
      xy <- xy + step * cbind(fx,fy)
    }
    xy <- scale(xy, center = TRUE, scale = FALSE)
    xy <- xy / max(abs(xy)) * 1.4
    # Separate word-label rectangles after the force layout, including in dense
    # components. Positions remain graphical layout choices, not measurements.
    half_width <- 0.042*nchar(words)+0.13
    for (iteration in 1:250) {
      moved <- FALSE
      for (a in seq_len(n-1L)) for (b in (a+1L):n) {
        dx <- xy[a,1]-xy[b,1]; dy <- xy[a,2]-xy[b,2]
        overlap_x <- half_width[a]+half_width[b]+0.08-abs(dx)
        overlap_y <- 0.38-abs(dy)
        if (overlap_x > 0 && overlap_y > 0) {
          if (overlap_y <= overlap_x) {
            shift <- (overlap_y+0.005)/2 * if (dy >= 0) 1 else -1
            xy[a,2] <- xy[a,2]+shift; xy[b,2] <- xy[b,2]-shift
          } else {
            shift <- (overlap_x+0.005)/2 * if (dx >= 0) 1 else -1
            xy[a,1] <- xy[a,1]+shift; xy[b,1] <- xy[b,1]-shift
          }
          moved <- TRUE
        }
      }
      xy[,1] <- pmin(1.4,pmax(-1.4,xy[,1]))
      xy[,2] <- pmin(1.4,pmax(-1.4,xy[,2]))
      if (!moved) break
    }
    data.frame(word = words, x = xy[,1], y = xy[,2],
                component = paste("Component", j), stringsAsFactors = FALSE)
  })
  nodes <- do.call(rbind, layouts)
  a <- nodes[match(edges$from,nodes$word), ]
  b <- nodes[match(edges$to,nodes$word), ]
  dx <- b$x-a$x; dy <- b$y-a$y
  # End arrows outside the word labels rather than hiding their heads.
  offset <- function(dx,dy,word)
    pmin(0.4, 1/pmax(abs(dx)/(0.042*nchar(word)+0.10), abs(dy)/0.13))
  left <- offset(dx,dy,a$word); right <- offset(dx,dy,b$word)
  edges$x <- a$x+dx*left; edges$y <- a$y+dy*left
  edges$xend <- b$x-dx*right; edges$yend <- b$y-dy*right
  edges$component <- a$component
  p <- ggplot2::ggplot() +
    ggplot2::geom_segment(data = edges,
      ggplot2::aes(x,y,xend=xend,yend=yend,linewidth=count),
      arrow = grid::arrow(length=grid::unit(2.2,"mm"),type="closed"),
      colour = "#0072B2", alpha = 0.7) +
    ggplot2::geom_label(data=nodes,ggplot2::aes(x,y,label=word),
                       size=3.3,fill="white",colour="grey15",linewidth=0.15) +
    ggplot2::facet_wrap(~component,ncol=min(3,length(selected))) +
    ggplot2::scale_linewidth_continuous(name="Bigram occurrences",range=c(0.4,1.8)) +
    ggplot2::coord_equal(xlim=c(-1.95,1.95),ylim=c(-1.8,1.8),clip="off") +
    ggplot2::labs(title=title) + ggplot2::theme_void(base_size=11) +
    ggplot2::theme(legend.position="bottom",strip.text=ggplot2::element_text(face="bold"),
                    plot.background=ggplot2::element_rect(fill="white",colour=NA),
                    panel.background=ggplot2::element_rect(fill="white",colour=NA),
                    plot.title=ggplot2::element_text(size=12),
                    plot.margin=ggplot2::margin(10,15,10,15))
  list(plot=p,nodes=nodes,edges=edges,
       all_components=length(sizes),shown_components=length(selected))
}

candidate_trigrams <- function(edges) {
  a <- edges[c("from","to")]; names(a) <- c("first","middle")
  b <- edges[c("from","to")]; names(b) <- c("middle","last")
  paths <- merge(a,b,by="middle")
  unique(paste(paths$first,paths$middle,paths$last))
}

verify_phrases <- function(candidates, text, n = 3L) {
  observed <- term_counts(lapply(text,sentence_ngrams,n=n))
  count <- observed$count[match(candidates,observed$term)]
  count[is.na(count)] <- 0L
  data.frame(phrase=candidates,actual_occurrences=count,stringsAsFactors=FALSE)
}
