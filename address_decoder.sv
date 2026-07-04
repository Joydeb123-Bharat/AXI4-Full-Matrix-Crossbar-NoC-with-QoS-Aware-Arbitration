`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.07.2026 10:46:47
// Design Name: 
// Module Name: address_decoder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module address_decoder(
    // Inputs
    input  logic [31:0] addr_in,
    
    // Outputs
    output logic [1:0]  slave_sel, // 0-3: valid slave
    output logic        decode_err // 1: no slave matched
);
    // For slave selection and decode error logic
    always_comb begin
        slave_sel  = 2'b00;
        decode_err = 1'b1;
        case(addr_in[31:28])
            4'd0:
            begin
                slave_sel = 2'b00;
                decode_err = 1'b0;
            end
            4'd1: 
            begin
                slave_sel = 2'b01;
                decode_err = 1'b0;
            end
            4'd2:
            begin
                slave_sel = 2'b10;
                decode_err = 1'b0;
            end
            4'd3:
            begin
                slave_sel = 2'b11;
                decode_err = 1'b0;
            end
            default: begin
                decode_err = 1'b1;
                slave_sel = 2'b0;
            end
        endcase
    end
endmodule