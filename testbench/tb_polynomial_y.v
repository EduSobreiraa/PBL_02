`timescale 1ns/1ps
module tb_polynomial_y;
    reg signed [7:0] a, b, c, x;
    wire signed [22:0] public_y, core_y;
    wire public_OV, core_OV, carry_y;
    integer fd, scanned, kind, va, vb, vc, vx, expected_y, expected_carry;
    integer rows, directed_count, cartesian_count, random_count;
    polynomial_y public_dut(.a(a), .b(b), .c(c), .x(x), .y(public_y), .OV(public_OV));
    polynomial_y_core core_dut(.a(a), .b(b), .c(c), .x(x),
        .y(core_y), .OV(core_OV), .carry_y(carry_y));
    initial begin
        fd=$fopen("verification/vectors/y.txt","r");
        case (fd)
            0: $fatal(1,"Cannot open y vectors");
            default: ;
        endcase
        rows=0; directed_count=0; cartesian_count=0; random_count=0;
        while (!$feof(fd)) begin
            scanned=$fscanf(fd,"%d %d %d %d %d %d %d\n",kind,va,vb,vc,vx,expected_y,expected_carry);
            case (scanned)
                7: begin
                    a=va[7:0]; b=vb[7:0]; c=vc[7:0]; x=vx[7:0];
                    #1;
                    rows=rows+1;
                    case (($signed(core_y) === expected_y) &&
                        ($signed(public_y) === expected_y) &&
                        (carry_y === expected_carry[0]) &&
                        (core_OV === 1'b0) && (public_OV === 1'b0))
                        1'b1: ;
                        default: $fatal(1,"y row=%0d a=%0d b=%0d c=%0d x=%0d core=%0d public=%0d expected=%0d carry=%0d expected_carry=%0d OV=%b%b",rows,va,vb,vc,vx,core_y,public_y,expected_y,carry_y,expected_carry,core_OV,public_OV);
                    endcase
                    case (kind)
                        0: directed_count=directed_count+1;
                        1: cartesian_count=cartesian_count+1;
                        2: random_count=random_count+1;
                        default: $fatal(1,"Unknown vector type");
                    endcase
                end
                default: $fatal(1,"Malformed y vector row=%0d scanned=%0d",rows,scanned);
            endcase
        end
        $fclose(fd);
        case ((rows==12413) && (directed_count==12) && (cartesian_count==2401) && (random_count==10000))
            1'b1: ;
            default: $fatal(1,"Incomplete y vectors rows=%0d",rows);
        endcase
        $display("TEST-006 PASS directed=%0d cartesian=%0d random=%0d rows=%0d wrapper_core=PASS carry=PASS OV=PASS",directed_count,cartesian_count,random_count,rows);
        $finish;
    end
endmodule
