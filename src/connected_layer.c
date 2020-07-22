#include "connected_layer.h"
#include "convolutional_layer.h"
#include "batchnorm_layer.h"
#include "utils.h"
#include "cuda.h"
#include "blas.h"
#include "gemm.h"
#include "quant.h"
#include "activations.h"
#include "libxlnk_cma.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


void gemm_fixed(int8_t *A, int arow, int8_t *B, int brow, int *C, int ccol)
{

    // compute
    for (int i = 0; i < ccol; i++) {
        for (int j = 0; j < arow; j++) {
          int result = 0;
          for (int k = 0; k < brow; k++) {
            result += A[j*brow+k]*B[i*brow+k];
          }
          C[i*arow+j] = result;
        }
    }

}


layer make_connected_layer(int batch, int inputs, int outputs, ACTIVATION activation, int batch_normalize, int adam, int swa)
{
    int i;
    layer l = {0};
    l.learning_rate_scale = 1;
    l.type = CONNECTED;
    l.swa = swa;

    l.inputs = inputs;
    l.outputs = outputs;
    l.batch=batch;
    l.batch_normalize = batch_normalize;
    l.h = 1;
    l.w = 1;
    l.c = inputs;
    l.out_h = 1;
    l.out_w = 1;
    l.out_c = outputs;

    l.output = calloc(batch*outputs, sizeof(float));
    l.delta = calloc(batch*outputs, sizeof(float));

    l.weight_updates = calloc(inputs*outputs, sizeof(float));
    l.bias_updates = calloc(outputs, sizeof(float));

#if defined (LOWP) || defined (FPGA)
    l.qw = (quant *) malloc( sizeof(quant) );
    l.qa = (quant *) malloc( sizeof(quant) );
    l.qe = (quant *) malloc( sizeof(quant) );
    l.qw->nbits = 8;
    l.qa->nbits = 8;
    l.qe->nbits = 8;
#endif

#ifdef FPGA
    l.weights = (int8_t *) zynq_alloc(outputs*inputs, sizeof(int8_t));
    l.input = (int8_t *) zynq_alloc(batch*inputs, sizeof(int8_t));
    l.bscale = (float *) zynq_alloc(l.batch*sizeof(float), 1);
#elif LOWP
    l.weights = calloc(outputs*inputs, sizeof(int8_t));
    l.input = calloc(batch*inputs, sizeof(int8_t));
    l.bscale = (float *) calloc(l.batch*sizeof(float), 1);
#else
    l.weights = calloc(outputs*inputs, sizeof(float));
#endif

    l.biases = calloc(outputs, sizeof(float));

    if(swa) l.weights_swa = calloc(outputs*inputs, sizeof(float));

#ifdef FPGA
    l.forward = forward_connected_layer_fpga;
    l.backward = backward_connected_layer_fpga;
    l.update = update_connected_layer_fpga;
#elif LOWP
    l.forward = forward_connected_layer_lowp;
    l.backward = backward_connected_layer_lowp;
    l.update = update_connected_layer_lowp;
#else
    l.forward = forward_connected_layer;
    l.backward = backward_connected_layer;
    l.update = update_connected_layer;
#endif

    if(swa) l.update_swa = update_swa_connected_layer;

    //float scale = 1./sqrt(inputs);
    float scale = sqrt(2./inputs);
    for(i = 0; i < outputs*inputs; ++i){
#if defined (LOWP) || defined (FPGA)
        l.weight_updates[i] = scale*rand_uniform(-1, 1);
#else
        l.weights[i] = scale*rand_uniform(-1, 1);
#endif
    }
    for(i = 0; i < outputs; ++i){
        l.biases[i] = 0;
    }

#if defined (LOWP) || defined (FPGA)
    quantize_with_update(l.weight_updates, l.weights, l.inputs*l.outputs, l.qw); // bit hacky using weight_updates
    fill_cpu(l.inputs*l.outputs, 0, l.weight_updates, 1);
    //printf("qw: nbits=%d exp=%d scale=%.6f\n", l.qw->nbits, l.qw->exp, l.qw->scale);
#endif

    if(adam){
        l.m = calloc(l.inputs*l.outputs, sizeof(float));
        l.v = calloc(l.inputs*l.outputs, sizeof(float));
        l.bias_m = calloc(l.outputs, sizeof(float));
        l.scale_m = calloc(l.outputs, sizeof(float));
        l.bias_v = calloc(l.outputs, sizeof(float));
        l.scale_v = calloc(l.outputs, sizeof(float));
    }
    if(batch_normalize){
        l.scales = calloc(outputs, sizeof(float));
        l.scale_updates = calloc(outputs, sizeof(float));
        for(i = 0; i < outputs; ++i){
            l.scales[i] = 1;
        }

        l.mean = calloc(outputs, sizeof(float));
        l.mean_delta = calloc(outputs, sizeof(float));
        l.variance = calloc(outputs, sizeof(float));
        l.variance_delta = calloc(outputs, sizeof(float));

        l.rolling_mean = calloc(outputs, sizeof(float));
        l.rolling_variance = calloc(outputs, sizeof(float));

        l.x = calloc(batch*outputs, sizeof(float));
        l.x_norm = calloc(batch*outputs, sizeof(float));
    }

#ifdef GPU
    l.forward_gpu = forward_connected_layer_gpu;
    l.backward_gpu = backward_connected_layer_gpu;
    l.update_gpu = update_connected_layer_gpu;

    l.weights_gpu = cuda_make_array(l.weights, outputs*inputs);
    l.biases_gpu = cuda_make_array(l.biases, outputs);

    l.weight_updates_gpu = cuda_make_array(l.weight_updates, outputs*inputs);
    l.bias_updates_gpu = cuda_make_array(l.bias_updates, outputs);

    l.output_gpu = cuda_make_array(l.output, outputs*batch);
    l.delta_gpu = cuda_make_array(l.delta, outputs*batch);
    if (adam) {
        l.m_gpu =       cuda_make_array(0, inputs*outputs);
        l.v_gpu =       cuda_make_array(0, inputs*outputs);
        l.bias_m_gpu =  cuda_make_array(0, outputs);
        l.bias_v_gpu =  cuda_make_array(0, outputs);
        l.scale_m_gpu = cuda_make_array(0, outputs);
        l.scale_v_gpu = cuda_make_array(0, outputs);
    }

    if(batch_normalize){
        l.mean_gpu = cuda_make_array(l.mean, outputs);
        l.variance_gpu = cuda_make_array(l.variance, outputs);

        l.rolling_mean_gpu = cuda_make_array(l.mean, outputs);
        l.rolling_variance_gpu = cuda_make_array(l.variance, outputs);

        l.mean_delta_gpu = cuda_make_array(l.mean, outputs);
        l.variance_delta_gpu = cuda_make_array(l.variance, outputs);

        l.scales_gpu = cuda_make_array(l.scales, outputs);
        l.scale_updates_gpu = cuda_make_array(l.scale_updates, outputs);

        l.x_gpu = cuda_make_array(l.output, l.batch*outputs);
        l.x_norm_gpu = cuda_make_array(l.output, l.batch*outputs);
#ifdef CUDNN
        cudnnCreateTensorDescriptor(&l.normTensorDesc);
        cudnnCreateTensorDescriptor(&l.dstTensorDesc);
        cudnnSetTensor4dDescriptor(l.dstTensorDesc, CUDNN_TENSOR_NCHW, CUDNN_DATA_FLOAT, l.batch, l.out_c, l.out_h, l.out_w); 
        cudnnSetTensor4dDescriptor(l.normTensorDesc, CUDNN_TENSOR_NCHW, CUDNN_DATA_FLOAT, 1, l.out_c, 1, 1); 
#endif
    }
#endif

#if defined (LOWP) || defined (FPGA)
    l.workspace_size = (l.inputs*l.outputs*4 > l.outputs*l.batch*4) ? (l.inputs*l.outputs*4) : (l.outputs*l.batch*4);
    l.cf_size = (l.outputs*l.batch*4 > l.inputs*l.outputs*4) ? (l.outputs*l.batch*4) : (l.inputs*l.outputs*4);
    l.af_size = l.batch*l.inputs*l.outputs;
    l.bf_size = l.batch*l.outputs*1;
    l.df_size = l.batch*l.outputs*1;
#else
    l.workspace_size = 4;
#endif

    l.activation = activation;
    fprintf(stderr, "connected                            %4d  ->  %4d\n", inputs, outputs);
    return l;
}


