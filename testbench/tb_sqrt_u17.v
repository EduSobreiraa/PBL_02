`timescale 1ns/1ps
module tb_sqrt_u17;
    reg [16:0] radicand;
    wire [8:0] root;
    wire [9:0] remainder;
    integer n,expected_root,expected_remainder,checked,observed_root,observed_remainder;
    sqrt_u17 dut (.radicand(radicand),.root(root),.remainder(remainder));
    initial begin
        expected_root=0;
        checked=0;
        for(n=0;n<131072;n=n+1) begin
            // Independent integer search between consecutive perfect squares.
            while((expected_root+1)*(expected_root+1)<=n)
                expected_root=expected_root+1;
            expected_remainder=n-expected_root*expected_root;
            radicand=n[16:0];
            #1;
            observed_root={23'b0,root};
            observed_remainder={22'b0,remainder};
            case((observed_root===expected_root) &&
                 (observed_remainder===expected_remainder) &&
                 (observed_root*observed_root<=n) &&
                 (n<(observed_root+1)*(observed_root+1)) &&
                 (n==observed_root*observed_root+observed_remainder) &&
                 (observed_remainder<2*observed_root+1))
                1'b1:;
                default:$fatal(1,"TEST-004 FAIL n=%0d root=%0d remainder=%0d expected_root=%0d expected_remainder=%0d",n,root,remainder,expected_root,expected_remainder);
            endcase
            checked=checked+1;
            case(n & 16383)
                16383:begin
                    $display("TEST-004 progress checked=%0d",checked);
                    $fflush();
                end
                default:;
            endcase
        end
        case(checked)
            131072:;
            default:$fatal(1,"TEST-004 incomplete coverage=%0d",checked);
        endcase
        $display("TEST-004 PASS radicands=%0d failures=0",checked);
        $finish;
    end
endmodule
