#ifndef __POWELL_H__
#define __POWELL_H__

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "nrutil.h"

void powell (float p[], float **xi, int n, float ftol, int *iter, float *fret, float (*func)(float p[]));

#endif