void update_swa_connected_layer(layer l, update_args a)
{
    float n_alpha = 1 - a.alpha;

    scal_cpu(l.inputs*l.outputs, n_alpha, l.weights_swa, 1);

#if defined (LOWP) || defined (FPGA)
    dequantize_int8(l.weights, a.workspace, l.inputs*l.outputs, l.qw->scale);
    axpy_cpu(l.inputs*l.outputs, a.alpha, a.workspace, 1, l.weights_swa, 1);
#else
    axpy_cpu(l.inputs*l.outputs, a.alpha, l.weights, 1, l.weights_swa, 1);
#endif
}

#ifdef FPGA
void update_connected_layer_fpga(layer l, update_args a)
{
    float learning_rate = a.learning_rate*l.learning_rate_scale;
    float momentum = a.momentum;
    float decay = a.decay;
    int batch = a.batch;

    axpy_cpu(l.outputs, learning_rate/batch, l.bias_updates, 1, l.biases, 1);
    scal_cpu(l.outputs, momentum, l.bias_updates, 1);

    if(l.batch_normalize){
        axpy_cpu(l.outputs, learning_rate/batch, l.scale_updates, 1, l.scales, 1);
        scal_cpu(l.outputs, momentum, l.scale_updates, 1);
    }

    float *temp = a.workspace;
    dequantize_int8(l.weights, temp, l.inputs*l.outputs, l.qw->scale);

    //axpy_cpu(l.inputs*l.outputs, -decay*batch, temp, 1, l.weight_updates, 1);
    //axpy_cpu(l.inputs*l.outputs, learning_rate/batch, l.weight_updates, 1, temp, 1);

    axpy_cpu(l.inputs*l.outputs, decay*batch, temp, 1, l.weight_updates, 1);
    axpy_cpu(l.inputs*l.outputs, learning_rate/batch, l.weight_updates, 1, temp, 1);

    scal_cpu(l.inputs*l.outputs, momentum, l.weight_updates, 1);
    quantize_with_update(temp, l.weights, l.inputs*l.outputs, l.qw);
}

