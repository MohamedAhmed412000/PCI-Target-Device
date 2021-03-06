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
	$dumpfile("testbench.vcd");
	$dumpvars(0, testbench);
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
