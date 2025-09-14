module axi_slave (
    // Global Control Signals
    input        clk,
    input        resetn,

    // Write Address Channel
    input        awvalid,
    output reg   awready,
    input  [3:0] awid,
    input  [3:0] awlen,
    input  [2:0] awsize,
    input [31:0] awaddr,
    input  [1:0] awburst,

    // Write Data Channel
    input        wvalid,
    output reg   wready,
    input  [3:0] wid,
    input [31:0] wdata,
    input  [3:0] wstrb,
    input        wlast,

    // Write Response Channel
    input        bready,
    output reg   bvalid,
    output reg [3:0] bid,
    output reg [1:0] bresp,

    // Read Address Channel
    output reg   arready,
    input  [3:0] arid,
    input [31:0] araddr,
    input  [3:0] arlen,
    input  [2:0] arsize,
    input  [1:0] arburst,
    input        arvalid,

    // Read Data Channel
    output reg [3:0] rid,
    output reg [31:0] rdata,
    output reg [1:0]  rresp,
    output reg        rlast,
    output reg        rvalid,
    input             rready
);

    // State machine types
    typedef enum bit [1:0] {
        AWIDLE   = 2'b00,
        AWSTART  = 2'b01, 
        AWREADYS = 2'b10
    } awstate_type;
    
    typedef enum bit [2:0] {
        WIDLE     = 0,
        WSTART    = 1,
        WREADYS   = 2,
        WVALIDS   = 3,
        WADDR_DEC = 4
    } wstate_type;
    
    typedef enum bit [1:0] {
        BIDLE        = 0,
        BDETECT_LAST = 1,
        BSTART       = 2,
        BWAIT        = 3
    } bstate_type;
    
    typedef enum bit [1:0] {
        ARIDLE   = 0,
        ARSTART  = 1,
        ARREADYS = 2
    } arstate_type;
    
    typedef enum bit [2:0] {
        RIDLE   = 0,
        RSTART  = 1,
        RWAIT   = 2,
        RVALIDS = 3,
        RERROR  = 4
    } rstate_type;

    // State variables
    awstate_type awstate, awnext_state;
    wstate_type  wstate, wnext_state;
    bstate_type  bstate, bnext_state;
    arstate_type arstate, arnext_state;
    rstate_type  rstate, rnext_state;

    // Internal registers
    reg [31:0] awaddrt;
    reg [31:0] wdatat;
    reg [7:0]  mem[128] = '{default:12};
    reg [31:0] retaddr;
    reg [31:0] nextaddr;
    reg        first;
    reg [7:0]  boundary;
    reg [3:0]  wlen_count;
    reg [31:0] araddrt;
    reg        rdfirst;
    reg [3:0]  len_count;
    reg [7:0]  rdboundary;
    
    bit [31:0] rdnextaddr;
    bit [31:0] rdretaddr;

    // Sequential state updates
    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            awstate <= AWIDLE;
            wstate  <= WIDLE;
            bstate  <= BIDLE;
            arstate <= ARIDLE;
            rstate  <= RIDLE;
        end else begin
            awstate <= awnext_state;
            wstate  <= wnext_state;
            bstate  <= bnext_state;
            arstate <= arnext_state;
            rstate  <= rnext_state;
        end
    end

    // Write Address Channel FSM
    always_comb begin
        case (awstate)
            AWIDLE: begin
                awready      = 1'b0;
                awnext_state = AWSTART;
            end
            
            AWSTART: begin
                if (awvalid) begin
                    awnext_state = AWREADYS;
                    awaddrt      = awaddr;
                end else begin
                    awnext_state = AWSTART;
                end
            end
            
            AWREADYS: begin
                awready      = 1'b1;
                awnext_state = (wstate == WREADYS) ? AWIDLE : AWREADYS;
            end
        endcase
    end

    // Write Data Channel Helper Functions
    function automatic bit [31:0] data_wr_fixed(input [3:0] wstrb, input [31:0] awaddrt);
        unique case (wstrb)
            4'b0001: mem[awaddrt] = wdatat[7:0];
            4'b0010: mem[awaddrt] = wdatat[15:8];
            4'b0011: begin
                mem[awaddrt]     = wdatat[7:0];
                mem[awaddrt + 1] = wdatat[15:8];
            end
            4'b0100: mem[awaddrt] = wdatat[23:16];
            4'b0101: begin
                mem[awaddrt]     = wdatat[7:0];
                mem[awaddrt + 1] = wdatat[23:16];
            end
            4'b0110: begin
                mem[awaddrt]     = wdatat[15:8];
                mem[awaddrt + 1] = wdatat[23:16];
            end
            4'b0111: begin
                mem[awaddrt]     = wdatat[7:0];
                mem[awaddrt + 1] = wdatat[15:8];
                mem[awaddrt + 2] = wdatat[23:16];
            end
            4'b1000: mem[awaddrt] = wdatat[31:24];
            4'b1001: begin
                mem[awaddrt]     = wdatat[7:0];
                mem[awaddrt + 1] = wdatat[31:24];
            end
            4'b1010: begin
                mem[awaddrt]     = wdatat[15:8];
                mem[awaddrt + 1] = wdatat[31:24];
            end
            4'b1011: begin
                mem[awaddrt]     = wdatat[7:0];
                mem[awaddrt + 1] = wdatat[15:8];
                mem[awaddrt + 2] = wdatat[31:24];
            end
            4'b1100: begin
                mem[awaddrt]     = wdatat[23:16];
                mem[awaddrt + 1] = wdatat[31:24];
            end
            4'b1101: begin
                mem[awaddrt]     = wdatat[7:0];
                mem[awaddrt + 1] = wdatat[23:16];
                mem[awaddrt + 2] = wdatat[31:24];
            end
            4'b1110: begin
                mem[awaddrt]     = wdatat[15:8];
                mem[awaddrt + 1] = wdatat[23:16];
                mem[awaddrt + 2] = wdatat[31:24];
            end
            4'b1111: begin
                mem[awaddrt]     = wdatat[7:0];
                mem[awaddrt + 1] = wdatat[15:8];
                mem[awaddrt + 2] = wdatat[23:16];
                mem[awaddrt + 3] = wdatat[31:24];
            end
        endcase
        return awaddrt;
    endfunction

    function automatic bit [31:0] data_wr_incr(input [3:0] wstrb, input [31:0] awaddrt);
        bit [31:0] addr;
        unique case (wstrb)
            4'b0001: begin
                mem[awaddrt] = wdatat[7:0];
                addr = awaddrt + 1;
            end
            4'b0010: begin
                mem[awaddrt] = wdatat[15:8];
                addr = awaddrt + 1;
            end
            4'b0011: begin
                mem[awaddrt]     = wdatat[7:0];
                mem[awaddrt + 1] = wdatat[15:8];
                addr = awaddrt + 2;
            end
            4'b0100: begin
                mem[awaddrt] = wdatat[23:16];
                addr = awaddrt + 1;
            end
            4'b0101: begin
                mem[awaddrt]     = wdatat[7:0];
                mem[awaddrt + 1] = wdatat[23:16];
                addr = awaddrt + 2;
            end
            4'b0110: begin
                mem[awaddrt]     = wdatat[15:8];
                mem[awaddrt + 1] = wdatat[23:16];
                addr = awaddrt + 2;
            end
            4'b0111: begin
                mem[awaddrt]     = wdatat[7:0];
                mem[awaddrt + 1] = wdatat[15:8];
                mem[awaddrt + 2] = wdatat[23:16];
                addr = awaddrt + 3;
            end
            4'b1000: begin
                mem[awaddrt] = wdatat[31:24];
                addr = awaddrt + 1;
            end
            4'b1001: begin
                mem[awaddrt]     = wdatat[7:0];
                mem[awaddrt + 1] = wdatat[31:24];
                addr = awaddrt + 2;
            end
            4'b1010: begin
                mem[awaddrt]     = wdatat[15:8];
                mem[awaddrt + 1] = wdatat[31:24];
                addr = awaddrt + 2;
            end
            4'b1011: begin
                mem[awaddrt]     = wdatat[7:0];
                mem[awaddrt + 1] = wdatat[15:8];
                mem[awaddrt + 2] = wdatat[31:24];
                addr = awaddrt + 3;
            end
            4'b1100: begin
                mem[awaddrt]     = wdatat[23:16];
                mem[awaddrt + 1] = wdatat[31:24];
                addr = awaddrt + 2;
            end
            4'b1101: begin
                mem[awaddrt]     = wdatat[7:0];
                mem[awaddrt + 1] = wdatat[23:16];
                mem[awaddrt + 2] = wdatat[31:24];
                addr = awaddrt + 3;
            end
            4'b1110: begin
                mem[awaddrt]     = wdatat[15:8];
                mem[awaddrt + 1] = wdatat[23:16];
                mem[awaddrt + 2] = wdatat[31:24];
                addr = awaddrt + 3;
            end
            4'b1111: begin
                mem[awaddrt]     = wdatat[7:0];
                mem[awaddrt + 1] = wdatat[15:8];
                mem[awaddrt + 2] = wdatat[23:16];
                mem[awaddrt + 3] = wdatat[31:24];
                addr = awaddrt + 4;
            end
        endcase
        return addr;
    endfunction

    function automatic bit [7:0] wrap_boundary(input bit [3:0] awlen, input bit [2:0] awsize);
        bit [7:0] boundary;
        unique case(awlen)
            4'b0001: begin
                unique case(awsize)
                    3'b000: boundary = 2 * 1;
                    3'b001: boundary = 2 * 2;
                    3'b010: boundary = 2 * 4;
                endcase
            end
            4'b0011: begin
                unique case(awsize)
                    3'b000: boundary = 4 * 1;
                    3'b001: boundary = 4 * 2;
                    3'b010: boundary = 4 * 4;
                endcase
            end
            4'b0111: begin
                unique case(awsize)
                    3'b000: boundary = 8 * 1;
                    3'b001: boundary = 8 * 2;
                    3'b010: boundary = 8 * 4;
                endcase
            end
            4'b1111: begin
                unique case(awsize)
                    3'b000: boundary = 16 * 1;
                    3'b001: boundary = 16 * 2;
                    3'b010: boundary = 16 * 4;
                endcase
            end
        endcase
        return boundary;
    endfunction

    function automatic bit [31:0] data_wr_wrap(input [3:0] wstrb, input [31:0] awaddrt, input [7:0] wboundary);
        bit [31:0] addr1, addr2, addr3, addr4;
        unique case (wstrb)
            4'b0001: begin
                mem[awaddrt] = wdatat[7:0];
                if ((awaddrt + 1) % wboundary == 0)
                    addr1 = (awaddrt + 1) - wboundary;
                else
                    addr1 = awaddrt + 1;
                return addr1;
            end
            4'b0010: begin
                mem[awaddrt] = wdatat[15:8];
                if ((awaddrt + 1) % wboundary == 0)
                    addr1 = (awaddrt + 1) - wboundary;
                else
                    addr1 = awaddrt + 1;
                return addr1;
            end
            4'b0011: begin
                mem[awaddrt] = wdatat[7:0];
                if ((awaddrt + 1) % wboundary == 0)
                    addr1 = (awaddrt + 1) - wboundary;
                else
                    addr1 = awaddrt + 1;
                mem[addr1] = wdatat[15:8];
                if ((addr1 + 1) % wboundary == 0)
                    addr2 = (addr1 + 1) - wboundary;
                else
                    addr2 = addr1 + 1;
                return addr2;
            end
            4'b0100: begin
                mem[awaddrt] = wdatat[23:16];
                if ((awaddrt + 1) % wboundary == 0)
                    addr1 = (awaddrt + 1) - wboundary;
                else
                    addr1 = awaddrt + 1;
                return addr1;
            end
            4'b0101: begin
                mem[awaddrt] = wdatat[7:0];
                if ((awaddrt + 1) % wboundary == 0)
                    addr1 = (awaddrt + 1) - wboundary;
                else
                    addr1 = awaddrt + 1;
                mem[addr1] = wdatat[23:16];
                if ((addr1 + 1) % wboundary == 0)
                    addr2 = (addr1 + 1) - wboundary;
                else
                    addr2 = addr1 + 1;
                return addr2;
            end
            4'b0110: begin
                mem[awaddrt] = wdatat[15:8];
                if ((awaddrt + 1) % wboundary == 0)
                    addr1 = (awaddrt + 1) - wboundary;
                else
                    addr1 = awaddrt + 1;
                mem[addr1] = wdatat[23:16];
                if ((addr1 + 1) % wboundary == 0)
                    addr2 = (addr1 + 1) - wboundary;
                else
                    addr2 = addr1 + 1;
                return addr2;
            end
            4'b0111: begin
                mem[awaddrt] = wdatat[7:0];
                if ((awaddrt + 1) % wboundary == 0)
                    addr1 = (awaddrt + 1) - wboundary;
                else
                    addr1 = awaddrt + 1;
                mem[addr1] = wdatat[15:8];
                if ((addr1 + 1) % wboundary == 0)
                    addr2 = (addr1 + 1) - wboundary;
                else
                    addr2 = addr1 + 1;
                mem[addr2] = wdatat[23:16];
                if ((addr2 + 1) % wboundary == 0)
                    addr3 = (addr2 + 1) - wboundary;
                else
                    addr3 = addr2 + 1;
                return addr3;
            end
            4'b1000: begin
                mem[awaddrt] = wdatat[31:24];
                if ((awaddrt + 1) % wboundary == 0)
                    addr1 = (awaddrt + 1) - wboundary;
                else
                    addr1 = awaddrt + 1;
                return addr1;
            end
            4'b1001: begin
                mem[awaddrt] = wdatat[7:0];
                if ((awaddrt + 1) % wboundary == 0)
                    addr1 = (awaddrt + 1) - wboundary;
                else
                    addr1 = awaddrt + 1;
                mem[addr1] = wdatat[31:24];
                if ((addr1 + 1) % wboundary == 0)
                    addr2 = (addr1 + 1) - wboundary;
                else
                    addr2 = addr1 + 1;
                return addr2;
            end
            4'b1010: begin
                mem[awaddrt] = wdatat[15:8];
                if ((awaddrt + 1) % wboundary == 0)
                    addr1 = (awaddrt + 1) - wboundary;
                else
                    addr1 = awaddrt + 1;
                mem[addr1] = wdatat[31:24];
                if ((addr1 + 1) % wboundary == 0)
                    addr2 = (addr1 + 1) - wboundary;
                else
                    addr2 = addr1 + 1;
                return addr2;
            end
            4'b1011: begin
                mem[awaddrt] = wdatat[7:0];
                if ((awaddrt + 1) % wboundary == 0)
                    addr1 = (awaddrt + 1) - wboundary;
                else
                    addr1 = awaddrt + 1;
                mem[addr1] = wdatat[15:8];
                if ((addr1 + 1) % wboundary == 0)
                    addr2 = (addr1 + 1) - wboundary;
                else
                    addr2 = addr1 + 1;
                mem[addr2] = wdatat[31:24];
                if ((addr2 + 1) % wboundary == 0)
                    addr3 = (addr2 + 1) - wboundary;
                else
                    addr3 = addr2 + 1;
                return addr3;
            end
            4'b1100: begin
                mem[awaddrt] = wdatat[23:16];
                if ((awaddrt + 1) % wboundary == 0)
                    addr1 = (awaddrt + 1) - wboundary;
                else
                    addr1 = awaddrt + 1;
                mem[addr1] = wdatat[31:24];
                if ((addr1 + 1) % wboundary == 0)
                    addr2 = (addr1 + 1) - wboundary;
                else
                    addr2 = addr1 + 1;
                return addr2;
            end
            4'b1101: begin
                mem[awaddrt] = wdatat[7:0];
                if ((awaddrt + 1) % wboundary == 0)
                    addr1 = (awaddrt + 1) - wboundary;
                else
                    addr1 = awaddrt + 1;
                mem[addr1] = wdatat[23:16];
                if ((addr1 + 1) % wboundary == 0)
                    addr2 = (addr1 + 1) - wboundary;
                else
                    addr2 = addr1 + 1;
                mem[addr2] = wdatat[31:24];
                if ((addr2 + 1) % wboundary == 0)
                    addr3 = (addr2 + 1) - wboundary;
                else
                    addr3 = addr2 + 1;
                return addr3;
            end
            4'b1110: begin
                mem[awaddrt] = wdatat[15:8];
                if ((awaddrt + 1) % wboundary == 0)
                    addr1 = (awaddrt + 1) - wboundary;
                else
                    addr1 = awaddrt + 1;
                mem[addr1] = wdatat[23:16];
                if ((addr1 + 1) % wboundary == 0)
                    addr2 = (addr1 + 1) - wboundary;
                else
                    addr2 = addr1 + 1;
                mem[addr2] = wdatat[31:24];
                if ((addr2 + 1) % wboundary == 0)
                    addr3 = (addr2 + 1) - wboundary;
                else
                    addr3 = addr2 + 1;
                return addr3;
            end
            4'b1111: begin
                mem[awaddrt] = wdatat[7:0];
                if ((awaddrt + 1) % wboundary == 0)
                    addr1 = (awaddrt + 1) - wboundary;
                else
                    addr1 = awaddrt + 1;
                mem[addr1] = wdatat[15:8];
                if ((addr1 + 1) % wboundary == 0)
                    addr2 = (addr1 + 1) - wboundary;
                else
                    addr2 = addr1 + 1;
                mem[addr2] = wdatat[23:16];
                if ((addr2 + 1) % wboundary == 0)
                    addr3 = (addr2 + 1) - wboundary;
                else
                    addr3 = addr2 + 1;
                mem[addr3] = wdatat[31:24];
                if ((addr3 + 1) % wboundary == 0)
                    addr4 = (addr3 + 1) - wboundary;
                else
                    addr4 = addr3 + 1;
                return addr4;
            end
        endcase
    endfunction

    // Write Data Channel FSM
    always_comb begin
        case (wstate)
            WIDLE: begin
                wready       = 1'b0;
                wnext_state  = WSTART;
                first        = 1'b0;
                wlen_count   = 0;
            end
            
            WSTART: begin
                if (wvalid) begin
                    wnext_state = WADDR_DEC;
                    wdatat      = wdata;
                end else begin
                    wnext_state = WSTART;
                end
            end
            
            WADDR_DEC: begin
                wnext_state = WREADYS;
                if (!first) begin
                    nextaddr   = awaddr;
                    first      = 1'b1;
                    wlen_count = 0;
                end else if (wlen_count < (awlen + 1)) begin
                    nextaddr = retaddr;
                end else begin
                    nextaddr = awaddr;
                end
            end
            
            WREADYS: begin
                if (wlast) begin
                    wnext_state = WIDLE;
                    wready      = 1'b0;
                    wlen_count  = 0;
                    first       = 1'b0;
                end else if (wlen_count < (awlen + 1)) begin
                    wnext_state = WVALIDS;
                    wready      = 1'b1;
                end else begin
                    wnext_state = WREADYS;
                end
                
                case (awburst)
                    2'b00: retaddr = data_wr_fixed(wstrb, awaddr);
                    2'b01: retaddr = data_wr_incr(wstrb, nextaddr);
                    2'b10: begin
                        boundary = wrap_boundary(awlen, awsize);
                        retaddr = data_wr_wrap(wstrb, nextaddr, boundary);
                    end
                endcase
            end
            
            WVALIDS: begin
                wready      = 1'b0;
                wnext_state = WSTART;
                if (wlen_count < (awlen + 1)) wlen_count++;
            end
        endcase
    end

    // Write Response FSM
    always_comb begin
        case (bstate)
            BIDLE: begin
                bid          = 0;
                bresp        = 0;
                bvalid       = 0;
                bnext_state  = BDETECT_LAST;
            end
            
            BDETECT_LAST: begin
                bnext_state = wlast ? BSTART : BDETECT_LAST;
            end
            
            BSTART: begin
                bid         = awid;
                bvalid      = 1'b1;
                bnext_state = BWAIT;
                
                if ((awaddr < 128) && (awsize <= 3'b010)) begin
                    bresp = 2'b00;
                end else if (awsize > 3'b010) begin
                    bresp = 2'b10;
                end else begin
                    bresp = 2'b11;
                end
            end
            
            BWAIT: begin
                bnext_state = bready ? BIDLE : BWAIT;
            end
        endcase
    end

    // Read Address Channel FSM
    always_comb begin
        case (arstate)
            ARIDLE: begin
                arready      = 1'b0;
                arnext_state = ARSTART;
            end
            
            ARSTART: begin
                if (arvalid) begin
                    arnext_state = ARREADYS;
                    araddrt      = araddr;
                end else begin
                    arnext_state = ARSTART;
                end
            end
            
            ARREADYS: begin
                arready      = 1'b1;
                arnext_state = ARIDLE;
            end
        endcase
    end

    // Read Data Channel Helper Functions
    function automatic void read_data_fixed(input [31:0] addr, input [2:0] arsize);
        unique case(arsize)
            3'b000: rdata[7:0] = mem[addr];
            3'b001: begin
                rdata[7:0]  = mem[addr];
                rdata[15:8] = mem[addr + 1];
            end
            3'b010: begin
                rdata[7:0]    = mem[addr];
                rdata[15:8]   = mem[addr + 1];
                rdata[23:16]  = mem[addr + 2];
                rdata[31:24]  = mem[addr + 3];
            end
        endcase
    endfunction

    function automatic bit [31:0] read_data_incr(input [31:0] addr, input [2:0] arsize);
        bit [31:0] nextaddr;
        unique case(arsize)
            3'b000: begin
                rdata[7:0] = mem[addr];
                nextaddr = addr + 1;
            end
            3'b001: begin
                rdata[7:0]  = mem[addr];
                rdata[15:8] = mem[addr + 1];
                nextaddr = addr + 2;
            end
            3'b010: begin
                rdata[7:0]    = mem[addr];
                rdata[15:8]   = mem[addr + 1];
                rdata[23:16]  = mem[addr + 2];
                rdata[31:24]  = mem[addr + 3];
                nextaddr = addr + 4;
            end
        endcase
        return nextaddr;
    endfunction

    function automatic bit [31:0] read_data_wrap(input bit [31:0] addr, input bit [2:0] rsize, input [7:0] rboundary);
        bit [31:0] addr1, addr2, addr3, addr4;
        unique case (rsize)
            3'b000: begin
                rdata[7:0] = mem[addr];
                if (((addr + 1) % rboundary) == 0)
                    addr1 = (addr + 1) - rboundary;
                else
                    addr1 = (addr + 1);
                return addr1;
            end
            3'b001: begin
                rdata[7:0] = mem[addr];
                if (((addr + 1) % rboundary) == 0)
                    addr1 = (addr + 1) - rboundary;
                else
                    addr1 = (addr + 1);
                rdata[15:8] = mem[addr1];
                if (((addr1 + 1) % rboundary) == 0)
                    addr2 = (addr1 + 1) - rboundary;
                else
                    addr2 = (addr1 + 1);
                return addr2;
            end
            3'b010: begin
                rdata[7:0] = mem[addr];
                if (((addr + 1) % rboundary) == 0)
                    addr1 = (addr + 1) - rboundary;
                else
                    addr1 = (addr + 1);
                rdata[15:8] = mem[addr1];
                if (((addr1 + 1) % rboundary) == 0)
                    addr2 = (addr1 + 1) - rboundary;
                else
                    addr2 = (addr1 + 1);
                rdata[23:16] = mem[addr2];
                if (((addr2 + 1) % rboundary) == 0)
                    addr3 = (addr2 + 1) - rboundary;
                else
                    addr3 = (addr2 + 1);
                rdata[31:24] = mem[addr3];
                if (((addr3 + 1) % rboundary) == 0)
                    addr4 = (addr3 + 1) - rboundary;
                else
                    addr4 = (addr3 + 1);
                return addr4;
            end
        endcase
    endfunction

    // Read Data Channel FSM
    always_comb begin
        case (rstate)
            RIDLE: begin
                rid        = 0;
                rdfirst    = 0;
                rdata      = 0;
                rresp      = 0;
                rlast      = 0;
                rvalid     = 0;
                len_count  = 0;
                rnext_state = arvalid ? RSTART : RIDLE;
            end
            
            RSTART: begin
                if ((araddrt < 128) && (arsize <= 3'b010)) begin
                    rid    = arid;
                    rvalid = 1'b1;
                    rnext_state = RWAIT;
                    rresp  = 2'b00;
                    unique case(arburst)
                        2'b00: begin
                            if (!rdfirst) begin
                                rdnextaddr = araddr;
                                rdfirst    = 1'b1;
                                len_count  = 0;
                            end else if (len_count != (arlen + 1)) begin
                                rdnextaddr = araddr;
                            end
                            read_data_fixed(araddrt, arsize);
                        end
                        2'b01: begin
                            if (!rdfirst) begin
                                rdnextaddr = araddr;
                                rdfirst    = 1'b1;
                                len_count  = 0;
                            end else if (len_count != (arlen + 1)) begin
                                rdnextaddr = rdretaddr;
                            end
                            rdretaddr = read_data_incr(rdnextaddr, arsize);
                        end
                        2'b10: begin
                            if (!rdfirst) begin
                                rdnextaddr = araddr;
                                rdfirst    = 1'b1;
                                len_count  = 0;
                            end else if (len_count != (arlen + 1)) begin
                                rdnextaddr = rdretaddr;
                            end
                            rdboundary = wrap_boundary(arlen, arsize);
                            rdretaddr = read_data_wrap(rdnextaddr, arsize, rdboundary);
                        end
                    endcase
                end else if ((araddr >= 128) && (arsize <= 3'b010)) begin
                    rresp  = 2'b11;
                    rvalid = 1'b1;
                    rnext_state = RERROR;
                end else if (arsize > 3'b010) begin
                    rresp  = 2'b10;
                    rvalid = 1'b1;
                    rnext_state = RERROR;
                end
            end
            
            RWAIT: begin
                rvalid = 1'b0;
                rnext_state = rready ? RVALIDS : RWAIT;
            end
            
            RVALIDS: begin
                len_count = len_count + 1;
                if (len_count == (arlen + 1)) begin
                    rnext_state = RIDLE;
                    rlast       = 1'b1;
                end else begin
                    rnext_state = RSTART;
                    rlast       = 1'b0;
                end
            end
            
            RERROR: begin
                rvalid = 1'b0;
                if (len_count < arlen) begin
                    if (arready) begin
                        rnext_state = RSTART;
                        len_count = len_count + 1;
                    end
                end else begin
                    rlast = 1'b1;
                    rnext_state = RIDLE;
                    len_count   = 0;
                end
            end
            
            default: rnext_state = RIDLE;
        endcase
    end

endmodule