void forward_connected_layer_fpga(layer l, network net)
{
    fill_cpu(l.batch*l.outputs, 0, l.output, 1);

    int m = l.batch;
    int n = l.outputs;
    int k = l.inputs;

    int8_t *a = l.weights;
    int8_t *b = l.input;
    float *c = l.output;

    int ctrl=1;
    int an=n;

    quantize_with_update(net.input, b, m*k, l.qa);
    l.bscale[0] = l.qa->scale;

    p_0_gemm_hw_1_noasync(a, n, b, k, net.cf, m, an, 1, ctrl, 0, 0, l.qw->scale, l.bscale);
    ctrl = 0;
    an = 0;

    copy_cpu(n*m, net.cf, 1, c, 1); // need to remove this

    if(l.batch_normalize){
        forward_batchnorm_layer(l, net);
    } else {
        add_bias(l.output, l.biases, l.batch, l.outputs, 1);
    }
    activate_array(l.output, l.outputs*l.batch, l.activation);

}

void backward_connected_layer_fpga(layer l, network net)
{ 
    // quantise l.delta here!! really!! // make sure net.bf is big enough
    //if (strcmp(get_activation_string(l.activation), "linear")==0){
    //}else{
    //quantize_with_update(l.delta, net.bf, l.outputs*l.batch, l.qe);
    //dequantize_int8(net.bf, l.delta, l.outputs*l.batch, l.qe->scale);
    //}

    gradient_array(l.output, l.outputs*l.batch, l.activation, l.delta);

    if(l.batch_normalize){
        backward_batchnorm_layer(l, net);
    } else {
        backward_bias(l.bias_updates, l.delta, l.batch, l.outputs, 1);
    }

    int m = l.outputs;
    int k = l.batch;
    int n = l.inputs;
    float scale;

    int8_t *a = net.af;
    int8_t *b = net.bf;
    float *c = l.weight_updates;

    transpose_int8(l.input, net.af, k, n);
    quantize_with_update_transpose(l.delta, net.bf, k, m, k*m, l.qe);
    l.bscale[0] = l.qa->scale;

    int TAr = 0;
    int TAw = 0;
    int ctrl = 1;
    int an = n;
    
    p_0_gemm_hw_1_noasync(a, n, b, k, net.cf, m, an, 1, ctrl, TAw, TAr, l.qe->scale, l.bscale);
    ctrl = 0;
    an = 0;
    axpy_cpu(m*n, 1, net.cf, 1, c, 1);


    //gemm_fixed(a, n, b, k, net.cf, m);
    //scale = (l.qa->scale)*(l.qe->scale);
    //dequantize_acc_int(net.cf, c, m*n, scale);   

    if (net.delta){

        m = l.batch;
        k = l.outputs;
        n = l.inputs;

        /*
        a = net.af; 
        b = net.df;
        c = net.delta;

        transpose_int8(l.weights, net.af, k, n);
        transpose_int8(net.bf, net.df, k, m);
        gemm_fixed(a, n, b, k, net.cf, m);
        scale = (l.qw->scale)*(l.qe->scale);
        dequantize(net.cf, c, n*m, scale);
        */

        a = net.af;
        b = net.df;
        c = net.delta;

        ctrl=1;
        an = n;
        TAw = 1;
        TAr = 1;

        //net.af = l.weights;
        transpose_int8(l.weights, net.af, k, n);
        transpose_int8(net.bf, net.df, k, m);
        l.bscale[0] = l.qe->scale;

        p_0_gemm_hw_1_noasync(a, n, b, k, net.cf, m, an, 1, ctrl, TAw, TAr, l.qw->scale, l.bscale);
        ctrl=0;
        an=0;

        copy_cpu(n*m, net.cf, 1, c, 1); // need to remove this

    }

}
#endif


