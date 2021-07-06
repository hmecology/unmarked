#define TMB_LIB_INIT R_init_unmarked_TMBExports
#include <TMB.hpp>
#include <float.h>
#include "tmb_utils.hpp"
#include "tmb_occu.hpp"
#include "tmb_pcount.hpp"

template<class Type>
Type objective_function<Type>::operator() () {
  DATA_STRING(model);
  if(model == "tmb_occu") {
    return tmb_occu(this);
  } else if(model == "tmb_pcount") {
    return tmb_pcount(this);
  } else {
    error("Unknown model.");
  }
  return 0;
}
