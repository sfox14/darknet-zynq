#ifdef LOWP

#include "quant.h"
#include <math.h>


float max_array(float *input, int n)
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
    mval = max_array(input, n);
    //printf("mval=%.4f ", mval);

    eval = _log2(mval);
    //printf("eval=%.6f ", eval);
    if (eval<0) result = floor(eval); //-0.99;
    else result = floor(eval); // + 0.5;

    // result.clamp(exp_min, exp_max)
    //printf("exp=%d\n", result);

    if (result>exp_max) return exp_max;
        else if (result<exp_min) return exp_min;
            else return result;

    return result;
}


// type conversion functions for block floating point 
float _toFloat(int a, float scale)
{
    float result;
    result = (float)(a) * scale;
    return result;
}

float _toFloat_int8(int8_t a, float scale)
{

    float result;
    result = a * scale;

    return result;
}

float stochastic_rounding(float x){

    float decimal = fabs(x - trunc(x));
    float random_selector = (float)rand() / RAND_MAX;
    float adjustor;
    if (random_selector < decimal) adjustor = 1;
    else adjustor = 0;
    // consider sign
    if(x < 0) adjustor = -1 * adjustor;

    return trunc(x) + adjustor;

}

float nearest_rounding(float x){
    
    float result;
    float imm;
    imm = x + 0.5;
    result = floor(imm);
    return result;
}


void _transpose_float(int *input, float *output, int dim1, int dim2, float scale)
{
    for (int i=0; i<dim1; i++){
        for (int j=0; j<dim2; j++){
            output[j*dim1 + i] = (float) _toFloat(input[i*dim2 + j], scale);
        }
    }
}

void _array_float(int *input, float *output, int n, float scale)
{
    for (int i=0; i<n; i++){
        output[i] = (float) _toFloat(input[i], scale);
    }
}

void _array_int8_float(int8_t *input, float *output, int n, float scale)
{
    for (int i=0; i<n; i++){
        output[i] = (float) _toFloat_int8(input[i], scale);
    }
}


int8_t _toFixed_int8(float a, int fbits)
{
    
    
    int temp, temp2;
    int8_t result;
    float scale;
    float imm;

    scale = pow(2, fbits);
    imm = a * scale;

    //imm = stochastic_rounding(imm);
    //result = imm;

    imm = nearest_rounding(imm);
    temp = imm;
    temp2 = (temp < -128) ? -128 : temp;  // 8-bit boundaries
    result = (temp2 > 127) ? 127 : temp2;
    return result;
    
}

void transpose_fixed_int8(float *input, int8_t *output, int dim1, int dim2, int fbits)
{
    for (int i=0; i<dim1; i++){
        for (int j=0; j<dim2; j++){
            output[j*dim1 + i] = (int8_t) _toFixed_int8(input[i*dim2 + j], fbits);

        }
    }
}


void array_fixed_int8(float *input, int8_t *output, int n, int fbits)
{
    for (int i=0; i<n; i++){
        output[i] = (int) _toFixed_int8(input[i], fbits);

    }
}


void quantize_with_update(float *input, int8_t *output, int n, quant *qf)
{
    int exp, left_shift, right_shift;
    float scale;

    exp = get_mexp(input, n);
    left_shift = -exp + (qf->nbits - 2);
    right_shift = exp - (qf->nbits - 2);

    array_fixed_int8(input, output, n, left_shift);

    scale = pow(2, right_shift);
    qf->exp = exp;
    qf->scale = scale;

}

void quantize(float *input, int8_t *output, int n, quant *qf)
{
    int exp, left_shift;

    exp = qf->exp;
    left_shift = -exp + (qf->nbits - 2);

    array_fixed_int8(input, output, n, left_shift);

}


void quantize_with_update_transpose(float *input, int8_t *output, int dim1, int dim2, int n, quant *qf)
{
    int exp, left_shift, right_shift;
    float scale;

    exp = get_mexp(input, n);
    left_shift = -exp + (qf->nbits - 2);
    right_shift = exp - (qf->nbits - 2);

    transpose_fixed_int8(input, output, dim1, dim2, left_shift);

    scale = pow(2, right_shift);
    qf->exp = exp;
    qf->scale = scale;

}

void dequantize(int *input, float *output, int n, float scale)
{
    for (int i=0; i<n; i++){
        output[i] = (float) _toFloat(input[i], scale);
    }
}

void dequantize_int8(int8_t *input, float *output, int n, float scale)
{

    for (int i=0; i<n; i++){
        output[i] = (float) _toFloat_int8(input[i], scale);
    }
}


void dequantize_acc_int(int *input, float *output, int n, float scale)
{

    for (int i=0; i<n; i++){
        output[i] += (float) _toFloat(input[i], scale);
    }
}


void transpose_int8(int8_t *input, int8_t *output, int dim1, int dim2)
{
    for (int i=0; i<dim1; i++){
        for (int j=0; j<dim2; j++){
            output[j*dim1 + i] = input[i*dim2 + j];
        }
    }
}


#endif