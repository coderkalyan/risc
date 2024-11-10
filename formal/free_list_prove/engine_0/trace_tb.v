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
  reg [5:0] PI_i_ret_p2;
  reg [2:0] PI_i_ret_count;
  reg [5:0] PI_i_ret_p3;
  reg [5:0] PI_i_ret_p1;
  reg [2:0] PI_i_req_count;
  reg [0:0] PI_i_clk;
  reg [0:0] PI_i_rst_n;
  reg [5:0] PI_i_ret_p0;
  free_list UUT (
    .i_ret_p2(PI_i_ret_p2),
    .i_ret_count(PI_i_ret_count),
    .i_ret_p3(PI_i_ret_p3),
    .i_ret_p1(PI_i_ret_p1),
    .i_req_count(PI_i_req_count),
    .i_clk(PI_i_clk),
    .i_rst_n(PI_i_rst_n),
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
    // UUT.$auto$clk2fflogic.\cc:65:sample_control$$auto$rtlil .\cc:2485:Not$320#sampled$321  = 1'b0;
    // UUT.$auto$clk2fflogic.\cc:77:sample_control_edge$/i_clk#sampled$253  = 1'b1;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$$0$past$free_list .\v:100$3$0[0:0]$47#sampled$477  = 1'b0;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$$0$past$free_list .\v:101$5$0[0:0]$49#sampled$457  = 1'b0;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$$0/free[47:0]#sampled$311  = 48'b000000000000000000000000000000000000000000000000;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$$0/o_avail_count[5:0]#sampled$329  = 6'b000000;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$$assert$free_list .\v:101$60_EN#sampled$287  = 1'b0;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$$assert$free_list .\v:96$54_EN#sampled$259  = 1'b0;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$$eq$free_list .\v:79$72_Y#sampled$265  = 1'b1;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$$eq$free_list .\v:80$75_Y#sampled$279  = 1'b1;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$$logic_not$free_list .\v:102$65_Y#sampled$293  = 1'b1;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$$past$free_list .\v:100$3$0#sampled$475  = 1'b0;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$$past$free_list .\v:101$4$0#sampled$465  = 6'b110000;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$$past$free_list .\v:101$5$0#sampled$307  = 1'b1;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$$past$free_list .\v:101$5$0#sampled$455  = 1'b0;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$$past$free_list .\v:102$6$0#sampled$445  = 6'b000000;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$$past$free_list .\v:95$1$0#sampled$495  = 1'b0;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$$past$free_list .\v:99$2$0#sampled$485  = 3'b000;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$/f_past_valid#sampled$435  = 1'b0;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$/free#sampled$309  = 48'b111111111111111111111111111111111111111111111111;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$/i_req_count#sampled$347  = 3'b000;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$/i_ret_count#sampled$487  = 3'b000;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$/i_rst_n#sampled$497  = 1'b0;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$/o_avail_count#sampled$327  = 6'b100000;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$/o_req0#sampled$417  = 6'b110000;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$/o_req0#sampled$447  = 6'b000000;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$/o_req1#sampled$399  = 6'b000000;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$/o_req2#sampled$381  = 6'b000000;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$/o_req3#sampled$363  = 6'b000000;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$/o_req_count#sampled$345  = 3'b000;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$/req0#sampled$419  = 6'b000000;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$/req1#sampled$401  = 6'b000000;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$/req2#sampled$383  = 6'b000000;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$/req3#sampled$365  = 6'b000000;
    // UUT.$auto$clk2fflogic.\cc:91:sample_data$1'1#sampled$437  = 1'b0;

    // state 0
    PI_i_ret_p2 = 6'b000000;
    PI_i_ret_count = 3'b000;
    PI_i_ret_p3 = 6'b000000;
    PI_i_ret_p1 = 6'b000000;
    PI_i_req_count = 3'b100;
    PI_i_clk = 1'b0;
    PI_i_rst_n = 1'b1;
    PI_i_ret_p0 = 6'b000000;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_i_ret_p2 <= 6'b000000;
      PI_i_ret_count <= 3'b011;
      PI_i_ret_p3 <= 6'b000000;
      PI_i_ret_p1 <= 6'b000000;
      PI_i_req_count <= 3'b000;
      PI_i_clk <= 1'b1;
      PI_i_rst_n <= 1'b1;
      PI_i_ret_p0 <= 6'b000000;
    end

    // state 2
    if (cycle == 1) begin
      PI_i_ret_p2 <= 6'b000000;
      PI_i_ret_count <= 3'b011;
      PI_i_ret_p3 <= 6'b000000;
      PI_i_ret_p1 <= 6'b000000;
      PI_i_req_count <= 3'b000;
      PI_i_clk <= 1'b0;
      PI_i_rst_n <= 1'b1;
      PI_i_ret_p0 <= 6'b000000;
    end

    // state 3
    if (cycle == 2) begin
      PI_i_ret_p2 <= 6'b000000;
      PI_i_ret_count <= 3'b011;
      PI_i_ret_p3 <= 6'b000000;
      PI_i_ret_p1 <= 6'b000000;
      PI_i_req_count <= 3'b000;
      PI_i_clk <= 1'b1;
      PI_i_rst_n <= 1'b1;
      PI_i_ret_p0 <= 6'b000000;
    end

    genclock <= cycle < 3;
    cycle <= cycle + 1;
  end
endmodule
