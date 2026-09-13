`timescale 1ns/1ps

module top_module_tb;

    reg                     clk;
    reg                     reset;
    reg signed [31:0]       numA;
    reg signed [31:0]       numB;
    reg                     in_valid;

    wire                    out_valid;
    wire signed [63:0]      productALL;

    integer tests_passed;
    integer tests_failed;

    top_module dut (reset,clk,numA,numB,in_valid,out_valid,productALL);


    
    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end

    task run_test;

        input signed [7:0] a0;
        input signed [7:0] a1;
        input signed [7:0] a2;
        input signed [7:0] a3;

        input signed [7:0] b0;
        input signed [7:0] b1;
        input signed [7:0] b2;
        input signed [7:0] b3;

        reg signed [15:0] expected_product0;
        reg signed [15:0] expected_product1;
        reg signed [15:0] expected_product2;
        reg signed [15:0] expected_product3;

        reg signed [63:0] expected_result;

        begin
  
            expected_product0 = a0 * b0;
            expected_product1 = a1 * b1;
            expected_product2 = a2 * b2;
            expected_product3 = a3 * b3;


            expected_result = 64'sd0;
            expected_result = expected_result + expected_product0;
            expected_result = expected_result + expected_product1;
            expected_result = expected_result + expected_product2;
            expected_result = expected_result + expected_product3;


            @(negedge clk);

            numA = {a3, a2, a1, a0};
            numB = {b3, b2, b1, b0};

            in_valid = 1'b1;


            @(posedge clk);
            #1;

            @(negedge clk);

            in_valid = 1'b0;
            numA     = 32'sd0;
            numB     = 32'sd0;

            @(posedge clk);
            #1;

            if (out_valid !== 1'b1) begin
                $display("FAIL: out_valid was not asserted");
                tests_failed = tests_failed + 1;
            end
            else if (productALL !== expected_result) begin
                $display("FAIL");
                $display("  A        = [%0d, %0d, %0d, %0d]",
                         a0, a1, a2, a3);
                $display("  B        = [%0d, %0d, %0d, %0d]",
                         b0, b1, b2, b3);
                $display("  Expected = %0d", expected_result);
                $display("  Actual   = %0d", productALL);

                tests_failed = tests_failed + 1;
            end
            else begin
                $display("PASS: dot product = %0d", productALL);
                tests_passed = tests_passed + 1;
            end
        end

    endtask

    /*
     * Test sequence.
     */
    initial begin
        reset        = 1'b1;
        numA         = 32'sd0;
        numB         = 32'sd0;
        in_valid     = 1'b0;
        tests_passed = 0;
        tests_failed = 0;

        $dumpfile("dotproduct.vcd");
        $dumpvars(0, top_module_tb);
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        run_test(
             8'sd1,  8'sd2,  8'sd3,  8'sd4,
             8'sd5,  8'sd6,  8'sd7,  8'sd8
        );

        run_test(
             8'sd1, -8'sd2,  8'sd3, -8'sd4,
             8'sd5,  8'sd6, -8'sd7,  8'sd8
        );


        run_test(
             8'sd0, 8'sd0, 8'sd0, 8'sd0,
             8'sd0, 8'sd0, 8'sd0, 8'sd0
        );


        run_test(
            8'sd127, 8'sd127, 8'sd127, 8'sd127,
            8'sd127, 8'sd127, 8'sd127, 8'sd127
        );

        run_test(
            8'sh80, 8'sh80, 8'sh80, 8'sh80,
            8'sh80, 8'sh80, 8'sh80, 8'sh80
        );

        $display("");
        $display("Tests passed: %0d", tests_passed);
        $display("Tests failed: %0d", tests_failed);

        if (tests_failed == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule






module top_module(
    input                    reset,
    input                    clk,
    input wire signed [31:0]  numA,
    input wire signed [31:0]  numB,
    input                    in_valid,
    output reg                  out_valid,
    output reg signed [63:0] productALL
);

wire signed [15:0] product1;
wire signed [15:0] product2;
wire signed [15:0] product3;
wire signed [15:0] product4;

reg valid_delay;

multiplier mulitplier1(reset,clk,numA[31:24],numB[31:24],product1);
multiplier mulitplier2(reset,clk,numA[23:16],numB[23:16],product2);
multiplier mulitplier3(reset,clk,numA[15:8],numB[15:8],product3);
multiplier mulitplier4(reset,clk,numA[7:0],numB[7:0],product4);

always @(posedge clk) begin
    if (reset) begin
        productALL <= 64'b0;
        out_valid <= 1'b0;
        valid_delay <= 1'b0;

    end
    else begin
        valid_delay <= in_valid;
        out_valid <= valid_delay;
        if (valid_delay) begin
            productALL <= product1+product2+product3+product4;
        end
    end
       
end

endmodule


module multiplier(
    input                  reset,
    input                  clk,
    input wire signed [7:0] a_lane,
    input wire signed [7:0] b_lane,
    output reg signed [15:0] product

);
always @(posedge clk) begin
    if (reset) begin
        product <= 16'b0;
    end
    else begin
        product <= a_lane * b_lane;
    end
end

endmodule
