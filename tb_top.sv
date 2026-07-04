`timescale 1ns / 1ps

// 1. THE AXI4 INTERFACE (NOW WITH SVA PROTOCOL CHECKERS)
interface axi4_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 8
)(
    input logic clk,
    input logic rst_n
);
    // AW Channel
    logic [ID_WIDTH-1:0]   AWID;
    logic [ADDR_WIDTH-1:0] AWADDR;
    logic [7:0]            AWLEN;
    logic                  AWVALID;
    logic                  AWREADY;

    // W Channel
    logic [DATA_WIDTH-1:0]   WDATA;
    logic [DATA_WIDTH/8-1:0] WSTRB;
    logic                    WLAST;
    logic                    WVALID;
    logic                    WREADY;

    // B Channel
    logic [ID_WIDTH-1:0] BID;
    logic [1:0]          BRESP;
    logic                BVALID;
    logic                BREADY;

    // AR Channel
    logic [ID_WIDTH-1:0]   ARID;
    logic [ADDR_WIDTH-1:0] ARADDR;
    logic [7:0]            ARLEN;
    logic                  ARVALID;
    logic                  ARREADY;

    // R Channel
    logic [ID_WIDTH-1:0]   RID;
    logic [DATA_WIDTH-1:0] RDATA;
    logic [1:0]            RRESP;
    logic                  RLAST;
    logic                  RVALID;
    logic                  RREADY;

    // SYSTEMVERILOG ASSERTIONS (SVA): STRICT PROTOCOL COMPLIANCE CHECKING
    property p_valid_hold(valid, ready);
        @(posedge clk) disable iff(!rst_n)
        valid && !ready |=> valid;
    endproperty

    assert property(p_valid_hold(AWVALID, AWREADY)) else $error("SVA FAIL: AWVALID dropped before AWREADY!");
    assert property(p_valid_hold(WVALID, WREADY))   else $error("SVA FAIL: WVALID dropped before WREADY!");
    assert property(p_valid_hold(BVALID, BREADY))   else $error("SVA FAIL: BVALID dropped before BREADY!");
    assert property(p_valid_hold(ARVALID, ARREADY)) else $error("SVA FAIL: ARVALID dropped before ARREADY!");
    assert property(p_valid_hold(RVALID, RREADY))   else $error("SVA FAIL: RVALID dropped before RREADY!");

endinterface

// 2. TRANSACTION CLASS
class axi4_transaction;
    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit [7:0]  id;
    rand bit        is_write; 
    
    bit [1:0]  bresp;
    bit [1:0]  rresp;
    bit [31:0] rdata;
    int        master_id; // Tagged by monitor for coverage

    // Constrain to valid slave memory quadrants (0x0..., 0x1..., 0x2..., 0x3...)
    constraint c_addr { addr[31:28] inside {4'h0, 4'h1, 4'h2, 4'h3}; }
    
    function void display(input string name);
        $display("[%0t] %s: %s ID:%0h ADDR:%0h DATA:%0h", $time, name, (is_write ? "WRITE" : "READ"), id, addr, data);
    endfunction
endclass

// 3. GENERATOR CLASS
class axi4_generator;
    mailbox #(axi4_transaction) gen2drv;
    int num_transactions;

    function new(mailbox #(axi4_transaction) g2d);
        gen2drv = g2d;
    endfunction

    task run();
        for(int i = 0; i < num_transactions; i++) begin
            axi4_transaction tx = new();
            if(!tx.randomize()) $fatal(1, "Gen: Randomization failed!");
            gen2drv.put(tx);
        end
    endtask
endclass

// 4. MASTER DRIVER CLASS
class axi4_master_driver;
    virtual axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(32), .ID_WIDTH(8)) vif;
    mailbox #(axi4_transaction) gen2drv;
    int port_id;

    function new(input int id, mailbox #(axi4_transaction) g2d);
        port_id = id;
        gen2drv = g2d;
    endfunction

    task reset_bus();
        vif.AWVALID <= 0; vif.WVALID <= 0; vif.BREADY <= 0;
        vif.ARVALID <= 0; vif.RREADY <= 0;
        vif.AWID <= '0; vif.AWADDR <= '0; vif.AWLEN <= '0;
        vif.WDATA <= '0; vif.WSTRB <= '0; vif.WLAST <= 0;
        vif.ARID <= '0; vif.ARADDR <= '0; vif.ARLEN <= '0;
    endtask

    task run();
        axi4_transaction tx;
        forever begin
            gen2drv.get(tx);
            if(tx.is_write) drive_write(tx);
            else drive_read(tx);
        end
    endtask

    task drive_write(axi4_transaction tx);
        @(posedge vif.clk);
        vif.AWID <= tx.id; vif.AWADDR <= tx.addr; vif.AWLEN <= 8'd0;
        vif.AWVALID <= 1;
        do @(posedge vif.clk); while(!vif.AWREADY);
        vif.AWVALID <= 0;

        vif.WDATA <= tx.data; vif.WSTRB <= 4'hF; vif.WLAST <= 1;
        vif.WVALID <= 1;
        do @(posedge vif.clk); while(!vif.WREADY);
        vif.WVALID <= 0;

        vif.BREADY <= 1;
        do @(posedge vif.clk); while(!vif.BVALID);
        vif.BREADY <= 0;
    endtask

    task drive_read(axi4_transaction tx);
        @(posedge vif.clk);
        vif.ARID <= tx.id; vif.ARADDR <= tx.addr; vif.ARLEN <= 8'd0;
        vif.ARVALID <= 1;
        do @(posedge vif.clk); while(!vif.ARREADY);
        vif.ARVALID <= 0;

        vif.RREADY <= 1;
        do @(posedge vif.clk); while(!(vif.RVALID && vif.RLAST));
        vif.RREADY <= 0;
    endtask
endclass

// 5. SLAVE RESPONDER
class axi4_slave_responder;
    virtual axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(32), .ID_WIDTH(10)) vif;
    int port_id;
    bit [31:0] mem [int]; 

    function new(input int id);
        port_id = id;
    endfunction

    task reset_bus();
        vif.AWREADY <= 0; vif.WREADY <= 0; vif.BVALID <= 0;
        vif.ARREADY <= 0; vif.RVALID <= 0;
        vif.BID <= '0; vif.BRESP <= '0;
        vif.RID <= '0; vif.RDATA <= '0; vif.RRESP <= '0; vif.RLAST <= 0;
    endtask

    task run();
        fork
            handle_writes();
            handle_reads();
        join
    endtask

    task handle_writes();
        bit [9:0] cur_id;
        bit [31:0] cur_addr;
        forever begin
            vif.AWREADY <= 0; vif.WREADY  <= 0; vif.BVALID  <= 0;
            
            @(posedge vif.clk);
            vif.AWREADY <= 1;
            do @(posedge vif.clk); while(!vif.AWVALID);
            cur_id = vif.AWID; cur_addr = vif.AWADDR; 
            vif.AWREADY <= 0;

            vif.WREADY <= 1;
            do @(posedge vif.clk); while(!(vif.WVALID && vif.WLAST)); 
            mem[cur_addr] = vif.WDATA; 
            vif.WREADY <= 0;

            vif.BID <= cur_id; vif.BRESP <= 2'b00; 
            vif.BVALID <= 1;
            do @(posedge vif.clk); while(!vif.BREADY);
            vif.BVALID <= 0;
        end
    endtask

    task handle_reads();
        bit [9:0] cur_id;
        bit [31:0] cur_addr;
        forever begin
            vif.ARREADY <= 0; vif.RVALID  <= 0;
            
            @(posedge vif.clk);
            vif.ARREADY <= 1;
            do @(posedge vif.clk); while(!vif.ARVALID);
            cur_id = vif.ARID; cur_addr = vif.ARADDR; 
            vif.ARREADY <= 0;

            vif.RID <= cur_id; 
            vif.RDATA <= mem.exists(cur_addr) ? mem[cur_addr] : 32'hDEADBEEF; 
            vif.RRESP <= 2'b00; vif.RLAST <= 1; 
            vif.RVALID <= 1;
            do @(posedge vif.clk); while(!vif.RREADY); 
            vif.RVALID <= 0;
        end
    endtask
endclass

// 6. MONITOR (CAPTURES COMPLETE RESPONSES)
class axi4_monitor;
    virtual axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(32), .ID_WIDTH(8)) vif;
    mailbox #(axi4_transaction) mon2scb;
    int port_id;

    function new(input int id, mailbox #(axi4_transaction) m2s);
        port_id = id;
        mon2scb = m2s;
    endfunction

    task run();
        fork
            monitor_writes();
            monitor_reads();
        join
    endtask
    
    task monitor_writes();
        axi4_transaction tx;
        forever begin
            @(posedge vif.clk);
            if(vif.AWVALID && vif.AWREADY) begin
                tx = new(); 
                tx.is_write = 1; tx.addr = vif.AWADDR; tx.id = vif.AWID; tx.master_id = port_id;
                
                do @(posedge vif.clk); while(!(vif.WVALID && vif.WREADY && vif.WLAST)); 
                tx.data = vif.WDATA;
                
                do @(posedge vif.clk); while(!(vif.BVALID && vif.BREADY)); 
                tx.bresp = vif.BRESP;
                mon2scb.put(tx);
            end
        end
    endtask

    task monitor_reads();
        axi4_transaction tx;
        forever begin
            @(posedge vif.clk);
            if(vif.ARVALID && vif.ARREADY) begin
                tx = new(); 
                tx.is_write = 0; tx.addr = vif.ARADDR; tx.id = vif.ARID; tx.master_id = port_id;
                
                do @(posedge vif.clk); while(!(vif.RVALID && vif.RREADY && vif.RLAST)); 
                tx.rdata = vif.RDATA;
                tx.rresp = vif.RRESP;
                mon2scb.put(tx);
            end
        end
    endtask
endclass

// 7. ROBUST SCOREBOARD & FUNCTIONAL COVERAGE
class axi4_scoreboard;
    mailbox #(axi4_transaction) m_mon2scb[4]; 
    
    // Golden Memory Model
    bit [31:0] expected_mem [int];

    // Tracking Metrics
    int writes_passed = 0;
    int writes_failed = 0;
    int reads_passed  = 0;
    int reads_failed  = 0;

    // Functional Coverage Group
    int cov_m_id, cov_s_id;
    bit cov_is_write;
    
    covergroup cg_crossbar_routes;
        cp_master: coverpoint cov_m_id { bins m[] = {[0:3]}; }
        cp_slave:  coverpoint cov_s_id { bins s[] = {[0:3]}; }
        cp_dir:    coverpoint cov_is_write;
        cx_matrix: cross cp_master, cp_slave, cp_dir; // Ensures all 32 routing paths are tested
    endgroup

    function new(mailbox #(axi4_transaction) m2s[4]);
        m_mon2scb = m2s;
        cg_crossbar_routes = new();
    endfunction

    task run();
        for(int i=0; i<4; i++) begin
            automatic int idx = i;
            fork
                forever begin
                    axi4_transaction tx;
                    m_mon2scb[idx].get(tx);
                    
                    // Sample Coverage
                    cov_m_id = tx.master_id;
                    cov_s_id = tx.addr[31:28]; // Slave identified by top 4 bits of address
                    cov_is_write = tx.is_write;
                    cg_crossbar_routes.sample();

                    // Evaluate Data Integrity
                    if(tx.is_write) begin
                        if(tx.bresp == 2'b00) begin
                            writes_passed++;
                            expected_mem[tx.addr] = tx.data; // Update Golden Model
                        end else begin
                            writes_failed++;
                            $error("SCB: Write Failed! Master %0d, Addr %0h got bad BRESP", idx, tx.addr);
                        end
                    end else begin
                        bit [31:0] exp_data = expected_mem.exists(tx.addr) ? expected_mem[tx.addr] : 32'hDEADBEEF;
                        if(tx.rresp == 2'b00 && tx.rdata == exp_data) begin
                            reads_passed++;
                        end else begin
                            reads_failed++;
                            $error("SCB: Read Data Mismatch! Master %0d, Addr %0h | Expected: %0h, Actual: %0h", idx, tx.addr, exp_data, tx.rdata);
                        end
                    end
                end
            join_none
        end
    endtask

    function void print_report();
        $display("\n=======================================================");
        $display("                 SCOREBOARD FINAL REPORT               ");
        $display("=======================================================");
        $display(" WRITES PASSED : %0d", writes_passed);
        $display(" WRITES FAILED : %0d", writes_failed);
        $display(" READS PASSED  : %0d", reads_passed);
        $display(" READS FAILED  : %0d", reads_failed);
        $display("-------------------------------------------------------");
        if(writes_failed == 0 && reads_failed == 0)
            $display(" STATUS: [ SUCCESS ] All Transactions Verified!");
        else
            $display(" STATUS: [ FAILED ] Mismatches Detected in Matrix.");
        $display(" FUNCTIONAL COVERAGE: %0.2f%%", cg_crossbar_routes.get_inst_coverage());
        $display("=======================================================\n");
    endfunction
endclass

// 8. ENVIRONMENT
class axi4_environment;
    axi4_generator       gen[4];
    axi4_master_driver   drv[4];
    axi4_monitor         mon[4];
    axi4_slave_responder rsp[4];
    axi4_scoreboard      scb;

    mailbox #(axi4_transaction) gen2drv[4];
    mailbox #(axi4_transaction) mon2scb[4];

    function new();
        for(int i=0; i<4; i++) begin
            gen2drv[i] = new();
            mon2scb[i] = new();
            gen[i] = new(gen2drv[i]);
            drv[i] = new(i, gen2drv[i]);
            mon[i] = new(i, mon2scb[i]);
            rsp[i] = new(i);
        end
        scb = new(mon2scb);
    endfunction

    task reset_system();
        for(int i=0; i<4; i++) begin
            drv[i].reset_bus();
            rsp[i].reset_bus();
        end
    endtask

    task start_threads();
        for(int i=0; i<4; i++) begin
            fork
                automatic int idx = i;
                gen[idx].run();
                drv[idx].run();
                mon[idx].run();
                rsp[idx].run();
            join_none
        end
        fork scb.run(); join_none
    endtask
endclass

// 9. TEST CLASS (WITH WATCHDOG)
class axi4_test;
    axi4_environment env;

    function new();
        env = new();
    endfunction

    task run(input int num_tx);
        for(int i=0; i<4; i++) env.gen[i].num_transactions = num_tx;
        env.start_threads();
        
        fork
            begin
                // Wait for Scoreboard to see ALL expected transactions
                wait((env.scb.writes_passed + env.scb.writes_failed + 
                      env.scb.reads_passed + env.scb.reads_failed) == (num_tx * 4));
            end
            begin
                #10000;
                $display("\n[FATAL] TIMEOUT! DEADLOCK DETECTED.");
                env.scb.print_report();
                $finish;
            end
        join_any

        #100; 
        env.scb.print_report();
    endtask
endclass

// 10. TOP LEVEL TB MODULE
module tb_top;
    localparam int ADDR_WIDTH = 32;
    localparam int DATA_WIDTH = 32;
    localparam int ID_WIDTH   = 8;
    localparam int SLAVE_ID_W = ID_WIDTH + 2; 

    logic clk, rst_n;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    axi4_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH)) m_if[4] (clk, rst_n);
    axi4_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(SLAVE_ID_W)) s_if[4] (clk, rst_n);

    axi4_crossbar_top #(
        .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .m0_awid(m_if[0].AWID), .m0_awaddr(m_if[0].AWADDR), .m0_awlen(m_if[0].AWLEN), .m0_awvalid(m_if[0].AWVALID), .m0_awready(m_if[0].AWREADY),
        .m0_wdata(m_if[0].WDATA), .m0_wstrb(m_if[0].WSTRB), .m0_wlast(m_if[0].WLAST), .m0_wvalid(m_if[0].WVALID), .m0_wready(m_if[0].WREADY),
        .m0_bid(m_if[0].BID), .m0_bresp(m_if[0].BRESP), .m0_bvalid(m_if[0].BVALID), .m0_bready(m_if[0].BREADY),
        .m0_arid(m_if[0].ARID), .m0_araddr(m_if[0].ARADDR), .m0_arlen(m_if[0].ARLEN), .m0_arvalid(m_if[0].ARVALID), .m0_arready(m_if[0].ARREADY),
        .m0_rid(m_if[0].RID), .m0_rdata(m_if[0].RDATA), .m0_rresp(m_if[0].RRESP), .m0_rlast(m_if[0].RLAST), .m0_rvalid(m_if[0].RVALID), .m0_rready(m_if[0].RREADY),

        .m1_awid(m_if[1].AWID), .m1_awaddr(m_if[1].AWADDR), .m1_awlen(m_if[1].AWLEN), .m1_awvalid(m_if[1].AWVALID), .m1_awready(m_if[1].AWREADY),
        .m1_wdata(m_if[1].WDATA), .m1_wstrb(m_if[1].WSTRB), .m1_wlast(m_if[1].WLAST), .m1_wvalid(m_if[1].WVALID), .m1_wready(m_if[1].WREADY),
        .m1_bid(m_if[1].BID), .m1_bresp(m_if[1].BRESP), .m1_bvalid(m_if[1].BVALID), .m1_bready(m_if[1].BREADY),
        .m1_arid(m_if[1].ARID), .m1_araddr(m_if[1].ARADDR), .m1_arlen(m_if[1].ARLEN), .m1_arvalid(m_if[1].ARVALID), .m1_arready(m_if[1].ARREADY),
        .m1_rid(m_if[1].RID), .m1_rdata(m_if[1].RDATA), .m1_rresp(m_if[1].RRESP), .m1_rlast(m_if[1].RLAST), .m1_rvalid(m_if[1].RVALID), .m1_rready(m_if[1].RREADY),

        .m2_awid(m_if[2].AWID), .m2_awaddr(m_if[2].AWADDR), .m2_awlen(m_if[2].AWLEN), .m2_awvalid(m_if[2].AWVALID), .m2_awready(m_if[2].AWREADY),
        .m2_wdata(m_if[2].WDATA), .m2_wstrb(m_if[2].WSTRB), .m2_wlast(m_if[2].WLAST), .m2_wvalid(m_if[2].WVALID), .m2_wready(m_if[2].WREADY),
        .m2_bid(m_if[2].BID), .m2_bresp(m_if[2].BRESP), .m2_bvalid(m_if[2].BVALID), .m2_bready(m_if[2].BREADY),
        .m2_arid(m_if[2].ARID), .m2_araddr(m_if[2].ARADDR), .m2_arlen(m_if[2].ARLEN), .m2_arvalid(m_if[2].ARVALID), .m2_arready(m_if[2].ARREADY),
        .m2_rid(m_if[2].RID), .m2_rdata(m_if[2].RDATA), .m2_rresp(m_if[2].RRESP), .m2_rlast(m_if[2].RLAST), .m2_rvalid(m_if[2].RVALID), .m2_rready(m_if[2].RREADY),

        .m3_awid(m_if[3].AWID), .m3_awaddr(m_if[3].AWADDR), .m3_awlen(m_if[3].AWLEN), .m3_awvalid(m_if[3].AWVALID), .m3_awready(m_if[3].AWREADY),
        .m3_wdata(m_if[3].WDATA), .m3_wstrb(m_if[3].WSTRB), .m3_wlast(m_if[3].WLAST), .m3_wvalid(m_if[3].WVALID), .m3_wready(m_if[3].WREADY),
        .m3_bid(m_if[3].BID), .m3_bresp(m_if[3].BRESP), .m3_bvalid(m_if[3].BVALID), .m3_bready(m_if[3].BREADY),
        .m3_arid(m_if[3].ARID), .m3_araddr(m_if[3].ARADDR), .m3_arlen(m_if[3].ARLEN), .m3_arvalid(m_if[3].ARVALID), .m3_arready(m_if[3].ARREADY),
        .m3_rid(m_if[3].RID), .m3_rdata(m_if[3].RDATA), .m3_rresp(m_if[3].RRESP), .m3_rlast(m_if[3].RLAST), .m3_rvalid(m_if[3].RVALID), .m3_rready(m_if[3].RREADY),

        .s0_awid(s_if[0].AWID), .s0_awaddr(s_if[0].AWADDR), .s0_awlen(s_if[0].AWLEN), .s0_awvalid(s_if[0].AWVALID), .s0_awready(s_if[0].AWREADY),
        .s0_wdata(s_if[0].WDATA), .s0_wstrb(s_if[0].WSTRB), .s0_wlast(s_if[0].WLAST), .s0_wvalid(s_if[0].WVALID), .s0_wready(s_if[0].WREADY),
        .s0_bid(s_if[0].BID), .s0_bresp(s_if[0].BRESP), .s0_bvalid(s_if[0].BVALID), .s0_bready(s_if[0].BREADY),
        .s0_arid(s_if[0].ARID), .s0_araddr(s_if[0].ARADDR), .s0_arlen(s_if[0].ARLEN), .s0_arvalid(s_if[0].ARVALID), .s0_arready(s_if[0].ARREADY),
        .s0_rid(s_if[0].RID), .s0_rdata(s_if[0].RDATA), .s0_rresp(s_if[0].RRESP), .s0_rlast(s_if[0].RLAST), .s0_rvalid(s_if[0].RVALID), .s0_rready(s_if[0].RREADY),

        .s1_awid(s_if[1].AWID), .s1_awaddr(s_if[1].AWADDR), .s1_awlen(s_if[1].AWLEN), .s1_awvalid(s_if[1].AWVALID), .s1_awready(s_if[1].AWREADY),
        .s1_wdata(s_if[1].WDATA), .s1_wstrb(s_if[1].WSTRB), .s1_wlast(s_if[1].WLAST), .s1_wvalid(s_if[1].WVALID), .s1_wready(s_if[1].WREADY),
        .s1_bid(s_if[1].BID), .s1_bresp(s_if[1].BRESP), .s1_bvalid(s_if[1].BVALID), .s1_bready(s_if[1].BREADY),
        .s1_arid(s_if[1].ARID), .s1_araddr(s_if[1].ARADDR), .s1_arlen(s_if[1].ARLEN), .s1_arvalid(s_if[1].ARVALID), .s1_arready(s_if[1].ARREADY),
        .s1_rid(s_if[1].RID), .s1_rdata(s_if[1].RDATA), .s1_rresp(s_if[1].RRESP), .s1_rlast(s_if[1].RLAST), .s1_rvalid(s_if[1].RVALID), .s1_rready(s_if[1].RREADY),

        .s2_awid(s_if[2].AWID), .s2_awaddr(s_if[2].AWADDR), .s2_awlen(s_if[2].AWLEN), .s2_awvalid(s_if[2].AWVALID), .s2_awready(s_if[2].AWREADY),
        .s2_wdata(s_if[2].WDATA), .s2_wstrb(s_if[2].WSTRB), .s2_wlast(s_if[2].WLAST), .s2_wvalid(s_if[2].WVALID), .s2_wready(s_if[2].WREADY),
        .s2_bid(s_if[2].BID), .s2_bresp(s_if[2].BRESP), .s2_bvalid(s_if[2].BVALID), .s2_bready(s_if[2].BREADY),
        .s2_arid(s_if[2].ARID), .s2_araddr(s_if[2].ARADDR), .s2_arlen(s_if[2].ARLEN), .s2_arvalid(s_if[2].ARVALID), .s2_arready(s_if[2].ARREADY),
        .s2_rid(s_if[2].RID), .s2_rdata(s_if[2].RDATA), .s2_rresp(s_if[2].RRESP), .s2_rlast(s_if[2].RLAST), .s2_rvalid(s_if[2].RVALID), .s2_rready(s_if[2].RREADY),

        .s3_awid(s_if[3].AWID), .s3_awaddr(s_if[3].AWADDR), .s3_awlen(s_if[3].AWLEN), .s3_awvalid(s_if[3].AWVALID), .s3_awready(s_if[3].AWREADY),
        .s3_wdata(s_if[3].WDATA), .s3_wstrb(s_if[3].WSTRB), .s3_wlast(s_if[3].WLAST), .s3_wvalid(s_if[3].WVALID), .s3_wready(s_if[3].WREADY),
        .s3_bid(s_if[3].BID), .s3_bresp(s_if[3].BRESP), .s3_bvalid(s_if[3].BVALID), .s3_bready(s_if[3].BREADY),
        .s3_arid(s_if[3].ARID), .s3_araddr(s_if[3].ARADDR), .s3_arlen(s_if[3].ARLEN), .s3_arvalid(s_if[3].ARVALID), .s3_arready(s_if[3].ARREADY),
        .s3_rid(s_if[3].RID), .s3_rdata(s_if[3].RDATA), .s3_rresp(s_if[3].RRESP), .s3_rlast(s_if[3].RLAST), .s3_rvalid(s_if[3].RVALID), .s3_rready(s_if[3].RREADY)
    );

    axi4_test test;

    initial begin
        test = new();
        
        test.env.drv[0].vif = m_if[0]; test.env.mon[0].vif = m_if[0]; test.env.rsp[0].vif = s_if[0];
        test.env.drv[1].vif = m_if[1]; test.env.mon[1].vif = m_if[1]; test.env.rsp[1].vif = s_if[1];
        test.env.drv[2].vif = m_if[2]; test.env.mon[2].vif = m_if[2]; test.env.rsp[2].vif = s_if[2];
        test.env.drv[3].vif = m_if[3]; test.env.mon[3].vif = m_if[3]; test.env.rsp[3].vif = s_if[3];

        $display("-------------------------------------------");
        $display("[%0t] Asserting System Reset...", $time);
        rst_n = 0;
        test.env.reset_system();
        #20;
        rst_n = 1;
        $display("[%0t] System Reset Released. Matrix Active.", $time);
        $display("-------------------------------------------");

        // Execute 20 randomly distributed transactions per Master (80 total)
        test.run(20);

        $finish;
    end
endmodule