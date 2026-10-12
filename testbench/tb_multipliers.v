`timescale 1ns/1ps
module tb_multipliers;
    reg signed [7:0] lhs8, rhs8;
    reg signed [7:0] lhs_mixed;
    reg [14:0] rhs15;
    wire signed [15:0] signed_product;
    wire signed [21:0] mixed_product;
    integer a,b,expected,fd,scanned,kind,va,vb,count_signed,count_mixed,count_squares,count_boundary;
    mul_s8_s8 signed_dut (.lhs(lhs8),.rhs(rhs8),.product(signed_product));
    mul_s8_u15 mixed_dut (.lhs(lhs_mixed),.rhs(rhs15),.product(mixed_product));
    initial begin
        count_signed=0; count_mixed=0; count_squares=0; count_boundary=0;
        lhs8=0;rhs8=0;lhs_mixed=0;rhs15=0;
        fd=$fopen("verification/vectors/multipliers.txt","r");
        case(fd) 0:$fatal(1,"Missing reference vectors"); default:; endcase
        while (!$feof(fd)) begin
            scanned=$fscanf(fd,"%d %d %d %d\n",kind,va,vb,expected);
            case(scanned)
                4: begin
                    count_boundary=count_boundary+1;
                    case(kind)
                        0: begin
                            lhs8=va;rhs8=vb;#1;
                            case($signed(signed_product)===expected)
                                1'b1:; default:$fatal(1,"Boundary signed a=%0d b=%0d",va,vb);
                            endcase
                        end
                        1: begin
                            lhs_mixed=va;rhs15=vb;#1;
                            case($signed(mixed_product)===expected)
                                1'b1:; default:$fatal(1,"Boundary mixed a=%0d b=%0d",va,vb);
                            endcase
                        end
                        default:$fatal(1,"Unknown boundary kind");
                    endcase
                end
                default:$fatal(1,"Malformed boundary vector");
            endcase
        end
        $fclose(fd);
        for(a=-128;a<128;a=a+1) begin
            for(b=-128;b<128;b=b+1) begin
                lhs8=a;rhs8=b;expected=a*b;#1;
                case($signed(signed_product)===expected)
                    1'b1:;default:$fatal(1,"Signed a=%0d b=%0d got=%0d expected=%0d",a,b,signed_product,expected);
                endcase
                count_signed=count_signed+1;
            end
        end
        for(a=-128;a<128;a=a+1) begin
            lhs8=a;rhs8=a;expected=a*a;#1;
            case((signed_product[15]===1'b0) && ({1'b0,signed_product[14:0]}===expected))
                1'b1:;default:$fatal(1,"Square conversion a=%0d",a);
            endcase
            count_squares=count_squares+1;
        end
        for(a=-128;a<128;a=a+1) begin
            lhs_mixed=a;
            for(b=0;b<=16384;b=b+1) begin
                rhs15=b;expected=a*b;#1;
                case($signed(mixed_product)===expected)
                    1'b1:;default:$fatal(1,"Mixed a=%0d b=%0d got=%0d expected=%0d",a,b,mixed_product,expected);
                endcase
                count_mixed=count_mixed+1;
            end
            case(a & 31)
                31:$display("TEST-003 progress lhs=%0d mixed=%0d",a,count_mixed);
                default:;
            endcase
        end
        case((count_signed==65536)&&(count_mixed==4194560)&&(count_squares==256)&&(count_boundary==91))
            1'b1:;default:$fatal(1,"Incomplete coverage");
        endcase
        $display("TEST-003 PASS signed=%0d mixed=%0d squares=%0d boundary=%0d",count_signed,count_mixed,count_squares,count_boundary);
        $finish;
    end
endmodule
