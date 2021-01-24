
module clk(output reg clock);
initial
    clock = 0;
    always
        #10 clock = ~clock;
endmodule

module PCI(Clk, Rst, Frame, IRDY, TRDY, Ad, Ctrl, DevSel, Stop);
    input Clk, Rst, Frame, IRDY;
    inout [31:0] Ad;
    input [3:0] Ctrl;
    output reg DevSel, TRDY, Stop;

    clk C(Clk);
    reg[31:0] Buf[0:3];
    reg[31:0] AddBuf[0:3];

    // Flags
    reg flgDS, flgTRGT, flgDOA, flgData, flgBFR, flgRW, flgTR, flgIR, regIR, flg0,flg1,flg2,flg3, flgAdd, flgifadd, flgOP;
    reg [2:0]Counter;
    reg [31:0]Address;
    reg [31:0]BE;
	//flgDS to delay DEVSEL 1 Clk
	//flgTRGT to delay TRDY 1 Clk

    // INOUT Port
    reg flg; // 1 for read and 0 for write
    wire [31:0]W1; // Read Address from address lines
    reg [31:0]W2; //Put data in address lines
    assign Ad = (flg)? W2 : 32'hzzzzzzzz;
    //assign W1 = (flg)? 32'hzzzzzzzz : Ad;
    assign W1 = Ad;
    always@(posedge Clk or negedge Rst) begin
         if(~Rst)begin
            flg0 <= 1'b0;
	        flg1 <= 1'b0;
	        flg2 <= 1'b0;
	        flg3 <= 1'b0;
            flgAdd <= 1'b0;
            flgDS <= 1'b1;
            flgIR <= 1'b0;
            Counter = 3'b000;
            flgTR <= 1'b1;
            TRDY <= 1'b1;
    	    DevSel <= 1'b1;
    	    Stop <= 1'b1;
    	    flg <= 1'b1;
    	    W2 <= 32'hzzzzzzzz;
    	    flgData <= 1'b0;   // Flag to data number 1
    	    flgDOA <= 1'b0;    // Flag Data Or Address
	
    	    //flgBFR <= 1'b1;  // Flag Buffer
    	    //flgMe <= 1'b0;   // Flag Telling us if we are the target or not
    	end
    	else begin //With Clk
            if (Frame == 1'b0) begin
		        if (((Ctrl == 4'b0010 || Ctrl == 4'b0011) && (W1 === 32'h00001F40 || W1 === 32'h00001F41 || W1 === 32'h00001F42 || W1 === 32'h00001F43) || W1 === 32'hzzzzzzzz) && flgDOA == 1'b0)begin // Address Phase, 
		            flgDS <= 1'b0;
		            if(Ctrl == 4'b0010) begin flgOP = Ctrl[0]; end
		            if(Ctrl == 4'b0011) begin flgOP = Ctrl[0]; flgDOA <= 1'b1; end
			        if(W1 === 32'h00001F40 || W1 === 32'h00001F41 || W1 === 32'h00001F42 || W1 === 32'h00001F43) begin Address = W1 - 32'h00001F40; end
			        if (W1 === 32'hzzzzzzzz) begin// Check that read with ad is z or Write to begin Data phase,    //ZZZZ is a problem
		                flgDOA <= 1'b1; // Flag = 1 to begin Data Phase
			        end // check z
			    end
            end
        end
    end
    always@(posedge Clk) begin
        if(Frame == 1'b0) begin
            if(flgDOA == 1'b1) begin   // Data Phase, Check to begin sending Data , IRDY equal zero
		         
		            if(flgOP == 1'b1) begin // Write Operation, Data Phase
                        if(flgData == 1'b0) begin // check first data when Ad is Turning around
                    	    	DevSel = flgDS;	
				TRDY <= 1'b0;
                    	    BE = {{8{Ctrl[3]}}, {8{Ctrl[2]}}, {8{Ctrl[1]}}, {8{Ctrl[0]}}};
                    		Buf[Address] = W1 & BE;
                			flgData <= 1'b1;
                			Address  <= (Address + 1'b1) % 4;
            		    end
            		    if(flgData == 1'b1 && TRDY == 1'b0 && Counter < 3'b011 && flgIR == 1'b0) begin // Not first data there is no need for check address equal z
        		            BE = {{8{Ctrl[3]}}, {8{Ctrl[2]}}, {8{Ctrl[1]}}, {8{Ctrl[0]}}};
        		            Buf[Address] = W1 & BE;
        		            Address  <= (Address + 1'b1) % 4;
                            Counter <= Counter + 1;
                        end
                        else if(flgData == 1'b1 && Counter == 3'b100 && flgAdd == 1'b0) begin
                            TRDY <= 1'b1;
                            AddBuf[0] <= Buf[0];
                            AddBuf[1] <= Buf[1];
                            AddBuf[2] <= Buf[2];
                            AddBuf[3] <= Buf[3];
                            flgTR <= 1'b0;
                            flgAdd <= 1'b1;
                            Counter <= Counter + 1;
                        end
                        else if(flgTR == 1'b0 && flgAdd == 1'b1 && Counter == 3'b101) begin
                            TRDY <= 1'b0; 
                            flgTR <= 1'b1;
                            flgData <= 1'b0;
                            Counter <= 3'b000;
                            Address <= 32'h00000000;
                        end
                        else if(flgData == 1'b1 && Counter == 3'b011 && flgAdd == 1'b1) begin
                            Stop <= 1'b0;
                        end
                        if(IRDY == 1'b1) begin 
                            flgIR <= 1'b1; 
                        end
                        else if(IRDY == 1'b0) begin 
                            flgIR <= 1'b0;//Clk ?????
                            //flgIR <= regIR;
                        end                    	
                    end // close Write Operation 
	        end
		end
		if (Frame == 1'b1)begin
                DevSel <= 1'b1;
                TRDY <= 1'b1;
                flg0 <= 1'b0;
                flgAdd <= 1'b0;
                flgDS <= 1'b1;
                flgIR <= 1'b0;
                Counter = 3'b000;
                flgTR <= 1'b1;
        	    Stop <= 1'b1;
                flg <= 1'b1;
	            W2 <= 32'hzzzzzzzz;
                flgData <= 1'b0;   // Flag to data number 1
        	    flgDOA <= 1'b0;
        end //Close Not Frame
    end
    always@(negedge Clk) begin
       if(Frame == 1'b0) begin    
			    if(flgDOA == 1'b1) begin   // Data Phase, Check to begin sending Data , IRDY equal zero
		            
		            if(flgOP == 1'b0) begin // Read Operation
                    	if(flgData == 1'b0) begin // check first data when Ad is Turning around
				DevSel = flgDS;                    	    
				TRDY <= 1'b0;
                    		W2 = Buf[Address];
                			flgData <= 1'b1;
                			Address  <= (Address + 1) % 4;
            		    end
            		    else if(flgData == 1'b1 && TRDY == 1'b0 && Counter < 3'b011 && flgIR == 1'b0) begin // Not first data there is no need for check address equal z
        		            W2 = Buf[Address];
        		            Address  <= (Address + 1) % 4;
                            Counter <= Counter + 1;
                        end
                        else if(flgData == 1'b1 && Counter == 3'b100 && flgAdd == 1'b0) begin
                            TRDY <= 1'b1;
                            Buf[0] <= AddBuf[0];
                            Buf[1] <= AddBuf[1];
                            Buf[2] <= AddBuf[2];
                            Buf[3] <= AddBuf[3];
                            flgTR <= 1'b0;
                            flgAdd <= 1'b1;
                            Counter <= Counter + 1;
                        end
                        else if(flgTR == 1'b0 && flgAdd == 1'b1 && Counter == 3'b101) begin
                            TRDY <= 1'b0; 
                            flgTR <= 1'b1;
                            flgData <= 1'b0;
                            Counter <= 3'b000;
                            Address <= 32'h00000000;
                        end
                        else if(flgData == 1'b1 && Counter == 3'b011 && flgAdd == 1'b1) begin
                            Stop <= 1'b0;
                        end
                        if(IRDY == 1'b1) begin 
                            flgIR <= 1'b1; 
                        end
                        else if(IRDY == 1'b0) begin 
                            flgIR <= 1'b0;//Clk ?????
                            //flgIR <= regIR;
                        end
                    end
                end
    	end //else clk not rst
    	if (Frame == 1'b1)begin
                DevSel <= 1'b1;
                TRDY <= 1'b1;
                flg0 <= 1'b0;
                flgAdd <= 1'b0;
                flgDS <= 1'b1;
                flgIR <= 1'b0;
                Counter = 3'b000;
                flgTR <= 1'b1;
        	    Stop <= 1'b1;
                flg <= 1'b1;
	            W2 <= 32'hzzzzzzzz;
                flgData <= 1'b0;   // Flag to data number 1
        	    flgDOA <= 1'b0;
        end //Close Not Frame
    end //always
endmodule

/*module ATestbenchPCI11 (Trdy, Devsel, Stop, Address);
inout [31:0]Address;
input Stop, Devsel, Trdy;
reg Frame, Irdy, Rst;
reg [3:0] CBE;
wire flg_TRGT;
reg flg; // 1 for write and 0 for read 
wire[31:0] W1; 
reg [31:0]WW, Mem [0:1];
clk c1(Clk);
//wire [31:0]Add;
assign Address = flg? WW : 32'hzzzzzzzz;
//assign W1 = flg? 32'hzzzzzzzz : Address;
assign W1 = Address;
PCI p1(Clk, Rst, Frame, Irdy, Trdy, Address, CBE, Devsel, Stop);
assign flg_TRGT = (Trdy==1'b0 && Devsel == 1'b0)? 1'b1 : 1'b0;
//assign Add = (1'b1)? W2 : 'bz;
//assign W1 = Add;

initial begin
#0
Frame <= 1'b1;
Irdy <= 1'b1;
CBE <= 4'b0000;
Rst <= 1'b0;
flg <= 1'b1;

#20
Rst <= 1'b1; 
Frame <= 1'b0;
CBE <= 4'b0011;
flg <= 1'b1;
WW = 32'h00001F42;

#20 // Byte enable Turn around
CBE <= 4'b0001;
Irdy <= 1'b0;
WW = 32'h11111111;
//flg <= 1'b0;


#20 // Byte enable Turn around
CBE <= 4'b1000;
WW = 32'h01000110;




#20
CBE <= 4'b0110;
WW <= 32'h11110000;
Frame <= 1'b1;






////////////////////////
#20
Frame <= 1'b1;
Irdy <= 1'b1;
CBE <= 4'b0000;
flg <= 1'b1;

#20 
Frame <= 1'b0;
CBE <= 4'b0010;
flg <= 1'b1;
WW = 32'h00001F42;

#20 // Byte enable Turn around
CBE <= 4'b0000;
Irdy <= 1'b0;
WW = 32'hzzzzzzzz;
//flg <= 1'b0;

#40
flg <= 1'b1;
if(flg_TRGT)begin
Mem[0] = W1;
end

#20
Irdy = 1'b0;
Mem[1] = W1;

end
endmodule*/ 

module testbench_2(Trdy, Devsel, Stop, Address);
    reg[31:0] W2, Mem[0:7];
    clk c1(Clk);
    inout [31:0]Address;
    input Stop, Devsel, Trdy;
    reg [3:0] Cbe;
    reg flg, Rst, Frame, Irdy;
    wire[31:0] W1;
    PCI p1(Clk, Rst, Frame, Irdy, Trdy, Address, Cbe, Devsel, Stop);
    assign Address = flg? W2 : 32'hzzzzzzzz;
    assign W1 = flg? Address : 32'hzzzzzzzz;
    //Beginig Testbench 
    initial begin
	//$dumpfile("testbench.vcd");
	//$dumpvars(0, testbench);
        Rst <= 1'b1;
        #20
            Rst <= 1'b0;
            Frame <= 1'b1;
        #20
	    flg <= 1'b1;
            Rst <= 1'b1;
            Frame <= 1'b0;
            W2 <= 32'h00001F40; //Not Our PCI Device
            Cbe <= 4'b0011; // Read Operation
	    #20
            Frame <= 1'b0;
	    Irdy <= 1'b0;
	    W2 <= 32'h11111000;
		Cbe <= 4'b1011;
		 Frame <= 1'b1;
	#20
	    W2 <= 32'h00001111;
	    Cbe <= 4'b0001;
	    Irdy <= 1'b1;
    end
endmodule

