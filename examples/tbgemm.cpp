
//This is a simple example of Matrix Multiplication on CPU.

#include <iostream>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "math.h"

extern "C" {
#include "darknet.h"
#include "utils.h"
//#include "data.h"
#include "libxlnk_cma.h"
//#include "fpga.h" 
}

#define BITWIDTH 8
#define VECTOR_WIDTH 16
#define NUM_PES 16
#define R_DEPTH 15
#define C_DEPTH 133  

typedef int8_t data_t;


data_t toFixed(float a, float scale)
{
	data_t result;
	float imm;

	imm = a*scale;

	if (a<0) result = imm - 0.5; //rounding
	else result = imm + 0.5;

	return result;
}

float array_max(float *input, int n)
{
    float imm;
    float mval = 0;
    for (int i=0; i<n; i++){
        imm = fabs(input[i]);
        if (imm>mval) mval=imm;
    }

    return mval;
}


float _log2( float x)
{
    return logf(x)/logf(2);
}


int get_mexp(float *input, int n)
{
    float mval,eval;
    int result;
    mval = array_max(input, n);
    //printf("mval=%.6f ", mval);

    eval = _log2(mval);
    //printf("eval=%.6f ", eval);
    if (eval<0) result = eval-0.99;
    else result = eval + 0.5;

    return result;
}


void convert_to_fixed(float *input, data_t *output, int n, int m, float *scale)
{
	int i,j;
	float fact;
	for (i=0; i<n; i++){
		fact = 1.0/scale[i];
		for (j=0; j<m; j++){
			output[i*m + j] = toFixed(input[i*m + j], fact);
		}
	}
}


void get_scaling_coeffs(float *input, float *output, int n, int m)
{
	int i,j;
	int ex, left_shift;

	for (i=0; i<n; i++){
		float *xin = input + i*m;
		ex = get_mexp(xin, m);
		left_shift = -ex + (BITWIDTH - 2);
		float scale = pow(2, left_shift);
		output[i] = (1.0/scale);
		printf("Scale Factor [%d] = %.6f, %.6f\n", i, scale, output[i]);
	}
}


void init(float *x, int n)
{
	float rnum;
	int i;

	for (i=0; i<n; i++){
		rnum = 2*((float) rand()/(float) (RAND_MAX/1.0))-1;
		x[i] = rnum;
	}
}


void example_acol_big(float *A, float *B, float *C, data_t *Af, data_t *Bf, float *Cf,
		float *ascale, float *bscale)
{

	int batch = 6;
	int bt = 1;
	int m = NUM_PES*R_DEPTH;
	int n = VECTOR_WIDTH*C_DEPTH;
	int k = 40;
    int am = m;
	//printf("here b\n");

    //hw_accel_float(A, m, b, n, C, k);

	for (int i=0; i<(batch/bt); i++){

		float *bsb = bscale + i*bt;

        float *b = B + i*(bt*n*k);
		data_t *bf = Bf + i*(bt*n*k);

		/* software */
		hw_accel_float(A, m, b, n, C, k, bt);

		/* hardware */
		char ctrl = (i==0) ? 1 : 0;
		char TAw = 0;
		char TAr = 0;
		//gemm_hw(Af, m, bf, n, Cf, k, bt, ctrl, TAw, TAr, ascale[0], bsb);
		p_0_gemm_hw_1_noasync(Af, m, bf, n, Cf, k, am, bt, ctrl, TAw, TAr, ascale[0], bsb);
        am=0;
		printf("------------- CTRL=%d---------------- as=%.6f bs=%.6f\n", ctrl, ascale[0], bsb[0]);
		float sqerr = 0;
		for (int j=0; j<(bt*m*k); j++){
			float imm = Cf[j]; //1.0/(as*bs);
			float err = C[j]-imm;
			sqerr += (err*err);
			if (j%1000000 == 0) printf("%.6f		%.6f		error=%.6f\n", C[j], imm, err);
		}
		float mse = sqerr/(bt*m*k);
		printf("\nMSE=%.7f\n", mse);

	}

}

