`ifndef _TCC_COMMON_DEFINES_H_

`define CHROM_WIDTH 8
`define MUT_RATE    13  // $ceil(0.05 * 256) or 5%
`define POP_SIZE    32
`define GENS        100
// `define SEED 32'hCDE5_A1EF
`define SEED 32'h895C80A7
// `define SEED 16'h95A7
// `define SEED 8'hA7
`define FITNESS_FUNCTION (chrom - 10)*(chrom - 10)*(chrom + 5)
`define FITNESS_WIDTH ((`CHROM_WIDTH + 1) * 3)  // Change to match `FITNESS_FUNCTION
// `define FITNESS_FUNCTION ((chrom + 1)*(chrom - 100)*(chrom - 100)*(chrom - 180)*(chrom - 210) + 450000000)
// `define FITNESS_WIDTH (((`CHROM_WIDTH + 1) * 5) + 1)  // Change to match `FITNESS_FUNCTION

`endif // _TCC_COMMON_DEFINES_H_