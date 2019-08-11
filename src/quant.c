#ifdef LOWP

#include "quant.h"


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
    //printf("mval=%.6f ", mval);

    eval = _log2(mval);
    //printf("eval=%.6f ", eval);
    if (eval<0) result = eval-0.99;
    else result = eval + 0.5;

    // result.clamp(exp_min, exp_max)
    if (result>exp_max) return exp_max;
        else if (result<exp_min) return exp_min;
            else return result;

    return result;
}


// type conversion functions for block floating point 
float _toFloat(int a, float scale)
{

    static int cnt = 0;

    float result;
    //int fb = abs(fbits);
    //float val = 1; // << fb;
    //if (fbits>0) result = a/val;
    //else result = a*val;
    result = a * scale;

    if (cnt < 256){
        //printf("%d %.6f %.6f\n", a, scale, result);
        cnt += 1;
    }


    return result;
}

float _toFloat_int8(int8_t a, float scale)
{

    static int cnt = 0;

    float result;
    //int fb = abs(fbits);
    //float val = 1; // << fb;
    //if (fbits>0) result = a/val;
    //else result = a*val;
    result = a * scale;

    if (cnt < 256){
        //printf("%d %.6f %.6f\n", a, scale, result);
        cnt += 1;
    }


    return result;
}

int _toFixed(float a, int fbits)
{

    int static cnt = 0;

    int result;
    int fb = abs(fbits);
    int val = 1 << fb; //logical shift

    float imm;
    if (fbits>0) imm=a*val;
    else imm = a/val;

    if (a<0) result = imm - 0.5; //nearest rounding
    else result = imm + 0.5;

    //if (cnt<108) printf("%.6f %d\n", a, result);


    cnt += 1;

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

    int8_t result;
    int fb = abs(fbits);
    int val = 1 << fb; //logical shift

    float imm;
    if (fbits>0) imm=a*val; // do left shift
    else imm = a/val; // do right_shift

    if (a<0) result = imm - 0.5; //nearest rounding
    else result = imm + 0.5;

    //printf("%d %.6f %.6f\n", result, imm, a);

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

        //check_float(input[i]);
        //check_error(input[i], output[i], fbits);
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