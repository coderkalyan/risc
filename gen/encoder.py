import sys

BITS = int(sys.argv[1])
WIDTH = 2 ** BITS

print("`default_nettype none\n")
print(f"module encoder_{BITS}bit (")
print(f"    input wire [{WIDTH - 1}:0] i_vec,")
print(f"    output reg [{BITS - 1}:0] o_code")
print(");")

print(f"    always @(*) begin")
print(f"        o_code = {BITS}'h0;\n")
print(f"        case (1'b1)")
for i in range(WIDTH):
    print(f"            i_vec[{BITS}'h{i:x}]: o_code = {BITS}'h{i:x};")
print(f"        endcase")
print("    end")

print("endmodule")
