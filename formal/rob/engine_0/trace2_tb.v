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
  reg [56:0] PI_i_ins_bundle3;
  reg [5:0] PI_i_ins_old_p1;
  reg [56:0] PI_i_ins_bundle2;
  reg [5:0] PI_i_cmpl_en;
  reg [2:0] PI_i_ins_count;
  reg [3:0] PI_i_cmpl5;
  reg [3:0] PI_i_cmpl1;
  reg [56:0] PI_i_ins_bundle1;
  reg [0:0] PI_i_clk;
  reg [5:0] PI_i_ins_old_p2;
  reg [3:0] PI_i_cmpl4;
  reg [3:0] PI_i_cmpl3;
  reg [5:0] PI_i_ins_old_p0;
  reg [3:0] PI_i_cmpl0;
  reg [0:0] PI_i_rst_n;
  reg [3:0] PI_i_cmpl2;
  reg [56:0] PI_i_ins_bundle0;
  reg [5:0] PI_i_ins_old_p3;
  rob UUT (
    .i_ins_bundle3(PI_i_ins_bundle3),
    .i_ins_old_p1(PI_i_ins_old_p1),
    .i_ins_bundle2(PI_i_ins_bundle2),
    .i_cmpl_en(PI_i_cmpl_en),
    .i_ins_count(PI_i_ins_count),
    .i_cmpl5(PI_i_cmpl5),
    .i_cmpl1(PI_i_cmpl1),
    .i_ins_bundle1(PI_i_ins_bundle1),
    .i_clk(PI_i_clk),
    .i_ins_old_p2(PI_i_ins_old_p2),
    .i_cmpl4(PI_i_cmpl4),
    .i_cmpl3(PI_i_cmpl3),
    .i_ins_old_p0(PI_i_ins_old_p0),
    .i_cmpl0(PI_i_cmpl0),
    .i_rst_n(PI_i_rst_n),
    .i_cmpl2(PI_i_cmpl2),
    .i_ins_bundle0(PI_i_ins_bundle0),
    .i_ins_old_p3(PI_i_ins_old_p3)
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
    // UUT.$auto$async2sync.\cc:101:execute$4272  = 1'b0;
    // UUT.$auto$async2sync.\cc:101:execute$4320  = 1'b0;
    // UUT.$auto$async2sync.\cc:101:execute$4326  = 1'b0;
    // UUT.$auto$async2sync.\cc:110:execute$4276  = 1'b1;
    // UUT.$auto$async2sync.\cc:110:execute$4282  = 1'b1;
    // UUT.$auto$async2sync.\cc:110:execute$4288  = 1'b1;
    // UUT.$auto$async2sync.\cc:110:execute$4294  = 1'b1;
    // UUT.$auto$async2sync.\cc:110:execute$4300  = 1'b1;
    // UUT.$auto$async2sync.\cc:110:execute$4306  = 1'b1;
    // UUT.$auto$async2sync.\cc:110:execute$4312  = 1'b1;
    // UUT.$auto$async2sync.\cc:110:execute$4324  = 1'b1;
    // UUT.$auto$async2sync.\cc:228:execute$4410  = 4'b0000;
    // UUT.$past$rob.\v:170$2$0  = 1'b0;
    UUT._witness_.anyinit_procdff_4164 = 4'b0000;
    UUT._witness_.anyinit_procdff_4165 = 3'b000;
    UUT._witness_.anyinit_procdff_4168 = 6'b000000;
    UUT._witness_.anyinit_procdff_4169 = 6'b000000;
    UUT._witness_.anyinit_procdff_4170 = 6'b000000;
    UUT._witness_.anyinit_procdff_4171 = 6'b000000;
    UUT._witness_.anyinit_procdff_4172 = 3'b000;
    UUT._witness_.anyinit_procdff_4173 = 4'b0000;
    UUT._witness_.anyinit_procdff_4174 = 4'b0000;
    UUT._witness_.anyinit_procdff_4192 = 1'b0;
    UUT._witness_.anyinit_procdff_4193 = 1'b0;
    UUT._witness_.anyinit_procdff_4194 = 1'b0;
    UUT._witness_.anyinit_procdff_4195 = 1'b0;
    UUT._witness_.anyinit_procdff_4196 = 1'b0;
    UUT._witness_.anyinit_procdff_4197 = 1'b0;
    UUT._witness_.anyinit_procdff_4198 = 1'b0;
    UUT._witness_.anyinit_procdff_4199 = 1'b0;
    UUT._witness_.anyinit_procdff_4200 = 1'b0;
    UUT._witness_.anyinit_procdff_4201 = 1'b0;
    UUT._witness_.anyinit_procdff_4202 = 1'b0;
    UUT._witness_.anyinit_procdff_4203 = 1'b0;
    UUT._witness_.anyinit_procdff_4204 = 1'b0;
    UUT._witness_.anyinit_procdff_4205 = 1'b0;
    UUT._witness_.anyinit_procdff_4206 = 1'b0;
    UUT._witness_.anyinit_procdff_4207 = 1'b0;
    UUT._witness_.anyinit_procdff_4208 = 6'b000000;
    UUT._witness_.anyinit_procdff_4209 = 6'b000000;
    UUT._witness_.anyinit_procdff_4210 = 6'b000000;
    UUT._witness_.anyinit_procdff_4211 = 6'b000000;
    UUT._witness_.anyinit_procdff_4212 = 6'b000000;
    UUT._witness_.anyinit_procdff_4213 = 6'b000000;
    UUT._witness_.anyinit_procdff_4214 = 6'b000000;
    UUT._witness_.anyinit_procdff_4215 = 6'b000000;
    UUT._witness_.anyinit_procdff_4216 = 6'b000000;
    UUT._witness_.anyinit_procdff_4217 = 6'b000000;
    UUT._witness_.anyinit_procdff_4218 = 6'b000000;
    UUT._witness_.anyinit_procdff_4219 = 6'b000000;
    UUT._witness_.anyinit_procdff_4220 = 6'b000000;
    UUT._witness_.anyinit_procdff_4221 = 6'b000000;
    UUT._witness_.anyinit_procdff_4222 = 6'b000000;
    UUT._witness_.anyinit_procdff_4223 = 6'b000000;
    UUT.f_past_valid = 1'b0;

    // state 0
    PI_i_ins_bundle3 = 57'b000000000000000000000000000000000000000000000000000000000;
    PI_i_ins_old_p1 = 6'b000000;
    PI_i_ins_bundle2 = 57'b000000000000000000000000000000000000000000000000000000000;
    PI_i_cmpl_en = 6'b000000;
    PI_i_ins_count = 3'b000;
    PI_i_cmpl5 = 4'b0000;
    PI_i_cmpl1 = 4'b0000;
    PI_i_ins_bundle1 = 57'b000000000000000000000000000000000000000000000000000000000;
    PI_i_clk = 1'b0;
    PI_i_ins_old_p2 = 6'b000000;
    PI_i_cmpl4 = 4'b0000;
    PI_i_cmpl3 = 4'b0000;
    PI_i_ins_old_p0 = 6'b000000;
    PI_i_cmpl0 = 4'b0000;
    PI_i_rst_n = 1'b0;
    PI_i_cmpl2 = 4'b0000;
    PI_i_ins_bundle0 = 57'b000000000000000000000000000000000000000000000000000000000;
    PI_i_ins_old_p3 = 6'b000000;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_i_ins_bundle3 <= 57'b000000000000000000000000000000000000000000000000000000000;
      PI_i_ins_old_p1 <= 6'b000000;
      PI_i_ins_bundle2 <= 57'b000000000000000000000000000000000000000000000000000000000;
      PI_i_cmpl_en <= 6'b000111;
      PI_i_ins_count <= 3'b011;
      PI_i_cmpl5 <= 4'b0000;
      PI_i_cmpl1 <= 4'b0010;
      PI_i_ins_bundle1 <= 57'b000000000000000000000000000000000000000000000000000000000;
      PI_i_clk <= 1'b0;
      PI_i_ins_old_p2 <= 6'b000000;
      PI_i_cmpl4 <= 4'b0000;
      PI_i_cmpl3 <= 4'b0000;
      PI_i_ins_old_p0 <= 6'b000000;
      PI_i_cmpl0 <= 4'b0000;
      PI_i_rst_n <= 1'b1;
      PI_i_cmpl2 <= 4'b0001;
      PI_i_ins_bundle0 <= 57'b000000000000000000000000000000000000000000000000000000000;
      PI_i_ins_old_p3 <= 6'b000000;
    end

    // state 2
    if (cycle == 1) begin
      PI_i_ins_bundle3 <= 57'b000000000000000000000000000000000000000000000000000000000;
      PI_i_ins_old_p1 <= 6'b000000;
      PI_i_ins_bundle2 <= 57'b000000000000000000000000000000000000000000000000000000000;
      PI_i_cmpl_en <= 6'b000000;
      PI_i_ins_count <= 3'b011;
      PI_i_cmpl5 <= 4'b0000;
      PI_i_cmpl1 <= 4'b0000;
      PI_i_ins_bundle1 <= 57'b000000000000000000000000000000000000000000000000000000000;
      PI_i_clk <= 1'b0;
      PI_i_ins_old_p2 <= 6'b000000;
      PI_i_cmpl4 <= 4'b0000;
      PI_i_cmpl3 <= 4'b0000;
      PI_i_ins_old_p0 <= 6'b000000;
      PI_i_cmpl0 <= 4'b0000;
      PI_i_rst_n <= 1'b1;
      PI_i_cmpl2 <= 4'b0000;
      PI_i_ins_bundle0 <= 57'b000000000000000000000000000000000000000000000000000000000;
      PI_i_ins_old_p3 <= 6'b000000;
    end

    // state 3
    if (cycle == 2) begin
      PI_i_ins_bundle3 <= 57'b000000000000000000000000000000000000000000000000000000000;
      PI_i_ins_old_p1 <= 6'b000000;
      PI_i_ins_bundle2 <= 57'b000000000000000000000000000000000000000000000000000000000;
      PI_i_cmpl_en <= 6'b000000;
      PI_i_ins_count <= 3'b000;
      PI_i_cmpl5 <= 4'b0000;
      PI_i_cmpl1 <= 4'b0000;
      PI_i_ins_bundle1 <= 57'b000000000000000000000000000000000000000000000000000000000;
      PI_i_clk <= 1'b0;
      PI_i_ins_old_p2 <= 6'b000000;
      PI_i_cmpl4 <= 4'b0000;
      PI_i_cmpl3 <= 4'b0000;
      PI_i_ins_old_p0 <= 6'b000000;
      PI_i_cmpl0 <= 4'b0000;
      PI_i_rst_n <= 1'b1;
      PI_i_cmpl2 <= 4'b0000;
      PI_i_ins_bundle0 <= 57'b000000000000000000000000000000000000000000000000000000000;
      PI_i_ins_old_p3 <= 6'b000000;
    end

    // state 4
    if (cycle == 3) begin
      PI_i_ins_bundle3 <= 57'b000000000000000000000000000000000000000000000000000000000;
      PI_i_ins_old_p1 <= 6'b000000;
      PI_i_ins_bundle2 <= 57'b000000000000000000000000000000000000000000000000000000000;
      PI_i_cmpl_en <= 6'b000000;
      PI_i_ins_count <= 3'b000;
      PI_i_cmpl5 <= 4'b0000;
      PI_i_cmpl1 <= 4'b0000;
      PI_i_ins_bundle1 <= 57'b000000000000000000000000000000000000000000000000000000000;
      PI_i_clk <= 1'b0;
      PI_i_ins_old_p2 <= 6'b000000;
      PI_i_cmpl4 <= 4'b0000;
      PI_i_cmpl3 <= 4'b0000;
      PI_i_ins_old_p0 <= 6'b000000;
      PI_i_cmpl0 <= 4'b0000;
      PI_i_rst_n <= 1'b0;
      PI_i_cmpl2 <= 4'b0000;
      PI_i_ins_bundle0 <= 57'b000000000000000000000000000000000000000000000000000000000;
      PI_i_ins_old_p3 <= 6'b000000;
    end

    genclock <= cycle < 4;
    cycle <= cycle + 1;
  end
endmodule
