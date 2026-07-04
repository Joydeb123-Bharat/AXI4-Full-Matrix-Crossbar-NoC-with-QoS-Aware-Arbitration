`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.07.2026 22:29:17
// Design Name: 
// Module Name: skid_buffer
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

module skid_buffer #(
    parameter int DATA_WIDTH = 40 // Typically width of Payload (e.g., ADDR, SIZE) + ID
)(
    input  logic clk,
    input  logic rst_n,

    // Upstream (from master / previous stage)
    input  logic [DATA_WIDTH-1:0] s_data,
    input  logic                  s_valid,
    output logic                  s_ready, // Drives upstream READY

    // Downstream (to slave / next stage)
    output logic [DATA_WIDTH-1:0] m_data,
    output logic                  m_valid,
    input  logic                  m_ready  // Receives downstream READY
);

    // Internal Registers
    logic [DATA_WIDTH-1:0] primary_r, shadow_r;
    logic                  primary_valid_r, shadow_valid_r;

    // Combinational Output Assignments
    assign s_ready = !shadow_valid_r;
    assign m_data = primary_r;
    assign m_valid = primary_valid_r; 
   
    // Sequential State Machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
        begin
            primary_valid_r <= 1'b0;
            shadow_valid_r  <= 1'b0;
            primary_r       <= '0;
            shadow_r        <= '0;
        end 
        else 
        begin
            case({shadow_valid_r,primary_valid_r})
                2'b00: // IDLE
                begin
                    if(s_valid)
                    begin
                        primary_valid_r <= 1'b1;
                        primary_r <= s_data;
                    end
                end
                2'b01: // BUSY
                begin
                    if(!m_ready)
                    begin
                        shadow_valid_r <= s_valid;
                        if(s_valid)
                        shadow_r <= s_data;
                    end
                    else if(m_ready)
                    begin
                        primary_valid_r <= s_valid;
                        primary_r <= s_data;
                    end
                end
                2'b11: // FULL
                begin
                    if(m_ready)
                    begin
                        primary_valid_r <= shadow_valid_r;
                        primary_r <= shadow_r;
                        shadow_valid_r <= '0;
                        shadow_r <= '0;
                    end
                end
                default: 
                begin
                    primary_valid_r <= 1'b0;
                    shadow_valid_r  <= 1'b0;
                    primary_r       <= '0;
                    shadow_r        <= '0;
                end
           endcase
        end
    end

endmodule