
module testbench_4(Trdy, Devsel, Stop, Address);
    reg[31:0] W2, Get, Mem[0:7];
    clk c1(Clk);
    inout [31:0]Address;
    input Stop, Devsel, Trdy;
    reg [3:0] Cbe;
    reg flg, Rst, Frame, Irdy, Transaction;
    wire[31:0] W1;
    PCI p1(Clk, Rst, Frame, Irdy, Trdy, Address, Cbe, Devsel, Stop);
    assign Address = flg? W2 : 32'hzzzzzzzz;
    assign W1 = flg? Address : 32'hzzzzzzzz;
    //Beginig Testbench
    initial begin
        Rst <= 1'b1;
        Transaction <= 1'b0;
        Mem[0] <= 32'h11111111;
        Mem[1] <= 32'h00001111;
        Mem[2] <= 32'h11110000;
        Mem[3] <= 32'h00000000;
        Mem[4] <= 32'h10101010;
        Mem[5] <= 32'h01010101;
        Mem[6] <= 32'h11111010;
        Mem[7] <= 32'h01001111;
        #20
            Rst <= 1'b0;
            Frame <= 1'b1;
        #20
	    flg <= 1'b1;
            Rst <= 1'b1;
            Frame <= 1'b0;
            Transaction <= 1'b1;
            W2 <= 32'h00001F41; //Not Our PCI Device
            Cbe <= 4'b0011; // Write Operation
        #20
            Irdy = 1'b0;
            if (Stop) Transaction <= 1'b0; 
            if(Trdy == 1'b0) begin
                Frame <= 1'b0;
                W2 <= Mem[0]; 
                Cbe <= 4'b0011;
            end
        #20
            if (Stop) Transaction <= 1'b0; 
            while (Trdy == 1'b1) 
                #20 //Do Nothing
            if(Trdy == 1'b0 && Transaction == 1'b1) begin
                Frame <= 1'b0;
                W2 <= Mem[1]; 
                Cbe <= 4'b0100;
            end
        #20
            Irdy <= 1'b1;
        #20
            Irdy <= 1'b0;
            if (Stop) Transaction <= 1'b0; 
            while (Trdy == 1'b1)
                #20 //Do Nothing
           
            if(Trdy == 1'b0 && Transaction == 1'b1) begin
                Frame <= 1'b0;
                W2 <= Mem[2]; 
                Cbe <= 4'b0011;
            end
        #20
            if (Stop) Transaction <= 1'b0; 
            while (Trdy == 1'b1)
                #20 //Do Nothing
          
            if(Trdy == 1'b0 && Transaction == 1'b1) begin
                Frame <= 1'b0;
                W2 <= Mem[3]; 
                Cbe <= 4'b0011;
            end
        #20
            if (Stop) Transaction <= 1'b0; 
            while (Trdy == 1'b1 )
                #20 //Do Nothing
          
            if(Trdy == 1'b0 && Transaction == 1'b1) begin
                Frame <= 1'b0;
                W2 <= Mem[4]; 
                Cbe <= 4'b0011;
            end
	    #20
	        if (Stop) Transaction <= 1'b0; 
	        while (Trdy == 1'b1 && Transaction == 1'b1) 
                #20 //Do Nothing
          
            if(Trdy == 1'b0 && Transaction == 1'b1) begin
                Frame <= 1'b0;
                W2 <= Mem[5]; 
                Cbe <= 4'b0011;
            end
	    
        #20
            if (Stop) Transaction <= 1'b0; 
	        while (Trdy == 1'b1 && Transaction == 1'b1) 
                #20 //Do Nothing
            
            if(Trdy == 1'b0 && Transaction == 1'b1) begin
                Frame <= 1'b0;
                W2 <= Mem[6]; 
                Cbe <= 4'b0011;
            end
	        Frame <= 1'b1;
        #20
            if (Stop) Transaction <= 1'b0;
    	    while (Trdy == 1'b1 && Transaction == 1'b1) 
                 #20 //Do Nothing
         
            if(Trdy == 1'b0 && Transaction == 1'b1) begin
                Frame <= 1'b0;
                W2 <= Mem[7]; 
                Cbe <= 4'b0011;
            end
	        Irdy <= 1'b1;
	    #20
	        W2 <= 32'hzzzzzzzz;
	        Cbe <= 4'bzzzz;
    end
endmodule