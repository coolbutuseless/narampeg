

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Initialise mpeg playback
#'
#' @param file mpeg1 filename
#' @param video logical. Should video be decoded?  Default: TRUE
#' @param audio logical. Should audio be decoded?  Default: TRUE
#' @param audio_stream audio stream to play. Default: 0
#' 
#' @return mpeg decoding context
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
init_mpeg <- function(
    file, 
    video = TRUE,
    audio = TRUE,
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
#' Decode frames of audio 
#' 
#' Each audio frame consists of 1152 interleaved stereo samples
#' 
#' @inheritParams mpeg_decode_video
#' @param n number of frames of audio to decode
#' 
#' @return numeric vector with 2n * 1152 floating point sample values. Each 
#'         sample is in the range [-1, 1]. The stereo channels are interleaved.
#'         If the full number of audio frames cannot be returned (e.g. the 
#'         mpeg stream is finished) then the audio samples will be set to 
#'         0 for the missing samples.  If there is no audio data to return 
#'         at all, then function returns NULL
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mpeg_decode_audio <- function(ctx, n = 1) {
  .Call(mpeg_decode_audio_, ctx, n)
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


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Rewind to beginning of mpeg 
#' 
#' @inheritParams mpeg_decode_video
#' 
#' @return None.
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mpeg_rewind <- function(ctx) {
  .Call(mpeg_rewind_, ctx)
  invisible()
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Samples per channel per frame
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
samples_per_channel_per_frame <- 1152

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Time to play a single frame of audio at 44100 kHz
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
audio_time_per_frame <- 1152 / 44100


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Video playback
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if (FALSE) {
  
  library(grid)
  library(governor)
  library(narampeg)
  
  x11(type = 'dbcairo', antialias = 'none', width = 7, height = 4)
  dev.control(displaylist = 'inhibit')
  
  file <- "~/projectsdata/mpeg/bjork-all-is-full-of-love.mpg"
  ctx <- narampeg::init_mpeg(file)
  
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
  
  snd <- mpeg_decode_audio(ctx, 100)
  snd <- matrix(snd, nrow = 2)
  snd <- audio::as.audioSample(snd)
  audio::play(snd)  
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Audio playback
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if (FALSE) {
  
  library(rminiaudio)  
  library(narampeg)
  library(governor)
  
  nframes    <- 100
  frame_time <- 1152 / 44100
  segment_time <- nframes * frame_time
  
  stream <- rminiaudio::open_stream('write', rate = 44100, channels = 2)
  
  file <- "~/projectsdata/mpeg/bjork-all-is-full-of-love.mpg"
  ctx <- narampeg::init_mpeg(file, video = TRUE, audio = TRUE)
  
  start <- Sys.time()
  
  count <- 1L
  while(TRUE) {
    cat(count, " ")
    snd <- mpeg_decode_audio(ctx, nframes)
    
    if (is.null(snd)) {
      message("Done")
      break;
    }
    
    wrote_audio <- rminiaudio::stream_write(stream, snd, rate = 44100, channels = 2, wait = FALSE)
    while (!wrote_audio) {
      Sys.sleep(0.2)
      wrote_audio <- rminiaudio::stream_write(stream, snd, rate = 44100, channels = 2, wait = FALSE)
    }
    
    count <- count + 1L
  }      
  
  rminiaudio::close_stream(stream)
  Sys.time() - start
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# AUDIO + Video playback
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if (FALSE) {
  
  library(grid)
  library(governor)
  library(rminiaudio)
  library(narampeg)
  
  x11(type = 'dbcairo', antialias = 'none', width = 7, height = 4)
  dev.control(displaylist = 'inhibit')
  
  n_audio_frames     <- 100
  audio_frame_time   <- 1152 / 44100
  audio_segment_time <- n_audio_frames * audio_frame_time
  stream <- rminiaudio::open_stream('write', rate = 44100, channels = 2)
  
  file <- "~/projectsdata/mpeg/bjork-all-is-full-of-love.mpg"
  ctx <- narampeg::init_mpeg(file)
  
  gov <- governor::gov_init(1/25)  # 25fps
  tim <- governor::timer_init(audio_segment_time - 0.2)
  
  snd <- mpeg_decode_audio(ctx, n_audio_frames)
  rminiaudio::stream_write(stream, snd, rate = 44100, channels = 2, wait = FALSE)
  
  audio_to_inject <- FALSE
  
  while(TRUE) {
    nr <- mpeg_decode_video(ctx)
    if (is.null(nr)) break;
    dev.hold(); grid.raster(nr); dev.flush()
    if (governor::timer_check(tim)) {
      snd <- mpeg_decode_audio(ctx, nframes)
      audio_to_inject <- !rminiaudio::stream_write(stream, snd, rate = 44100, channels = 2, wait = FALSE)
    }
    if (audio_to_inject) {
      audio_to_inject <- !rminiaudio::stream_write(stream, snd, rate = 44100, channels = 2, wait = FALSE)
    }
    gov_wait(gov)
  }
  
  rminiaudio::close_stream(stream)
  
}






