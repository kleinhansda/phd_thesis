///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////								MACRO INSTRUCTIONS			 		        ///////////	
///////////////////////////////////////////////////////////////////////////////////////////////
/////////// To use this macro you need to open a (segmented) binary and the 		///////////
/////////// according original image data, then press Run, then follow instructions.///////////
///////////	It was designed to Analyze (shape & nuclei number) and register 		///////////
/////////// the movement of the dr pLLP in Timelapse data.							///////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////								OPTIMIZED FOR... 						    ///////////
///////////			- 40x microscopic data of the 								    ///////////
///////////			- zebrafish pLLP												///////////
/////////// 		- different labels							   					///////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////         			     David Kleinhans, 09.02.2017				    ///////////
///////////						  Kleinhansda@bio.uni-frankfurt.de				    ///////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////	
	
// ################### GET PARAMETERS & DIRECTORIES, SHOW DIALOGS ######################
	
// Start up / get Screen parameters to set location of Dialog Boxes
	cleanup();
	saveSettings();
	version = 1.53;
	header = "pLLP ANALYZER 3D v"+version+" "; 
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	print("started: "+ hour + ":" + minute);
	scrH = screenHeight();
		DiaH = scrH/5;
		InfoH = scrH/5;
		LogH = scrH/5;
	scrW = screenWidth();
		DiaW = scrW/6;
		InfoW = scrW/3;
		LogW = scrW/1;
	selectWindow("Log");
	setLocation(LogW,LogH);
//	Opening Dialog
	guideI();
	Dialog.create(header);
	Dialog.setLocation(DiaW,DiaH);
	labelsC1 = newArray("515", "-139");
	labelsC2 = newArray("H2BRFP", "Arl13b", " ");
	Zorder = newArray("Bottom to Top", "Top to Bottom");
		Dialog.setInsets(0,10,0);
		Dialog.addMessage("                   INPUT DATA DIMENSIONS");
	  	  	//Dialog.addCheckbox("Deconvolved", false);
	  	  	Dialog.addCheckbox("Multi Channel", false);
	  	  	Dialog.setInsets(0,20,0);
			Dialog.addChoice("C1:", labelsC1);
			Dialog.setInsets(0,20,0);
			Dialog.addChoice("C2:", labelsC2, " ");
			Dialog.setInsets(0,20,0);
			Dialog.addCheckbox("Swap Channel #", false);
			Dialog.addCheckbox("Time-Series", false);
		Dialog.setInsets(0,10,0);
		Dialog.addMessage("                           MACRO OPTIONS");
			Dialog.addCheckbox("Save metadata", false);
			Dialog.setInsets(0,20,0);
			Dialog.addChoice("Z order", Zorder);
			Dialog.addCheckbox("Register primordium", true);
			Dialog.addCheckbox("Reconstruct Ferret lines", true);
			Dialog.setInsets(0,20,0);
			Dialog.addMessage("3D Membrane Segmentation tolerance level:");
			Dialog.addSlider("Tol", 0, 50, 10);
			Dialog.addCheckbox("Measure Apical Constriction", false);
			Dialog.addSlider("µm", 0, 30, 5);
		Dialog.addMessage("Click 'OK' to proceed to input folder selection");
		//Dialog.addMessage("click 'HELP' for info");
		Dialog.show();
			//decon = Dialog.getCheckbox();
			multi = Dialog.getCheckbox();
			C1label = Dialog.getChoice();
			C2label = Dialog.getChoice();
			inv = Dialog.getCheckbox();
			ts = Dialog.getCheckbox();
			meta = Dialog.getCheckbox();
			rev = Dialog.getChoice();
			ferrr = Dialog.getCheckbox();
			reg = Dialog.getCheckbox();
			ros = Dialog.getCheckbox();
			tol = Dialog.getNumber();
			um = Dialog.getNumber();
	selectWindow(header);
	wait(100);
	run("Close");
//	CHOOSE DIRECTORIES
		dir = getDirectory("Choose directory");
		//output = getDirectory("Choose an output directory");
//	Batch Mode
		list = getFileList(dir);
