fanEdgeLength = 40;
fanDepth = 10;
fanDiameter = 38;

$fn=50;

module fan (edgeLength, depth, diameter) {
	
	screwHoleDiameter = 3;
	screwHoleOffset = 3;
	
	module screwhole () {
			translate([
 				screwHoleDiameter/2 + screwHoleOffset,
 				screwHoleDiameter/2 + screwHoleOffset,
 				-(depth * 0.5),
 			])
			cylinder(d=screwHoleDiameter, h= 2 * depth);
	}
	
	difference (){
		cube([edgeLength, edgeLength, depth]);


		// Screwholes
		screwhole();
		
		translate([edgeLength,0,0])
		mirror([1, 0, 0])
		screwhole();
		
		translate([0,edgeLength,0])
		mirror([0, 1, 0])
		screwhole();
		
		translate([edgeLength,edgeLength,0])
		mirror([1, 1, 0])
		screwhole();
		
		translate([edgeLength/2, edgeLength/2, -(depth * 0.5)])
		cylinder(d=diameter, h=(2 * depth));
	}
}



module mount (fanEdgeLength, fanDepth, fanDiameter) {
	
	bridgeHeigth = 12;
	bridgeWidth = 60;
	bridgeDepth = 5;
	hornHeight = 10;
	

	screwHoleDiameter = 3;
	screwHoleOffset = 3;
	
	nutHeight = 7;
	nutDepth = 3;
	nutWidth = 6;
	
	inaccuracyCorrection = 0.4;

	// Printer-part
	/*
	color([0, 0, 0]) {
 		translate([-bridgeWidth/2, -bridgeHeigth*1.2, -bridgeDepth*2])
 		cube(size=[bridgeWidth, bridgeHeigth * 1.2, bridgeDepth*2], center=false);
	}
	*/
	
	
	difference () {
		
		union(){
			// Bridge
			translate([0, -bridgeHeigth/2 + hornHeight/2, 0])
			cube(size=[bridgeWidth, bridgeHeigth + hornHeight, bridgeDepth * 2], center=true);
			
			// Outer cylinder
			translate([0,-fanEdgeLength/2,0])
			cylinder(d1=fanDiameter, d2=fanDiameter + 20, h=10, center=true);
		}
		
		// Cutoffs
		union(){
			translate([0, 0, -bridgeDepth])
			cube(size=[bridgeWidth - 2 * bridgeDepth, 18 * 2, bridgeDepth * 2], center=true);

			translate([0, bridgeHeigth, 0])
			cube(size=[fanEdgeLength + 10, bridgeHeigth * 2, bridgeDepth*4], center=true);
			
			translate([0, -fanEdgeLength - bridgeHeigth, 0])
			cube(size=[bridgeWidth*2, bridgeHeigth * 2, bridgeDepth*4], center=true);
		}
		
		// Inner cylinder
		translate([0,-fanEdgeLength/2,0])
		cylinder(d1=(fanDiameter-10), d2=fanDiameter, h=10.1, center=true);
		
		// Recess
		translate([0,0,-10])
		rotate([90,0,0])
		cylinder(r=10, h=100, center=true);
		
		// Baseplate screwholes
		translate([
			-fanEdgeLength/2 + screwHoleOffset + screwHoleDiameter/2 - inaccuracyCorrection,
			-screwHoleOffset - screwHoleDiameter/2,
			0
		])
		cylinder(d=3, h=20, center=true);
		
		translate([
			fanEdgeLength/2 - screwHoleOffset - screwHoleDiameter/2 + inaccuracyCorrection,
			-screwHoleOffset - screwHoleDiameter/2,
			0
		])
		cylinder(d=3, h=20, center=true);
		
		// Fans screwholes
		translate([
			fanEdgeLength/2,
			-screwHoleOffset - screwHoleDiameter/2 + hornHeight,
			0
		])
		rotate([0,90,0])
		cylinder(d=3, h=20);
		
		translate([
			-fanEdgeLength/2 - 20,
			-screwHoleOffset - screwHoleDiameter/2 + hornHeight,
			0
		])
		rotate([0,90,0])
		cylinder(d=3, h=20);

		// Nuts recesses
		/*translate([
			bridgeWidth/2 - bridgeDepth - nutDepth/2,
			-screwHoleOffset - screwHoleDiameter/2,
			0
		])
		cube(size=[nutDepth, nutWidth, nutHeight], center=true);
		
		translate([
			- bridgeWidth/2 + bridgeDepth + nutDepth/2,
			-screwHoleOffset - screwHoleDiameter/2,
			0
		])
		cube(size=[nutDepth, nutWidth, nutHeight], center=true);
		*/
	}
}

translate([0,0,5])
mirror([0,0,1]){
	*translate([-20,-40,5])
	fan(fanEdgeLength, fanDepth, fanDiameter);
	
	mount(fanEdgeLength, fanDepth, fanDiameter);
}