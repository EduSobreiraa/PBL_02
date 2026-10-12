`timescale 1ns/1ps
module tb_decimal_display;
    reg signed [22:0] value;
    reg invalid;
    wire [6:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5;
    reg [3:0] digit;
    wire [6:0] decoded;
    wire [3:0] corrected;
    wire [22:0] magnitude;
    wire [27:0] bcd;
    reg [41:0] expected;
    reg [27:0] expected_bcd;
    integer count,i,j,seed,random_value,v,mag,temp,k,limit,d,expected_add3;
    decimal_display dut(.value(value),.invalid(invalid),.HEX0(HEX0),.HEX1(HEX1),.HEX2(HEX2),.HEX3(HEX3),.HEX4(HEX4),.HEX5(HEX5));
    decimal_bcd_segments decoder(.digit(digit),.segments(decoded));
    decimal_add3 corrector(.digit(digit),.corrected(corrected));
    decimal_magnitude abs_check(.value(value),.magnitude(magnitude));
    decimal_double_dabble conversion_check(.magnitude(magnitude),.bcd(bcd));
    function [6:0] encode;
        input integer decimal_digit;
        begin
            case (decimal_digit)
                0: encode=7'b1000000;
                1: encode=7'b1111001;
                2: encode=7'b0100100;
                3: encode=7'b0110000;
                4: encode=7'b0011001;
                5: encode=7'b0010010;
                6: encode=7'b0000010;
                7: encode=7'b1111000;
                8: encode=7'b0000000;
                9: encode=7'b0010000;
                default: encode=7'b1111111;
            endcase
        end
    endfunction
    task check;
        input integer input_value;
        input input_invalid;
        integer abs_value,remaining,pos,digit_value;
        reg bad;
        begin
            value=input_value[22:0]; invalid=input_invalid;
            case (input_value<0) 1: abs_value=-input_value; default: abs_value=input_value; endcase
            bad=input_invalid || (input_value>999999) || (input_value< -99999);
            expected={6{7'b1111111}};
            case (bad)
                1: expected={6{7'b0111111}};
                0: begin
                    remaining=abs_value;
                    for (pos=0;pos<6;pos=pos+1) begin
                        digit_value=remaining%10;
                        case ((pos==0)||(remaining!=0))
                            1: expected[pos*7+:7]=encode(digit_value);
                            default: ;
                        endcase
                        remaining=remaining/10;
                    end
                    case (input_value<0) 1: expected[35+:7]=7'b0111111; default: ; endcase
                end
            endcase
            remaining=abs_value;
            for (pos=0;pos<7;pos=pos+1) begin
                digit_value=remaining%10;
                expected_bcd[pos*4+:4]=digit_value[3:0];
                remaining=remaining/10;
            end
            #1;
            case (({HEX5,HEX4,HEX3,HEX2,HEX1,HEX0}===expected) && (magnitude===abs_value[22:0]) && (bcd===expected_bcd))
                1: ;
                default: $fatal(1,"display v=%0d invalid=%b got=%h expected=%h bcd=%h expected_bcd=%h",input_value,input_invalid,{HEX5,HEX4,HEX3,HEX2,HEX1,HEX0},expected,bcd,expected_bcd);
            endcase
            count=count+1;
        end
    endtask
    initial begin
        count=0; seed=20261011;
        for (i=0;i<16;i=i+1) begin
            digit=i[3:0];
            case (i>=5) 1: expected_add3=i+3; default: expected_add3=i; endcase
            #1;
            case ((decoded===encode(i)) && (corrected===expected_add3[3:0]))
                1: ;
                default: $fatal(1,"BCD/add3 digit=%d",i);
            endcase
        end
        for (j=0;j<2;j=j+1) begin
            check(0,j[0]); check(1,j[0]); check(-1,j[0]);
            check(99999,j[0]); check(100000,j[0]); check(999999,j[0]);
            check(1000000,j[0]); check(-99999,j[0]); check(-100000,j[0]);
            check(-4194304,j[0]); check(4194303,j[0]);
            check(123456,j[0]); check(-12345,j[0]); check(909090,j[0]);
            check(100001,j[0]); check(-10001,j[0]);
            for (i=0;i<1000;i=i+1) begin
                check(i,j[0]); check(-i,j[0]);
            end
            for (i=0;i<1000;i=i+1) begin
                random_value=$random(seed); v=$signed(random_value[22:0]);
                check(v,j[0]);
                random_value=$random(seed); v=(random_value & 32'h7fffffff)%1000000;
                check(v,j[0]); check(-(v%100000),j[0]);
            end
        end
        case (count) 10032: ; default: $fatal(1,"Incomplete display test count=%0d",count); endcase
        $display("TEST-008 DISPLAY PASS cases=%0d BCD_add3=16 seed=20261011 segments_magnitude_BCD=PASS",count);
        $finish;
    end
endmodule
