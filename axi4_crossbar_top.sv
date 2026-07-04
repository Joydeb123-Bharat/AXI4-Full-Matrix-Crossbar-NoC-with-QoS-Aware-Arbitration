`timescale 1ns / 1ps

module axi4_crossbar_top #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 8
)(
    input logic clk,
    input logic rst_n,

    // Master 0 Ports
    input  logic [ID_WIDTH-1:0]     m0_awid,    input  logic [ADDR_WIDTH-1:0]  m0_awaddr,  input  logic [7:0] m0_awlen,    input  logic m0_awvalid,  output logic m0_awready,
    input  logic [DATA_WIDTH-1:0]   m0_wdata,   input  logic [DATA_WIDTH/8-1:0] m0_wstrb,   input  logic m0_wlast,      input  logic m0_wvalid,   output logic m0_wready,
    output logic [ID_WIDTH-1:0]     m0_bid,     output logic [1:0]             m0_bresp,   output logic m0_bvalid,     input  logic m0_bready,
    input  logic [ID_WIDTH-1:0]     m0_arid,    input  logic [ADDR_WIDTH-1:0]  m0_araddr,  input  logic [7:0] m0_arlen,    input  logic m0_arvalid,  output logic m0_arready,
    output logic [ID_WIDTH-1:0]     m0_rid,     output logic [DATA_WIDTH-1:0]  m0_rdata,   output logic [1:0] m0_rresp,    output logic m0_rlast,    output logic m0_rvalid, input logic m0_rready,

    // Master 1 Ports
    input  logic [ID_WIDTH-1:0]     m1_awid,    input  logic [ADDR_WIDTH-1:0]  m1_awaddr,  input  logic [7:0] m1_awlen,    input  logic m1_awvalid,  output logic m1_awready,
    input  logic [DATA_WIDTH-1:0]   m1_wdata,   input  logic [DATA_WIDTH/8-1:0] m1_wstrb,   input  logic m1_wlast,      input  logic m1_wvalid,   output logic m1_wready,
    output logic [ID_WIDTH-1:0]     m1_bid,     output logic [1:0]             m1_bresp,   output logic m1_bvalid,     input  logic m1_bready,
    input  logic [ID_WIDTH-1:0]     m1_arid,    input  logic [ADDR_WIDTH-1:0]  m1_araddr,  input  logic [7:0] m1_arlen,    input  logic m1_arvalid,  output logic m1_arready,
    output logic [ID_WIDTH-1:0]     m1_rid,     output logic [DATA_WIDTH-1:0]  m1_rdata,   output logic [1:0] m1_rresp,    output logic m1_rlast,    output logic m1_rvalid, input logic m1_rready,

    // Master 2 Ports
    input  logic [ID_WIDTH-1:0]     m2_awid,    input  logic [ADDR_WIDTH-1:0]  m2_awaddr,  input  logic [7:0] m2_awlen,    input  logic m2_awvalid,  output logic m2_awready,
    input  logic [DATA_WIDTH-1:0]   m2_wdata,   input  logic [DATA_WIDTH/8-1:0] m2_wstrb,   input  logic m2_wlast,      input  logic m2_wvalid,   output logic m2_wready,
    output logic [ID_WIDTH-1:0]     m2_bid,     output logic [1:0]             m2_bresp,   output logic m2_bvalid,     input  logic m2_bready,
    input  logic [ID_WIDTH-1:0]     m2_arid,    input  logic [ADDR_WIDTH-1:0]  m2_araddr,  input  logic [7:0] m2_arlen,    input  logic m2_arvalid,  output logic m2_arready,
    output logic [ID_WIDTH-1:0]     m2_rid,     output logic [DATA_WIDTH-1:0]  m2_rdata,   output logic [1:0] m2_rresp,    output logic m2_rlast,    output logic m2_rvalid, input logic m2_rready,

    // Master 3 Ports
    input  logic [ID_WIDTH-1:0]     m3_awid,    input  logic [ADDR_WIDTH-1:0]  m3_awaddr,  input  logic [7:0] m3_awlen,    input  logic m3_awvalid,  output logic m3_awready,
    input  logic [DATA_WIDTH-1:0]   m3_wdata,   input  logic [DATA_WIDTH/8-1:0] m3_wstrb,   input  logic m3_wlast,      input  logic m3_wvalid,   output logic m3_wready,
    output logic [ID_WIDTH-1:0]     m3_bid,     output logic [1:0]             m3_bresp,   output logic m3_bvalid,     input  logic m3_bready,
    input  logic [ID_WIDTH-1:0]     m3_arid,    input  logic [ADDR_WIDTH-1:0]  m3_araddr,  input  logic [7:0] m3_arlen,    input  logic m3_arvalid,  output logic m3_arready,
    output logic [ID_WIDTH-1:0]     m3_rid,     output logic [DATA_WIDTH-1:0]  m3_rdata,   output logic [1:0] m3_rresp,    output logic m3_rlast,    output logic m3_rvalid, input logic m3_rready,

    // Slave 0 Ports
    output logic [ID_WIDTH+2-1:0]   s0_awid,    output logic [ADDR_WIDTH-1:0]  s0_awaddr,  output logic [7:0] s0_awlen,    output logic s0_awvalid,  input  logic s0_awready,
    output logic [DATA_WIDTH-1:0]   s0_wdata,   output logic [DATA_WIDTH/8-1:0] s0_wstrb,   output logic s0_wlast,      output logic s0_wvalid,   input  logic s0_wready,
    input  logic [ID_WIDTH+2-1:0]   s0_bid,     input  logic [1:0]             s0_bresp,   input  logic s0_bvalid,     output logic s0_bready,
    output logic [ID_WIDTH+2-1:0]   s0_arid,    output logic [ADDR_WIDTH-1:0]  s0_araddr,  output logic [7:0] s0_arlen,    output logic s0_arvalid,  input  logic s0_arready,
    input  logic [ID_WIDTH+2-1:0]   s0_rid,     input  logic [DATA_WIDTH-1:0]  s0_rdata,   input  logic [1:0] s0_rresp,    input  logic s0_rlast,    input  logic s0_rvalid, output logic s0_rready,

    // Slave 1 Ports
    output logic [ID_WIDTH+2-1:0]   s1_awid,    output logic [ADDR_WIDTH-1:0]  s1_awaddr,  output logic [7:0] s1_awlen,    output logic s1_awvalid,  input  logic s1_awready,
    output logic [DATA_WIDTH-1:0]   s1_wdata,   output logic [DATA_WIDTH/8-1:0] s1_wstrb,   output logic s1_wlast,      output logic s1_wvalid,   input  logic s1_wready,
    input  logic [ID_WIDTH+2-1:0]   s1_bid,     input  logic [1:0]             s1_bresp,   input  logic s1_bvalid,     output logic s1_bready,
    output logic [ID_WIDTH+2-1:0]   s1_arid,    output logic [ADDR_WIDTH-1:0]  s1_araddr,  output logic [7:0] s1_arlen,    output logic s1_arvalid,  input  logic s1_arready,
    input  logic [ID_WIDTH+2-1:0]   s1_rid,     input  logic [DATA_WIDTH-1:0]  s1_rdata,   input  logic [1:0] s1_rresp,    input  logic s1_rlast,    input  logic s1_rvalid, output logic s1_rready,

    // Slave 2 Ports
    output logic [ID_WIDTH+2-1:0]   s2_awid,    output logic [ADDR_WIDTH-1:0]  s2_awaddr,  output logic [7:0] s2_awlen,    output logic s2_awvalid,  input  logic s2_awready,
    output logic [DATA_WIDTH-1:0]   s2_wdata,   output logic [DATA_WIDTH/8-1:0] s2_wstrb,   output logic s2_wlast,      output logic s2_wvalid,   input  logic s2_wready,
    input  logic [ID_WIDTH+2-1:0]   s2_bid,     input  logic [1:0]             s2_bresp,   input  logic s2_bvalid,     output logic s2_bready,
    output logic [ID_WIDTH+2-1:0]   s2_arid,    output logic [ADDR_WIDTH-1:0]  s2_araddr,  output logic [7:0] s2_arlen,    output logic s2_arvalid,  input  logic s2_arready,
    input  logic [ID_WIDTH+2-1:0]   s2_rid,     input  logic [DATA_WIDTH-1:0]  s2_rdata,   input  logic [1:0] s2_rresp,    input  logic s2_rlast,    input  logic s2_rvalid, output logic s2_rready,

    // Slave 3 Ports
    output logic [ID_WIDTH+2-1:0]   s3_awid,    output logic [ADDR_WIDTH-1:0]  s3_awaddr,  output logic [7:0] s3_awlen,    output logic s3_awvalid,  input  logic s3_awready,
    output logic [DATA_WIDTH-1:0]   s3_wdata,   output logic [DATA_WIDTH/8-1:0] s3_wstrb,   output logic s3_wlast,      output logic s3_wvalid,   input  logic s3_wready,
    input  logic [ID_WIDTH+2-1:0]   s3_bid,     input  logic [1:0]             s3_bresp,   input  logic s3_bvalid,     output logic s3_bready,
    output logic [ID_WIDTH+2-1:0]   s3_arid,    output logic [ADDR_WIDTH-1:0]  s3_araddr,  output logic [7:0] s3_arlen,    output logic s3_arvalid,  input  logic s3_arready,
    input  logic [ID_WIDTH+2-1:0]   s3_rid,     input  logic [DATA_WIDTH-1:0]  s3_rdata,   input  logic [1:0] s3_rresp,    input  logic s3_rlast,    input  logic s3_rvalid, output logic s3_rready
);

    // One-hot Valid Vectors from Master Ingress Engines [4]=Default, [3:0]=Slaves
    logic [4:0] m0_awvalid_vector, m1_awvalid_vector, m2_awvalid_vector, m3_awvalid_vector;
    logic [4:0] m0_awready_vector, m1_awready_vector, m2_awready_vector, m3_awready_vector;
    logic [4:0] m0_arvalid_vector, m1_arvalid_vector, m2_arvalid_vector, m3_arvalid_vector;
    logic [4:0] m0_arready_vector, m1_arready_vector, m2_arready_vector, m3_arready_vector;

    // Master Ingress Clean Payload Signals
    logic [ID_WIDTH-1:0]   m0_clean_awid,   m1_clean_awid,   m2_clean_awid,   m3_clean_awid;
    logic [ADDR_WIDTH-1:0] m0_clean_awaddr, m1_clean_awaddr, m2_clean_awaddr, m3_clean_awaddr;
    logic [7:0]            m0_clean_awlen,  m1_clean_awlen,  m2_clean_awlen,  m3_clean_awlen;
    logic [ID_WIDTH-1:0]   m0_clean_arid,   m1_clean_arid,   m2_clean_arid,   m3_clean_arid;
    logic [ADDR_WIDTH-1:0] m0_clean_araddr, m1_clean_araddr, m2_clean_araddr, m3_clean_araddr;
    logic [7:0]            m0_clean_arlen,  m1_clean_arlen,  m2_clean_arlen,  m3_clean_arlen;

    // W-Channel Interconnect Mesh Buses
    logic [DATA_WIDTH-1:0]   m0_wdata_mat,  m1_wdata_mat,  m2_wdata_mat,  m3_wdata_mat;
    logic [DATA_WIDTH/8-1:0] m0_wstrb_mat,  m1_wstrb_mat,  m2_wstrb_mat,  m3_wstrb_mat;
    logic                    m0_wlast_mat,  m1_wlast_mat,  m2_wlast_mat,  m3_wlast_mat;
    logic                    m0_wvalid_mat, m1_wvalid_mat, m2_wvalid_mat, m3_wvalid_mat;
    logic                    m0_wready_mat, m1_wready_mat, m2_wready_mat, m3_wready_mat;

    // Arbiter Handshake Extraction Buses
    logic [3:0] s0_awready_bus, s1_awready_bus, s2_awready_bus, s3_awready_bus, sd_awready_bus;
    logic [3:0] s0_arready_bus, s1_arready_bus, s2_arready_bus, s3_arready_bus, sd_arready_bus;
    logic [3:0] s0_wready_bus,  s1_wready_bus,  s2_wready_bus,  s3_wready_bus,  sd_wready_bus;

    // Response Matrix Reverse Backpressure Buses to prevent multi-driver collisions
    // Bit [4] of each carries the Default (decode-error) Slave's ready lane
    logic [4:0] m0_s_bready_bus, m1_s_bready_bus, m2_s_bready_bus, m3_s_bready_bus;
    logic [4:0] m0_s_rready_bus, m1_s_rready_bus, m2_s_rready_bus, m3_s_rready_bus;

    // Route-Info FIFO Internal Structures
    logic       fifo0_empty,     fifo1_empty,     fifo2_empty,     fifo3_empty;
    logic [1:0] fifo0_master_id, fifo1_master_id, fifo2_master_id, fifo3_master_id;
    logic       fifo0_push,      fifo1_push,      fifo2_push,      fifo3_push;
    logic       fifo0_pop,       fifo1_pop,       fifo2_pop,       fifo3_pop;
    logic [1:0] fifo0_push_id,   fifo1_push_id,   fifo2_push_id,   fifo3_push_id;

    // Default Slave Error Intercept Buses
    logic [ID_WIDTH+2-1:0] sd_awid, sd_arid;
    logic                  sd_awvalid, sd_awready, sd_wvalid, sd_wready, sd_wlast, sd_arvalid, sd_arready;
    logic [ID_WIDTH+2-1:0] sd_bid, sd_rid;
    logic [1:0]            sd_bresp, sd_rresp;
    logic                  sd_bvalid, sd_bready, sd_rvalid, sd_rready, sd_rlast;
    logic [DATA_WIDTH-1:0] sd_rdata;

    // Combinational Matrix Routing
    always_comb begin
        // Address matrix reverse paths
        m0_awready_vector = {sd_awready_bus[0], s3_awready_bus[0], s2_awready_bus[0], s1_awready_bus[0], s0_awready_bus[0]};
        m1_awready_vector = {sd_awready_bus[1], s3_awready_bus[1], s2_awready_bus[1], s1_awready_bus[1], s0_awready_bus[1]};
        m2_awready_vector = {sd_awready_bus[2], s3_awready_bus[2], s2_awready_bus[2], s1_awready_bus[2], s0_awready_bus[2]};
        m3_awready_vector = {sd_awready_bus[3], s3_awready_bus[3], s2_awready_bus[3], s1_awready_bus[3], s0_awready_bus[3]};

        m0_arready_vector = {sd_arready_bus[0], s3_arready_bus[0], s2_arready_bus[0], s1_arready_bus[0], s0_arready_bus[0]};
        m1_arready_vector = {sd_arready_bus[1], s3_arready_bus[1], s2_arready_bus[1], s1_arready_bus[1], s0_arready_bus[1]};
        m2_arready_vector = {sd_arready_bus[2], s3_arready_bus[2], s2_arready_bus[2], s1_arready_bus[2], s0_arready_bus[2]};
        m3_arready_vector = {sd_arready_bus[3], s3_arready_bus[3], s2_arready_bus[3], s1_arready_bus[3], s0_arready_bus[3]};

        // Data matrix flat collapse
        m0_wready_mat = s0_wready_bus[0] | s1_wready_bus[0] | s2_wready_bus[0] | s3_wready_bus[0] | sd_wready_bus[0];
        m1_wready_mat = s0_wready_bus[1] | s1_wready_bus[1] | s2_wready_bus[1] | s3_wready_bus[1] | sd_wready_bus[1];
        m2_wready_mat = s0_wready_bus[2] | s1_wready_bus[2] | s2_wready_bus[2] | s3_wready_bus[2] | sd_wready_bus[2];
        m3_wready_mat = s0_wready_bus[3] | s1_wready_bus[3] | s2_wready_bus[3] | s3_wready_bus[3] | sd_wready_bus[3];

        // Combine the 4 Master Egress B-channel ready signals to drive the Slaves
        s0_bready = m0_s_bready_bus[0] | m1_s_bready_bus[0] | m2_s_bready_bus[0] | m3_s_bready_bus[0];
        s1_bready = m0_s_bready_bus[1] | m1_s_bready_bus[1] | m2_s_bready_bus[1] | m3_s_bready_bus[1];
        s2_bready = m0_s_bready_bus[2] | m1_s_bready_bus[2] | m2_s_bready_bus[2] | m3_s_bready_bus[2];
        s3_bready = m0_s_bready_bus[3] | m1_s_bready_bus[3] | m2_s_bready_bus[3] | m3_s_bready_bus[3];
        sd_bready = m0_s_bready_bus[4] | m1_s_bready_bus[4] | m2_s_bready_bus[4] | m3_s_bready_bus[4];

        // Combine the 4 Master Egress R-channel ready signals to drive the Slaves
        s0_rready = m0_s_rready_bus[0] | m1_s_rready_bus[0] | m2_s_rready_bus[0] | m3_s_rready_bus[0];
        s1_rready = m0_s_rready_bus[1] | m1_s_rready_bus[1] | m2_s_rready_bus[1] | m3_s_rready_bus[1];
        s2_rready = m0_s_rready_bus[2] | m1_s_rready_bus[2] | m2_s_rready_bus[2] | m3_s_rready_bus[2];
        s3_rready = m0_s_rready_bus[3] | m1_s_rready_bus[3] | m2_s_rready_bus[3] | m3_s_rready_bus[3];
        sd_rready = m0_s_rready_bus[4] | m1_s_rready_bus[4] | m2_s_rready_bus[4] | m3_s_rready_bus[4];
    end

    // Master 0 Ingress Blocks
    master_ingress #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH)) m0_ingress (
        .clk(clk), .rst_n(rst_n),
        .s_awid(m0_awid), .s_awaddr(m0_awaddr), .s_awlen(m0_awlen), .s_awvalid(m0_awvalid), .s_awready(m0_awready),
        .s_wdata(m0_wdata), .s_wstrb(m0_wstrb), .s_wlast(m0_wlast), .s_wvalid(m0_wvalid), .s_wready(m0_wready),
        .m_awvalid_vector(m0_awvalid_vector), .m_awready_vector(m0_awready_vector), .m_slave_sel(),
        .m_wdata(m0_wdata_mat), .m_wstrb(m0_wstrb_mat), .m_wlast(m0_wlast_mat), .m_wvalid(m0_wvalid_mat), .m_wready(m0_wready_mat)
    );
    master_ingress #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH)) m0_ar_ingress (
        .clk(clk), .rst_n(rst_n),
        .s_awid(m0_arid), .s_awaddr(m0_araddr), .s_awlen(m0_arlen), .s_awvalid(m0_arvalid), .s_awready(m0_arready),
        .s_wdata('0), .s_wstrb('0), .s_wlast(1'b0), .s_wvalid(1'b0), .s_wready(),
        .m_awvalid_vector(m0_arvalid_vector), .m_awready_vector(m0_arready_vector), .m_slave_sel(),
        .m_wdata(), .m_wstrb(), .m_wlast(), .m_wvalid(), .m_wready(1'b0)
    );

    // Master 1 Ingress Blocks
    master_ingress #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH)) m1_ingress (
        .clk(clk), .rst_n(rst_n),
        .s_awid(m1_awid), .s_awaddr(m1_awaddr), .s_awlen(m1_awlen), .s_awvalid(m1_awvalid), .s_awready(m1_awready),
        .s_wdata(m1_wdata), .s_wstrb(m1_wstrb), .s_wlast(m1_wlast), .s_wvalid(m1_wvalid), .s_wready(m1_wready),
        .m_awvalid_vector(m1_awvalid_vector), .m_awready_vector(m1_awready_vector), .m_slave_sel(),
        .m_wdata(m1_wdata_mat), .m_wstrb(m1_wstrb_mat), .m_wlast(m1_wlast_mat), .m_wvalid(m1_wvalid_mat), .m_wready(m1_wready_mat)
    );
    master_ingress #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH)) m1_ar_ingress (
        .clk(clk), .rst_n(rst_n),
        .s_awid(m1_arid), .s_awaddr(m1_araddr), .s_awlen(m1_arlen), .s_awvalid(m1_arvalid), .s_awready(m1_arready),
        .s_wdata('0), .s_wstrb('0), .s_wlast(1'b0), .s_wvalid(1'b0), .s_wready(),
        .m_awvalid_vector(m1_arvalid_vector), .m_awready_vector(m1_arready_vector), .m_slave_sel(),
        .m_wdata(), .m_wstrb(), .m_wlast(), .m_wvalid(), .m_wready(1'b0)
    );

    // Master 2 Ingress Blocks
    master_ingress #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH)) m2_ingress (
        .clk(clk), .rst_n(rst_n),
        .s_awid(m2_awid), .s_awaddr(m2_awaddr), .s_awlen(m2_awlen), .s_awvalid(m2_awvalid), .s_awready(m2_awready),
        .s_wdata(m2_wdata), .s_wstrb(m2_wstrb), .s_wlast(m2_wlast), .s_wvalid(m2_wvalid), .s_wready(m2_wready),
        .m_awvalid_vector(m2_awvalid_vector), .m_awready_vector(m2_awready_vector), .m_slave_sel(),
        .m_wdata(m2_wdata_mat), .m_wstrb(m2_wstrb_mat), .m_wlast(m2_wlast_mat), .m_wvalid(m2_wvalid_mat), .m_wready(m2_wready_mat)
    );
    master_ingress #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH)) m2_ar_ingress (
        .clk(clk), .rst_n(rst_n),
        .s_awid(m2_arid), .s_awaddr(m2_araddr), .s_awlen(m2_arlen), .s_awvalid(m2_arvalid), .s_awready(m2_arready),
        .s_wdata('0), .s_wstrb('0), .s_wlast(1'b0), .s_wvalid(1'b0), .s_wready(),
        .m_awvalid_vector(m2_arvalid_vector), .m_awready_vector(m2_arready_vector), .m_slave_sel(),
        .m_wdata(), .m_wstrb(), .m_wlast(), .m_wvalid(), .m_wready(1'b0)
    );

    // Master 3 Ingress Blocks
    master_ingress #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH)) m3_ingress (
        .clk(clk), .rst_n(rst_n),
        .s_awid(m3_awid), .s_awaddr(m3_awaddr), .s_awlen(m3_awlen), .s_awvalid(m3_awvalid), .s_awready(m3_awready),
        .s_wdata(m3_wdata), .s_wstrb(m3_wstrb), .s_wlast(m3_wlast), .s_wvalid(m3_wvalid), .s_wready(m3_wready),
        .m_awvalid_vector(m3_awvalid_vector), .m_awready_vector(m3_awready_vector), .m_slave_sel(),
        .m_wdata(m3_wdata_mat), .m_wstrb(m3_wstrb_mat), .m_wlast(m3_wlast_mat), .m_wvalid(m3_wvalid_mat), .m_wready(m3_wready_mat)
    );
    master_ingress #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH)) m3_ar_ingress (
        .clk(clk), .rst_n(rst_n),
        .s_awid(m3_arid), .s_awaddr(m3_araddr), .s_awlen(m3_arlen), .s_awvalid(m3_arvalid), .s_awready(m3_arready),
        .s_wdata('0), .s_wstrb('0), .s_wlast(1'b0), .s_wvalid(1'b0), .s_wready(),
        .m_awvalid_vector(m3_arvalid_vector), .m_awready_vector(m3_arready_vector), .m_slave_sel(),
        .m_wdata(), .m_wstrb(), .m_wlast(), .m_wvalid(), .m_wready(1'b0)
    );

    // Clean payload assigns
    assign m0_clean_awid = m0_awid; assign m0_clean_awaddr = m0_awaddr; assign m0_clean_awlen = m0_awlen;
    assign m1_clean_awid = m1_awid; assign m1_clean_awaddr = m1_awaddr; assign m1_clean_awlen = m1_awlen;
    assign m2_clean_awid = m2_awid; assign m2_clean_awaddr = m2_awaddr; assign m2_clean_awlen = m2_awlen;
    assign m3_clean_awid = m3_awid; assign m3_clean_awaddr = m3_awaddr; assign m3_clean_awlen = m3_awlen;

    assign m0_clean_arid = m0_arid; assign m0_clean_araddr = m0_araddr; assign m0_clean_arlen = m0_arlen;
    assign m1_clean_arid = m1_arid; assign m1_clean_araddr = m1_araddr; assign m1_clean_arlen = m1_arlen;
    assign m2_clean_arid = m2_arid; assign m2_clean_araddr = m2_araddr; assign m2_clean_arlen = m2_arlen;
    assign m3_clean_arid = m3_arid; assign m3_clean_araddr = m3_araddr; assign m3_clean_arlen = m3_arlen;

    // Route Struct FIFOs
    // Route token layout: [17:16]=slave_id, [15:8]=master_id, [7:0]=burst_len (unused, always 0 here)
    logic [17:0] fifo0_popdata, fifo1_popdata, fifo2_popdata, fifo3_popdata;
    logic        fifo0_full,    fifo1_full,    fifo2_full,    fifo3_full;

    route_info_fifo #(.DEPTH(8)) route_fifo_s0 (.clk(clk), .rst_n(rst_n), .push_data({2'b00, 8'(fifo0_push_id), 8'b0}), .push_en(fifo0_push), .full(fifo0_full), .pop_data(fifo0_popdata), .pop_en(fifo0_pop), .empty(fifo0_empty));
    route_info_fifo #(.DEPTH(8)) route_fifo_s1 (.clk(clk), .rst_n(rst_n), .push_data({2'b01, 8'(fifo1_push_id), 8'b0}), .push_en(fifo1_push), .full(fifo1_full), .pop_data(fifo1_popdata), .pop_en(fifo1_pop), .empty(fifo1_empty));
    route_info_fifo #(.DEPTH(8)) route_fifo_s2 (.clk(clk), .rst_n(rst_n), .push_data({2'b10, 8'(fifo2_push_id), 8'b0}), .push_en(fifo2_push), .full(fifo2_full), .pop_data(fifo2_popdata), .pop_en(fifo2_pop), .empty(fifo2_empty));
    route_info_fifo #(.DEPTH(8)) route_fifo_s3 (.clk(clk), .rst_n(rst_n), .push_data({2'b11, 8'(fifo3_push_id), 8'b0}), .push_en(fifo3_push), .full(fifo3_full), .pop_data(fifo3_popdata), .pop_en(fifo3_pop), .empty(fifo3_empty));

    assign fifo0_master_id = fifo0_popdata[9:8];
    assign fifo1_master_id = fifo1_popdata[9:8];
    assign fifo2_master_id = fifo2_popdata[9:8];
    assign fifo3_master_id = fifo3_popdata[9:8];

    // Slave 0 Egress Allocators
    slave_aw_egress_dwrr #(.ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH), .QUANTUM(16)) s0_aw_gate (
        .clk(clk), .rst_n(rst_n), .s_awvalid_bus({m3_awvalid_vector[0], m2_awvalid_vector[0], m1_awvalid_vector[0], m0_awvalid_vector[0]}), .s_awready_bus(s0_awready_bus),
        .s_awid_m0(m0_clean_awid), .s_awaddr_m0(m0_clean_awaddr), .s_awlen_m0(m0_clean_awlen), .s_awid_m1(m1_clean_awid), .s_awaddr_m1(m1_clean_awaddr), .s_awlen_m1(m1_clean_awlen),
        .s_awid_m2(m2_clean_awid), .s_awaddr_m2(m2_clean_awaddr), .s_awlen_m2(m2_clean_awlen), .s_awid_m3(m3_clean_awid), .s_awaddr_m3(m3_clean_awaddr), .s_awlen_m3(m3_clean_awlen),
        .m_awid(s0_awid), .m_awaddr(s0_awaddr), .m_awlen(s0_awlen), .m_awvalid(s0_awvalid), .m_awready(s0_awready), .fifo_push_en(fifo0_push), .fifo_master_id(fifo0_push_id), .fifo_full(fifo0_full)
    );
    slave_aw_egress_dwrr #(.ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH), .QUANTUM(16)) s0_ar_gate (
        .clk(clk), .rst_n(rst_n), .s_awvalid_bus({m3_arvalid_vector[0], m2_arvalid_vector[0], m1_arvalid_vector[0], m0_arvalid_vector[0]}), .s_awready_bus(s0_arready_bus),
        .s_awid_m0(m0_clean_arid), .s_awaddr_m0(m0_clean_araddr), .s_awlen_m0(m0_clean_arlen), .s_awid_m1(m1_clean_arid), .s_awaddr_m1(m1_clean_araddr), .s_awlen_m1(m1_clean_arlen),
        .s_awid_m2(m2_clean_arid), .s_awaddr_m2(m2_clean_araddr), .s_awlen_m2(m2_clean_arlen), .s_awid_m3(m3_clean_arid), .s_awaddr_m3(m3_clean_araddr), .s_awlen_m3(m3_clean_arlen),
        .m_awid(s0_arid), .m_awaddr(s0_araddr), .m_awlen(s0_arlen), .m_awvalid(s0_arvalid), .m_awready(s0_arready), .fifo_push_en(), .fifo_master_id(), .fifo_full(1'b0) // No route FIFO on AR/default paths
    );
    slave_w_egress #(.DATA_WIDTH(DATA_WIDTH)) s0_w_gate (
        .clk(clk), .rst_n(rst_n), .fifo_empty(fifo0_empty), .fifo_master_id(fifo0_master_id), .fifo_pop_en(fifo0_pop),
        .s_wdata_m0(m0_wdata_mat), .s_wstrb_m0(m0_wstrb_mat), .s_wlast_m0(m0_wlast_mat), .s_wvalid_m0(m0_wvalid_mat),
        .s_wdata_m1(m1_wdata_mat), .s_wstrb_m1(m1_wstrb_mat), .s_wlast_m1(m1_wlast_mat), .s_wvalid_m1(m1_wvalid_mat),
        .s_wdata_m2(m2_wdata_mat), .s_wstrb_m2(m2_wstrb_mat), .s_wlast_m2(m2_wlast_mat), .s_wvalid_m2(m2_wvalid_mat),
        .s_wdata_m3(m3_wdata_mat), .s_wstrb_m3(m3_wstrb_mat), .s_wlast_m3(m3_wlast_mat), .s_wvalid_m3(m3_wvalid_mat),
        .s_wready_bus(s0_wready_bus), .m_wdata(s0_wdata), .m_wstrb(s0_wstrb), .m_wlast(s0_wlast), .m_wvalid(s0_wvalid), .m_wready(s0_wready)
    );

    // Slave 1 Egress Allocators
    slave_aw_egress_dwrr #(.ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH), .QUANTUM(16)) s1_aw_gate (
        .clk(clk), .rst_n(rst_n), .s_awvalid_bus({m3_awvalid_vector[1], m2_awvalid_vector[1], m1_awvalid_vector[1], m0_awvalid_vector[1]}), .s_awready_bus(s1_awready_bus),
        .s_awid_m0(m0_clean_awid), .s_awaddr_m0(m0_clean_awaddr), .s_awlen_m0(m0_clean_awlen), .s_awid_m1(m1_clean_awid), .s_awaddr_m1(m1_clean_awaddr), .s_awlen_m1(m1_clean_awlen),
        .s_awid_m2(m2_clean_awid), .s_awaddr_m2(m2_clean_awaddr), .s_awlen_m2(m2_clean_awlen), .s_awid_m3(m3_clean_awid), .s_awaddr_m3(m3_clean_awaddr), .s_awlen_m3(m3_clean_awlen),
        .m_awid(s1_awid), .m_awaddr(s1_awaddr), .m_awlen(s1_awlen), .m_awvalid(s1_awvalid), .m_awready(s1_awready), .fifo_push_en(fifo1_push), .fifo_master_id(fifo1_push_id), .fifo_full(fifo1_full)
    );
    slave_aw_egress_dwrr #(.ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH), .QUANTUM(16)) s1_ar_gate (
        .clk(clk), .rst_n(rst_n), .s_awvalid_bus({m3_arvalid_vector[1], m2_arvalid_vector[1], m1_arvalid_vector[1], m0_arvalid_vector[1]}), .s_awready_bus(s1_arready_bus),
        .s_awid_m0(m0_clean_arid), .s_awaddr_m0(m0_clean_araddr), .s_awlen_m0(m0_clean_arlen), .s_awid_m1(m1_clean_arid), .s_awaddr_m1(m1_clean_araddr), .s_awlen_m1(m1_clean_arlen),
        .s_awid_m2(m2_clean_arid), .s_awaddr_m2(m2_clean_araddr), .s_awlen_m2(m2_clean_arlen), .s_awid_m3(m3_clean_arid), .s_awaddr_m3(m3_clean_araddr), .s_awlen_m3(m3_clean_arlen),
        .m_awid(s1_arid), .m_awaddr(s1_araddr), .m_awlen(s1_arlen), .m_awvalid(s1_arvalid), .m_awready(s1_arready), .fifo_push_en(), .fifo_master_id(), .fifo_full(1'b0) // No route FIFO on AR/default paths
    );
    slave_w_egress #(.DATA_WIDTH(DATA_WIDTH)) s1_w_gate (
        .clk(clk), .rst_n(rst_n), .fifo_empty(fifo1_empty), .fifo_master_id(fifo1_master_id), .fifo_pop_en(fifo1_pop),
        .s_wdata_m0(m0_wdata_mat), .s_wstrb_m0(m0_wstrb_mat), .s_wlast_m0(m0_wlast_mat), .s_wvalid_m0(m0_wvalid_mat),
        .s_wdata_m1(m1_wdata_mat), .s_wstrb_m1(m1_wstrb_mat), .s_wlast_m1(m1_wlast_mat), .s_wvalid_m1(m1_wvalid_mat),
        .s_wdata_m2(m2_wdata_mat), .s_wstrb_m2(m2_wstrb_mat), .s_wlast_m2(m2_wlast_mat), .s_wvalid_m2(m2_wvalid_mat),
        .s_wdata_m3(m3_wdata_mat), .s_wstrb_m3(m3_wstrb_mat), .s_wlast_m3(m3_wlast_mat), .s_wvalid_m3(m3_wvalid_mat),
        .s_wready_bus(s1_wready_bus), .m_wdata(s1_wdata), .m_wstrb(s1_wstrb), .m_wlast(s1_wlast), .m_wvalid(s1_wvalid), .m_wready(s1_wready)
    );

    // Slave 2 Egress Allocators
    slave_aw_egress_dwrr #(.ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH), .QUANTUM(16)) s2_aw_gate (
        .clk(clk), .rst_n(rst_n), .s_awvalid_bus({m3_awvalid_vector[2], m2_awvalid_vector[2], m1_awvalid_vector[2], m0_awvalid_vector[2]}), .s_awready_bus(s2_awready_bus),
        .s_awid_m0(m0_clean_awid), .s_awaddr_m0(m0_clean_awaddr), .s_awlen_m0(m0_clean_awlen), .s_awid_m1(m1_clean_awid), .s_awaddr_m1(m1_clean_awaddr), .s_awlen_m1(m1_clean_awlen),
        .s_awid_m2(m2_clean_awid), .s_awaddr_m2(m2_clean_awaddr), .s_awlen_m2(m2_clean_awlen), .s_awid_m3(m3_clean_awid), .s_awaddr_m3(m3_clean_awaddr), .s_awlen_m3(m3_clean_awlen),
        .m_awid(s2_awid), .m_awaddr(s2_awaddr), .m_awlen(s2_awlen), .m_awvalid(s2_awvalid), .m_awready(s2_awready), .fifo_push_en(fifo2_push), .fifo_master_id(fifo2_push_id), .fifo_full(fifo2_full)
    );
    slave_aw_egress_dwrr #(.ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH), .QUANTUM(16)) s2_ar_gate (
        .clk(clk), .rst_n(rst_n), .s_awvalid_bus({m3_arvalid_vector[2], m2_arvalid_vector[2], m1_arvalid_vector[2], m0_arvalid_vector[2]}), .s_awready_bus(s2_arready_bus),
        .s_awid_m0(m0_clean_arid), .s_awaddr_m0(m0_clean_araddr), .s_awlen_m0(m0_clean_arlen), .s_awid_m1(m1_clean_arid), .s_awaddr_m1(m1_clean_araddr), .s_awlen_m1(m1_clean_arlen),
        .s_awid_m2(m2_clean_arid), .s_awaddr_m2(m2_clean_araddr), .s_awlen_m2(m2_clean_arlen), .s_awid_m3(m3_clean_arid), .s_awaddr_m3(m3_clean_araddr), .s_awlen_m3(m3_clean_arlen),
        .m_awid(s2_arid), .m_awaddr(s2_araddr), .m_awlen(s2_arlen), .m_awvalid(s2_arvalid), .m_awready(s2_arready), .fifo_push_en(), .fifo_master_id(), .fifo_full(1'b0) // No route FIFO on AR/default paths
    );
    slave_w_egress #(.DATA_WIDTH(DATA_WIDTH)) s2_w_gate (
        .clk(clk), .rst_n(rst_n), .fifo_empty(fifo2_empty), .fifo_master_id(fifo2_master_id), .fifo_pop_en(fifo2_pop),
        .s_wdata_m0(m0_wdata_mat), .s_wstrb_m0(m0_wstrb_mat), .s_wlast_m0(m0_wlast_mat), .s_wvalid_m0(m0_wvalid_mat),
        .s_wdata_m1(m1_wdata_mat), .s_wstrb_m1(m1_wstrb_mat), .s_wlast_m1(m1_wlast_mat), .s_wvalid_m1(m1_wvalid_mat),
        .s_wdata_m2(m2_wdata_mat), .s_wstrb_m2(m2_wstrb_mat), .s_wlast_m2(m2_wlast_mat), .s_wvalid_m2(m2_wvalid_mat),
        .s_wdata_m3(m3_wdata_mat), .s_wstrb_m3(m3_wstrb_mat), .s_wlast_m3(m3_wlast_mat), .s_wvalid_m3(m3_wvalid_mat),
        .s_wready_bus(s2_wready_bus), .m_wdata(s2_wdata), .m_wstrb(s2_wstrb), .m_wlast(s2_wlast), .m_wvalid(s2_wvalid), .m_wready(s2_wready)
    );

    // Slave 3 Egress Allocators
    slave_aw_egress_dwrr #(.ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH), .QUANTUM(16)) s3_aw_gate (
        .clk(clk), .rst_n(rst_n), .s_awvalid_bus({m3_awvalid_vector[3], m2_awvalid_vector[3], m1_awvalid_vector[3], m0_awvalid_vector[3]}), .s_awready_bus(s3_awready_bus),
        .s_awid_m0(m0_clean_awid), .s_awaddr_m0(m0_clean_awaddr), .s_awlen_m0(m0_clean_awlen), .s_awid_m1(m1_clean_awid), .s_awaddr_m1(m1_clean_awaddr), .s_awlen_m1(m1_clean_awlen),
        .s_awid_m2(m2_clean_awid), .s_awaddr_m2(m2_clean_awaddr), .s_awlen_m2(m2_clean_awlen), .s_awid_m3(m3_clean_awid), .s_awaddr_m3(m3_clean_awaddr), .s_awlen_m3(m3_clean_awlen),
        .m_awid(s3_awid), .m_awaddr(s3_awaddr), .m_awlen(s3_awlen), .m_awvalid(s3_awvalid), .m_awready(s3_awready), .fifo_push_en(fifo3_push), .fifo_master_id(fifo3_push_id), .fifo_full(fifo3_full)
    );
    slave_aw_egress_dwrr #(.ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH), .QUANTUM(16)) s3_ar_gate (
        .clk(clk), .rst_n(rst_n), .s_awvalid_bus({m3_arvalid_vector[3], m2_arvalid_vector[3], m1_arvalid_vector[3], m0_arvalid_vector[3]}), .s_awready_bus(s3_arready_bus),
        .s_awid_m0(m0_clean_arid), .s_awaddr_m0(m0_clean_araddr), .s_awlen_m0(m0_clean_arlen), .s_awid_m1(m1_clean_arid), .s_awaddr_m1(m1_clean_araddr), .s_awlen_m1(m1_clean_arlen),
        .s_awid_m2(m2_clean_arid), .s_awaddr_m2(m2_clean_araddr), .s_awlen_m2(m2_clean_arlen), .s_awid_m3(m3_clean_arid), .s_awaddr_m3(m3_clean_araddr), .s_awlen_m3(m3_clean_arlen),
        .m_awid(s3_arid), .m_awaddr(s3_araddr), .m_awlen(s3_arlen), .m_awvalid(s3_arvalid), .m_awready(s3_arready), .fifo_push_en(), .fifo_master_id(), .fifo_full(1'b0) // No route FIFO on AR/default paths
    );
    slave_w_egress #(.DATA_WIDTH(DATA_WIDTH)) s3_w_gate (
        .clk(clk), .rst_n(rst_n), .fifo_empty(fifo3_empty), .fifo_master_id(fifo3_master_id), .fifo_pop_en(fifo3_pop),
        .s_wdata_m0(m0_wdata_mat), .s_wstrb_m0(m0_wstrb_mat), .s_wlast_m0(m0_wlast_mat), .s_wvalid_m0(m0_wvalid_mat),
        .s_wdata_m1(m1_wdata_mat), .s_wstrb_m1(m1_wstrb_mat), .s_wlast_m1(m1_wlast_mat), .s_wvalid_m1(m1_wvalid_mat),
        .s_wdata_m2(m2_wdata_mat), .s_wstrb_m2(m2_wstrb_mat), .s_wlast_m2(m2_wlast_mat), .s_wvalid_m2(m2_wvalid_mat),
        .s_wdata_m3(m3_wdata_mat), .s_wstrb_m3(m3_wstrb_mat), .s_wlast_m3(m3_wlast_mat), .s_wvalid_m3(m3_wvalid_mat),
        .s_wready_bus(s3_wready_bus), .m_wdata(s3_wdata), .m_wstrb(s3_wstrb), .m_wlast(s3_wlast), .m_wvalid(s3_wvalid), .m_wready(s3_wready)
    );

    // Default Slave Catch-All Network
    logic        fifosd_push, fifosd_pop, fifosd_empty, fifosd_full;
    logic [1:0]  fifosd_push_id, fifosd_master_id;
    logic [17:0] fifosd_popdata;

    route_info_fifo #(.DEPTH(8)) route_fifo_sd (.clk(clk), .rst_n(rst_n), .push_data({2'b00, 8'(fifosd_push_id), 8'b0}), .push_en(fifosd_push), .full(fifosd_full), .pop_data(fifosd_popdata), .pop_en(fifosd_pop), .empty(fifosd_empty));
    assign fifosd_master_id = fifosd_popdata[9:8];

    slave_aw_egress_dwrr #(.ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH), .QUANTUM(16)) sd_aw_gate (
        .clk(clk), .rst_n(rst_n), .s_awvalid_bus({m3_awvalid_vector[4], m2_awvalid_vector[4], m1_awvalid_vector[4], m0_awvalid_vector[4]}), .s_awready_bus(sd_awready_bus),
        .s_awid_m0(m0_clean_awid), .s_awaddr_m0(m0_clean_awaddr), .s_awlen_m0(m0_clean_awlen), .s_awid_m1(m1_clean_awid), .s_awaddr_m1(m1_clean_awaddr), .s_awlen_m1(m1_clean_awlen),
        .s_awid_m2(m2_clean_awid), .s_awaddr_m2(m2_clean_awaddr), .s_awlen_m2(m2_clean_awlen), .s_awid_m3(m3_clean_awid), .s_awaddr_m3(m3_clean_awaddr), .s_awlen_m3(m3_clean_awlen),
        .m_awid(sd_awid), .m_awaddr(), .m_awlen(), .m_awvalid(sd_awvalid), .m_awready(sd_awready), .fifo_push_en(fifosd_push), .fifo_master_id(fifosd_push_id), .fifo_full(fifosd_full)
    );
    slave_aw_egress_dwrr #(.ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH), .QUANTUM(16)) sd_ar_gate (
        .clk(clk), .rst_n(rst_n), .s_awvalid_bus({m3_arvalid_vector[4], m2_arvalid_vector[4], m1_arvalid_vector[4], m0_arvalid_vector[4]}), .s_awready_bus(sd_arready_bus),
        .s_awid_m0(m0_clean_arid), .s_awaddr_m0(m0_clean_araddr), .s_awlen_m0(m0_clean_arlen), .s_awid_m1(m1_clean_arid), .s_awaddr_m1(m1_clean_araddr), .s_awlen_m1(m1_clean_arlen),
        .s_awid_m2(m2_clean_arid), .s_awaddr_m2(m2_clean_araddr), .s_awlen_m2(m2_clean_arlen), .s_awid_m3(m3_clean_arid), .s_awaddr_m3(m3_clean_araddr), .s_awlen_m3(m3_clean_arlen),
        .m_awid(sd_arid), .m_awaddr(), .m_awlen(), .m_awvalid(sd_arvalid), .m_awready(sd_arready), .fifo_push_en(), .fifo_master_id(), .fifo_full(1'b0) // AR has no downstream W-mux, no ordering hazard exists here
    );
    slave_w_egress #(.DATA_WIDTH(DATA_WIDTH)) sd_w_gate (
        .clk(clk), .rst_n(rst_n), .fifo_empty(fifosd_empty), .fifo_master_id(fifosd_master_id), .fifo_pop_en(fifosd_pop),
        .s_wdata_m0(m0_wdata_mat), .s_wstrb_m0(m0_wstrb_mat), .s_wlast_m0(m0_wlast_mat), .s_wvalid_m0(m0_wvalid_mat),
        .s_wdata_m1(m1_wdata_mat), .s_wstrb_m1(m1_wstrb_mat), .s_wlast_m1(m1_wlast_mat), .s_wvalid_m1(m1_wvalid_mat),
        .s_wdata_m2(m2_wdata_mat), .s_wstrb_m2(m2_wstrb_mat), .s_wlast_m2(m2_wlast_mat), .s_wvalid_m2(m2_wvalid_mat),
        .s_wdata_m3(m3_wdata_mat), .s_wstrb_m3(m3_wstrb_mat), .s_wlast_m3(m3_wlast_mat), .s_wvalid_m3(m3_wvalid_mat),
        .s_wready_bus(sd_wready_bus), .m_wdata(), .m_wstrb(), .m_wlast(sd_wlast), .m_wvalid(sd_wvalid), .m_wready(sd_wready)
    );
    default_slave #(.DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH+2)) d_slave_sink (
        .clk(clk), .rst_n(rst_n), .awid(sd_awid), .awvalid(sd_awvalid), .awready(sd_awready), .wlast(sd_wlast), .wvalid(sd_wvalid), .wready(sd_wready),
        .bid(sd_bid), .bresp(sd_bresp), .bvalid(sd_bvalid), .bready(sd_bready), .arid(sd_arid), .arvalid(sd_arvalid), .arready(sd_arready),
        .rid(sd_rid), .rdata(sd_rdata), .rresp(sd_rresp), .rlast(sd_rlast), .rvalid(sd_rvalid), .rready(sd_rready)
    );

    // Master 0 Return Demux
    master_b_egress #(.ID_WIDTH(ID_WIDTH), .MASTER_INDEX(2'b00)) m0_b_return (
        .clk(clk), .rst_n(rst_n),
        .s_bid_s0(s0_bid), .s_bresp_s0(s0_bresp), .s_bvalid_s0(s0_bvalid), .s_bid_s1(s1_bid), .s_bresp_s1(s1_bresp), .s_bvalid_s1(s1_bvalid),
        .s_bid_s2(s2_bid), .s_bresp_s2(s2_bresp), .s_bvalid_s2(s2_bvalid), .s_bid_s3(s3_bid), .s_bresp_s3(s3_bresp), .s_bvalid_s3(s3_bvalid),
        .s_bid_s4(sd_bid), .s_bresp_s4(sd_bresp), .s_bvalid_s4(sd_bvalid),
        .s_bready_bus(m0_s_bready_bus), .m_bid(m0_bid), .m_bresp(m0_bresp), .m_bvalid(m0_bvalid), .m_bready(m0_bready)
    );
    master_r_egress #(.DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH), .MASTER_INDEX(2'b00)) m0_r_return (
        .clk(clk), .rst_n(rst_n),
        .s_rid_s0(s0_rid), .s_rdata_s0(s0_rdata), .s_rresp_s0(s0_rresp), .s_rlast_s0(s0_rlast), .s_rvalid_s0(s0_rvalid),
        .s_rid_s1(s1_rid), .s_rdata_s1(s1_rdata), .s_rresp_s1(s1_rresp), .s_rlast_s1(s1_rlast), .s_rvalid_s1(s1_rvalid),
        .s_rid_s2(s2_rid), .s_rdata_s2(s2_rdata), .s_rresp_s2(s2_rresp), .s_rlast_s2(s2_rlast), .s_rvalid_s2(s2_rvalid),
        .s_rid_s3(s3_rid), .s_rdata_s3(s3_rdata), .s_rresp_s3(s3_rresp), .s_rlast_s3(s3_rlast), .s_rvalid_s3(s3_rvalid),
        .s_rid_s4(sd_rid), .s_rdata_s4(sd_rdata), .s_rresp_s4(sd_rresp), .s_rlast_s4(sd_rlast), .s_rvalid_s4(sd_rvalid),
        .s_rready_bus(m0_s_rready_bus), .m_rid(m0_rid), .m_rdata(m0_rdata), .m_rresp(m0_rresp), .m_rlast(m0_rlast), .m_rvalid(m0_rvalid), .m_rready(m0_rready)
    );

    // Master 1 Return Demux
    master_b_egress #(.ID_WIDTH(ID_WIDTH), .MASTER_INDEX(2'b01)) m1_b_return (
        .clk(clk), .rst_n(rst_n),
        .s_bid_s0(s0_bid), .s_bresp_s0(s0_bresp), .s_bvalid_s0(s0_bvalid), .s_bid_s1(s1_bid), .s_bresp_s1(s1_bresp), .s_bvalid_s1(s1_bvalid),
        .s_bid_s2(s2_bid), .s_bresp_s2(s2_bresp), .s_bvalid_s2(s2_bvalid), .s_bid_s3(s3_bid), .s_bresp_s3(s3_bresp), .s_bvalid_s3(s3_bvalid),
        .s_bid_s4(sd_bid), .s_bresp_s4(sd_bresp), .s_bvalid_s4(sd_bvalid),
        .s_bready_bus(m1_s_bready_bus), .m_bid(m1_bid), .m_bresp(m1_bresp), .m_bvalid(m1_bvalid), .m_bready(m1_bready)
    );
    master_r_egress #(.DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH), .MASTER_INDEX(2'b01)) m1_r_return (
        .clk(clk), .rst_n(rst_n),
        .s_rid_s0(s0_rid), .s_rdata_s0(s0_rdata), .s_rresp_s0(s0_rresp), .s_rlast_s0(s0_rlast), .s_rvalid_s0(s0_rvalid),
        .s_rid_s1(s1_rid), .s_rdata_s1(s1_rdata), .s_rresp_s1(s1_rresp), .s_rlast_s1(s1_rlast), .s_rvalid_s1(s1_rvalid),
        .s_rid_s2(s2_rid), .s_rdata_s2(s2_rdata), .s_rresp_s2(s2_rresp), .s_rlast_s2(s2_rlast), .s_rvalid_s2(s2_rvalid),
        .s_rid_s3(s3_rid), .s_rdata_s3(s3_rdata), .s_rresp_s3(s3_rresp), .s_rlast_s3(s3_rlast), .s_rvalid_s3(s3_rvalid),
        .s_rid_s4(sd_rid), .s_rdata_s4(sd_rdata), .s_rresp_s4(sd_rresp), .s_rlast_s4(sd_rlast), .s_rvalid_s4(sd_rvalid),
        .s_rready_bus(m1_s_rready_bus), .m_rid(m1_rid), .m_rdata(m1_rdata), .m_rresp(m1_rresp), .m_rlast(m1_rlast), .m_rvalid(m1_rvalid), .m_rready(m1_rready)
    );

    // Master 2 Return Demux
    master_b_egress #(.ID_WIDTH(ID_WIDTH), .MASTER_INDEX(2'b10)) m2_b_return (
        .clk(clk), .rst_n(rst_n),
        .s_bid_s0(s0_bid), .s_bresp_s0(s0_bresp), .s_bvalid_s0(s0_bvalid), .s_bid_s1(s1_bid), .s_bresp_s1(s1_bresp), .s_bvalid_s1(s1_bvalid),
        .s_bid_s2(s2_bid), .s_bresp_s2(s2_bresp), .s_bvalid_s2(s2_bvalid), .s_bid_s3(s3_bid), .s_bresp_s3(s3_bresp), .s_bvalid_s3(s3_bvalid),
        .s_bid_s4(sd_bid), .s_bresp_s4(sd_bresp), .s_bvalid_s4(sd_bvalid),
        .s_bready_bus(m2_s_bready_bus), .m_bid(m2_bid), .m_bresp(m2_bresp), .m_bvalid(m2_bvalid), .m_bready(m2_bready)
    );
    master_r_egress #(.DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH), .MASTER_INDEX(2'b10)) m2_r_return (
        .clk(clk), .rst_n(rst_n),
        .s_rid_s0(s0_rid), .s_rdata_s0(s0_rdata), .s_rresp_s0(s0_rresp), .s_rlast_s0(s0_rlast), .s_rvalid_s0(s0_rvalid),
        .s_rid_s1(s1_rid), .s_rdata_s1(s1_rdata), .s_rresp_s1(s1_rresp), .s_rlast_s1(s1_rlast), .s_rvalid_s1(s1_rvalid),
        .s_rid_s2(s2_rid), .s_rdata_s2(s2_rdata), .s_rresp_s2(s2_rresp), .s_rlast_s2(s2_rlast), .s_rvalid_s2(s2_rvalid),
        .s_rid_s3(s3_rid), .s_rdata_s3(s3_rdata), .s_rresp_s3(s3_rresp), .s_rlast_s3(s3_rlast), .s_rvalid_s3(s3_rvalid),
        .s_rid_s4(sd_rid), .s_rdata_s4(sd_rdata), .s_rresp_s4(sd_rresp), .s_rlast_s4(sd_rlast), .s_rvalid_s4(sd_rvalid),
        .s_rready_bus(m2_s_rready_bus), .m_rid(m2_rid), .m_rdata(m2_rdata), .m_rresp(m2_rresp), .m_rlast(m2_rlast), .m_rvalid(m2_rvalid), .m_rready(m2_rready)
    );

    // Master 3 Return Demux
    master_b_egress #(.ID_WIDTH(ID_WIDTH), .MASTER_INDEX(2'b11)) m3_b_return (
        .clk(clk), .rst_n(rst_n),
        .s_bid_s0(s0_bid), .s_bresp_s0(s0_bresp), .s_bvalid_s0(s0_bvalid), .s_bid_s1(s1_bid), .s_bresp_s1(s1_bresp), .s_bvalid_s1(s1_bvalid),
        .s_bid_s2(s2_bid), .s_bresp_s2(s2_bresp), .s_bvalid_s2(s2_bvalid), .s_bid_s3(s3_bid), .s_bresp_s3(s3_bresp), .s_bvalid_s3(s3_bvalid),
        .s_bid_s4(sd_bid), .s_bresp_s4(sd_bresp), .s_bvalid_s4(sd_bvalid),
        .s_bready_bus(m3_s_bready_bus), .m_bid(m3_bid), .m_bresp(m3_bresp), .m_bvalid(m3_bvalid), .m_bready(m3_bready)
    );
    master_r_egress #(.DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH), .MASTER_INDEX(2'b11)) m3_r_return (
        .clk(clk), .rst_n(rst_n),
        .s_rid_s0(s0_rid), .s_rdata_s0(s0_rdata), .s_rresp_s0(s0_rresp), .s_rlast_s0(s0_rlast), .s_rvalid_s0(s0_rvalid),
        .s_rid_s1(s1_rid), .s_rdata_s1(s1_rdata), .s_rresp_s1(s1_rresp), .s_rlast_s1(s1_rlast), .s_rvalid_s1(s1_rvalid),
        .s_rid_s2(s2_rid), .s_rdata_s2(s2_rdata), .s_rresp_s2(s2_rresp), .s_rlast_s2(s2_rlast), .s_rvalid_s2(s2_rvalid),
        .s_rid_s3(s3_rid), .s_rdata_s3(s3_rdata), .s_rresp_s3(s3_rresp), .s_rlast_s3(s3_rlast), .s_rvalid_s3(s3_rvalid),
        .s_rid_s4(sd_rid), .s_rdata_s4(sd_rdata), .s_rresp_s4(sd_rresp), .s_rlast_s4(sd_rlast), .s_rvalid_s4(sd_rvalid),
        .s_rready_bus(m3_s_rready_bus), .m_rid(m3_rid), .m_rdata(m3_rdata), .m_rresp(m3_rresp), .m_rlast(m3_rlast), .m_rvalid(m3_rvalid), .m_rready(m3_rready)
    );

endmodule