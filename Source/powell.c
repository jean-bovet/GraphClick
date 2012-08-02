#include "powell.h"

#define ITMAX 500
#define TOL 1.0e-6

#define GLIMIT 100.0
#define ZEPS 1.0e-10

int ncom;
float (*nrfunc)(float p[]);
float *pcom,*xicom;

void mnbrak(float *ax, float *bx, float *cx, float *fa, float *fb, float *fc, float (*func)(float))
//Given a function func, and given distinct initial points ax and bx, this routine searches in
//the downhill direction (dened by the function as evaluated at the initial points) and returns
//new points ax, bx, cx that bracket a minimum of the function. Also returned are the function
//values at the three points, fa, fb, and fc.
{
	float ulim,u,r,q,fu,dum;
	*fa=(*func)(*ax);
	*fb=(*func)(*bx);
	if (*fb > *fa) { //Switch roles of a and b so that we can go
		//downhill in the direction from a to b. 
		SHFT(dum,*ax,*bx,dum)
		SHFT(dum,*fb,*fa,dum)
	}
	*cx=(*bx)+GOLD*(*bx-*ax); //First guess for c.
	*fc=(*func)(*cx);
	while (*fb > *fc) { //Keep returning here until we bracket.
		r=(*bx-*ax)*(*fb-*fc); //Compute u by parabolic extrapolation from
		//a; b; c. TINY is used to prevent any pos-
		//sible division by zero.
		q=(*bx-*cx)*(*fb-*fa);
		u=(*bx)-((*bx-*cx)*q-(*bx-*ax)*r)/(2.0*SIGN(FMAX(fabs(q-r),TINY),q-r));
		ulim=(*bx)+GLIMIT*(*cx-*bx);
		//We won't go farther than this. Test various possibilities:
		if ((*bx-u)*(u-*cx) > 0.0) { //Parabolic u is between b and c: try it.
			fu=(*func)(u);
			if (fu < *fc) { //Got a minimum between b and c.
				*ax=(*bx);
				*bx=u;
				*fa=(*fb);
				*fb=fu;
				return;
			} else if (fu > *fb) { //Got a minimum between between a and u.
				*cx=u;
				*fc=fu;
				return;
			}
			u=(*cx)+GOLD*(*cx-*bx); //Parabolic t was no use. Use default magnication. 
			fu=(*func)(u);
		} else if ((*cx-u)*(u-ulim) > 0.0) { //Parabolic t is between c and its allowed limit. 
			fu=(*func)(u);
			if (fu < *fc) {
				SHFT(*bx,*cx,u,*cx+GOLD*(*cx-*bx))
				SHFT(*fb,*fc,fu,(*func)(u))
			}
		} else if ((u-ulim)*(ulim-*cx) >= 0.0) { //Limit parabolic u to maximum allowed value. 
			u=ulim;
			fu=(*func)(u);
			} else { //Reject parabolic u, use default magnication. 
			u=(*cx)+GOLD*(*cx-*bx);
			fu=(*func)(u);
		}
		SHFT(*ax,*bx,*cx,u) //Eliminate oldest point and continue.
		SHFT(*fa,*fb,*fc,fu)
	}
}

float brent(float ax, float bx, float cx, float (*f)(float), float tol, float *xmin)
{
	int iter;
	float a,b,d,etemp,fu,fv,fw,fx,p,q,r,tol1,tol2,u,v,w,x,xm;
	float e=0.0;

	a=(ax < cx ? ax : cx);
	b=(ax > cx ? ax : cx);
	x=w=v=bx;
	fw=fv=fx=(*f)(x);
	for (iter=1;iter<=ITMAX;iter++) {
		xm=0.5*(a+b);
		tol2=2.0*(tol1=tol*fabs(x)+ZEPS);
		if (fabs(x-xm) <= (tol2-0.5*(b-a))) {
			*xmin=x;
			return fx;
		}
		if (fabs(e) > tol1) {
			r=(x-w)*(fx-fv);
			q=(x-v)*(fx-fw);
			p=(x-v)*q-(x-w)*r;
			q=2.0*(q-r);
			if (q > 0.0) p = -p;
			q=fabs(q);
			etemp=e;
			e=d;
			if (fabs(p) >= fabs(0.5*q*etemp) || p <= q*(a-x) || p >= q*(b-x))
				d=CGOLD*(e=(x >= xm ? a-x : b-x));
			else {
				d=p/q;
				u=x+d;
				if (u-a < tol2 || b-u < tol2)
					d=SIGN(tol1,xm-x);
			}
		} else {
			d=CGOLD*(e=(x >= xm ? a-x : b-x));
		}
		u=(fabs(d) >= tol1 ? x+d : x+SIGN(tol1,d));
		fu=(*f)(u);
		if (fu <= fx) {
			if (u >= x) a=x; else b=x;
			SHFT(v,w,x,u)
			SHFT(fv,fw,fx,fu)
		} else {
			if (u < x) a=u; else b=u;
			if (fu <= fw || w == x) {
				v=w;
				w=u;
				fv=fw;
				fw=fu;
			} else if (fu <= fv || v == x || v == w) {
				v=u;
				fv=fu;
			}
		}
	}
	nrerror("Too many iterations in brent");
	*xmin=x;
	return fx;
}

