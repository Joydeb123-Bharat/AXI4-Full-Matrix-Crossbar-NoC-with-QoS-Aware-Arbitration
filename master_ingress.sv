`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.07.2026 20:38:21
// Design Name: 
// Module Name: master_ingress
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
module master_ingress #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 8
)(
    input logic clk,
    input logic rst_n,

    // External Master Port - Write Address (AW) Channel
    input  logic [ID_WIDTH-1:0]   s_awid,
    input  logic [ADDR_WIDTH-1:0] s_awaddr,
    input  logic [7:0]            s_awlen,
    input  logic                  s_awvalid,
    output logic                  s_awready,

    // External Master Port - Write Data (W) Channel
    input  logic [DATA_WIDTH-1:0] s_wdata,
    input  logic [DATA_WIDTH/8-1:0] s_wstrb,
    input  logic                  s_wlast,
    input  logic                  s_wvalid,
    output logic                  s_wready,

    // Internal Matrix Outputs - Address Routing (Exploded Vectors)
    output logic [4:0]            m_awvalid_vector,
    input  logic [4:0]            m_awready_vector,
    output logic [1:0]            m_slave_sel,

    // Internal Matrix Outputs - Data Routing (Cleaned Flat Bus)
    output logic [DATA_WIDTH-1:0] m_wdata,
    output logic [DATA_WIDTH/8-1:0] m_wstrb,
    output logic                  m_wlast,
    output logic                  m_wvalid,
    input  logic                  m_wready // Feedback from the matrix multiplexer logic
);

    // AW Channel Pipeline & Decode
    localparam AW_PAYLOAD_WIDTH = ADDR_WIDTH + ID_WIDTH + 8;
    logic [AW_PAYLOAD_WIDTH-1:0] buffer_in_aw_payload,buffer_out_aw_payload;
    assign buffer_in_aw_payload = {s_awid,s_awaddr,s_awlen};
    logic [ID_WIDTH-1:0]   clean_awid;
    logic [ADDR_WIDTH-1:0] clean_awaddr;
    logic [7:0]            clean_awlen;
    assign {clean_awid, clean_awaddr, clean_awlen} = buffer_out_aw_payload;
    logic clean_valid;
    
    // Instantiating the AW channel modules
    logic target_ready,decoder_err;
    always_comb
    begin
        if(decoder_err)
        target_ready = m_awready_vector[4];
        else
        target_ready = m_awready_vector[m_slave_sel];
    end
    
    skid_buffer #(.DATA_WIDTH(AW_PAYLOAD_WIDTH)) aw_skid (
        .s_data(buffer_in_aw_payload),
        .s_valid(s_awvalid),
        .s_ready(s_awready),
        .m_data(buffer_out_aw_payload),
        .m_valid(clean_valid),
        .m_ready(target_ready),
        .clk(clk),
        .rst_n(rst_n)
    );
    
    address_decoder addrDec (
        .addr_in(clean_awaddr),
        .slave_sel(m_slave_sel),
        .decode_err(decoder_err)
    );
    
    always_comb
    begin
        m_awvalid_vector = 5'b00000;
        if(clean_valid)
        begin
            if(decoder_err)
            m_awvalid_vector[4] = 1'b1;
            else
            m_awvalid_vector[m_slave_sel] = 1'b1;
        end
    end  
    
    // W Channel Pipeline (No Decode Needed Here!)
    localparam W_PAYLOAD_WIDTH = DATA_WIDTH + DATA_WIDTH/8 + 1;
    logic [W_PAYLOAD_WIDTH-1:0] buffer_in_w_payload, buffer_out_w_payload;
    assign buffer_in_w_payload = {s_wdata,s_wstrb,s_wlast};
    assign {m_wdata,m_wstrb,m_wlast} = buffer_out_w_payload;
    
    
    // Instantiating the modules for W channel
    skid_buffer #(.DATA_WIDTH(W_PAYLOAD_WIDTH)) w_skid (
        .s_data(buffer_in_w_payload),
        .s_valid(s_wvalid),
        .s_ready(s_wready),
        .m_data(buffer_out_w_payload),
        .m_valid(m_wvalid),
        .m_ready(m_wready),
        .clk(clk),
        .rst_n(rst_n)
    );
    
    
    
endmodule