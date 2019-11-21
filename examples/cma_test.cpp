
// This program is for checking CMA available pages

#include <time.h>
#include <iostream>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
//#include "sds_lib.h"

extern "C" {
#include "darknet.h"
#include "utils.h"
//#include "data.h"
#include "libxlnk_cma.h"
#include <linux/ioctl.h>
#include <errno.h>
#include <dlfcn.h> 
}

#define RESET_IOCTL _IOWR('X', 101, unsigned long)

#define BUF_SIZE_A (16*1024*1024) // 16 Mbytes
#define BUF_SIZE_B (32*1024*1024) // 32 Mbytes
#define BUF_SIZE_C (64*1024*1024) // 64 Mbytes
#define BUF_SIZE_D (128*1024*1024) // 128 Mbytes
#define BUF_SIZE_E (256*1024*1024) // 256 Mbytes

#define AM 168
#define AN 1520
#define SIZE 32
#define ICH 64
#define OCH 64
#define NINS 41
#define NOUTS 42

#define BSIZE 32
#define BTILE 32 //32

// VGG (Max Parameters):
// ---------------------
// ACTS                 = Input Layer 2 = 64x32x32xBSIZE (Float)
// WEIGHTS              = Layer 12-14 = 512x512x9 (int8_t)
// GRADS (pre col2im)   = Between Layer 2 -> 1 = 64x32x32x9xBSIZE (float)
// GRADS (after col2im) = Between Layer 2 -> 1 = 64x32x32xBSIZE

// net.data_temp        = Temporary float and output activations (not tiled, full batch size)
// net.af               = Quantised input delta for bwd only (not tiled, full batch size) 
// net.bf               = im2col l.input (fwd and bwd1) and transpose (bwd) 
// net.cf               = Float output. 

// net.data_temp        = 0.27 MB x BSIZE, 64x32x32xBSIZEx4 bytes or l.weights max 
// net.af               = 0.07 MB x BSIZE, 64x32x32xBSIZE bytes 
// net.bf               = 0.58 MB x BTILE, 64x32x32x9xBTILE bytes
// net.cf               = 2.32 MB x BTILE, 64x32x32x9xBTILEx4 bytes
// net.df/l.input       = 0.07 MB x BSIZE, 64x32x32xBSIZE bytes (on a per layer basis)
// l.weights            = 2.35 MB, 512x512x9 bytes (on a per layer basis)

// According to SDSoC documentation, axi_dma_simple transfer size is limited to <=32 MB.
// We must chose our batch size and tile size to fit under this restriction.

// We can see the number of available pages in virtual memory (each are 4kB). On Pynq-Z1
// there are 32695 tables available when the application is launched, which approx.
// equals 120-130 MB available to use. We might need to increase the Contiguous 
// memory allocator in our PYNQ image to allow for larger allocations. Default is 128 MB 

// Benchmark works a little different. Don't have l.input yet, so use net.df for now.

template <typename T>  
void xi_init(T *x, int size) 
{

    int i;
    for (i=0; i<size; i++){
        x[i] = 0;
    }

}

void _xlnk_reset_a() {
    /* This performs the correct ioctl but probably isn't
       particularly stable as a behaviour */
    int xlnkfd = open("/dev/xlnk", O_RDWR | O_CLOEXEC);
    if (xlnkfd < 0) {
        printf("Reset failed - could not open device: %d\n", xlnkfd);
        return;
    }
    if (ioctl(xlnkfd, RESET_IOCTL, 0) < 0) {
        printf("Reset failed - IOCTL failed: %d\n", errno);
    }
    close(xlnkfd);
}


void cma_test()
{
    // Checks the CMA available pages
   
    uint32_t pages_before, pages_after, pages_reset;
    
    pages_before = cma_pages_available();
    printf("PAGES AVAILABLE (BEFORE): %u\n", pages_before);

    int8_t *af0, *af1; //, *af2;
    float *cf;
    af0 = (int8_t *) cma_alloc( BTILE * 64 * 32 * 32 * 9 * sizeof(int8_t), 1 );
    af1 = (int8_t *) cma_alloc( BTILE * 64 * 32 * 32 * 9 * sizeof(int8_t), 1 );
    //af2 = (int8_t *) cma_alloc( BTILE * 64 * 32 * 32 * 9 * sizeof(int8_t), 0 ); // fail with this
    cf = (float *) cma_alloc( BTILE * 64 * 32 * 32 * 9 * sizeof(float), 1 );

    pages_after = cma_pages_available();
    printf("PAGES AVAILABLE (AFTER): %u\n", pages_after);


    if( (af0 == NULL) || (af1 == NULL) || (cf == NULL) ) { // || (af2 == NULL) {
        std::cout << "TEST FAILED : Failed to allocate memory" << std::endl;
        exit(1);
    }

    // reset all system cma buffers
    _xlnk_reset_a();

    pages_reset = cma_pages_available();
    printf("PAGES AVAILABLE (RESET): %u\n", pages_reset);


    cma_free(af0);
    cma_free(af1);
    //cma_free(af2);
    cma_free(cf);


}



void run_cma_test(int argc, char** argv)
{

    cma_test();    

}
