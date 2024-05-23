`define SHIFT_DIR_RIGHT 1'b0
`define SHIFT_DIR_LEFT 1'b1
`define SHIFT_MODE_ROTATE 1'b0
`define SHIFT_MODE_SHIFT 1'b1
`define SHIFT_LOGICAL 1'b0
`define SHIFT_ARITHMETIC 1'b1

localparam WIDTH = 32;
localparam BITS = $clog2(WIDTH);

module shifter_tb ();
    logic signed [WIDTH - 1:0] in;
    logic [BITS - 1:0] amount;
    logic signed [WIDTH - 1:0] out;
    logic dir, mode, arith;
    integer step;

    shifter shifter(
        .i_operand(in),
        .i_amount(amount),
        .i_dir(dir),
        .i_mode(mode),
        .i_arith(arith),
        .o_result(out)
    );

    initial begin
        $dumpfile("shifter_tb.vcd");
        $dumpvars(0, shifter_tb);

        $display("testing shift left logical");
        dir = `SHIFT_DIR_LEFT;
        mode = `SHIFT_MODE_SHIFT;
        arith = `SHIFT_LOGICAL;

        in = 32'b1010111100000101;
        amount = 4'd0;
        #1;
        assert_eq(32'b1010111100000101, out);

        in = 32'b1010111100000101;
        amount = 4'd3;
        #1;
        assert_eq(32'b1010111100000101000, out);

        in = 32'b1010111100000101;
        amount = 4'd10;
        #1;
        assert_eq(32'b10101111000001010000000000, out);

        for (step = 0; step < 256; step = step + 1) begin
            in = $random;
            amount = $random % WIDTH;
            #1;
            assert_eq(in << amount, out);
        end

        $display("testing shift right logical");
        dir = `SHIFT_DIR_RIGHT;
        mode = `SHIFT_MODE_SHIFT;
        arith = `SHIFT_LOGICAL;

        in = 16'b1010111100000101;
        amount = 4'd0;
        #1;
        assert_eq(16'b1010111100000101, out);

        in = 16'b1010111100000101;
        amount = 4'd3;
        #1;
        assert_eq(16'b0001010111100000, out);

        in = 16'b1010111100000101;
        amount = 4'd10;
        #1;
        assert_eq(16'b0000000000101011, out);

        for (step = 0; step < 256; step = step + 1) begin
            in = $random;
            amount = $random % WIDTH;
            #1;
            assert_eq(in >> amount, out);
        end

        $display("testing shift right arithmetic");
        dir = `SHIFT_DIR_RIGHT;
        mode = `SHIFT_MODE_SHIFT;
        arith = `SHIFT_ARITHMETIC;

        // in = 16'b1010111100000101;
        // amount = 4'd0;
        // #1;
        // assert_eq(16'b1010111100000101, out);
        //
        // in = 16'b1010111100000101;
        // amount = 4'd3;
        // #1;
        // assert_eq(16'b1111010111100000, out);
        //
        // in = 16'b1010111100000101;
        // amount = 4'd10;
        // #1;
        // assert_eq(16'b1111111111101011, out);

        for (step = 0; step < 256; step = step + 1) begin
            in = $random;
            amount = $random % WIDTH;
            #1;
            assert_eq(in >>> amount, out);
        end

        $display("testing rotate left");
        dir = `SHIFT_DIR_LEFT;
        mode = `SHIFT_MODE_ROTATE;
        arith = 1'bx;

        for (step = 0; step < 256; step = step + 1) begin
            in = $random;
            amount = $random % WIDTH;
            #1;
            assert_eq((in << amount) | (in >> (WIDTH - amount)), out);
        end

        $display("testing rotate right");
        dir = `SHIFT_DIR_RIGHT;
        mode = `SHIFT_MODE_ROTATE;
        arith = 1'bx;

        for (step = 0; step < 256; step = step + 1) begin
            in = $random;
            amount = $random % WIDTH;
            #1;
            assert_eq((in >> amount) | (in << (WIDTH - amount)), out);
        end
    end

    task assert_eq (input [WIDTH - 1:0] expected, actual);
        if (expected !== actual) begin
            $error("expected: %b, actual: %b", expected, actual);
        end
    endtask
endmodule