//	##################################################################################################################
//	#################################################### ENTER LOOP ##################################################
//	##################################################################################################################
	for (i = 0; i < list.length; i++) {
		setBatchMode(true);
		roiManager("reset");
		//if (endsWith(list[i],".nd2")) {
		file = dir+list[i];
	// 	Import images + Split channels
		run("Bio-Formats Importer", "open=["+file+"] color_mode=Grayscale view=Hyperstack stack_order=XYCZT");
		ORG = getTitle();
		name = File.nameWithoutExtension;
		dir = File.directory;
		pardir = File.getParent(dir);
	//	Channel preparation
		if (rev == "Top to Bottom") {
			run("Reverse");
		}
		if (multi) {
			if (inv) {
				run("Arrange Channels...", "new=21");
			}
			wait(200);
			run("Split Channels");
			close(ORG);
		}
	//	Create subdirectories
			imgdir = pardir + File.separator + "(2) Image Analysis" + File.separator;
				File.makeDirectory(imgdir);
			datdir = pardir + File.separator + "(3) Data Analysis" + File.separator;
				File.makeDirectory(datdir);
			intensdir = pardir + File.separator + "(3) Data Analysis" + File.separator + "Intensities" + File.separator;
				File.makeDirectory(intensdir);
			datprimdir = pardir + File.separator + "(3) Data Analysis" + File.separator + "Primordia" + File.separator;
				File.makeDirectory(datprimdir);
			datrosdir = pardir + File.separator + "(3) Data Analysis" + File.separator + "Rosettes" + File.separator;
				File.makeDirectory(datrosdir);
			posdir = imgdir + name + File.separator;
				File.makeDirectory(posdir);
				if (multi) {
					C2dir = posdir + File.separator + "C2" + File.separator;
					File.makeDirectory(C2dir);
					C1dir = posdir + File.separator + "C1" + File.separator;
					File.makeDirectory(C1dir);
				}
			metadir = posdir + File.separator + "meta" + File.separator;
					File.makeDirectory(metadir);
			//resultsdir = pardir + File.separator + "Results" + File.separator;
					//File.makeDirectory(resultsdir);
	//	PRINT METADATA TO LOG WINDOW
		if (i==0) {
		print("Channels:");
			print("   C1: "+C1label);
			print("   C2: "+C2label);
		print("Macro options:");
			print("   pLLPANALYZER 3D version: v"+version);
			if (meta) {print("   Save metadata: true");} else {print("   Save metadata: false");}
			print("   Z Order: "+rev);
			if (reg) {print("   Primordium Registration: true");} else {print("   Primordium Registration: false");}
			if (ros) {print("   AC Measurement: true, "+um+" µm");} else {print("   AC Measurement: false");}
			print("   Segmentation Threshold: "+tol);
		print("Directories:");
			if (multi) {
			print("   Positions directory: "+posdir);
			print("   C1 directory: "+C1dir);
			print("   C2 directory: "+C2dir);
				} else {
			print("   Positions directory: "+posdir);
			}
			if (meta) {
			print("   Meta data: "+metadir);
			}
			print("   Results: "+datdir);
		}
	//	SAVE CHANNELS
		if (multi) {
		selectWindow("C1-"+ORG);
			//saveAs("Tiff", C1dir + name + "-C1.tif");
			ORGC1 = getTitle();
		selectWindow("C2-"+ORG);
			//saveAs("Tiff", C2dir + name + "-C2.tif");
			ORGC2 = getTitle();
		}
		resetMinAndMax();
	//	Get BioFormats
		n = nSlices();
		run("Bio-Formats Macro Extensions");
		if (multi) {
			id = C1dir+ORGC1; // get ID of first element of org.filelist(ofl)
		} else {
			id = dir+list[i];}
		Ext.setId(id);
		Ext.getSeriesName(seriesName);
		Ext.getImageCreationDate(creationDate);
  		Ext.getPixelsPhysicalSizeX(sizeX);
  		Ext.getPixelsPhysicalSizeY(sizeY);
  		Ext.getPixelsPhysicalSizeZ(sizeZ);
  		Ext.getPlaneTimingDeltaT(deltaT, 2);
  		Ext.getSizeC(sizeC);
  		if (i==0) {
  			print("Bio-Formats metadata:");
  			print("   X/Y Resolution: "+sizeX+"/"+sizeY + " µm");
  			print("   Z Resolution: "+sizeZ+" µm");
  			print("   T Resolution: "+deltaT+" s");
  			print("   Slices per Channel: "+n); 
  			setSlice(n/2);
  		}
  	  	
//	#################################################### PRE-PROCESSING ##################################################
		print("");
		print("################## Processing file "+name+" ##################");
//	######################### REGISTRATION PARAMETERS ########################
		print("Calculating registration parameters...");
		setSlice(n/2);
		resetMinAndMax();
	// 	create Z-projection to generate masks and do calculations on
		// projection=[Standard Deviation]");
		if (multi) {selectWindow(ORGC1);} else {selectWindow(ORG);}
		run("Z Project...", "projection=[Standard Deviation]");
		ZPSTD = getTitle();
		run("16-bit");
		run("Duplicate...", " ");
		ZPSTDD = getTitle();
		//projection=[Max Intensity]");
		if (multi) {selectWindow(ORGC1);} else {selectWindow(ORG);}
		run("Z Project...", "projection=[Max Intensity]");
		ZPMAX = getTitle();
	// Create Minimum Thresholded Mask
		selectWindow(ZPSTD);
		run("Gaussian Blur...", "sigma=8 scaled");
		setAutoThreshold("Minimum dark");
		run("Convert to Mask");
//	############################### ANGLE ##########################
		run("Analyze Particles...", "include add");
		rmcount = roiManager("count")-1;
		if(roiManager("count")==1) {
			roiManager("select", 0);
			List.setMeasurements;
			Angle = List.getValue("FeretAngle");
			if (Angle < 0) {Angle = Angle*(-1);}
			if (Angle > 90) {Angle = (180-Angle)*(-1);}
		} else {
			roiManager("select", 0);
			List.setMeasurements;
			X1Line = List.getValue("X");
			Y1Line = List.getValue("Y");
			roiManager("select", rmcount);
			List.setMeasurements;
			X2Line = List.getValue("X");
			Y2Line = List.getValue("Y");
			makeLine(X1Line, Y1Line, X2Line, Y2Line); 
			List.setMeasurements;
			Angle = List.getValue("Angle");
			if (Angle < -90) {Angle = Angle+180;}
			if (Angle > 90) {Angle = 180-Angle;}
		}
		print("   Rotation angle: "+Angle);
		selectWindow(ZPSTD);
		run("Select None");
		run("Rotate... ", "angle="+Angle+" grid=1 interpolation=Bilinear");
		if (meta) {
			print("   Saving "+ name + "RC_ZPSTD_Mask.tif");
			saveAs("Tiff", metadir + name + "_RC_ZPSTD_Mask.tif");
			ZPSTD = getTitle();
		}
//	########################## CROPPING Parameters ############################## 
		roiManager("reset");
		run("Select None");
		run("Make Binary");
		selectWindow(ZPSTD);
		run("Analyze Particles...", "size=150-10000 include exclude add");
		rmcount = roiManager("count")-1;
		if(roiManager("count")==1) {
			roiManager("select", 0);
		} else {
			roiManager("select", rmcount);
		}
		List.setMeasurements;
		XRect = List.getValue("X");
		YRect = List.getValue("Y");
		selectWindow(ZPSTD);
		getDimensions(width, height, channels, slices, frames);
		Regwidth = width;
		Regheight = 400; // change height of rect here
		toUnscaled(YRect);
		YRect = YRect-(Regheight/2);
		close(ZPSTD);
		print(" Cropping parameters");
		print("   Y Location: "+YRect);
	//print("   Height: "+height);
		print(" Registering "+ORG+"...");
		roiManager("reset");
		selectWindow(ZPMAX);
//	########################## Primordium Registration ############################## 
	// Rotate
		run("Rotate... ", "angle="+Angle+" grid=1 interpolation=Bilinear stack");
	// Crop
		makeRectangle(0, YRect, Regwidth, Regheight);
		run("Crop");
		print("   Saving "+ name + "RC_ZPMAX.tif");
		saveAs("Tiff", posdir + name + "_RC_ZPMAX.tif");
		ZPMAX = getTitle();
	// Create threshold mask to clear signals outside ROI
		run("Morphological Filters", "operation=Closing element=Disk radius=50");
		if (meta) {
			saveAs("Tiff", metadir + name + "_RC_ZPMAX_Close.tif");
		}
		ZPMAXClose = getTitle();
		close(ZPMAX);
		selectWindow(ZPMAXClose);
		run("Gaussian Blur...", "sigma=2 scaled");
		run("Duplicate...", " ");
		ZPMAXCloseMask = getTitle();
		//run("Enhance Contrast...", "saturated=0 equalize");
		run("Normalize Local Contrast", "block_radius_x=300 block_radius_y=20 standard_deviations=2 stretch");
		run("16-bit");
		run("Gaussian Blur...", "sigma=2 scaled");
		run("Normalize Local Contrast", "block_radius_x=300 block_radius_y=20 standard_deviations=2 stretch");
		run("16-bit");
		if (meta) {
			saveAs("Tiff", metadir + name + "_ZPMAX_RC_NLC.tif");
		}
		//setOption("BlackBackground", true);
		setAutoThreshold("Otsu dark");
		run("Convert to Mask");
		run("Invert");
	// save
		if (meta) {
			print("   Saving "+ name + "ZPMAX_RC_bin.tif");
			saveAs("Tiff", metadir + name + "_ZPMAX_RC_bin.tif");
		}
		ZPMAXCloseF = getTitle();
		run("Make Binary");
		roiManager("reset");
		run("Analyze Particles...", "include add");
	// Select most right Roi
		for (j=0 ; j<roiManager("count"); j++) {
			roiManager("select", j);
			run("Set Scale...", "distance=1 known=0.00005 pixel=1 unit=micron");
			List.setMeasurements;
  			//print(List.getList); // list all measurements
  			x = List.getValue("X");
    		roiManager("rename", x);
		}
		roiManager("Sort");
		run("Properties...", "channels=1 slices=1 frames=1 unit=micron pixel_width=[sizeX] pixel_height=[sizeY] voxel_depth=[sizeZ]");
		primroi = roiManager("count")-1; // since roi count starts from zero
		roiManager('select', primroi); // include selection of most right
	// Enlarge
		run("Enlarge...", "enlarge=10");
		run("Fit Ellipse");
		roiManager('update');
		roiManager('select', primroi);
		roiManager("save selected", metadir + name + ".zip");
		close(ZPMAXCloseMask);
		close(ZPMAXCloseF);
		close(ZPMAXClose);
		roiManager("reset");
//	############### Apical Constriction Detection ##############
		print("---- AC detection "+name+" ----    ");
		setBatchMode(true);
		if (ros) {
			selectWindow(ZPSTDD);
		// Rotate
			run("Rotate... ", "angle="+Angle+" grid=1 interpolation=Bilinear stack");
		// Crop Rectangle
			makeRectangle(0, YRect, Regwidth, Regheight);
			run("Crop");
			saveAs("Tiff", posdir + name + "_RC_ZPSTD.tif");
			ZPSTDD = getTitle();
		// Crop Primordium
		   	selectWindow(ZPSTDD);
		   	if (reg) {
		   		roiManager("Open", metadir + name + ".zip");
		   		roiManager("select", 0);
		   		//if (ts) {
		   			//} else {
		   			run("Crop");
		   			wait(100);
		   		run("Clear Outside");
		   	}
		   	roiManager("reset");
		   	roiManager("deselect");
		   	run("Select None");
		   	run("Rotate... ", "angle=0 grid=1 interpolation=Bilinear"); //necessary to get rid of selection outline
		// Morphological Filtering & Blurring
			//run("Morphological Filters", "operation=Closing element=Disk radius=50");
			run("Duplicate...", " ");
			ZPSTDDG = getTitle();
			run("Gaussian Blur...", "sigma=4 scaled");
		// Find Maxima
			run("8-bit");
		//	get normalised threshold value for point selection
			List.setMeasurements;
  			mean = List.getValue("Mean");
  			pointthresh = mean/2.5;
  			pointthresh = round(pointthresh);
			run("Find Maxima...", "noise="+pointthresh+" output=[Point Selection]");
			getSelectionCoordinates(xpoints, ypoints);
			//Array.reverse(ypoints);
			roiManager("Add");
			roiManager("save", metadir + name + "_Rosettes.zip");
		//	save Arrays, put xpoints in right order
			Rlx = lengthOf(xpoints);
			RX = Array.sort(xpoints);
			RX = Array.invert(RX);
		//	Fill ypoints with mean values of all y coordinates
			Array.getStatistics(ypoints, min, max, mean, stdDev);
			Array.fill(ypoints, mean);
			RY = ypoints;
			print("# AC Areas: "+Rlx);
		// Measure Intensities along horizontal line
			selectWindow(ZPSTDD);
			run("Rotate... ", "angle=0 grid=1 interpolation=Bilinear"); //necessary to get rid of selection outline
			getDimensions(width, height, channels, slices, frames);
			makeLine(0, mean, width, mean, 1);
			run("Clear Results");
			profile = getProfile();
			for (a=0; a<profile.length; a++) {
  				setResult("Value", a, profile[a]);
				updateResults();
			}
			saveAs("Measurements", intensdir + name + ".csv");
			//setBatchMode("exit and display");
			//waitForUser("HALT");
			run("Clear Results");
			if (isOpen("Results")) { 
			selectWindow("Results"); 
			run("Close");} 
		// Save capture
			//roiManager("reset");
			selectWindow(ZPSTDD);
			roiManager("deselect");
			run("Select None");
			roiManager("select", 0);
			run("Rotate... ", "angle=0 grid=1 interpolation=Bilinear"); //necessary to get rid of selection outline
			run("Point Tool...", "type=Dot color=Green size=[Extra Large] label counter=0");
			//run("Capture Image");
			saveAs("Tiff", posdir + name + "_RC_ZPSTD_Rosettes.tif");
			ZPSTDD = getTitle();
			roiManager("reset");
			close(ZPSTDDG);
		}
		close(ZPSTDD);
		// ############### C2 3D PROCESSING #################
		   	if (multi) {
		   		selectWindow(ORGC2);
		   // Rotate
		      	run("Rotate... ", "angle="+Angle+" grid=1 interpolation=Bilinear stack");
		   // Crop
		      	makeRectangle(0, YRect, Regwidth, Regheight);
		      	run("Crop");
		   // Save
		   	  	print("   Saving: "+name+"_-C2_RC.tif");
		      	saveAs("Tiff", C2dir + name + "-C2_RC.tif");
		       	ORGC2 = getTitle();
		   // label specific actions
		      	if (C2label=="H2BRFP") {
		      		run("Gaussian Blur 3D...", "x=3 y=3 z=3");
		      	}
		      	if (C2label=="Arl13b") {
		      		run("Z Project...", "projection=[Average Intensity]");
		      		AVG = getTitle();
		      		imageCalculator("Subtract stack", ORGC2, AVG);
		      		close(AVG);
		      		run("Gaussian Blur 3D...", "x=1 y=1 z=2");
		      	}
		   	  	saveAs("Tiff", C2dir + name + "-C2_RC_Pre-P.tif");
		   	  	ORGC2 = getTitle();;
		      	roiManager("select", 0);
		      	//run("Clear Outside", "stack");
		      	run("Crop");
		   	}
		// ############### C1 3D PROCESSING #################
		   if (multi) {
		   	selectWindow(ORGC1);
		   	} else {
		   		selectWindow(ORG);}
		   		run("Bleach Correction", "correction=[Simple Ratio] background=0");
		   		C1BC = getTitle();
		   		run("Properties...", "channels=1 slices="+n+" frames=1 unit=microns pixel_width="+sizeX+" pixel_height="+sizeY+" voxel_depth="+sizeZ);
		   		if (multi) {
		   		selectWindow(ORGC1);
		   		} else {
		   			selectWindow(ORG);}
			// Rotate
		   	selectWindow(C1BC);
		   	run("Rotate... ", "angle="+Angle+" grid=1 interpolation=Bilinear stack");
			// Crop
		   	makeRectangle(0, YRect, Regwidth, Regheight);
		   	run("Crop");
			// Save
		 	print("   Saving: "+name+"_-C1_RC.tif");
		   	if (multi) {
		   		saveAs("Tiff", C1dir + name + "-C1_RC.tif");
		   		} else {
		   		saveAs("Tiff", posdir + name + "_RC.tif");}
		   	C1BC = getTitle();  // Name ORG changed by saving
		   	C1F = getTitle();
		   	//run("Select None");
		   	roiManager("reset");
		   	roiManager("Open", metadir + name + ".zip");
		   	selectWindow(C1BC);
		   	if (reg) {
		   	roiManager("select", 0);
		   		if (ts) {
		   		} else {
		   		run("Crop");
		   		}
		   			run("Clear Outside", "stack");
		   		}
		   		if(C1label==515) {
		   			run("Morphological Filters (3D)", "operation=Closing element=Ball x-radius=2 y-radius=2 z-radius=2");
		   		} else { // C1Label==-139
		   			run("Duplicate...", "duplicate");
		   		}
		   C1F = getTitle();
		   setBatchMode("exit and display");
		   //setForegroundColor(65536, 65536, 65536);
		   //setBackgroundColor(0, 0, 0);

//	###############################################################################################
//	##################################### CREATING OBJECTS ########################################
//	###############################################################################################

// 	###################### MORPHOLOGICAL SEGMENTATION Membranes ###########################
			print("---- segmenting cells ----    ");
			selectWindow(C1F);
			setSlice(n/2);
			//run("Enhance Contrast", "saturated=0.35");
			run("Gaussian Blur 3D...", "x=1 y=1 z=1");
			resetMinAndMax();
			run("Morphological Segmentation");
			wait(2000);
			selectWindow("Morphological Segmentation");
			call("inra.ijpb.plugins.MorphologicalSegmentation.setInputImageType", "border");
			call("inra.ijpb.plugins.MorphologicalSegmentation.segment", "tolerance="+tol+"", "calculateDams=true", "connectivity=6"); //30ms exposure
			wait(90000);
			call("inra.ijpb.plugins.MorphologicalSegmentation.setDisplayFormat", "Catchment basins");
			call("inra.ijpb.plugins.MorphologicalSegmentation.createResultImage");
			//run("Properties...", "channels=1 slices="+n+" frames=1 unit=microns pixel_width=0.1625000 pixel_height=0.1625000 voxel_depth=0.4");
			run("Properties...", "channels=1 slices="+n+" frames=1 unit=microns pixel_width="+sizeX+" pixel_height="+sizeY+" voxel_depth="+sizeZ);
			if (meta) {
				if (multi) {
		   			saveAs("Tiff", C1dir + name + "-C1_RC_MS.tif");
		   			} else {
		   			saveAs("Tiff", posdir + name + "_RC_MS.tif");}
		   	}
			C1CB = getTitle();
			run("Grays");
			selectWindow("Morphological Segmentation");
			close();
			selectWindow(C1F);
			close();
// 	###################### CHANNEL 1: Cell Measurements and Maps ###########################
			selectWindow(C1CB);
			run("16-bit");
			run("3D Exclude Borders", "remove");
		   //save objects map
	   		if (multi) {
			saveAs("Tiff", C1dir + name + "-C1_RC_OMap.tif");
				} else {
				saveAs("Tiff", posdir + name + "_RC_OMap.tif");
			}
	   		OMap = getTitle();
			close(C1CB);
		// ######## Measure ferret coordinates at 5µm into prim and reconstruct f0 points in 3D #########
			selectWindow(OMap);
			getDimensions(width, height, channels, slices, frames);
			var done = false; 
			for(l=1; l<slices &&!done; l++) {
				setSlice(l);
				List.setMeasurements;
  				mean = List.getValue("Mean");
				if(mean > 10) {
					done = true;
					s1 = getSliceNumber();
					}
			}
			//print("s1 ="+s1+" n ="+n);
			if (s1 == n) { } else {
			run("Make Substack...", "  slices=" + ""+s1+"-"+slices);
			resliceOMap = getTitle();
			n = nSlices();
			run("Properties...", "channels=1 slices="+n+" frames=1 unit=microns pixel_width="+sizeX+" pixel_height="+sizeY+" voxel_depth="+sizeZ);
	   		//selectWindow(R);
	   		getDimensions(width, height, channels, slices, frames);
			newImage("FerretOMap", "8-bit black", width, height, slices);
			run("Properties...", "channels=1 slices="+n+" frames=1 unit=microns pixel_width="+sizeX+" pixel_height="+sizeY+" voxel_depth="+sizeZ);
			FerretOMap = getTitle();
			run("3D Manager");
			selectWindow(resliceOMap);
			Ext.Manager3D_AddImage();
			Ext.Manager3D_Count(nb); //get number of objects
			selectWindow(FerretOMap);
			Ext.Manager3D_MonoSelect();
			for(k=0; k<nb; k++) {
				showStatus("Processing "+k+"/"+nb);
				Ext.Manager3D_Measure3D(k,"Feret",ferr);
				Ext.Manager3D_GetName(k,obj);
				Ext.Manager3D_Feret1(k,fx0,fy0,fz0);
				//print("Object nb:"+name+" feret1: "+fx0+" "+fy0+" "+fz0);
				toScaled(fx0);
				toScaled(fy0);
				toScaled(fz0);
				Ext.Manager3D_Feret2(k,fx1,fy1,fz1);
				toScaled(fx1);
				toScaled(fy1);
				toScaled(fz1);
				//print("Object nb:"+name+" feret2: x="+fx1+" y="+fy1+" z="+fz1);
				//run("3D Draw Line", "size_x=&width size_y=&height size_z=&slices x0=&fx0 y0=&fy0 z0=&fz0 x1=&fx1 y1=&fy1 z1=&fz1 thickness=1.000 value=255 display=Overwrite ");
				//run("3D Draw Line", "size_x=&width size_y=&height size_z=&slices x0=&fx0 y0=&fy0 z0=&fz0 x1=&fx1 y1=&fy1 z1=&fz1 thickness=1.000 value=&ferr display=Overwrite ");
				//run("3D Draw Shape", "size="+width+","+height+","+slices+" center="+fx1+","+fy1+","+fz1+" radius=1,1,1 vector1=1,1,1 vector2=1,1,1 res_xy=1.000 res_z=1.000 unit=pix value=&val display=Overwrite ");
				run("3D Draw Shape", "size="+width+","+height+","+slices+" center="+fx0+","+fy0+","+fz0+" radius="+sizeX+","+sizeY+","+sizeZ+" vector1=1.0,0.0,0.0 vector2=0.0,1.0,0.0 res_xy="+sizeX+" res_z="+sizeZ+" unit=microns value=255 display=Overwrite ");
				//run("3D Draw Shape", "size="+width+","+height+","+slices+" center="+fx1+","+fy1+","+fz1+" radius=1,1,1 vector1=1.0,0.0,0.0 vector2=0.0,1.0,0.0 res_xy=1 res_z=1 unit=pix value=255 display=Overwrite");
				setSlice(slices/2);
			}
			//run("3D Draw Shape", "size="+width+","+height+","+slices+" center="+fx1+","+fy1+","+fz1+" radius=1,1,1 vector1=1,1,1 vector2=1,1,1 res_xy=1.000 res_z=1.000 unit=pix value=&val display=Overwrite ");
			run("Z Project...", "projection=[Max Intensity]");
			saveAs("Tiff", posdir + name + "_RC_OMap_Ferret0PointMax" + ".tif");
			FerretOMapMax = getTitle();
			close(FerretOMapMax);
			Ext.Manager3D_Reset();
			Ext.Manager3D_Close();
			selectWindow(FerretOMap);
			run("Enhance Contrast", "saturated=0.35");
			saveAs("Tiff", posdir + name + "_RC_OMap_Ferret0Point" + ".tif");
			FerretSOMap = getTitle();
			run("Enhance Contrast...", "saturated=0.3 equalize process_all");
			//setBatchMode("exit and display");
			//waitForUser("YO!");
		// ######## get coordinates or feret lines @ .25% of the stack size ########
			Zslice = um/sizeZ;
			round(Zslice);
			setSlice(Zslice);
			// Duplicate and save for projection
			run("Duplicate...", " ");
			run("Label...", "format=Text starting=0 interval=[] x=5 y=20 font=18 text=[Z "+Zslice+"] range=1-1");
			saveAs("Tiff", metadir + name + "Prim_FerrD" + ".tif");
			FerretSDOMap = getTitle();
			//close(FerretSD);
			selectWindow(FerretSOMap);
		// check if there are actually any points
			List.setMeasurements; 
  			mean = List.getValue("Mean");
  			if (mean > 0) {
  				//run("Find Maxima...", "noise=7 output=List");
  				//saveAs("results", datdir + name + "_ACXY" + ".txt");
  				//results();
				run("Find Maxima...", "noise=0 output=[Point Selection]");
				saveAs("XY Coordinates", datdir + "XY" + "_Prim" + name + ".txt");
				getSelectionCoordinates(xpoints, ypoints);
				FX = xpoints;
				FY = ypoints;
				Ferrlx = lengthOf(xpoints)-1;
				selectWindow(FerretSOMap);
				run("Select None");
				close(FerretSDOMap);
  				} // if(mean>0) 
			}  //if n == nR
			close(FerretOMap);
			close(FerretSOMap);
			close(resliceOMap);
			close(FerretOMapMax);
	   		//saveAs("results", datdir + "ApicalPoints_" + name + ".txt");
	   		//results();

			
			// ######## Crop around rosette center positions #########
			if (ros){
	   		print("---- registering regions of AC ----    ");
	   		// create directory for Rosette images
	   		//rosdir = posdir + name + File.separator;
			//File.makeDirectory(posdir);
			radius=80; 
			if (Rlx > 0) {
				results(); // see functions
	   			for (j = 0; j < Rlx; j++) { //RosN = Rosette Number
	   				print("    -- Rosette #"+j+" --    ");
	   				pos = j+1;
	   		// ######## Create directory ######## 
	   				rosdir = imgdir + name + File.separator + "R" + pos + File.separator;
					File.makeDirectory(rosdir);
			// ######## Crop Rosette ########
	   				selectWindow(OMap);
	   				run("Duplicate...", "duplicate");
	   				OMapD = getTitle();
	   				makeOval(RX[j]-radius, RY[j]-radius, 2*radius, 2*radius); 
	   				run("Crop");
	   				run("3D Exclude Borders", " "); // Z already removed
	   				selectWindow("Objects_removed");
	   				n = nSlices();
	   				run("Properties...", "channels=1 slices="+n+" frames=1 unit=microns pixel_width="+sizeX+" pixel_height="+sizeY+" voxel_depth="+sizeZ);
	   				saveAs("Tiff", rosdir + name + "_RC_OMap" + "_R" + pos + ".tif");
	   				R = getTitle();
	   				//close(R);
	   				close(OMapD);
	   		// ######## crop single cells and save to new dir ########
	   				selectWindow(R);
					run("3D Manager");
					//selectWindow(R);
					Ext.Manager3D_AddImage();
					Ext.Manager3D_Count(nb); //get number of objects
					Ext.Manager3D_MultiSelect();
					for(k=0; k<nb; k++) {
						selectWindow(R);
						run("Duplicate...", "duplicate");
						if (k>0) {Ext.Manager3D_AddImage();}
						Ext.Manager3D_GetName(k,obj);
						Ext.Manager3D_SelectAll();
						Ext.Manager3D_Select(k);
						Ext.Manager3D_Erase();
						run("Enhance Contrast...", "saturated=0.3 equalize process_all");
						run("8-bit");
						roscell = getTitle();
						run("Crop Label", "label=255 border=10");
						nCrop = nSlices();
						run("Properties...", "channels=1 slices="+nCrop+" frames=1 unit=microns pixel_width="+sizeX+" pixel_height="+sizeY+" voxel_depth="+sizeZ);
						saveAs("Tiff", rosdir + name + "_R" + pos + "_" + obj + ".tif");
						roscellcrop = getTitle();
						run("3D Project...", "projection=[Brightest Point] axis=Y-Axis slice="+sizeZ+" initial=0 total=360 rotation=10 lower=1 upper=255 opacity=50 surface=100 interior=50 interpolate");
						saveAs("Tiff", rosdir + name + "_R" + pos + "_3D_" + obj + ".tif");
						roscell3D = getTitle();
						close(roscellcrop);
						close(roscell);
						close(roscell3D);
						Ext.Manager3D_Reset();
					}
					Ext.Manager3D_Close();
	   		// ### MEASURE SINGLE CELLS ###
	   				selectWindow(R);
	   				run("3D Manager Options", "volume surface compactness fit_ellipse 3d_moments integrated_density mean_grey_value std_dev_grey_value mode_grey_value feret minimum_grey_value maximum_grey_value centroid_(pix) centroid_(unit) distance_to_surface centre_of_mass_(pix) centre_of_mass_(unit) bounding_box radial_distance surface_contact closest exclude_objects_on_edges_xy exclude_objects_on_edges_z sync distance_between_centers=10 distance_max_contact=1.80");
	   				run("3D Manager");
	   				Ext.Manager3D_AddImage();
	  				Ext.Manager3D_DeselectAll(); // to refresh RoiManager
	   				Ext.Manager3D_Measure();
	   				Ext.Manager3D_SaveResult("M", datrosdir + name + "cells_R" + pos + ".csv");
	   				Ext.Manager3D_CloseResult("M");
	   				Ext.Manager3D_Reset();
	   				Ext.Manager3D_Close();
	   				selectWindow(R);
	   				run("Duplicate...", "duplicate");
	   				RD = getTitle();
	   				run("8-bit");
	   		// ### MEASURE WHOLE ROSETTE ###
					run("Enhance Contrast...", "saturated=0 equalize process_all");
					run("Dilate", "stack");
					run("Erode", "stack");
					//run("Fill Holes", "stack");
					run("3D Manager Options", "volume surface compactness fit_ellipse 3d_moments integrated_density mean_grey_value std_dev_grey_value mode_grey_value minimum_grey_value maximum_grey_value centroid_(pix) centroid_(unit) distance_to_surface centre_of_mass_(pix) centre_of_mass_(unit) bounding_box radial_distance surface_contact closest exclude_objects_on_edges_xy exclude_objects_on_edges_z sync distance_between_centers=10 distance_max_contact=1.80");
					run("3D Manager");
					Ext.Manager3D_Segment(128, 255);
					RP = getTitle();
					Ext.Manager3D_AddImage();
					Ext.Manager3D_Count(nb_obj);
					if (nb_obj > 1) {
						Ext.Manager3D_SelectAll();
						Ext.Manager3D_Merge();
					}
					Ext.Manager3D_Measure();
					Ext.Manager3D_SaveResult("M", datrosdir + name + "whole_R" + pos + ".csv");
       				Ext.Manager3D_CloseResult("M");
       				Ext.Manager3D_Reset();
					Ext.Manager3D_Close();
					close(RP);
					close(RD);
	   		// ### MEASURE APICAL CONSTRICTION ###
	   		// ######## Draw Feret lines ########
	   				//	Create substack
	   				selectWindow(R);
					getDimensions(width, height, channels, slices, frames);
					var done = false; 
					for(l=1; l<slices &&!done; l++) {
						setSlice(l);
						List.setMeasurements;
  						mean = List.getValue("Mean");
						if(mean > 10) {
							done = true;
							s1 = getSliceNumber();
							}
					}
					//nR = nSlices();
					//print("s1 ="+s1+" n ="+n);
					if (s1 == n) { } else {
					run("Make Substack...", "  slices=" + ""+s1+"-"+slices);
					Rreslice = getTitle();
					n = nSlices();
					run("Properties...", "channels=1 slices="+n+" frames=1 unit=microns pixel_width="+sizeX+" pixel_height="+sizeY+" voxel_depth="+sizeZ);
	   				//selectWindow(R);
	   				getDimensions(width, height, channels, slices, frames);
					newImage("Ferret", "8-bit black", width, height, slices);
					Ferret = getTitle();
					run("3D Manager");
					selectWindow(Rreslice);
					Ext.Manager3D_AddImage();
					Ext.Manager3D_Count(nb); //get number of objects
					selectWindow(Ferret);
					Ext.Manager3D_MonoSelect();
					for(k=0; k<nb; k++) {
						showStatus("Processing "+k+"/"+nb);
						Ext.Manager3D_Measure3D(k,"Feret",ferr);
						Ext.Manager3D_GetName(k,obj);
						Ext.Manager3D_Feret1(k,fx0,fy0,fz0);
						//print("Object nb:"+name+" feret1: "+fx0+" "+fy0+" "+fz0);
						Ext.Manager3D_Feret2(k,fx1,fy1,fz1);
						//print("Object nb:"+name+" feret2: x="+fx1+" y="+fy1+" z="+fz1);
						//run("3D Draw Line", "size_x=&width size_y=&height size_z=&slices x0=&fx0 y0=&fy0 z0=&fz0 x1=&fx1 y1=&fy1 z1=&fz1 thickness=1.000 value=255 display=Overwrite ");
						run("3D Draw Line", "size_x=&width size_y=&height size_z=&slices x0=&fx0 y0=&fy0 z0=&fz0 x1=&fx1 y1=&fy1 z1=&fz1 thickness=1.000 value=&ferr display=Overwrite ");
						setSlice(slices/2);
						}
					Ext.Manager3D_Reset();
					Ext.Manager3D_Close();
					selectWindow(Ferret);
					saveAs("Tiff", rosdir + name + "_RC_OMap" + "_R" + pos + "_FerretLines" + ".tif");
					FerretS = getTitle();
					run("Enhance Contrast...", "saturated=0.3 equalize process_all");
				// ######## get coordinates or feret lines @ .25% of the stack size ########
					Zslice = um/sizeZ;
					round(Zslice);
					setSlice(Zslice);
						// Duplicate and save for projection
						run("Duplicate...", " ");
						if (j == 0) {
							run("Label...", "format=Text starting=0 interval=[] x=5 y=20 font=18 text=[Z "+Zslice+"] range=1-1");
						}
						saveAs("Tiff", metadir + "R" + pos + "_" + name + "_FerrD" + ".tif");
						FerretSD = getTitle();
						//close(FerretSD);
					selectWindow(FerretS);
						// check if there are actually any points
						List.setMeasurements; 
  						mean = List.getValue("Mean");
  						if (mean > 0) {
  							//run("Find Maxima...", "noise=7 output=List");
  							//saveAs("results", datdir + name + "_ACXY" + ".txt");
  							//results();
							run("Find Maxima...", "noise=0 output=[Point Selection]");
							saveAs("XY Coordinates", datdir + "XY" + "_R" + pos + name + ".txt");
							getSelectionCoordinates(xpoints, ypoints);
							FX = xpoints;
							FY = ypoints;
							Ferrlx = lengthOf(xpoints)-1;
							selectWindow(FerretS);
							run("Select None");
							// ####### Fit circle #######
							if (Ferrlx > 2) {
								selectWindow(FerretSD);
								run("Find Maxima...", "noise=0 output=[Single Points]");
								FerretSDD = getTitle();
								run("Points from Mask");
								run("Fit Ellipse");
								//run("Set Measurements...", "area bounding fit shape nan redirect=None decimal=2");
								run("Set Measurements...", "bounding fit shape feret's nan redirect=None decimal=2");
								run("Measure");
								close(FerretSDD);
							}
						close(FerretSD);
						//Dist = newArray(Ferrlx);
						Dist = newArray(0); // Array will be concatenated in for loop
						for (m = 0; m < Ferrlx ; m++) {
							if (m==0) {Ferrlx = Ferrlx;} else {Ferrlx = Ferrlx-1;}
								for (n = 0; n < Ferrlx; n++) {
									if (n==0) {posi = n;} else {posi = n+1;}
									ED = sqrt((FX[Ferrlx]-FX[Ferrlx-posi])*(FX[Ferrlx]-FX[Ferrlx-posi])+(FY[Ferrlx]-FY[Ferrlx-posi])*(FY[Ferrlx]-FY[Ferrlx-posi]));
										if (ED > 0){
										Dist = Array.concat(Dist, ED);
										}
								}
						}
						Array.getStatistics(Dist, min, max, mean, stdDev);
						setResult("Rosette", j, "R"+pos);
						setResult("Min", j, min);
						setResult("Max", j, max);
						setResult("Mean", j, mean);
						setResult("StdDev", j, stdDev);
						updateResults();
  						} // if(mean>0) 
					}  //if n == nR
					close(R);
					close(Ferret);
					close(FerretS);
					close(Rreslice);
	   			} // for loop
				rn = nResults();
					for (o = 1; o < rn ; o++) {
					res = rn-o;
					//print("row ="+res);
					rosi = getResult("Rosette", res);
						if (rosi == 0) {
						IJ.deleteRows(res,res);
						}
					}
				updateResults();
	   			saveAs("results", datdir + "ACM_" + name + ".txt");
	   			results();
	   		}
	   }
	   selectWindow(OMap);
	   getDimensions(width, height, channels, slices, frames);
	 // MEASURE SINGLE CELLS OF WHOLE PRIM
	   run("3D Manager Options", "volume surface compactness fit_ellipse 3d_moments integrated_density mean_grey_value std_dev_grey_value mode_grey_value feret minimum_grey_value maximum_grey_value centroid_(pix) centroid_(unit) distance_to_surface centre_of_mass_(pix) centre_of_mass_(unit) bounding_box radial_distance surface_contact closest exclude_objects_on_edges_xy exclude_objects_on_edges_z sync distance_between_centers=10 distance_max_contact=1.80");
	   run("3D Manager");
	   Ext.Manager3D_AddImage();
	   Ext.Manager3D_DeselectAll(); // to refresh RoiManager
	   Ext.Manager3D_Measure();
	   Ext.Manager3D_SaveResult("M", datprimdir + name + "_cells" + ".csv");
	   Ext.Manager3D_CloseResult("M");
	   Ext.Manager3D_Reset();
	   Ext.Manager3D_Close();
	   if (ferrr) {
	   		run("Clear Results");
	   		selectWindow(OMap);
	   		getDimensions(width, height, channels, slices, frames);
	   		run("3D Manager");
			Ext.Manager3D_AddImage();
			Ext.Manager3D_Count(nb); //get number of objects
			fxarray = newArray(nb);
			fyarray = newArray(nb);
			fzarray = newArray(nb);
	   		Ext.Manager3D_MonoSelect();
	   		for(k=0; k<nb; k++) {
				showStatus("Processing "+k+"/"+nb);
				Ext.Manager3D_Measure3D(k,"Feret",ferr);
				Ext.Manager3D_GetName(k,obj);
				Ext.Manager3D_Feret1(k,fx0,fy0,fz0);
				Ext.Manager3D_Feret2(k,fx1,fy1,fz1);
				fx = fx1-fx0;
				fy = fy1-fy0;
				fz = fz1-fz0;
	   		    fxarray[k] = fx;
	   		    fyarray[k] = fy;
	   		    fzarray[k] = fz;
	   		}
	   		Ext.Manager3D_Reset();
			Ext.Manager3D_Close();
	   		Array.getStatistics(fxarray, min, max, mean, stdDev);
	   		fxmax = max*2;
	   		Array.getStatistics(fyarray, min, max, mean, stdDev);
	   		fymax = max*2;
	   		Array.getStatistics(fzarray, min, max, mean, stdDev);
	   		fzmax = max*2;
	   		//getDimensions(width, height, channels, slices, frames);
			newImage("FerretNorm", "8-bit black", fxmax, fymax, slices);
			wait(200);
			selectWindow("FerretNorm");
			FerretNorm = getTitle();
			//waitForUser("Is this the ferret image?");
			selectWindow(OMap);
			//waitForUser("Is this the OMap image?");
			run("3D Manager");
			Ext.Manager3D_AddImage();
			Ext.Manager3D_Count(nb); //get number of objects
			selectWindow(FerretNorm);
			//waitForUser("Is this the ferret image?");
			Ext.Manager3D_MonoSelect();
			for(k=0; k<nb; k++) {
				showStatus("Processing "+k+"/"+nb);
				Ext.Manager3D_Measure3D(k,"Feret",ferr);
				Ext.Manager3D_GetName(k,obj);
				Ext.Manager3D_Feret1(k,fx0,fy0,fz0);
				//print("Object nb:"+name+" feret1: "+fx0+" "+fy0+" "+fz0);
				Ext.Manager3D_Feret2(k,fx1,fy1,fz1);
				//print("Object nb:"+name+" feret2: x="+fx1+" y="+fy1+" z="+fz1);
				setResult("obj", k, obj);
				setResult("fx0", k, fx0);
				setResult("fy0", k, fy0);
				setResult("fz0", k, fz0);
				setResult("fx1", k, fx1);
				setResult("fy1", k, fy1);
				setResult("fz1", k, fz1);
				fx1 = (fx1-fx0)+(fxmax/2);
				fx0 = fxmax/2;
				fy1 = (fy1-fy0)+(fymax/2);
				fy0 = fymax/2;
				fz1 = (fz1-fz0)+(fzmax/2);
				fz0 = 0;
				//run("3D Draw Line", "size_x=&width size_y=&height size_z=&slices x0=&fx0 y0=&fy0 z0=&fz0 x1=&fx1 y1=&fy1 z1=&fz1 thickness=1.000 value=255 display=Overwrite ");
				//run("3D Draw Line", "size_x=&width size_y=&height size_z=&slices x0= y0=&fy0 z0=&fz0 x1=&fx1 y1=&fy1 z1=&fz1 thickness=1.000 value=&ferr display=Overwrite ");
				run("3D Draw Line", "size_x=&width size_y=&height size_z=&slices x0=&fx0 y0=&fy0 z0=0 x1=&fx1 y1=&fy1 z1=&fz1 thickness=1.000 value=255 display=Overwrite ");
				setSlice(slices/2);
				}
			Ext.Manager3D_Reset();
			Ext.Manager3D_Close();
			selectWindow(FerretNorm);
			//waitForUser("Is this the ferret image?");
			saveAs("Tiff", posdir + name + "_RC_OMap" + "_FerretLinesPrimNorm" + ".tif");
			FerretNorm = getTitle();
			close(FerretNorm);
			if (isOpen("Results")) { 
				selectWindow("Results"); 
				run("Close");
				} 
			saveAs("results", datdir + name + "_ferretcords" + ".txt");
			//run("Enhance Contrast...", "saturated=0.3 equalize process_all");
	   }
	   selectWindow(OMap);
	   //waitForUser("Is this the OMap image?");
	   run("8-bit");
    // CREATE COMPOSITE
       selectWindow(C1BC);
       	run("8-bit");//run("Crop");
	   	run("Merge Channels...", "c2="+OMap+" c4="+C1BC+" create keep");
	   	close(C1BC);
	   	selectWindow("Composite");
	   	if (multi) {
	   	saveAs("Tiff", C1dir + name + "-C1_RC_OMap_Composite.tif");
			} else {
			saveAs("Tiff", posdir + name + "_RC_OMap_Composite.tif");
		}
	   close();
	// MEASURE MERGED CELLS / WHOLE PRIM
		selectWindow(OMap);
		run("Enhance Contrast...", "saturated=0 equalize process_all");
		run("Dilate", "stack");
		run("Erode", "stack");
		//run("Fill Holes", "stack");
		//Ext.Manager3D_AddImage();
		run("3D Manager Options", "volume surface compactness fit_ellipse 3d_moments integrated_density mean_grey_value std_dev_grey_value mode_grey_value minimum_grey_value maximum_grey_value centroid_(pix) centroid_(unit) distance_to_surface centre_of_mass_(pix) centre_of_mass_(unit) bounding_box radial_distance surface_contact closest exclude_objects_on_edges_xy exclude_objects_on_edges_z sync distance_between_centers=10 distance_max_contact=1.80");
		run("3D Manager");
		Ext.Manager3D_Segment(128, 255);
		OMapP = getTitle();
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Count(nb_obj);
		if (nb_obj > 1) {
			Ext.Manager3D_SelectAll();
			Ext.Manager3D_Merge();
		}
		Ext.Manager3D_Measure();
		Ext.Manager3D_SaveResult("M", datprimdir + name + "_whole" + ".csv");
       	Ext.Manager3D_CloseResult("M");
       	Ext.Manager3D_Reset();
		Ext.Manager3D_Close();
		close(OMapP);
// 	###################### C2 clearing + 3D Maxima finder ###########################
	if (multi) {
	setBatchMode(true);
	selectWindow(OMap);
		if (C2label=="H2BRFP") {
			sliceclear();
		}
		if (C2label=="Arl13b") {
			primseg();
			//selectWindow(indiv+"-3Dseg");
			close(); // close -3Dseg
			wait(200);
			close(OMap);
			selectWindow(name + "-C2_RC_prim-seg.tif");
			//waitForUser("HALT");
			OMap = getTitle();
			sliceclear();
		}
	selectWindow(ORGC2);
	saveAs("Tiff", C2dir + name + "-C2_RC_clear.tif");
	C2cleared = getTitle();
	run("8-bit");
	wait(200);
	selectWindow(C2cleared);
	run("8-bit");
	wait(200);
	close(OMap);
	// 	create composite
		run("Merge Channels...", "c1="+SMap+" c2="+C2cleared+" create keep");
		selectWindow("Composite");
		saveAs("Tiff", C2dir + name + "-C2_RC_prim-seg_clear_SMap_Composite.tif");
		close();
		close(SMap);
		if (C2label == "Arl13b") {
		// 	3D Maxima finder
			selectWindow(C2cleared);
			run("3D Maxima Finder", "radiusxy=5 radiusz=10 noise=30");
			selectWindow("peaks");
			saveAs("Tiff", C2dir + name + "-C2_RC_prim-seg_peaks.tif");
			close();
			selectWindow("Results");
			saveAs("results", datdir + name + "_3DMngr_3DMax_results" + ".txt");
		}
		//waitForUser("HALT");
		results(); // see functions
		setBatchMode("exit and display");
		close(C2cleared);
    	} // if (multi)
    	// CLOSE everything
	closewindows(); // see functions
	} // list.length 
