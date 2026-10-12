`timescale 1ns/1ps
module tb_divide_u9_u8;
    reg [8:0] dividend;
    reg [7:0] divisor;
    wire [8:0] quotient;
    wire [7:0] remainder;
    wire divide_by_zero;
    integer n, d, expected_q, expected_r, count, valid_count, zero_count;
    reg expected_zero;
    divide_u9_u8 dut(.dividend(dividend), .divisor(divisor),
        .quotient(quotient), .remainder(remainder), .divide_by_zero(divide_by_zero));
    initial begin
        count=0; valid_count=0; zero_count=0;
        for (n=0; n<512; n=n+1) begin
            for (d=0; d<256; d=d+1) begin
                dividend=n[8:0]; divisor=d[7:0];
                case (d)
                    0: begin
                        expected_q=0; expected_r=0; expected_zero=1'b1;
                        zero_count=zero_count+1;
                    end
                    default: begin
                        expected_q=n/d; expected_r=n%d; expected_zero=1'b0;
                        valid_count=valid_count+1;
                    end
                endcase
                #1;
                case ((quotient === expected_q[8:0]) &&
                    (remainder === expected_r[7:0]) &&
                    (divide_by_zero === expected_zero))
                    1'b1: ;
                    default: $fatal(1,"divide mismatch n=%0d d=%0d q=%0d r=%0d zero=%b expected_q=%0d expected_r=%0d expected_zero=%b",n,d,quotient,remainder,divide_by_zero,expected_q,expected_r,expected_zero);
                endcase
                case (d)
                    0: ;
                    default: begin
                        case ((n == quotient*d+remainder) && (remainder < d))
                            1'b1: ;
                            default: $fatal(1,"divide identity n=%0d d=%0d",n,d);
                        endcase
                    end
                endcase
                count=count+1;
            end
        end
        case ((count==131072) && (valid_count==130560) && (zero_count==512))
            1'b1: ;
            default: $fatal(1,"Incomplete coverage count=%0d",count);
        endcase
        $display("TEST-005 PASS pairs=%0d valid=%0d divisor_zero=%0d quotient_remainder=PASS identity=PASS masks=PASS",count,valid_count,zero_count);
        $finish;
    end
endmodule
