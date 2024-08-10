
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <unistd.h>

#include <R.h>
#include <Rinternals.h>
#include <Rdefines.h>

#include "pl_mpeg.h"
#include "R-mpeg-decode.h"

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Decode a single frame of audio
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SEXP mpeg_info_(SEXP ctx_) {
  
  int nprotect = 0;
  plm_t *plm = unpack_ext_ptr_to_mpeg_ctx(ctx_);
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Setup the list to be returned
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  int N = 8;
  SEXP res_ = PROTECT(allocVector(VECSXP, N)); nprotect++;
  SEXP nms_ = PROTECT(allocVector(STRSXP, N)); nprotect++;
  setAttrib(res_, R_NamesSymbol, nms_);
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Fill in all the values
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  SET_VECTOR_ELT(res_, 0, ScalarInteger(plm_get_width (plm)));
  SET_STRING_ELT(nms_, 0, mkChar("width"));
  
  SET_VECTOR_ELT(res_, 1, ScalarInteger(plm_get_height(plm)));
  SET_STRING_ELT(nms_, 1, mkChar("height"));
  
  SET_VECTOR_ELT(res_, 2, ScalarInteger(plm_get_num_video_streams(plm)));
  SET_STRING_ELT(nms_, 2, mkChar("video_streams"));
  
  SET_VECTOR_ELT(res_, 3, ScalarInteger(plm_get_num_audio_streams(plm)));
  SET_STRING_ELT(nms_, 3, mkChar("audio_streams"));
  
  SET_VECTOR_ELT(res_, 4, ScalarInteger(plm_get_framerate(plm)));
  SET_STRING_ELT(nms_, 4, mkChar("fps"));
  
  SET_VECTOR_ELT(res_, 5, ScalarInteger(plm_get_samplerate(plm)));
  SET_STRING_ELT(nms_, 5, mkChar("sample_rate"));
  
  SET_VECTOR_ELT(res_, 6, ScalarInteger(plm_get_time(plm)));
  SET_STRING_ELT(nms_, 6, mkChar("interval_time"));
  
  SET_VECTOR_ELT(res_, 7, ScalarInteger(plm_get_duration(plm)));
  SET_STRING_ELT(nms_, 7, mkChar("duration"));
  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // Tidy and return
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  UNPROTECT(nprotect);
  return res_;
}

