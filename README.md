<p align="center">
<img src="./data/logo.png" alt="Drawing" width="600"/>
</p>

# Darknet #
Darknet is an open source neural network framework written in C and CUDA. It is fast, easy to install, and supports CPU and GPU computation.

For more information see the [Darknet project website](http://pjreddie.com/darknet).

For questions or issues please use the [Google Group](https://groups.google.com/forum/#!forum/darknet).

# Darknet + ZYNQ #
Supports low precision training and inference on CPU and FPGA. Open a terminal on a ZCU111 board and run: 

```
make clean
make FPGA=1
```

```
./darknet anomaly train cfg/anomaly.cfg data/ad_train.bin
./darknet anomaly test cfg/anomaly.cfg data/ad_test.bin backup/anomaly.weights
```

The .bit and .so files can be rebuilt [here](https://github.com/sfox14/sdsoc-gemm)
