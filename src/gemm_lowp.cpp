#ifdef LOWP

#include "gemm.h"
#include "test/test.h"

/*
gemm_lowp currently only supports unsigned 8-bit matrix multiplication, and is 
incompatible with our block floating point quantisation scheme. 

see gemmlowp/doc/quantisation_example.cc for an example.
*/


using namespace gemmlowp;

extern "C" {
void gemm_lowp(int8_t *a, int arow, int8_t *b, int brow, int32_t *c, int ccol){

	std::uint8_t *A = (uint8_t *) a;
	std::uint8_t *B = (uint8_t *) b;

	int lda = brow;
	int ldb = brow;
	int ldc = arow;

	MatrixMap<const std::uint8_t, MapOrder::RowMajor> lhs(A, arow, brow, lda);
  	MatrixMap<const std::uint8_t, MapOrder::ColMajor> rhs(B, brow, ccol, ldb);
    MatrixMap<std::int32_t, MapOrder::ColMajor> result_raw_int32(c, arow, ccol, ldc);

	auto empty_pipeline = std::make_tuple();
	GemmContext context;
	GemmWithOutputPipeline<std::uint8_t, std::int32_t, DefaultL8R8BitDepthParams>(
		&context, lhs, rhs, &result_raw_int32, 0,
		0, empty_pipeline);

}

}

#endif