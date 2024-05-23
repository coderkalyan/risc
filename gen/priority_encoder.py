import sys

BITS = int(sys.argv[1])
WIDTH = 2 ** BITS

print("`default_nettype none\n")
print(f"module priority_encoder_{BITS}bit (")
print(f"    input wire [{WIDTH - 1}:0] i_vec,")
print(f"    output reg [{BITS - 1}:0] o_code")
print(");")

print(f"    always @(*) begin")
print(f"    o_code = {BITS}'h0;\n")
print(f"        if (i_vec[0])")
print(f"            o_code = {BITS}'h0;")
for i in range(1, WIDTH):
    print(f"        else if (i_vec[{i}])")
    print(f"            o_code = {BITS}'h{i:x};")

print("    end")
print("endmodule")
