`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.07.2026 22:48:21
// Design Name: 
// Module Name: slave_aw_egress
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

module slave_aw_egress_dwrr #(
    parameter int ADDR_WIDTH = 32,
    parameter int ID_WIDTH   = 8,
    parameter int QUANTUM    = 16 // Number of beats allocated per round
)(
    input logic clk,
    input logic rst_n,

    // Incoming requests from all 4 Master Ingress blocks
    input  logic [3:0]            s_awvalid_bus, // [3]=M3, [2]=M2, [1]=M1, [0]=M0
    output logic [3:0]            s_awready_bus, 
    
    // Incoming payloads from all 4 Masters
    input  logic [ID_WIDTH-1:0]   s_awid_m0,    input  logic [ADDR_WIDTH-1:0] s_awaddr_m0, input logic [7:0] s_awlen_m0,
    input  logic [ID_WIDTH-1:0]   s_awid_m1,    input  logic [ADDR_WIDTH-1:0] s_awaddr_m1, input logic [7:0] s_awlen_m1,
    input  logic [ID_WIDTH-1:0]   s_awid_m2,    input  logic [ADDR_WIDTH-1:0] s_awaddr_m2, input logic [7:0] s_awlen_m2,
    input  logic [ID_WIDTH-1:0]   s_awid_m3,    input  logic [ADDR_WIDTH-1:0] s_awaddr_m3, input logic [7:0] s_awlen_m3,

    // Outbound Port towards the actual Slave
    output logic [ID_WIDTH+2-1:0] m_awid, // Expands by 2 bits for Prepend Master ID!
    output logic [ADDR_WIDTH-1:0] m_awaddr,
    output logic [7:0]            m_awlen,
    output logic                  m_awvalid,
    input  logic                  m_awready,

    // FIFO interface to push routing tokens over to the companion W-mux
    output logic                  fifo_push_en,
    output logic [1:0]            fifo_master_id,
    input  logic                  fifo_full // Backpressure: route_info_fifo cannot accept another token
);

    // Deficit counters for the 4 masters (signed integers or wide logic to allow tracking subtraction)
    logic signed [11:0] deficit_count_r [4];
    logic [1:0]         current_master_r;
    
    // Cost of the selected transaction in beats: AWLEN + 1
    logic [8:0] transaction_cost;
    
    // DWRR Scheduler Logic (always_comb & always_ff)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 4; i++) deficit_count_r[i] <= 12'd0;
            current_master_r <= '0;
        end else begin
            if (m_awvalid && m_awready) 
            begin
                // A successful handshake finished! Deduct credit cost immediately
                deficit_count_r[current_master_r] <= deficit_count_r[current_master_r] - transaction_cost;
            end 
            else if (!s_awvalid_bus[current_master_r]) 
            begin
                // Condition A: Current master is silent. Skip to next master immediately.
                current_master_r <= current_master_r + 1;
            end 
            else if (deficit_count_r[current_master_r] < $signed({3'b000, transaction_cost})) 
            begin
                // Condition B: Master has a request, but budget is too low.
                // Replenish its account with QUANTUM credit and rotate.
                deficit_count_r[current_master_r] <= deficit_count_r[current_master_r] + QUANTUM;
                current_master_r <= current_master_r + 1;
            end
            else if (fifo_full)
            begin
                // Condition C: Master has a request and enough credit, but the downstream
                // route FIFO for its target is backed up. Not this master's fault - rotate
                // without touching its deficit, so a master targeting a non-backed-up
                // destination gets a turn instead of the whole arbiter stalling here forever.
                current_master_r <= current_master_r + 1;
            end
        end
    end
    
    // Multiplexer Payload Routing with ID Prepend
    always_comb
    begin
        m_awid = '0;
        m_awaddr = '0;
        m_awlen = '0;
        s_awready_bus = '0;
        m_awvalid = s_awvalid_bus[current_master_r] && !fifo_full;
        case(current_master_r)
            2'b00: // Master 0
                    begin
                        m_awid = {current_master_r,s_awid_m0};
                        m_awaddr = s_awaddr_m0;
                        m_awlen = s_awlen_m0;
                        s_awready_bus[0] = m_awready && !fifo_full;
                    end
            2'b01: // Master 1
                    begin
                        m_awid = {current_master_r,s_awid_m1};
                        m_awaddr = s_awaddr_m1;
                        m_awlen = s_awlen_m1;
                        s_awready_bus[1] = m_awready && !fifo_full;
                    end
            2'b10: // Master 2
                    begin
                        m_awid = {current_master_r,s_awid_m2};
                        m_awaddr = s_awaddr_m2;
                        m_awlen = s_awlen_m2;
                        s_awready_bus[2] = m_awready && !fifo_full;
                    end
            2'b11: // Master 3
                    begin
                        m_awid = {current_master_r,s_awid_m3};
                        m_awaddr = s_awaddr_m3;
                        m_awlen = s_awlen_m3;
                        s_awready_bus[3] = m_awready && !fifo_full;
                    end
        endcase
        
        transaction_cost = m_awlen + 1;
           
    end
   
    // Handshake & Token FIFO Signals
    // Combinational: the token is pushed the same cycle the AW handshake completes,
    // so route_info_fifo captures it with zero extra latency and stays reset-style
    // consistent with the async-reset arbiter state above.
    assign fifo_push_en   = m_awvalid && m_awready;
    assign fifo_master_id = current_master_r;
endmodule