`ifndef VERILATOR
module testbench;
  reg [4095:0] vcdfile;
  reg clock;
`else
module testbench(input clock, output reg genclock);
  initial genclock = 1;
`endif
  reg genclock = 1;
  reg [31:0] cycle = 0;
  reg [31:0] PI_i_inst;
  decoder UUT (
    .i_inst(PI_i_inst)
  );
`ifndef VERILATOR
  initial begin
    if ($value$plusargs("vcd=%s", vcdfile)) begin
      $dumpfile(vcdfile);
      $dumpvars(0, testbench);
    end
    #5 clock = 0;
    while (genclock) begin
      #5 clock = 0;
      #5 clock = 1;
    end
  end
`endif
  initial begin
`ifndef VERILATOR
    #1;
`endif

    // state 0
    PI_i_inst = 32'b00000000000000000000000000000011;
  end
  always @(posedge clock) begin
    genclock <= cycle < 0;
    cycle <= cycle + 1;
  end
endmodule
