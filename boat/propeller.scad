/* Usage: propeller(numberOfBlades, propellerDiameter, propellerHeight, shaftRadius);
 *
 * Example: propeller(2, 50, 15, 2);
 *
 * All specifications are per default in mm
 */

bladeAngle = 60;
convexity = 10;

$fn = 20;
numberOfSlices = 20;

module propeller(numberOfBlades, propellerDiameter, propellerHeight, shaftDiameter){
	
	bladeHeight = propellerHeight - hubRadius/3;
	ductOuterRadius = propellerDiameter/2;
	ductThickness = propellerHeight * 0.1;
	hubDiameter = shaftDiameter * 2.5;
	bladeThickness = propellerHeight * 0.1;
	
	difference(){
		
		union(){
			hub(hubDiameter, propellerHeight);
			blades(
				numberOfBlades,
				propellerDiameter - ductThickness,
				propellerHeight - hubDiameter/4,
				bladeThickness
			);
			duct(propellerDiameter, propellerHeight * 0.8, ductThickness);
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
		
	module blade() {
		
		rotate([90, 0, 90])
		linear_extrude(
			height = diameter,
			twist = bladeAngle,
			slices = numberOfSlices,
			convexity = convexity
		)
		scale([thickness/height, 1, 1])
		circle(r = height);
	}
	
	// Intersection between blades and bounding cylinder
	intersection(){
		
		for (i = [0:numberOfBlades-1]) {
			rotate([0, 0, i * (360/numberOfBlades)])
			blade();
		}
		
		translate([0, 0, -height/2])
		cylinder(h = height * 2, d = diameter);
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