#ifdef LOWP
void update_connected_layer_lowp(layer l, update_args a)
{
    float learning_rate = a.learning_rate*l.learning_rate_scale;
    float momentum = a.momentum;
    float decay = a.decay;
    int batch = a.batch;

    axpy_cpu(l.outputs, learning_rate/batch, l.bias_updates, 1, l.biases, 1);
    scal_cpu(l.outputs, momentum, l.bias_updates, 1);

    if(l.batch_normalize){
        axpy_cpu(l.outputs, learning_rate/batch, l.scale_updates, 1, l.scales, 1);
        scal_cpu(l.outputs, momentum, l.scale_updates, 1);
    }

    float *temp = a.workspace;
    dequantize_int8(l.weights, temp, l.inputs*l.outputs, l.qw->scale);

    //axpy_cpu(l.inputs*l.outputs, -decay*batch, temp, 1, l.weight_updates, 1);
    //axpy_cpu(l.inputs*l.outputs, learning_rate/batch, l.weight_updates, 1, temp, 1);

    axpy_cpu(l.inputs*l.outputs, decay*batch, temp, 1, l.weight_updates, 1);
    axpy_cpu(l.inputs*l.outputs, learning_rate/batch, l.weight_updates, 1, temp, 1);

    scal_cpu(l.inputs*l.outputs, momentum, l.weight_updates, 1);
    quantize_with_update(temp, l.weights, l.inputs*l.outputs, l.qw);
}

void forward_connected_layer_lowp(layer l, network net)
{
    fill_cpu(l.batch*l.outputs, 0, l.output, 1);

    int m = l.batch;
    int n = l.outputs;
    int k = l.inputs;
    float scale;

    int8_t *a = l.weights;
    int8_t *b = l.input;
    float *c = l.output;

    quantize_with_update(net.input, b, m*k, l.qa);
    //gemm_lowp(a, n, b, k, net.cf, m); // gemm_lowp does not work for int8 operands
    gemm_fixed(a, n, b, k, net.cf, m);
    scale = (l.qa->scale)*(l.qw->scale);
    dequantize(net.cf, c, n*m, scale);

    if(l.batch_normalize){
        forward_batchnorm_layer(l, net);
    } else {
        add_bias(l.output, l.biases, l.batch, l.outputs, 1);
    }
    activate_array(l.output, l.outputs*l.batch, l.activation);

}

void backward_connected_layer_lowp(layer l, network net)
{ 
    // quantise l.delta here!! really!! // make sure net.bf is big enough
    //if (strcmp(get_activation_string(l.activation), "linear")==0){
    //}else{
    //quantize_with_update(l.delta, net.bf, l.outputs*l.batch, l.qe);
    //dequantize_int8(net.bf, l.delta, l.outputs*l.batch, l.qe->scale);
    //}

    gradient_array(l.output, l.outputs*l.batch, l.activation, l.delta);

    if(l.batch_normalize){
        backward_batchnorm_layer(l, net);
    } else {
        backward_bias(l.bias_updates, l.delta, l.batch, l.outputs, 1);
    }

    int m = l.outputs;
    int k = l.batch;
    int n = l.inputs;
    float scale;

    int8_t *a = net.af;
    int8_t *b = net.bf;
    float *c = l.weight_updates;

    transpose_int8(l.input, net.af, k, n);
    quantize_with_update_transpose(l.delta, net.bf, k, m, k*m, l.qe);
    gemm_fixed(a, n, b, k, net.cf, m);
    scale = (l.qa->scale)*(l.qe->scale);
    dequantize_acc_int(net.cf, c, m*n, scale);   

    if (net.delta){

        m = l.batch;
        k = l.outputs;
        n = l.inputs;

        a = net.af; 
        b = net.df;
        c = net.delta;

        transpose_int8(l.weights, net.af, k, n);
        transpose_int8(net.bf, net.df, k, m);
        gemm_fixed(a, n, b, k, net.cf, m);
        scale = (l.qw->scale)*(l.qe->scale);
        dequantize(net.cf, c, n*m, scale);

    }

}
#endif

