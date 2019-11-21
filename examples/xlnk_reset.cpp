
// This program is to reset xlnk cma array

#include <time.h>
#include <iostream>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
//#include "sds_lib.h"

extern "C" {
#include "darknet.h"
#include "libxlnk_cma.h"
#include <linux/ioctl.h>
#include <errno.h>
#include <dlfcn.h> 
}

#define RESET_IOCTL _IOWR('X', 101, unsigned long)

void _xlnk_reset_b() {
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


void xl_rst()
{

   
    uint32_t pages_before, pages_reset;

    pages_before = cma_pages_available();
    printf("PAGES AVAILABLE: %u\n", pages_before);

    // reset all system cma buffers
    _xlnk_reset_b();

    pages_reset = cma_pages_available();
    printf("PAGES AVAILABLE (RESET): %u\n", pages_reset);

}



void run_xlnk_reset(int argc, char** argv)
{

    xl_rst();    

}
