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
  reg [5:0] PI_i_ret_p3;
  reg [5:0] PI_i_ret_p2;
  reg [0:0] PI_i_clk;
  reg [5:0] PI_i_ret_p1;
  reg [0:0] PI_i_rst_n;
  reg [2:0] PI_i_ret_count;
  reg [2:0] PI_i_req_count;
  reg [5:0] PI_i_ret_p0;
  free_list UUT (
    .i_ret_p3(PI_i_ret_p3),
    .i_ret_p2(PI_i_ret_p2),
    .i_clk(PI_i_clk),
    .i_ret_p1(PI_i_ret_p1),
    .i_rst_n(PI_i_rst_n),
    .i_ret_count(PI_i_ret_count),
    .i_req_count(PI_i_req_count),
    .i_ret_p0(PI_i_ret_p0)
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
    // UUT.$auto$async2sync.\cc:101:execute$245  = 1'b0;
    // UUT.$auto$async2sync.\cc:101:execute$257  = 1'b0;
    // UUT.$auto$async2sync.\cc:110:execute$249  = 1'b1;
    // UUT.$auto$async2sync.\cc:110:execute$255  = 1'b1;
    // UUT.$auto$async2sync.\cc:110:execute$261  = 1'b1;
    // UUT.$auto$async2sync.\cc:110:execute$267  = 1'b1;
    UUT._witness_.anyinit_procdff_227 = 1'b0;
    UUT._witness_.anyinit_procdff_228 = 3'b000;
    UUT._witness_.anyinit_procdff_229 = 1'b0;
    UUT._witness_.anyinit_procdff_230 = 6'b000000;
    UUT._witness_.anyinit_procdff_231 = 1'b0;
    UUT._witness_.anyinit_procdff_232 = 6'b000000;
    UUT._witness_.anyinit_procdff_234 = 6'b000000;
    UUT._witness_.anyinit_procdff_235 = 6'b000000;
    UUT._witness_.anyinit_procdff_236 = 6'b000000;
    UUT._witness_.anyinit_procdff_237 = 6'b000000;
    UUT._witness_.anyinit_procdff_238 = 3'b000;
    UUT._witness_.anyinit_procdff_239 = 6'b000000;
    UUT._witness_.anyinit_procdff_240 = 48'b000000000000000000000000000000000000000000000000;
    UUT.f_past_valid = 1'b0;

    // state 0
    PI_i_ret_p3 = 6'b000000;
    PI_i_ret_p2 = 6'b000000;
    PI_i_clk = 1'b0;
    PI_i_ret_p1 = 6'b000000;
    PI_i_rst_n = 1'b0;
    PI_i_ret_count = 3'b011;
    PI_i_req_count = 3'b000;
    PI_i_ret_p0 = 6'b000000;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_i_ret_p3 <= 6'b000000;
      PI_i_ret_p2 <= 6'b000000;
      PI_i_clk <= 1'b0;
      PI_i_ret_p1 <= 6'b000000;
      PI_i_rst_n <= 1'b1;
      PI_i_ret_count <= 3'b000;
      PI_i_req_count <= 3'b011;
      PI_i_ret_p0 <= 6'b000000;
    end

    // state 2
    if (cycle == 1) begin
      PI_i_ret_p3 <= 6'b000000;
      PI_i_ret_p2 <= 6'b000000;
      PI_i_clk <= 1'b0;
      PI_i_ret_p1 <= 6'b000000;
      PI_i_rst_n <= 1'b0;
      PI_i_ret_count <= 3'b011;
      PI_i_req_count <= 3'b000;
      PI_i_ret_p0 <= 6'b000000;
    end

    // state 3
    if (cycle == 2) begin
      PI_i_ret_p3 <= 6'b000000;
      PI_i_ret_p2 <= 6'b000000;
      PI_i_clk <= 1'b0;
      PI_i_ret_p1 <= 6'b000000;
      PI_i_rst_n <= 1'b0;
      PI_i_ret_count <= 3'b011;
      PI_i_req_count <= 3'b000;
      PI_i_ret_p0 <= 6'b000000;
    end

    genclock <= cycle < 3;
    cycle <= cycle + 1;
  end
endmodule