//}
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	print("finished: "+ hour + ":" + minute);
	selectWindow("Log");  //select Log-window 
	saveAs("Text", pardir + "Log_" + version + year+"0"+month+"0"+dayOfMonth+".txt"); 
	if (nImages>0) { 
          selectImage(nImages); 
          close(); 
      } 
	setBatchMode(false);
	if(getBoolean("DONE! :).\nOpen output directory?"))
    call("bar.Utils.revealFile", pdir);
    restoreSettings();

// ==============================================================================================================================================
// ############################################################# FUNCTIONS ######################################################################
// ==============================================================================================================================================
function cleanup(){
		if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");} 
		if (isOpen("ROI Manager")){
		selectWindow("ROI Manager");
		run("Close");}
	run("Close All");
	}

function results () {
	   	  if (isOpen("Results")) { 
          selectWindow("Results"); 
          run("Close"); 
    	  }
	}
function closewindows () {
	//if (isOpen(SMap)) {  
		//selectWindow(SMap);
		//close();} 
	if (isOpen(ORG)) { 
		selectWindow(ORG);
		close(); }
	if (isOpen(OMap)) {  
		selectWindow(OMap);
		close();} 
}

function allroi () {
	array1 = newArray("0");; 
		for (i=1;i<roiManager("count");i++){ 
        	array1 = Array.concat(array1,i); 
		} 
	//print("selecting all rois");
	roiManager("select", array1); 
	}