float f1dim(float x)
{
	float *xt;
	xt = vector(1, ncom);
	int j;
	for (j = 1; j <= ncom; j++)
		xt[j] = pcom[j] + x * xicom[j];
	float value = (*nrfunc)(xt);
	free_vector(xt, 1, ncom);
	
	return value;
}

void linmin (float p[], float xi[], int n, float *fret, float (*func)(float p[]))
{
	int j;
	float xx,xmin,fx,fb,fa,bx,ax;

	ncom = n; //Dene the global variables.
	pcom = vector(1,n);
	xicom = vector(1,n);
	nrfunc = func;
	for (j=1; j<=n; j++) 
	{
		pcom[j] = p[j];
		xicom[j] = xi[j];
	}
	ax = 0.0; //Initial guess for brackets.
	xx = 1.0;
	mnbrak (&ax,&xx,&bx,&fa,&fx,&fb,f1dim);
	*fret = brent (ax, xx, bx, f1dim, TOL, &xmin);
	for (j=1;j<=n;j++) 
	{ //Construct the vector results to return.
		xi[j] *= xmin;
		p[j] += xi[j];
	}
	free_vector (xicom,1,n);
	free_vector (pcom,1,n);
}

void powell (float p[], float **xi, int n, float ftol, int *iter, float *fret, float (*func)(float p[]))
{
	int i,ibig,j;
	float del,fp,fptt,t,*pt,*ptt,*xit;

	pt=vector(1,n);
	ptt=vector(1,n);
	xit=vector(1,n);
	*fret=(*func)(p);

	for (j=1;j<=n;j++) pt[j]=p[j]; //Save the initial point.

	for (*iter=1;;++(*iter)) 
	{
		fp=(*fret);
		ibig=0;
		del=0.0; //Will be the biggest function decrease.
		
		for (i=1;i<=n;i++) //In each iteration, loop over all directions in the set.
		{ 
			for (j=1;j<=n;j++) xit[j]=xi[j][i]; //Copy the direction,
			fptt = (*fret);
			linmin (p, xit, n, fret, func); //minimize along it,
			if (fptt-(*fret) > del) //and record it if it is the largest decrease so far.
			{  
				del=fptt-(*fret);
				ibig=i;
			}
		}

		if (2.0*(fp-(*fret)) <= ftol*(fabs(fp)+fabs(*fret))+TINY) //Termination criterion.
		{
			free_vector(xit,1,n); 
			free_vector(ptt,1,n);
			free_vector(pt,1,n);
			return;
		}

		if (*iter == ITMAX) nrerror ("powell exceeding maximum iterations.");

		//Construct the extrapolated point and the average direction moved. Save the old starting point.		
		for (j=1;j<=n;j++) 
		{ 
			ptt[j]=2.0*p[j]-pt[j];
			xit[j]=p[j]-pt[j];
			pt[j]=p[j];
		}

		fptt=(*func)(ptt); //Function value at extrapolated point.

		if (fptt < fp) 
		{
			t=2.0*(fp-2.0*(*fret)+fptt)*SQR(fp-(*fret)-del)-del*SQR(fp-fptt);
			if (t < 0.0) 
			{
				//Move to the minimum of the new direction, and save the new direction.
				linmin (p,xit,n,fret,func); 
				for (j=1;j<=n;j++) 
				{
					xi[j][ibig]=xi[j][n];
					xi[j][n]=xit[j];

					// fixes bug of NR
					pt[j]=p[j];	//save the old starting point
				}
			}
		}
	} //Back for another iteration.
}
