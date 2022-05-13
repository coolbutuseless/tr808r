
env <- new.env()


RED    <- rgb(222, 105,  78, maxColorValue = 255)
ORANGE <- rgb(238, 170, 102, maxColorValue = 255)
YELLOW <- rgb(243, 212, 102, maxColorValue = 255)
WHITE  <- rgb(241, 243, 245, maxColorValue = 255)
BLACK  <- rgb( 30,  30,  30, maxColorValue = 255)

ROLAND_RED <- rgb(230, 102, 48, maxColorValue = 255)

LABEL_YELLOW <- rgb(243, 234, 202, maxColorValue = 255)

# colorspace::darken(c(RED, ORANGE, YELLOW, WHITE), 0.9) -> col
DRED    <- '#2a0700'
DORANGE <- '#241300'
DYELLOW <- '#1f1800'
DWHITE  <- '#0e1c26'


pattern_ui_light_cols <- c(rep( RED, 4), rep( ORANGE, 4), rep( YELLOW, 4), rep( WHITE, 4))
pattern_ui_dark_cols  <- c(rep(DRED, 4), rep(DORANGE, 4), rep(DYELLOW, 4), rep(DWHITE, 4))

pattern_ui_light_cols <- rep(pattern_ui_light_cols, 18)
pattern_ui_dark_cols  <- rep(pattern_ui_dark_cols , 18)