function sliceclear() {
		for (j=1; j<=n; j++) {
		selectWindow(OMap);
		roiManager("reset");
		setSlice(j);
		run("Analyze Particles...", "include add slice");
		if (roiManager("count")==0) {
			selectWindow(ORGC2);
			setSlice(j);
			makeRectangle(0, 0, width, height);
			run("Cut");
		}
		if (roiManager("count")==1) {
			selectWindow(ORGC2);
			setSlice(j);
			allroi();
			wait(200);
			run("Clear Outside", "slice");
		}
		if (roiManager("count")>1) {
			selectWindow(ORGC2);
			setSlice(j);
			allroi();
			roiManager("Combine");
			wait(200);
			run("Clear Outside", "slice");
		}
	}
}

function primseg() {
	run("Duplicate...", "duplicate");
	indiv = getTitle();
	run("Enhance Contrast...", "saturated=0.3 equalize process_all");
	run("Options...", "iterations=3 count=1 black do=Close stack");
	run("Fill Holes", "stack");
// save
	saveAs("Tiff", C2dir + name + "-C2_RC_prim-seg.tif");
	indiv = getTitle();
// set 3D Manager Options (Feret doesn't work here)
	run("3D Manager Options", "volume surface compactness fit_ellipse 3d_moments integrated_density mean_grey_value std_dev_grey_value mode_grey_value minimum_grey_value maximum_grey_value centroid_(pix) centroid_(unit) distance_to_surface centre_of_mass_(pix) centre_of_mass_(unit) bounding_box radial_distance surface_contact closest exclude_objects_on_edges_xy exclude_objects_on_edges_z sync distance_between_centers=10 distance_max_contact=1.80");
// run the manager 3D and add image
	selectWindow(indiv);
	run("3D Manager");
		Ext.Manager3D_Segment(128,255);
		Ext.Manager3D_AddImage();
		Ext.Manager3D_DeselectAll(); // to refresh RoiManager
// do some measurements, save measurements and close window
		//Ext.Manager3D_Count(nb_obj);
		//Ext.Manager3D_SelectAll();
		Ext.Manager3D_Measure();
		Ext.Manager3D_SaveResult("M", resultsdir + name + "_3DMngr_PrimMeasure.csv");
		Ext.Manager3D_CloseResult("M");
		Ext.Manager3D_Reset();
		Ext.Manager3D_Close();
}

function guideI () {
	newImage(header, "8-bit black", 400, 490, 1);
	setLocation(InfoW, InfoH);
	setColor(200, 200, 200);
  	setFont("SansSerif", 20, "antiliased bold");
  	drawString("   LEGEND\n ", 10, 35);
  	setFont("SansSerif", 18, "antiliased");
  	setColor(255, 255, 255);
  	drawString("\n \n1. DATA DIMENSIONS\n    If you want to analyze more than one \n    channel, select 'Multi Channel'.\n    If C1 in your original files is not your\n    membrane label, select 'Swap Channel #'.\n3. MACRO OPTIONS\n    If 'Register Primordium', the algorithm will \n    create an oval selection around it and \n    crop it in X and Y.\n    If 'Measure Apical Constriction', the degree \n    of AC will be measured (dimensionless). \n    For further details please look up \n    the documentation \n    \n    next: Choose directory to process", 10, 60);
}
