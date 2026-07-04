`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.07.2026 15:57:40
// Design Name: 
// Module Name: route_info_fifo
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

// Route token layout, packed into 18 bits so no shared type crosses a file boundary: [17:16]=slave_id, [15:8]=master_id, [7:0]=burst_len

module route_info_fifo #(
    parameter int DEPTH = 8
)(
    input  logic clk,
    input  logic rst_n,

    // Push Interface (from AW Arbiter)
    input  logic [17:0] push_data,
    input  logic        push_en,
    output logic        full,

    // Pop Interface (from W Channel Mux)
    output logic [17:0] pop_data,
    input  logic        pop_en,
    output logic        empty
);

    // Pointer width sized to DEPTH, plus one wrap bit for full/empty disambiguation
    localparam int PTR_WIDTH = $clog2(DEPTH);

    // Fifo memory array - DEPTH entries, one 18-bit route token each
    logic [17:0] fifo [DEPTH];
    
    // Read and write pointers
    logic [PTR_WIDTH:0] w_ptr,r_ptr;
   
    // Fifo status logic
    assign full = (w_ptr[PTR_WIDTH-1:0] == r_ptr[PTR_WIDTH-1:0]) && (w_ptr[PTR_WIDTH] != r_ptr[PTR_WIDTH]);
    assign empty = (w_ptr == r_ptr);
    
    // Header data
    assign pop_data = fifo[r_ptr[PTR_WIDTH-1:0]];
    
    // Push Pop logic 
    always_ff@(posedge clk)
    begin
        if(!rst_n)
        begin
            for(int i=0; i<DEPTH; i++)
            begin: Initialiser
                fifo[i] <= '0;
            end
            w_ptr <= '0;
            r_ptr <= '0;
        end
        else
        begin
            if(push_en)
            begin
                fifo[w_ptr[PTR_WIDTH-1:0]] <= push_data;
                w_ptr <= w_ptr + 1; 
            end
            if(pop_en)
            begin
                r_ptr <= r_ptr + 1;
            end
        end
    end

endmodule