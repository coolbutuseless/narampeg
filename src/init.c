
// #define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>


extern SEXP init_mpeg_(SEXP file_, SEXP video_, SEXP audio_, SEXP audio_stream_);

extern SEXP mpeg_info_        (SEXP ctx_);
extern SEXP mpeg_decode_video_(SEXP ctx_);
extern SEXP mpeg_decode_audio_(SEXP ctx_);

extern SEXP mpeg_seek_(SEXP ctx_, SEXP time_, SEXP exact_);

static const R_CallMethodDef CEntries[] = {
  
  {"init_mpeg_"        , (DL_FUNC) &init_mpeg_        , 4},
  {"mpeg_info_"        , (DL_FUNC) &mpeg_info_        , 1},
  {"mpeg_decode_video_", (DL_FUNC) &mpeg_decode_video_, 1},
  {"mpeg_decode_audio_", (DL_FUNC) &mpeg_decode_audio_, 1},
  {"mpeg_seek_"        , (DL_FUNC) &mpeg_seek_        , 3},
  
  {NULL , NULL, 0}
};


void R_init_narampeg(DllInfo *info) {
  R_registerRoutines(
    info,      // DllInfo
    NULL,      // .C
    CEntries,  // .Call
    NULL,      // Fortran
    NULL       // External
  );
  R_useDynamicSymbols(info, FALSE);
}



