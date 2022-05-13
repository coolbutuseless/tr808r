
globalVariables(c('x', 'active'))



PATTERN_UI_OFFSET <- 0.2
PATTERN_UI_SCALE  <- 0.8
NPAT              <- 8   # 8 patterns

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Draw the tempo/tracer across the top
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
draw_tracer <- function(i) {
  cols <- rep('grey30', 16)
  cols[i] <- 'grey80'
  grid::grid.rect(
    x = (seq(0, 1, length.out = 17)[-17] + 1/32) * PATTERN_UI_SCALE + PATTERN_UI_OFFSET,
    y = 0.975,
    width = 0.045, height = 0.05,
    just = c(0.5, 1),
    gp = grid::gpar(fill = cols)
  )
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Draw the pattern editor UI
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
draw_current_pattern <- function() {

  pattern <- env$pattern[[env$current_pattern_idx]]

  fill <- pattern_ui_dark_cols
  fill[pattern$active] <- pattern_ui_light_cols[pattern$active]

  grid.rect(
    width  = 0.04,
    height = 0.065,
    x = (pattern$x / 16 - 1/32) * PATTERN_UI_SCALE + PATTERN_UI_OFFSET,  # 16 beats
    y = pattern$y / 12 - 1/24,  # 11 instruments
    gp = gpar(fill = fill)
  )

}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Update the state of the pattern based upon mouse click position
# Thic function is called when mouse is clicked, and if it corresponds
# to an element in the pattern deck, then set this value to active
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
update_current_pattern <- function(mouse_x, mouse_y) {

  # Instrument pattern
  pattern <- env$pattern[[env$current_pattern_idx]]

  x <- ceiling((mouse_x - PATTERN_UI_OFFSET) / PATTERN_UI_SCALE * 16)
  y <- ceiling(mouse_y * 11 / (1 - 0.065))

  idx <- pattern$x == x & pattern$y == y

  pattern[idx, 'active'] <- !pattern[idx, 'active']

  env$pattern[[env$current_pattern_idx]] <- pattern
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Draw Pattern Select UI
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
draw_pattern_selection <- function() {

  fills <- c('grey20', 'dodgerblue3')[env$pattern_set + 1L]

  cols <- rep(BLACK, NPAT)
  cols[env$current_pattern_idx] <- 'WHITE'

  y <- c(
    0.95, 0.95, 0.95, 0.95,
    0.92, 0.92, 0.92, 0.92
  ) + 0.014

  grid::grid.rect(
    x = seq_len(NPAT/2) / 48 + 4/48,
    y = y,
    width = 1/55,
    height = 1/36,
    gp = gpar(col = cols, fill = fills, lwd = 3)
  )

  grid::grid.text(
    label = seq_len(NPAT),
    x = seq_len(NPAT/2) / 48 + 4/48,
    y = y,
    gp = gpar(
      fontfamily = 'sans',
      col        = 'white',
      cex        = 1
    )
  )
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Update pattern select
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
update_pattern_selection <- function(idx) {
  # user has pressed a key in "1" - NPAT
  idx <- as.integer(idx)
  env$pattern_set[idx] <- !env$pattern_set[idx]

  # If the user turned off the last valid pattern,
  # then turn on pattern #1
  if (!any(env$pattern_set)) env$pattern_set[1] <- TRUE
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Render the names of the instruments somehow
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
draw_instrument_names <- function() {
  y <- (1:11) / 12 - 1/24

  for (yi in y) {
    grid::grid.roundrect(
      x = 0.02,
      y = yi,
      width = 0.16,
      height = 0.05,
      just =c(0, 0.5),
      r = unit(0.2, 'snpc'),
      gp = gpar(col = NA, fill = LABEL_YELLOW)
    )
  }

  grid::grid.text(
    tr808r::sample_names,
    x = 0.03, y = y,
    hjust = -0.1,
    gp = gpar(
      fontfamily = 'sans',
      col        = 'black',
      cex        = 1.75
    )
  )
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reset_current_pattern <- function() {

  pattern <- expand.grid(x=1:16, y=1:11, active = FALSE)

  env$pattern[[env$current_pattern_idx]] <- pattern

  draw_current_pattern()
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reset_all_patterns <- function() {

  pattern <- expand.grid(x=1:16, y=1:11, active = FALSE)

  env$pattern <- rep(list(pattern), NPAT)

  draw_current_pattern()
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Render the BPM info
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
draw_bpm <- function() {

  # Rectangle underneath
  grid::grid.roundrect(
    x = 0.01, y = 0.95,
    r = unit(0.1, 'snpc'),
    width = 0.06,
    height = 0.05,
    just = c(0, 0.5),
    gp = gpar(
      col = NA,
      fill = 'pink'
    )
  )

  # BPM text on top
  grid::grid.text(
    env$bpm,
    x = 0.06,
    y = 0.95,
    hjust = 1,
    gp = gpar(
      fontfamily = 'sans',
      col        = 'black',
      cex        = 1.75
    )
  )
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Initialise function for eventloop
#'
#' @return None
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
tr808_init <- function() {

  env$playing             <- TRUE
  env$count               <- 0L
  env$pattern             <- NULL
  env$pattern_set         <- logical(NPAT)
  env$pattern_set[1]      <- TRUE
  env$current_pattern_idx <- 1L

  reset_all_patterns()

  if (!is.null(env$init_state)) {
    env$pattern     <- env$init_state$pattern
    env$pattern_set <- env$init_state$pattern_set
    env$current_pattern_idx <- which(env$pattern_set)[[1]]

    env$init_state <- NULL
  }

  # Set background
  grid.rect(gp = gpar(col = NA, fill = BLACK))

  # Draw components
  draw_pattern_selection()
  draw_current_pattern()
  draw_instrument_names()
  draw_bpm()
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Run the frame rate at a faster multiple of the BPM so that the UI
# is more responsive.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FPS_MULT <- 4
SHIFT    <- log2(FPS_MULT)


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Main TR808 eventloop callback
#'
#' @param event,mouse_x,mouse_y,event_env,... eventloop args
#'
#' @import grid
#' @import audio
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
tr808_func <- function(event, mouse_x, mouse_y, event_env, ...) {

  i <- ( bitwShiftR(env$count, SHIFT) %% 16L) + 1L

  # Only 'play' audio every n'th frame
  play_audio <- (env$count %% FPS_MULT) == 0


  # Update patterns on first note of first beat
  if (play_audio && env$playing && i == 1 && env$count != 0) {
    all_pattern_indices <- which(env$pattern_set)
    pattern_indices <- all_pattern_indices[all_pattern_indices > env$current_pattern_idx]
    if (length(pattern_indices) == 0) {
      # Loop around to first index
      next_pattern_idx <- all_pattern_indices[1]
      if (next_pattern_idx != env$current_pattern_idx) {
        env$current_pattern_idx <- next_pattern_idx
        draw_current_pattern()
        draw_pattern_selection()
      }
    } else {
      # Move to next pattern, and update the pattern
      env$current_pattern_idx <- pattern_indices[1]
      draw_current_pattern()
      draw_pattern_selection()
    }
  }



  if (play_audio && env$playing) {
    draw_tracer(i)

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Find instruments active at this time step and play them
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    now <- subset(env$pattern[[env$current_pattern_idx]], x == i & active)
    for (sample_idx in now$y) {
      sample_name <- tr808r::sample_names[[sample_idx]]
      audio::play(samples[[sample_name]])
    }
  }

  if (env$playing) {
    env$count <- env$count + 1L
  }


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Mouse clicks update the active state of the instrument pattern
  # Keys:
  #   c - clear pattern
  #   SPACE = play/pause
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  shifted_nums <- c('!', '@', '#', '$', '%', '^', '&', '*')
  if (!is.null(event)) {
    if (event$type == 'key_press') {
      if (event$str == 'c') {
        reset_current_pattern()
        draw_pattern_selection()
      } else if (event$str == ' ') {
        env$playing <- !env$playing
      } else if (event$str %in% seq_len(NPAT)) {
        update_pattern_selection(event$str)
        draw_pattern_selection()
      } else if (event$str %in% shifted_nums) {
        idx <- which(shifted_nums == event$str)
        env$pattern_set[idx] <- TRUE
        env$current_pattern_idx <- idx
        draw_pattern_selection()
        draw_current_pattern()
      } else if (event$str %in% c('-', '_', 'Down')) {
        env$bpm <- env$bpm - 1L
        event_env$fps_target <- bpm_to_fps(env$bpm)
        draw_bpm()
      } else if (event$str %in% c('+', '=', 'Up')) {
        env$bpm <- env$bpm + 1L
        event_env$fps_target <- bpm_to_fps(env$bpm)
        draw_bpm()
      } else if (event$str == 's') {
        datestamp <- strftime(Sys.time(), "%Y%m%d-%H:%M:%S")
        filename <- paste0('tr808-', datestamp, ".rds")
        message("Saved to: ", filename)
        save_obj <- list(
          pattern_set = env$pattern_set,
          pattern     = env$pattern,
          bpm         = env$bpm
        )
        saveRDS(save_obj, file = filename)
      } else if (event$str == 't') {
        cat(pattern_to_text(env$pattern[[env$current_pattern_idx]]))
      }
    } else if (event$type == 'mouse_down') {
      update_current_pattern(mouse_x, mouse_y)
      draw_current_pattern()
    }

  }


}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Run the FPS at a multiple of the BPM
# E.g. 96 BPM is only 6.4Hz
#      Having a framerate of 6.4Hz makes the UI feel really unresponsive
# So just multiply by a factor, and divide by this factor later on
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
bpm_to_fps <- function(bpm) {
  bpm * 4 / 60 * FPS_MULT
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Is this object a valid pattern of 11instruments * 16 notes
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
is_pattern <- function(pattern) {
  is.data.frame(pattern) &&
    nrow(pattern) == 176 &&
    !anyNA(pattern) &&
    all(pattern$x %in% 1:16) &&
    all(pattern$y %in% 1:11) &&
    all(pattern$active %in% c(TRUE, FALSE))
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Is this a valid list of patterns?
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
is_pattern_list <- function(pattern) {
  is.list(pattern) &&
    length(pattern) == NPAT &&
    !anyNA(pattern) &&
    all(
      vapply(pattern, is_pattern, logical(1))
    )
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Is this a valid tr808 state?
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
is_tr808_state <- function(state) {
  is.list(state) &&
  is.logical(state$pattern_set) &&
    !anyNA(state$pattern_set) &&
    any(state$pattern_set) &&
    is_pattern_list(state$pattern) &&
    is.numeric(state$bpm) &&
    !is.na(state$bpm)
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' TR-808
#'
#' @param width,height,... arguments passed to \code{eventloop::run_loop()}
#' @param bpm beats per minute. default: 96
#' @param state a \code{tr808_state} object or the path of a saved object in
#'        an RDS file.  Note: Pressing 's' within the interactive drum machine
#'        window will save the current state to a time stamped RDS file.
#'
#' @importFrom utils packageVersion
#' @import eventloop
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
tr808 <- function(bpm = 96, width = 12, height = 8, state = NULL, ...) {

  if (!interactive()) {
    stop("Running this app only makes sense when R is interactive")
  }

  if (packageVersion('eventloop') < "0.1.1") {
    stop("Need {eventloop} v0.1.1\nremotes::install_github('coolbutuseless/eventloop')")
  }


  if (!is.null(state)) {
    if (is_tr808_state(state)) {
      # do nothing
    } else if (file.exists(state)) {
      state <- readRDS(state)
      if (!is_tr808_state(state)) {
        stop("File specified does not contain a tr808 state object")
      }
    } else if (is_text_pattern(state)) {
      state <- text_to_tr808_state(state)
    } else {
      stop("'state' argument must be a tr808 state object, a file path to a ",
           "saved object in RDS format, or a text string coercible to a",
           " pattern")
    }
    env$init_state <- state

    # Use BPM of the loaded object rather than function argument
    bpm <- state$bpm
  }


  env$bpm <- as.integer(bpm)

  fps <- bpm_to_fps(bpm)
  message("BPM: ", bpm, "  FPS: ", fps)
  message("SPACE to play/pause")
  message("'c' to clear current pattern")
  message("'s' to save tr808 state (load with 'state = ...' argument)")
  message("'t' to copy tweetable text to clipboard/print to console")
  message("'1'-'8' to toggle pattern for playback")
  message("SHIFT + '1'-'8' to jump immediately to this pattern (usually best when PAUSED)")
  message("+/- Up/Down to adjust BPM")


  eventloop::run_loop(
    tr808_func, init_func = tr808_init,
    width = width, height = height,
    fps_target = fps, ..., double_buffer = FALSE
  )
}



if (FALSE) {
  library(eventloop)
  run_loop(tr808_func, init_func = tr808_init, bpm = 96)
}