void update_connected_layer(layer l, update_args a)
{
    float learning_rate = a.learning_rate*l.learning_rate_scale;
    float momentum = a.momentum;
    float decay = a.decay;
    int batch = a.batch;
    axpy_cpu(l.outputs, learning_rate/batch, l.bias_updates, 1, l.biases, 1);
    scal_cpu(l.outputs, momentum, l.bias_updates, 1);

    if(l.batch_normalize){
        axpy_cpu(l.outputs, learning_rate/batch, l.scale_updates, 1, l.scales, 1);
        scal_cpu(l.outputs, momentum, l.scale_updates, 1);
    }

    axpy_cpu(l.inputs*l.outputs, -decay*batch, l.weights, 1, l.weight_updates, 1);
    axpy_cpu(l.inputs*l.outputs, learning_rate/batch, l.weight_updates, 1, l.weights, 1);
    scal_cpu(l.inputs*l.outputs, momentum, l.weight_updates, 1);
}

void forward_connected_layer(layer l, network net)
{
    fill_cpu(l.outputs*l.batch, 0, l.output, 1);
    int m = l.batch;
    int k = l.inputs;
    int n = l.outputs;
    float *a = net.input;
    float *b = l.weights;
    float *c = l.output;
    gemm(0,1,m,n,k,1,a,k,b,k,1,c,n);
    if(l.batch_normalize){
        forward_batchnorm_layer(l, net);
    } else {
        add_bias(l.output, l.biases, l.batch, l.outputs, 1);
    }
    activate_array(l.output, l.outputs*l.batch, l.activation);
}

void backward_connected_layer(layer l, network net)
{
    gradient_array(l.output, l.outputs*l.batch, l.activation, l.delta);

    if(l.batch_normalize){
        backward_batchnorm_layer(l, net);
    } else {
        backward_bias(l.bias_updates, l.delta, l.batch, l.outputs, 1);
    }

    int m = l.outputs;
    int k = l.batch;
    int n = l.inputs;
    float *a = l.delta;
    float *b = net.input;
    float *c = l.weight_updates;
    gemm(1,0,m,n,k,1,a,m,b,n,1,c,n);

    m = l.batch;
    k = l.outputs;
    n = l.inputs;

    a = l.delta;
    b = l.weights;
    c = net.delta;

    if(c) gemm(0,0,m,n,k,1,a,k,b,n,1,c,n);
}


void denormalize_connected_layer(layer l)
{
    int i, j;
    for(i = 0; i < l.outputs; ++i){
        float scale = l.scales[i]/sqrt(l.rolling_variance[i] + .000001);
        for(j = 0; j < l.inputs; ++j){
            l.weights[i*l.inputs + j] *= scale;
        }
        l.biases[i] -= l.rolling_mean[i] * scale;
        l.scales[i] = 1;
        l.rolling_mean[i] = 0;
        l.rolling_variance[i] = 1;
    }
}


void statistics_connected_layer(layer l)
{
    if(l.batch_normalize){
        printf("Scales ");
        print_statistics(l.scales, l.outputs);
        /*
           printf("Rolling Mean ");
           print_statistics(l.rolling_mean, l.outputs);
           printf("Rolling Variance ");
           print_statistics(l.rolling_variance, l.outputs);
         */
    }
    printf("Biases ");
    print_statistics(l.biases, l.outputs);
    printf("Weights ");
    print_statistics(l.weights, l.outputs);
}

#ifdef GPU

void pull_connected_layer(layer l)
{
    cuda_pull_array(l.weights_gpu, l.weights, l.inputs*l.outputs);
    cuda_pull_array(l.biases_gpu, l.biases, l.outputs);
    cuda_pull_array(l.weight_updates_gpu, l.weight_updates, l.inputs*l.outputs);
    cuda_pull_array(l.bias_updates_gpu, l.bias_updates, l.outputs);
    if (l.batch_normalize){
        cuda_pull_array(l.scales_gpu, l.scales, l.outputs);
        cuda_pull_array(l.rolling_mean_gpu, l.rolling_mean, l.outputs);
        cuda_pull_array(l.rolling_variance_gpu, l.rolling_variance, l.outputs);
    }
}

