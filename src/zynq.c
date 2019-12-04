#include "libxlnk_cma.h"

#ifdef FPGA

void *zynq_alloc(uint32_t len, uint32_t cacheable)
{
    void *temp;
    temp = cma_alloc( len, cacheable );

    if ( temp == NULL ){
        printf("CMA_ALLOC FAILED: Failed to allocate memory of size %d\n", len);
    }

    return temp;

}


void zynq_free(void *buf)
{
    cma_free(buf);
}

#endif
