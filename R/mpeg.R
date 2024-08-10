

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Initialise mpeg playback
#'
#' @param file mpeg1 filename
#' @param video logical. Should video be decoded?  Default: FALSE
#' @param audio logical. Should audio be decoded?  Default: FALSE
#' @param audio_stream audio stream to play. Default: 0
#' 
#' @return mpeg decoding context
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
init_mpeg <- function(
    file, 
    video = TRUE,
    audio = FALSE,
    audio_stream = 0) {
  file <- normalizePath(file, mustWork = TRUE)
  .Call(init_mpeg_, file, isTRUE(video), isTRUE(audio), as.integer(audio_stream))
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Decode a frame of video 
#' 
#' @param ctx mpeg context (as created by \code{init_mpeg()})
#' 
#' @return native raster containing the image data. This data is "owned" by 
#'         the decoding process and will be overwritten with each
#'         decoded frame
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mpeg_decode_video <- function(ctx) {
  .Call(mpeg_decode_video_, ctx)
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Decode a single frame of audio (1152 stereo samples)
#' 
#' @inheritParams mpeg_decode_video
#' 
#' @return numeric vector with 2 * 1152 floating point sample values. Each 
#'         sample is in the range [-1, 1]. The stereo channels are interleaved.
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mpeg_decode_audio <- function(ctx) {
  .Call(mpeg_decode_audio_, ctx)
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Information about mpeg stream
#' 
#' @inheritParams mpeg_decode_video
#' 
#' @return named list of information
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mpeg_info <- function(ctx) {
  .Call(mpeg_info_, ctx)
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Seek to time within mpeg data
#' 
#' @inheritParams mpeg_decode_video
#' @param time time (seconds)
#' @param exact logical.  perform slow exact seek? Default: FALSE
#' 
#' @return logical value indicating if seek was successful
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mpeg_seek <- function(ctx, time, exact = FALSE) {
  .Call(mpeg_seek_, ctx, time, isTRUE(exact))
}



if (FALSE) {
  
  library(grid)
  library(governor)
  library(narampeg)
  
  x11(type = 'dbcairo', antialias = 'none', width = 7, height = 4)
  dev.control(displaylist = 'inhibit')
  
  ctx <- narampeg::init_mpeg()
  
  mpeg_seek(ctx, 120)
  
  gov <- governor::gov_init(1/25)  # 25fps
  
  while(TRUE) {
    nr <- mpeg_decode_video(ctx)
    if (is.null(nr)) break;
    dev.hold()
    grid.raster(nr)
    dev.flush()
    gov_wait(gov)
  }      
  
  N <- 100
  snds <- vector('list', N)
  for (i in seq_len(N)) {
    snds[[i]] <- mpeg_decode_audio(ctx)
  }
  
  snd <- unlist(snds)
  snd <- matrix(snd, nrow = 2)
  snd <- audio::as.audioSample(snd)
  audio::play(snd)  
}


if (FALSE) {
  
  library(narampeg)
  
  ctx <- narampeg::init_mpeg(); mpeg_info(ctx)
  
  
}








