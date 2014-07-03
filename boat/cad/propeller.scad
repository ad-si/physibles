/*
 * Usage: propeller(numberOfBlades, propellerDiameter, propellerHeight, shaftRadius);
 */

// Example:
propeller(2, 60, 20, 2);


bladeStartAngle = 40;
bladeEndAngle = 60;
airfoilWidthScaleFactor= 0.8;
airfoilHeightScaleFactor = 1.5;
airfoilOffset = 7.1;
airfoilHeight = 1;
airfoilWidth = 10;
convexity = 10;

$fn = 100;
numberOfSlices = 20;

module propeller(numberOfBlades, propellerDiameter, propellerHeight, shaftDiameter){
	
	airfoilScaleFactor = propellerHeight/airfoilWidth;
	// Bounding-box in x dimension at hub
	bladeXDimension = sin(bladeStartAngle) * propellerHeight * airfoilWidthScaleFactor;
	// Bounding-box in y dimension at hub
	bladeYDimension = cos(bladeStartAngle) * propellerHeight * airfoilWidthScaleFactor;
	ductOuterRadius = propellerDiameter/2;
	ductThickness = propellerHeight * 0.1;
	bladeThickness = propellerHeight * 0.1;
	finalAirfoilHeight = airfoilHeight * airfoilHeightScaleFactor * airfoilScaleFactor;
	hubDiameter = shaftDiameter * 2.5;
	
	difference(){
		
		union(){

			if (finalAirfoilHeight > hubDiameter || bladeXDimension > hubDiameter)
				if (finalAirfoilHeight > bladeXDimension)
					hub(finalAirfoilHeight, bladeYDimension * 1.1);
				else
					hub(bladeXDimension * 1.2, bladeYDimension * 1.1);
			else
				hub(hubDiameter, bladeYDimension * 1.1);
			
			
			blades(
				numberOfBlades,
				propellerDiameter - ductThickness,
				propellerHeight - hubDiameter/4,
				bladeThickness,
				airfoilScaleFactor
			);
			
			//duct(propellerDiameter, bladeYDimension, ductThickness);
		}
		
		// Hole for shaft
		translate([0, 0, -propellerHeight/4])
		cylinder(h = propellerHeight * 2, d = shaftDiameter);
	
		// Cutoff
		translate([0, 0, -propellerHeight])
		cylinder(h = propellerHeight, r = propellerDiameter * 1.5);
	}
}

module hub (diameter, height){
	translate([0, 0, height - diameter/2])
	sphere(d = diameter);

	translate([0, 0, -diameter/2])
	cylinder(h = height, d = diameter);
}

module blades (numberOfBlades, diameter, height, thickness) {
	
	airfoilScaleFactor = height/airfoilWidth;
		
	module blade() {
		linear_extrude(
			height = diameter/2,
			twist = -(bladeEndAngle - bladeStartAngle),
			slices = numberOfSlices,
			convexity = convexity,
			scale = [1, 2]
		)
		//scale([thickness/height, 1, 1])
		//circle(r = height);
		//scale([thickness/height, thickness/height, thickness/height])
		//scale(height/airfoilWidth)
		scale(airfoilScaleFactor)
		rotate([0, 0, bladeStartAngle])
		scale([airfoilWidthScaleFactor, airfoilHeightScaleFactor])
		import(file = "airfoil.dxf", layer = "0");
	}
	
	// Intersection between blades and bounding cylinder
	intersection(){
		
		for (i = [0:numberOfBlades-1]) {
			rotate([0, 90, i * (360/numberOfBlades)])
			translate([-airfoilOffset * cos(bladeStartAngle) * airfoilScaleFactor, 0, 0])
			blade();
		}
		
		cylinder(h = height * 10, d = diameter, center = true);
	}
}

module duct (diameter, height, wallThickness){
	
	difference(){
		cylinder(
			h = height,
			d = diameter
		);
		
		translate([0, 0, - height/2]) 
		cylinder(h = (2 * height), d = diameter - (2 * wallThickness));
	}
}