void push_connected_layer(layer l)
{
    cuda_push_array(l.weights_gpu, l.weights, l.inputs*l.outputs);
    cuda_push_array(l.biases_gpu, l.biases, l.outputs);
    cuda_push_array(l.weight_updates_gpu, l.weight_updates, l.inputs*l.outputs);
    cuda_push_array(l.bias_updates_gpu, l.bias_updates, l.outputs);
    if (l.batch_normalize){
        cuda_push_array(l.scales_gpu, l.scales, l.outputs);
        cuda_push_array(l.rolling_mean_gpu, l.rolling_mean, l.outputs);
        cuda_push_array(l.rolling_variance_gpu, l.rolling_variance, l.outputs);
    }
}

void update_connected_layer_gpu(layer l, update_args a)
{
    float learning_rate = a.learning_rate*l.learning_rate_scale;
    float momentum = a.momentum;
    float decay = a.decay;
    int batch = a.batch;
    if(a.adam){
        adam_update_gpu(l.weights_gpu, l.weight_updates_gpu, l.m_gpu, l.v_gpu, a.B1, a.B2, a.eps, decay, learning_rate, l.inputs*l.outputs, batch, a.t);
        adam_update_gpu(l.biases_gpu, l.bias_updates_gpu, l.bias_m_gpu, l.bias_v_gpu, a.B1, a.B2, a.eps, decay, learning_rate, l.outputs, batch, a.t);
        if(l.scales_gpu){
            adam_update_gpu(l.scales_gpu, l.scale_updates_gpu, l.scale_m_gpu, l.scale_v_gpu, a.B1, a.B2, a.eps, decay, learning_rate, l.outputs, batch, a.t);
        }
    }else{
        axpy_gpu(l.outputs, learning_rate/batch, l.bias_updates_gpu, 1, l.biases_gpu, 1);
        scal_gpu(l.outputs, momentum, l.bias_updates_gpu, 1);

        if(l.batch_normalize){
            axpy_gpu(l.outputs, learning_rate/batch, l.scale_updates_gpu, 1, l.scales_gpu, 1);
            scal_gpu(l.outputs, momentum, l.scale_updates_gpu, 1);
        }

        axpy_gpu(l.inputs*l.outputs, -decay*batch, l.weights_gpu, 1, l.weight_updates_gpu, 1);
        axpy_gpu(l.inputs*l.outputs, learning_rate/batch, l.weight_updates_gpu, 1, l.weights_gpu, 1);
        scal_gpu(l.inputs*l.outputs, momentum, l.weight_updates_gpu, 1);
    }
}

void forward_connected_layer_gpu(layer l, network net)
{
    fill_gpu(l.outputs*l.batch, 0, l.output_gpu, 1);

    int m = l.batch;
    int k = l.inputs;
    int n = l.outputs;
    float * a = net.input_gpu;
    float * b = l.weights_gpu;
    float * c = l.output_gpu;
    gemm_gpu(0,1,m,n,k,1,a,k,b,k,1,c,n);

    if (l.batch_normalize) {
        forward_batchnorm_layer_gpu(l, net);
    } else {
        add_bias_gpu(l.output_gpu, l.biases_gpu, l.batch, l.outputs, 1);
    }
    activate_array_gpu(l.output_gpu, l.outputs*l.batch, l.activation);
}

void backward_connected_layer_gpu(layer l, network net)
{
    constrain_gpu(l.outputs*l.batch, 1, l.delta_gpu, 1);
    gradient_array_gpu(l.output_gpu, l.outputs*l.batch, l.activation, l.delta_gpu);
    if(l.batch_normalize){
        backward_batchnorm_layer_gpu(l, net);
    } else {
        backward_bias_gpu(l.bias_updates_gpu, l.delta_gpu, l.batch, l.outputs, 1);
    }

    int m = l.outputs;
    int k = l.batch;
    int n = l.inputs;
    float * a = l.delta_gpu;
    float * b = net.input_gpu;
    float * c = l.weight_updates_gpu;
    gemm_gpu(1,0,m,n,k,1,a,m,b,n,1,c,n);

    m = l.batch;
    k = l.outputs;
    n = l.inputs;

    a = l.delta_gpu;
    b = l.weights_gpu;
    c = net.delta_gpu;

    if(c) gemm_gpu(0,0,m,n,k,1,a,k,b,n,1,c,n);
}
#endif
