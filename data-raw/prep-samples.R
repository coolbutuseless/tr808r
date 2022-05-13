## code to prepare `prep-samples` dataset goes here

files <- list.files("data-raw/samples/", full.names = TRUE)
sample_names <- basename(tools::file_path_sans_ext(files))
names(files) <- sample_names
samples <- lapply(files, audio::load.wave)


samples <- samples[c(
  'Bassdrum-01',
  'Snaredrum',
  'Tom L',
  'Tom M',
  'Tom H',
  'Rimshot',
  'Clap',
  'Cowbell',
  'Crash-01',
  'Hat Open',
  'Hat Closed'
)]

sample_names <- c(
  'Bass Drum',
  'Snare Drum',
  'Low Tom',
  'Mid Tom',
  'Hi Tom',
  'Rimshot',
  'Hand Clap',
  'Cowbell',
  'Cymbal',
  'Open Hat',
  'Closed Hat'
)


samples <- rev(samples)
sample_names <- rev(sample_names)

names(samples) <- sample_names



usethis::use_data(samples, internal = TRUE, overwrite = TRUE)



demo_songs <- list()
demo_songs[[1]] <- readRDS("data-raw/New Order - Confusion.rds")
demo_songs[[2]] <- readRDS("data-raw/Marvin Gaye - Sexual Healing.rds")
demo_songs[[3]] <- readRDS("data-raw/Michael Jackson - Beat It Intro.rds")
usethis::use_data(demo_songs, sample_names, internal = FALSE, overwrite = TRUE)
