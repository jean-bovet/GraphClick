#ifndef __MRQMIN_H__
#define __MRQMIN_H__

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "matmath.h"

void mrqmin( m_elem x[], m_elem y[], m_elem sig[], int ndata, m_elem a[],
	    int ia[], int ma, m_elem **covar, m_elem **alpha, m_elem *chisq,
	    void (*funcs)(m_elem, m_elem [], m_elem *, m_elem [], int),
	    m_elem *alamda);

#endif