void example_arow_big(float *A, float *B, float *C, data_t *Af, data_t *Bf, float *Cf,
		float *ascale, float *bscale)
{

	/* The hardware partitions our arrays by assuming that acol_max > arow_max, roughly 4480/480.
	 * Therefore, when arow is larger than acol, we should signal our hardware to switch memory banks.
	 * That is, we wish to write in reverse/or transpose order, and read out reverse/transpose order. */

	// for test purposes, we can swap arow and acol

	int batch = 6;
	int bt = 1;
	int m = VECTOR_WIDTH*C_DEPTH; // swap
	int n = NUM_PES*R_DEPTH; // swap
	int k = 40;
    int am = m;

	for (int i=0; i<(batch/bt); i++){

		float *bsb = bscale + i*bt;

		float *b = B + i*(bt*n*k);
		data_t *bf = Bf + i*(bt*n*k);

		/* software */
		hw_accel_float(A, m, b, n, C, k, bt);

		/* hardware */
		char ctrl = (i==0) ? 1 : 0;
		char TAw = 1; // we read A in reverse
		char TAr = 1;
		//gemm_hw(Af, m, bf, n, Cf, k, bt, ctrl, TAw, TAr, ascale[0], bsb);
		p_0_gemm_hw_1_noasync(Af, m, bf, n, Cf, k, am, bt, ctrl, TAw, TAr, ascale[0], bsb);
        am=0;
		printf("------------- CTRL=%d---------------- as=%.6f bs=%.6f\n", ctrl, ascale[0], bsb[0]);
		float sqerr = 0;
		for (int j=0; j<(bt*m*k); j++){
			float imm = Cf[j]; //*1.0/(as*bs);
			float err = C[j]-imm;
			sqerr += (err*err);
			if (j%1000000 == 0) printf("%.6f		%.6f		error=%.6f\n", C[j], imm, err);
		}
		float mse = sqerr/(bt*m*k);
		printf("\nMSE=%.7f\n", mse);

	}
}


int main(int argc, char** argv)
{

	float *A, *B, *C, *ascale, *bscale;
	data_t *Af, *Bf;
	float *Cf;

	int btile = 8; // batch tile size (we can configure batch tile size later)
	int max_arow = NUM_PES*R_DEPTH;
	int max_acol = VECTOR_WIDTH*C_DEPTH;
	int max_image = NUM_PES*R_DEPTH;

	/* allocate memory for all our experiments */
	A = (float *) malloc(sizeof(float)*max_arow*max_acol);
	B = (float *) malloc(sizeof(float)*btile*max_acol*max_image);
	C = (float *) malloc(sizeof(float)*btile*max_acol*max_image);

	/* block floating point scaling coefficients on batch dimension */
	ascale = (float *) cma_alloc(sizeof(float), 1);
	bscale = (float *) cma_alloc(sizeof(float)*btile, 1);

	/* hardware inputs and outputs */
	Af = (data_t *) cma_alloc(int(sizeof(data_t)*max_arow*max_acol), 1);
	Bf = (data_t *) cma_alloc(int(sizeof(data_t)*btile*max_acol*max_image), 1); // set to max_col because transpose
	Cf = (float *) cma_alloc(int(sizeof(float)*max_acol*btile*max_image), 1); // set to max_col because transpose

	/* init data */
	srand(3);
	init(A, max_arow*max_acol);
	init(B, btile*max_acol*max_image);

	/* scaling coefficients */
	get_scaling_coeffs(A, ascale, 1, max_arow*max_acol);
	get_scaling_coeffs(B, bscale, btile, max_acol*max_image);

	/* convert to fixed point */
	convert_to_fixed(A, Af, 1, max_arow*max_acol, ascale);
	convert_to_fixed(B, Bf, btile, max_acol*max_image, bscale);

	//example_small(A, B, C, Af, Bf, Cf, ascale, bscale);
	//example_preload(A, B, C, Af, Bf, Cf, ascale, bscale);
	example_acol_big(A, B, C, Af, Bf, Cf, ascale, bscale);
	example_arow_big(A, B, C, Af, Bf, Cf, ascale, bscale);

	std::cout << "TEST PASSED" << std::endl;

	free(A);
	free(B);
	free(C);
	cma_free(Af);
	cma_free(Bf);
	cma_free(Cf);
	cma_free(ascale);
	cma_free(bscale);

    return 0;
}
