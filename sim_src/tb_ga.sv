`timescale 1ns / 1ps

`include "../src/ga.sv"

`define POP_SIZE 32
`define GENS 100
`define CHROM_WIDTH 16
`define FITNESS_WIDTH ((`CHROM_WIDTH + 1) * 3)
`define SEED 32'hA1EF_CDE5
`define DUMP_FILENAME "path/to/dump/file"

module tb_ga();
    logic [`CHROM_WIDTH - 1:0] best;
    logic [`FITNESS_WIDTH - 1:0] best_fit;
    logic finished;
    logic reset;
    logic clk;

    reg [`CHROM_WIDTH - 1:0] bests[`GENS];
    int unsigned i;

    integer output_file;
    reg [`CHROM_WIDTH - 1:0] chroms_dump[`POP_SIZE];
    reg [`FITNESS_WIDTH - 1:0] fits_dump[`POP_SIZE];
    integer unsigned dumps_counter;
    integer unsigned dump_it;
    bit first_gen = 1;

    initial begin
        // Open the file where dump goes with result
        output_file = $fopen(`DUMP_FILENAME, "w");
        dumps_counter = -1;

        clk = 0;
        reset = 1;
        i = 0;

        @ (posedge clk);
        @ (negedge clk);

        reset = 0;

        @ (posedge clk);
        @ (negedge clk);

        @ (posedge finished);

        $fwrite(output_file, "Chrom: %04X\n", best);
        $fwrite(output_file, "Fit: %1d", best_fit);

        $display("\n###########\n");
        $display("Chrom: %04X", best);
        $display("Fit: %1d", best_fit);
        $display("\n###########\n");

        $fclose(output_file);

        $finish();
    end

    always @(posedge clk) begin
        if (DUT.ff_enable) begin
            if (first_gen) begin
                if (dumps_counter == -1) begin
                    chroms_dump[0] = DUT.ff_chrom1;
                    chroms_dump[1] = DUT.ff_chrom2;
                    dumps_counter = 2;
                end else if (dumps_counter == `POP_SIZE) begin
                    fits_dump[dumps_counter - 2] = DUT.ff_fit1;
                    fits_dump[dumps_counter - 1] = DUT.ff_fit2;

                    $fwrite(output_file, ">>>>> GEN #%1d <<<<<\n", DUT.gen_counter + 1);
                    for (dump_it = 0; dump_it < `POP_SIZE; dump_it = dump_it + 1) begin
                        $fwrite(output_file, "CHROM: %02X - FIT: %07X\n", chroms_dump[dump_it], fits_dump[dump_it]);
                    end
                    $fwrite(output_file, "\n");

                    for (dump_it = 0; dump_it < `POP_SIZE >> 1; dump_it = dump_it + 1) begin
                        if (fits_dump[2*dump_it] < fits_dump[2*dump_it + 1]) begin
                            chroms_dump[dump_it] = chroms_dump[2*dump_it];
                            fits_dump[dump_it] = fits_dump[2*dump_it];
                        end else begin
                            chroms_dump[dump_it] = chroms_dump[2*dump_it + 1];
                            fits_dump[dump_it] = fits_dump[2*dump_it + 1];
                        end
                    end

                    dumps_counter = `POP_SIZE >> 1;
                    chroms_dump[dumps_counter] = DUT.ff_chrom1;
                    chroms_dump[dumps_counter + 1] = DUT.ff_chrom2;
                    dumps_counter = dumps_counter + 2;

                    first_gen = 0;
                end else begin
                    fits_dump[dumps_counter - 2] = DUT.ff_fit1;
                    fits_dump[dumps_counter - 1] = DUT.ff_fit2;
                    chroms_dump[dumps_counter] = DUT.ff_chrom1;
                    chroms_dump[dumps_counter + 1] = DUT.ff_chrom2;
                    dumps_counter = dumps_counter + 2;
                end
            end else begin
                if (dumps_counter == `POP_SIZE) begin
                    fits_dump[dumps_counter - 2] = DUT.ff_fit1;
                    fits_dump[dumps_counter - 1] = DUT.ff_fit2;

                    $fwrite(output_file, ">>>>> GEN #%1d <<<<<\n", DUT.gen_counter + 1);
                    for (dump_it = 0; dump_it < `POP_SIZE; dump_it = dump_it + 1) begin
                        $fwrite(output_file, "CHROM: %02X - FIT: %07X\n", chroms_dump[dump_it], fits_dump[dump_it]);
                    end
                    $fwrite(output_file, "\n");

                    for (dump_it = 0; dump_it < `POP_SIZE >> 2; dump_it = dump_it + 1) begin
                        if (fits_dump[2*dump_it] < fits_dump[2*dump_it + 1]) begin
                            chroms_dump[2*dump_it + 1] = chroms_dump[2*dump_it];
                            fits_dump[2*dump_it + 1] = fits_dump[2*dump_it];
                        end else begin
                            chroms_dump[2*dump_it + 1] = chroms_dump[2*dump_it + 1];
                            fits_dump[2*dump_it + 1] = fits_dump[2*dump_it + 1];
                        end

                        if (fits_dump[2*dump_it + (`POP_SIZE >> 1)] < fits_dump[2*dump_it + (`POP_SIZE >> 1) + 1]) begin
                            chroms_dump[2*dump_it] = chroms_dump[2*dump_it + (`POP_SIZE >> 1)];
                            fits_dump[2*dump_it] = fits_dump[2*dump_it + (`POP_SIZE >> 1)];
                        end else begin
                            chroms_dump[2*dump_it] = chroms_dump[2*dump_it + (`POP_SIZE >> 1) + 1];
                            fits_dump[2*dump_it] = fits_dump[2*dump_it + (`POP_SIZE >> 1) + 1];
                        end
                    end
                    dumps_counter = `POP_SIZE >> 1;

                    chroms_dump[dumps_counter] = DUT.ff_chrom1;
                    chroms_dump[dumps_counter + 1] = DUT.ff_chrom2;
                    dumps_counter = dumps_counter + 2;
                end else begin
                    fits_dump[dumps_counter - 2] = DUT.ff_fit1;
                    fits_dump[dumps_counter - 1] = DUT.ff_fit2;
                    chroms_dump[dumps_counter] = DUT.ff_chrom1;
                    chroms_dump[dumps_counter + 1] = DUT.ff_chrom2;
                    dumps_counter = dumps_counter + 2;
                end
            end
        end
    end

    always @(DUT.gen_counter) begin
        if (DUT.gen_counter > 0) begin
            bests[DUT.gen_counter - 1] = best;
        end
    end

    always begin
        #5 clk = ~clk;
    end

    ga #(
        .POP_SIZE      (`POP_SIZE),
        .GENS          (`GENS),
        .CHROM_WIDTH   (`CHROM_WIDTH)
    ) DUT (
        .best     (best),
        .best_fit (best_fit),
        .finished (finished),
        .seed     (`SEED),
        .reset    (reset),
        .clk      (clk)
    );
endmodule
