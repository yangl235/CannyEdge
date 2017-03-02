// TESTBENCH
//isim set maxtraceablesize 320000
`timescale 1ns/10ps
`include "CannyEdge.v"

`define MODE_GAUSSIAN	0
`define MODE_SOBEL	1
`define MODE_NMS	2
`define MODE_HYSTERESIS	3

`define DATA_WIDTH	8
`define REG_ROW		5
`define REG_COL		5

`define REG_GAUSSIAN	0
`define REG_GRADIENT	1
`define REG_DIRECTION	2
`define REG_NMS		3
`define REG_HYSTERESIS	4

`define WRITE_REGX	0
`define WRITE_REGY	1
`define WRITE_REGZ	2

`define EOF		32'hFFFF_FFFF
`define NULL		0
`define LEN_HEADER	54   // 0x36

module stimulus;

	reg 		[2:0]		AddrRegRow;
	reg		[2:0]		AddrRegCol;
	reg				bWE, bCE;
	reg		[7:0]		InData;
	wire		[7:0]		OutData;
	
	reg				clk, rst_b;
	
	reg		[2:0]		OPMode;
	reg				bOPEnable;
	reg		[3:0]		dReadReg, dWriteReg;

   	CannyEdge CannyEdge_01(AddrRegRow, AddrRegCol, bWE, bCE, InData, OutData, OPMode, bOPEnable, dReadReg, dWriteReg, clk, rst_b);  // Connect to TOP MODULE

	// FILE I/O
	integer 			fileI, fileO, c, r;
	reg		[7:0]		FILE_HEADER[0:`LEN_HEADER-1];
   	reg    	[31:0] 	LHEADER;
	reg		[7:0]		memX[0:40000-1];		// 200x200
	reg		[7:0]		memXG[0:40000-1];		// 200x200
	reg		[7:0]		Gxy[0:40000-1];		// 200x200
	reg		[7:0]		Theta[0:40000-1];		// 200x200
	reg		[7:0]		bGxy[0:40000-1];		// 200x200

   	reg   	[7:0]   	memLine[0:600-1];
   	reg   	[31:0]   	HeaderLine[0:12];
   	reg   	[7:0]   	rG, rB, rR;
   
	parameter			dWidth = 200;
	parameter   		dHeight = 200;

	integer			i,j,k,l;
	integer			t;
   
	initial
	begin
	    	// MEMORY INIT // ----------------------------------------------------
   		for(i=0; i<40000; i=i+1)
		begin
			Gxy[i] = 0;		
			Theta[i] = 0;
			bGxy[i] = 0;
		end

		// READ function // ---------------------------------------------------
		//fileI = $fopen("cman_200.bmp","rb");
		fileI = $fopen("kodim22_200.bmp","rb");
		if (fileI == `NULL) $display("> FAIL: The file is not exist !!!\n");
		else	           $display("> SUCCESS : The file was read successfully.\n");
		
      		r = $fread(FILE_HEADER, fileI, 0, `LEN_HEADER); 
      		$display("$fread read %0d bytes: \n", r); 
      
		for(i=0; i<dHeight; i=i+1)
		begin
			for(j=0; j<dWidth; j=j+1)
			begin	
				c = $fgetc(fileI);
				c = $fgetc(fileI);
				memX[(dHeight-i-1)*dWidth+j] = $fgetc(fileI);
			end
		end
		$display("> memX[] Array is created.");			
		$display("> memXG[] Array is created.");			
		$display("> Gxy[] Array is created.");			
		$display("> Theta[] Array is created.");			
		$display("> bGxy[] Array is created.");
		$display("\n");		
		$fclose(fileI);
		
		// WRITE function // ---------------------------------------------------
		fileO = $fopen("0.OutputOrigin.bmp","wb");
      		// BMP HEADER
		for(i=1; i<3; i=i+1)
		begin
			$fwrite(fileO, "%c", FILE_HEADER[i]);
			//$display("[%d]:%x",i, FILE_HEADER[i]);
		end
	
      		// BMP HEADER for 200x200 size of image
      		HeaderLine[0]=32'h00_01_d4_f8;
      		HeaderLine[1]=32'h00_00_00_00;
      		HeaderLine[2]=32'h00_00_00_36;
      		HeaderLine[3]=32'h00_00_00_28;
      		HeaderLine[4]=32'h00_00_00_c8;
      		HeaderLine[5]=32'h00_00_00_c8;
      		HeaderLine[6]=32'h00_18_00_01;
      		HeaderLine[7]=32'h00_00_00_00;
      		HeaderLine[8]=32'h00_00_00_00;
      		HeaderLine[9]=32'h00_00_0b_12;
      		HeaderLine[10]=32'h00_00_0b_12;
      		HeaderLine[11]=32'h00_00_00_00;
      		HeaderLine[12]=32'h00_00_00_00;
		for(i=0; i<13; i=i+1) begin
			$fwrite(fileO, "%c", HeaderLine[i][7:0]);
         $fwrite(fileO, "%c", HeaderLine[i][15:8]);
         $fwrite(fileO, "%c", HeaderLine[i][23:16]);
         $fwrite(fileO, "%c", HeaderLine[i][31:24]);			
		end

      		for(i=0; i<dHeight; i=i+1)
		begin
		   	for(j=0; j<dWidth; j=j+1)
			begin
			   	$fwrite(fileO, "%c",memX[(dHeight-i-1)*dWidth+j]);////////////////////////////////////////////////////////////
			   	$fwrite(fileO, "%c",memX[(dHeight-i-1)*dWidth+j]);
			   	$fwrite(fileO, "%c",memX[(dHeight-i-1)*dWidth+j]);
			end
			
		end
		$fwrite(fileO, "%c",8'h00);
		$fwrite(fileO, "%c",8'h00);
		$display("> 0.OutputOrigin.bmp is created.\n");
		//$fclose(fileO);
	end	

   	// Initial Condition -------------------------------------------------------
   	initial
   	begin
       		clk = 1'b0;      // clock
       		rst_b = 1'b0;    // Enable : Reset
       		bWE = 1'b1;      // Canny Memory Operation (READ)
       		bCE = 1'b1;      // Disable : Canny Memory Operation
       		#40
       		rst_b = 1'b1;    // Disable : Reset
   	end

   	// Clock Generation ---------------------------------------------------------
   	always begin
      		#10 clk = !clk;
   	end
   
   	// MAIN Test Bench ----------------------------------------------------------
   	initial
   	begin
       	#100;
       	// NOISE REDUCTION ------------------------------------------------------
       	dReadReg = `REG_GAUSSIAN;
       	dWriteReg = `WRITE_REGX;
       	OPMode = `MODE_GAUSSIAN;
       	bOPEnable = 1'b1;
       	for(i=0; i<dHeight; i=i+1)
       	begin
           	for(j=0; j<dWidth; j=j+1)
           	begin
            	//$display("pixel[%d][%d] ...",i,j);
             	if(i<2 || j<2 || i>=dHeight-2 || j>=dWidth-2)
               	begin
                  	memXG[i*dWidth+j] = memX[i*dWidth+j];
               	end
               	else begin
                  	//send_5x5(i,j);
                  	bWE = 1'b0;      // WRITE MODE
                  	bCE = 1'b1;      // Disable Canny Memory Operation
                  	for(k=-2; k<=2; k=k+1)
                  	begin
                  		for(l=-2; l<=2; l=l+1)
                  		begin
                  			bCE = 1'b1;
                          		AddrRegRow = k+2;
                          		AddrRegCol = l+2;
                          		InData = memX[(i+k)*dWidth+(j+l)]; //memX[i+k][j+l];
                          		#20   bCE = 1'b0;
                          		#20   bCE = 1'b1;
                          		#20;
                      		end
                  	end  
                  	#20   bOPEnable = 1'b0;
                  	#100   bOPEnable = 1'b1;
                  	//read_pixel(i,j);
	            	bWE = 1'b1;      // READ MODE
	            	bCE = 1'b1;      // Disable Canny Memory Operation
        	      	#20   bCE = 1'b0; // Enable Canny Memory Operation
                		#20   memXG[i*dWidth+j] = OutData;   // Read Data
                  	#20   bCE = 1'b1; // Disable Canny Memory Operation
                  	#20;
               	end
     		end // of 'for(j=0; j<dWidth; j=j+1)'
     	end // of 'for(i=0; i<dHeight; i=i+1)'

	// WriteBMPOut(1); // ---------------------------------------------------
	fileO = $fopen("1.OutputGauss.bmp","wb");
      // BMP HEADER MAGIC NUMBER
	for(i=1; i<3; i=i+1) begin
		$fwrite(fileO, "%c", FILE_HEADER[i]);
	end
	for(i=0; i<13; i=i+1)	begin
		$fwrite(fileO, "%c", HeaderLine[i][7:0]);
      $fwrite(fileO, "%c", HeaderLine[i][15:8]);
      $fwrite(fileO, "%c", HeaderLine[i][23:16]);
      $fwrite(fileO, "%c", HeaderLine[i][31:24]);		
	end
      // Data
      for(i=0; i<dHeight; i=i+1)
	begin
		for(j=0; j<dWidth; j=j+1)
		begin
			$fwrite(fileO, "%c",memXG[(dHeight-i-1)*dWidth+j]);
			$fwrite(fileO, "%c",memXG[(dHeight-i-1)*dWidth+j]);
			$fwrite(fileO, "%c",memXG[(dHeight-i-1)*dWidth+j]);
		end
		
	end
	$fwrite(fileO, "%c",8'h00);
	$fwrite(fileO, "%c",8'h00);
	$display("> 1.OutputGauss.bmp is created.\n");
		
      #100;
	// Gradient & Direction ------------------------------------------------
      dWriteReg = `WRITE_REGX;
	OPMode = `MODE_SOBEL;
	bOPEnable = 1'b1;
      for(i=0; i<dHeight; i=i+1)
      begin
      	for(j=0; j<dWidth; j=j+1)
     		begin
			//$display("pixel[%d][%d] ...",i,j);
      		//send_3x3(i,j);
      		bWE = 1'b0;      // WRITE MODE
      		bCE = 1'b1;      // Disable Canny Memory Operation
			#20
           		for(k=-1; k<=1; k=k+1)
       		begin
           			for(l=-1; l<=1; l=l+1)
           			begin
	           			if(i+k<0 || j+l<0 || i+k>=dHeight || j+l>=dWidth)
        	            	begin
                	      		InData = 0;
                       		end
                       		else begin
                        		bCE = 1'b1;
                          		AddrRegRow = k+1;
	                        	AddrRegCol = l+1;
        	                  	InData = memXG[(i+k)*dWidth+(j+l)]; //memX[i+k][j+l];
                	          		#20   bCE = 1'b0;
                        		#20   bCE = 1'b1;
                          		#20;
                       		end
	                  end
        	      end  
               	#20   bOPEnable = 1'b0;
               	#100   bOPEnable = 1'b1;
	            dReadReg = `REG_GRADIENT;
        	      //read_pixel(i,j);
               	bWE = 1'b1;      // READ MODE
               	bCE = 1'b1;      // Disable Canny Memory Operation
	            #20   bCE = 1'b0; // Enable Canny Memory Operation
        	      #20   Gxy[i*dWidth+j] = OutData;   // Read Data
               	#20   bCE = 1'b1; // Disable Canny Memory Operation
               	#20;
	            dReadReg = `REG_DIRECTION;
        	      //read_pixel(i,j);
               	bWE = 1'b1;      // READ MODE
               	bCE = 1'b1;      // Disable Canny Memory Operation
	            #20   bCE = 1'b0; // Enable Canny Memory Operation
        	      #20   Theta[i*dWidth+j] = OutData;   // Read Data
               	#20   bCE = 1'b1; // Disable Canny Memory Operation
               	#20;
           	end // of 'for(j=0; j<dWidth; j=j+1)'
       end // of 'for(i=0; i<dHeight; i=i+1)'
       
	// WriteBMPOut(2); // ---------------------------------------------------
	fileO = $fopen("2.OutputGradient.bmp","wb");
      // BMP HEADER MAGIC NUMBER
	for(i=1; i<3; i=i+1) begin
		$fwrite(fileO, "%c", FILE_HEADER[i]);
	end
	for(i=0; i<13; i=i+1)	begin
		$fwrite(fileO, "%c", HeaderLine[i][7:0]);
      $fwrite(fileO, "%c", HeaderLine[i][15:8]);
      $fwrite(fileO, "%c", HeaderLine[i][23:16]);
      $fwrite(fileO, "%c", HeaderLine[i][31:24]);	
	end
	// Data
      for(i=0; i<dHeight; i=i+1)
	begin
	   	for(j=0; j<dWidth; j=j+1)
		begin
         $fwrite(fileO, "%c",Gxy[(dHeight-i-1)*dWidth+j]);
         $fwrite(fileO, "%c",Gxy[(dHeight-i-1)*dWidth+j]);
			$fwrite(fileO, "%c",Gxy[(dHeight-i-1)*dWidth+j]);
		end
	end
	$fwrite(fileO, "%c",8'h00);
	$fwrite(fileO, "%c",8'h00);
	$display("> 2.OutputGradient.bmp is created.\n");

	// WriteBMPOut(3); // ---------------------------------------------------
	fileO = $fopen("3.OutputDirection.bmp","wb");
	// BMP HEADER MAGIC NUMBER
	for(i=1; i<3; i=i+1) begin
		$fwrite(fileO, "%c", FILE_HEADER[i]);
	end
	for(i=0; i<13; i=i+1)	begin
		$fwrite(fileO, "%c", HeaderLine[i][7:0]);
      $fwrite(fileO, "%c", HeaderLine[i][15:8]);
      $fwrite(fileO, "%c", HeaderLine[i][23:16]);
      $fwrite(fileO, "%c", HeaderLine[i][31:24]);		
	end
      // Data
	for(i=0; i<dHeight; i=i+1)
	begin
		for(j=0; j<dWidth; j=j+1)
		begin
			rG=8'h00; rB=8'h00; rR=8'h00;
			// Edge Direction 90 = Edge Normal 0 Degree
			if(Theta[(dHeight-i-1)*dWidth+j]==90) begin
				rG = 8'hff;   rB = 8'h00;   rR = 8'hff;
			end
			// Edge Direction 135 = Edge Normal 45 Degree
			else if(Theta[(dHeight-i-1)*dWidth+j]==135) begin
				rG = 8'hff;   rB = 8'h00;   rR = 8'h00;
			end
			// Edge Direction 0 = Edge Normal 90 Degree
			else if(Theta[(dHeight-i-1)*dWidth+j]==0) begin
				rG = 8'h00;   rB = 8'hff;   rR = 8'h00;
			end
			// Edge Direction 45 = Edge Normal 135 Degree
			else begin //if(Theta[(dHeight-i-1)*dWidth+j]==90) begin
				rG = 8'h00;   rB = 8'h00;   rR = 8'hff;
			end
			 $fwrite(fileO, "%c",rB);
			 $fwrite(fileO, "%c",rG);
			 $fwrite(fileO, "%c",rR);
		end
	end
	   $fwrite(fileO, "%c",8'h00);
	   $fwrite(fileO, "%c",8'h00);
		$display("> 3.OutputDirection.bmp is created.\n");
		
	#100;
      // NON MAXIMUM SUPPRESSION ------------------------------------------------
	OPMode = `MODE_NMS;
      bOPEnable = 1'b1;
	for(i=0; i<dHeight; i=i+1)
      begin
      	for(j=0; j<dWidth; j=j+1)
	     	begin
            	for(t=0; t<2; t=t+1)
               	begin
                  	if(t==0)   dWriteReg = `WRITE_REGX;
                  	else       dWriteReg = `WRITE_REGY;
	                  //send_3x3(i,j);
        	          	bWE = 1'b0;      // WRITE MODE
                	  	bCE = 1'b1;      // Disable Canny Memory Operation
                  	#20
                  	for(k=-1; k<=1; k=k+1)
	                  begin
        	            	for(l=-1; l<=1; l=l+1)
                	      	begin
                        		if(i+k<0 || j+l<0 || i+k>=dHeight || j+l>=dWidth)
                        		begin
                        			InData = 0;
                        		end
	                  		else begin
        	                   		bCE = 1'b1;
                	             		AddrRegRow = k+1;
                        	     		AddrRegCol = l+1;
                             			if(t==0) InData = Gxy[(i+k)*dWidth+(j+l)];
                             			else     InData = Theta[(i+k)*dWidth+(j+l)];
                             			#20   bCE = 1'b0;
                             			#20   bCE = 1'b1;
	                             		#20;
        	                  	end
                	      	end
                  	end 
	   		end // of 'for(t=0; t<2; t=t+1)'
        	      #20   bOPEnable = 1'b0;
               	#100   bOPEnable = 1'b1;
               	dReadReg = `REG_NMS;
	               //read_3x3(i,j);
        	      bWE = 1'b1;      // READ MODE
               	bCE = 1'b1;      // Disable Canny Memory Operation
	            #20   bCE = 1'b0; // Enable Canny Memory Operation
        	      #20   Gxy[i*dWidth+j] = OutData;   // Read Data
               	#20   bCE = 1'b1; // Disable Canny Memory Operation
               	#20;
		end // of 'for(j=0; j<dWidth; j=j+1)'
      end // of 'for(i=0; i<dHeight; i=i+1)'
       
	// WriteBMPOut(4); // ---------------------------------------------------
	fileO = $fopen("4.OutputNMS.bmp","wb");
      //BMP HEADER MAGIC NUMBER
	for(i=1; i<3; i=i+1) begin
		$fwrite(fileO, "%c", FILE_HEADER[i]);
	end
	for(i=0; i<13; i=i+1)	begin
		$fwrite(fileO, "%c", HeaderLine[i][7:0]);
      $fwrite(fileO, "%c", HeaderLine[i][15:8]);
      $fwrite(fileO, "%c", HeaderLine[i][23:16]);
      $fwrite(fileO, "%c", HeaderLine[i][31:24]);	
	end
      // Data
	for(i=0; i<dHeight; i=i+1)
	begin
		for(j=0; j<dWidth; j=j+1)
		begin
         $fwrite(fileO, "%c",Gxy[(dHeight-i-1)*dWidth+j]);
			$fwrite(fileO, "%c",Gxy[(dHeight-i-1)*dWidth+j]);
			$fwrite(fileO, "%c",Gxy[(dHeight-i-1)*dWidth+j]);
		end
	end
	$fwrite(fileO, "%c",8'h00);
	$fwrite(fileO, "%c",8'h00);
	$display("> 4.OutputNMS.bmp is created.\n");
		
	#100;
      // HYSTERESIS THRESHOLDING -------------------------------------------
	OPMode = `MODE_HYSTERESIS;
      bOPEnable = 1'b1;
	for(i=0; i<dHeight; i=i+1)
      begin
           	for(j=0; j<dWidth; j=j+1)
	      begin
        	      for(t=0; t<3; t=t+1)
               	begin
                  	if(t==0)      dWriteReg = `WRITE_REGX;
                  	else if(t==1) dWriteReg = `WRITE_REGY;
	                  else          dWriteReg = `WRITE_REGZ;
        	          	//send_3x3(i,j);
                	  	bWE = 1'b0;      // WRITE MODE
                  	bCE = 1'b1;      // Disable Canny Memory Operation
                  	#20
	                  for(k=-1; k<=1; k=k+1)
        	          	begin
                	      	for(l=-1; l<=1; l=l+1)
                      		begin
                        		if(i+k<0 || j+l<0 || i+k>=dHeight || j+l>=dWidth)
                        		begin
                        			InData = 0;
	                  		end
        	            		else begin
                	             		bCE = 1'b1;
                        	     		AddrRegRow = k+1;
                             			AddrRegCol = l+1;
                             			if(t==0)       InData = Gxy[(i+k)*dWidth+(j+l)];
                             			else if(t==1)  InData = Theta[(i+k)*dWidth+(j+l)];
                             			else           InData = bGxy[(i+k)*dWidth+(j+l)];
	                             		#20   bCE = 1'b0;
        	                     		#20   bCE = 1'b1;
                	             		#20;
                        	  	end
                      		end
	                  end 	
        	      end // of 'for(t=0; t<3; t=t+1)'
               	#20   bOPEnable = 1'b0;
               	#100   bOPEnable = 1'b1;
	            dReadReg = `REG_HYSTERESIS;
	            //read_pixel(i,j);
        	      bWE = 1'b1;      // READ MODE
               	bCE = 1'b1;      // Disable Canny Memory Operation
               	#20   bCE = 1'b0; // Enable Canny Memory Operation
	            #20   bGxy[i*dWidth+j] = OutData;   // Read Data
        	      #20   bCE = 1'b1; // Disable Canny Memory Operation
               	#20;
 		end // of 'for(j=0; j<dWidth; j=j+1)'
      end // of 'for(i=0; i<dHeight; i=i+1)'
		
	// WriteBMPOut(5); // ---------------------------------------------------
	fileO = $fopen("5.OutputHysteresis.bmp","wb");
      // BMP HEADER MAGIC NUMBER
	for(i=1; i<3; i=i+1) begin
		$fwrite(fileO, "%c", FILE_HEADER[i]);
	end
	for(i=0; i<13; i=i+1)	begin
      $fwrite(fileO, "%c", HeaderLine[i][7:0]);
      $fwrite(fileO, "%c", HeaderLine[i][15:8]);
      $fwrite(fileO, "%c", HeaderLine[i][23:16]);
      $fwrite(fileO, "%c", HeaderLine[i][31:24]);
	end
      // Data
	for(i=0; i<dHeight; i=i+1)
	begin
		for(j=0; j<dWidth; j=j+1)
		begin
			if(bGxy[(dHeight-i-1)*dWidth+j]!=0)
			begin
				$fwrite(fileO, "%c",8'hff);
				$fwrite(fileO, "%c",8'hff);
				$fwrite(fileO, "%c",8'hff);
			end
			else
			begin
				$fwrite(fileO, "%c",8'h00);
	         $fwrite(fileO, "%c",8'h00);
	         $fwrite(fileO, "%c",8'h00);
			end
		end
	end
	$fwrite(fileO, "%c",8'h00);
	$fwrite(fileO, "%c",8'h00);
	$display("> 5.OutputHysteresis.bmp is created.\n");

      #3000 $stop;		// stop
	end // of initial
   
	// Dump Waveform ---------------------------------------------------
	//initial
	//begin
      //	$dumpflush;
     	//	$dumpfile ("wave.dump");
     	//	$dumpvars (0, stimulus);
   	//end
   
   	initial	// output to text
	begin
     		//$monitor($time, " OPMode:%d / dReadReg:%d/ dWriteReg:%d", OPMode, dReadReg, dWriteReg);
	end

   	//initial
   	//	$sdf_annotate("CannyEdge.sdf", CannyEdge_01);

endmodule
