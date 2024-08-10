
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <unistd.h>

#include <R.h>
#include <Rinternals.h>
#include <Rdefines.h>

#define PL_MPEG_IMPLEMENTATION
#include "pl_mpeg.h"

#include "R-mpeg-decode.h"


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Finalizer: Called via garbage collection by R itself
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void mpeg_finalizer(SEXP mpeg_ctx_) {
  plm_t *plm = (plm_t *)R_ExternalPtrAddr(mpeg_ctx_);
  plm_destroy(plm);
  R_ClearExternalPtr(mpeg_ctx_);
}


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Unpack an ExternalPointer to the MPEG context
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
plm_t *unpack_ext_ptr_to_mpeg_ctx(SEXP mpeg_ctx_) {
  
  if (!inherits(mpeg_ctx_, "mpeg")) {
    error("unpack_ext_ptr_to_mpeg_ctx(): Not a 'mpeg context' external pointer");
  }
  
  plm_t *plm = TYPEOF(mpeg_ctx_) == EXTPTRSXP ? (plm_t *)R_ExternalPtrAddr(mpeg_ctx_) : NULL;
  
  if (plm ==  NULL) {
    error("unpack_ext_ptr_to_mpeg_ctx(): mpeg context external pointer is invalid or NULL");
  }
  
  return plm;
}





//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// 
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SEXP init_mpeg_(SEXP file_, SEXP video_, SEXP audio_, SEXP audio_stream_) {
  
  int nprotect = 0;
  const char *file = CHAR(STRING_ELT(file_, 0));
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Initialize MPEG context
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  plm_t *plm = plm_create_with_filename(file);
  if (!plm) {
    error("Couldn't open file %s\n", file);
  }
  
  plm_set_video_enabled(plm, asLogical(video_));
  plm_set_audio_enabled(plm, asLogical(audio_));
  plm_set_audio_stream (plm, asInteger(audio_stream_));

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Create a native raster that is protected within the external pointer
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  int w = plm_get_width(plm);
  int h = plm_get_height(plm);
  
  SEXP dst_ = PROTECT(allocVector(INTSXP, w * h)); nprotect++;
  
  SET_CLASS(dst_, mkString("nativeRaster"));
  SEXP nr_dim = PROTECT(allocVector(INTSXP, 2)); nprotect++;
  INTEGER(nr_dim)[0] = h;
  INTEGER(nr_dim)[1] = w;
  SET_DIM(dst_, nr_dim);
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Wrap 'mpeg context' as an ExternalPointer for R
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  SEXP mpeg_ctx_ = PROTECT(R_MakeExternalPtr(plm, R_NilValue, dst_)); nprotect++;
  R_RegisterCFinalizer(mpeg_ctx_, mpeg_finalizer);
  SET_CLASS(mpeg_ctx_, mkString("mpeg"));
  
  UNPROTECT(nprotect);
  return mpeg_ctx_;
}


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Decode a single frame of video
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SEXP mpeg_decode_video_(SEXP ctx_) {

  plm_t *plm = unpack_ext_ptr_to_mpeg_ctx(ctx_);
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Unpack the native raster that accompanies the external pointer and 
  // clear it (plm library expects all values to be set to 255 here)
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  SEXP dst_ = R_ExternalPtrProtected(ctx_);
  if (isNull(dst_)) {
    error("Couldn't unpack native raster from mpeg ctx");
  }
  
  int h = nrows(dst_);
  int w = ncols(dst_);
  
  uint8_t *dst = (uint8_t *)INTEGER(dst_);
  memset(dst, 255, w * h * 4);
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // If there's a frame, then decode it into our native raster
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  plm_frame_t *frame = plm_decode_video(plm);
  if (frame) {
    plm_frame_to_rgba(frame, dst, w * 4);
    return(dst_);
  }
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // If there was no frame, then we've reached the end of the video
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  return R_NilValue;
}


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Decode a single frame of audio
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SEXP mpeg_decode_audio_(SEXP ctx_) {
  
  plm_t *plm = unpack_ext_ptr_to_mpeg_ctx(ctx_);
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Decode samples and convert from float to double to return to R
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  plm_samples_t *samples = plm_decode_audio(plm);
  
  if (samples) {
    SEXP snd_ = PROTECT(allocVector(REALSXP, PLM_AUDIO_SAMPLES_PER_FRAME * 2));
    double *snd = REAL(snd_);
    
    for (int i = 0; i < PLM_AUDIO_SAMPLES_PER_FRAME * 2; i++) {
      snd[i] = samples->interleaved[i];
    }
    
    UNPROTECT(1);
    return(snd_);
  }
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // If there were no samples, return NULL
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  return R_NilValue;
}


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Seek to a location within the file
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SEXP mpeg_seek_(SEXP ctx_, SEXP time_, SEXP exact_) {
  
  plm_t *plm = unpack_ext_ptr_to_mpeg_ctx(ctx_);

  int res = plm_seek(plm, asReal(time_), asLogical(exact_));
    
  return ScalarLogical(res);
}

