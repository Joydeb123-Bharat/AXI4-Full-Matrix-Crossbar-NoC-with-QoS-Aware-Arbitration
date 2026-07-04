`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.07.2026 14:54:25
// Design Name: 
// Module Name: slave_w_egress
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


module slave_w_egress #(
    parameter int DATA_WIDTH = 32
)(
    input logic clk,
    input logic rst_n,

    // Interface linking directly to the local Route-Info FIFO
    input  logic        fifo_empty,
    input  logic [1:0]  fifo_master_id, // Head of the FIFO token
    output logic        fifo_pop_en,

    // Flat data buses arriving from all 4 Master Ingress pipelines
    input  logic [DATA_WIDTH-1:0]   s_wdata_m0, input logic [DATA_WIDTH/8-1:0] s_wstrb_m0, input logic s_wlast_m0, input logic s_wvalid_m0,
    input  logic [DATA_WIDTH-1:0]   s_wdata_m1, input logic [DATA_WIDTH/8-1:0] s_wstrb_m1, input logic s_wlast_m1, input logic s_wvalid_m1,
    input  logic [DATA_WIDTH-1:0]   s_wdata_m2, input logic [DATA_WIDTH/8-1:0] s_wstrb_m2, input logic s_wlast_m2, input logic s_wvalid_m2,
    input  logic [DATA_WIDTH-1:0]   s_wdata_m3, input logic [DATA_WIDTH/8-1:0] s_wstrb_m3, input logic s_wlast_m3, input logic s_wvalid_m3,
    
    // Backpressure reverse feedback signals returned to the Masters
    output logic [3:0]              s_wready_bus,

    // Outbound W Port driving the external Slave
    output logic [DATA_WIDTH-1:0]   m_wdata,
    output logic [DATA_WIDTH/8-1:0] m_wstrb,
    output logic                    m_wlast,
    output logic                    m_wvalid,
    input  logic                    m_wready
);

     // Implement Burst-Lock Multiplexer Selection Tree
    always_comb
    begin
        m_wdata = '0;
        m_wstrb = '0;
        m_wlast = '0;
        m_wvalid= '0;
        s_wready_bus = '0;
        if(!fifo_empty)
        begin
            case(fifo_master_id)
                2'b00: // Master 0
                    begin
                        m_wdata = s_wdata_m0;
                        m_wstrb = s_wstrb_m0;
                        m_wlast = s_wlast_m0;
                        m_wvalid = s_wvalid_m0;
                    end
                2'b01: // Master 1
                    begin
                        m_wdata = s_wdata_m1;
                        m_wstrb = s_wstrb_m1;
                        m_wlast = s_wlast_m1;
                        m_wvalid = s_wvalid_m1;
                    end
                2'b10: // Master 2
                    begin
                        m_wdata = s_wdata_m2;
                        m_wstrb = s_wstrb_m2;
                        m_wlast = s_wlast_m2;
                        m_wvalid = s_wvalid_m2;
                    end
                2'b11: // Master 3
                    begin
                        m_wdata = s_wdata_m3;
                        m_wstrb = s_wstrb_m3;
                        m_wlast = s_wlast_m3;
                        m_wvalid = s_wvalid_m3;
                    end 
              endcase
              s_wready_bus[fifo_master_id] = m_wready;
        end
    end
    
    // Implement Token Consumption Pop Strobe
    assign fifo_pop_en = (m_wlast && m_wready && m_wvalid) ? 1'b1 : 1'b0;
    
endmodule