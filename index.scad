use <MCAD/boxes.scad>

renderAssembled = false;

buildWidth = 50;
buildHeight= 50;
buildLength = 50;

projectileDiameter = 10;
catapultLength = 50;
catapultThickness = 1.5;
arm_angle = 45;
play = 0.25;

baseOfHook = 42;


margin = 2;
catapultWidth = 2/3 * projectileDiameter;
roundnessRadius = projectileDiameter/3;
boxRoundness = roundnessRadius/3;
fnroundnessRadius = 32;
innerHoleRadius = (projectileDiameter - 1)/2;
outerHoleRadius = 1.4 * innerHoleRadius;
hw = catapultWidth/2;
xs = roundnessRadius + catapultWidth/2;
ys = sqrt(
	(outerHoleRadius + roundnessRadius) *
	(outerHoleRadius + roundnessRadius) -
	(hw + roundnessRadius) * (hw + roundnessRadius)
);
lb = catapultLength - (2 * ys) - boxRoundness;

baseWidth = max(15, catapultWidth * 1.4);
baseLength = catapultLength * 1;
baseThickness = catapultThickness * 1.5;

catapult();


//------------------------- Modules --------------------------------------

module catapult(){
	union(){
		translate([0, 0, 0])
		base(shift=[1,1,1]);

		translate([baseWidth/2, 0, 0])
		hook(shift=[0,-1,1]);

		translate([0, 0, 0])
		arm(shift=[0,1,1]);
	}
}


module arm() {

	translation = [catapultWidth/2, catapultLength/2, catapultThickness/2];

	translate(hadamard(translation, shift))
	translate([0,catapultLength/2,0])
	difference() {
		union () {
			cylinder(r = outerHoleRadius, h = catapultThickness, center = true, $fn = fnroundnessRadius);

			roundedLink(xs, ys, roundnessRadius, catapultThickness);
			roundedLink(xs, -ys, roundnessRadius, catapultThickness);
			roundedLink(-xs, -ys, roundnessRadius, catapultThickness);
			roundedLink(-xs, ys, roundnessRadius, catapultThickness);

			translate([xs - roundnessRadius - boxRoundness, ys, 0])
			cylinder(r=boxRoundness, h=catapultThickness, center=true, $fn=fnroundnessRadius);

			translate([-xs+roundnessRadius+boxRoundness, ys, 0])
			cylinder(r=boxRoundness, h=catapultThickness, center=true, $fn=fnroundnessRadius);

			translate([0, ys, 0])
			cube([2*(xs-roundnessRadius-boxRoundness), 2*boxRoundness, catapultThickness], center=true);

			translate([0, -(ys+lb/2-boxRoundness/2), 0])
			cube([catapultWidth, lb - boxRoundness, catapultThickness], center=true);

			translate([catapultWidth/2-boxRoundness, -(ys+lb-boxRoundness), 0])
			cylinder(r=boxRoundness, h=catapultThickness, center=true, $fn=fnroundnessRadius);

			translate([-catapultWidth/2+boxRoundness, -(ys+lb-boxRoundness), 0])
			cylinder(r=boxRoundness, h=catapultThickness, center=true, $fn=fnroundnessRadius);

			translate([0, -(ys+lb-boxRoundness), 0])
			cube([2*(xs-roundnessRadius-boxRoundness), 2*boxRoundness, catapultThickness], center=true);
		}

		cylinder(r = innerHoleRadius, h = catapultThickness * 1.2, center = true, $fn=fnroundnessRadius);
	}
}

module base(){

	baseOffW = (buildArm ? baseWidth/2 + margin : 0);

	cylinderRadius = baseThickness * 2;
	cylinderOffset = baseLength/2 - cylinderRadius;

	baseHoleWidth = catapultWidth * 0.8;
	baseHoleThickness = catapultThickness;
	baseHoleLength = catapultLength * 0.6;

	translation = [baseWidth/2, baseLength/2, baseThickness/2];


	translate(hadamard(translation, shift))
	difference() {
		union () {
			// Base
			roundBox(baseWidth, baseLength, baseThickness, 2);

			// Cylinder
			translate([0, cylinderOffset, baseThickness/2])
			rotate (90, [0, -1, 0])
			difference() {
				cylinder(r = cylinderRadius, h = baseWidth - 2, center = true);
				translate([-baseThickness * 2, 0, 0])
				cube([baseThickness * 4, baseThickness * 4, baseWidth * 1.5], center = true);
			}
		}

		// Hole in base plate
		roundBox(catapultWidth, baseHoleLength, baseThickness * 2, 2);

		// Slot for ball-holder
		//translate([0, -catapultLength/2 + 5, 0])
		//	cube([catapultWidth, 2, baseThickness * 2], center = true);

		// Slot for arm
		translate([0, baseLength/2 - 1.5, 0])
		rotate(-arm_angle, [1, 0, 0])
		cube([catapultWidth + play, catapultLength, catapultThickness + play],
			center=true);
	}
}

module hook(normalize=false){

	poleHeight = 30;
	poleWidth = 4;
	poleLength = 1.5;

	hookWidth = 2;
	hookHeight = 5;

	triggerWidth = 4;
	triggerLength = 6;
	triggerThickness = 2;

	translation = [poleWidth/2, -poleLength/2, poleHeight/2];


	translate(hadamard(translation, shift))
	union (){

		// Pole
		cube([poleWidth, poleLength, poleHeight], center=true);

		// Trigger
		translate([poleWidth/2, -poleLength/2, poleHeight/2])
		rotate ([180, 0, -90])
		scale([3,1,2])
		polyhedron(
			points = [[0, 0, 5], [0, 4, 5], [0, 4, 0], [0, 0, 0], [2, 0, 0], [2, 4, 0]],
			faces = [[0,3,2],  [0,2,1],  [4,0,5],  [5,0,1],  [5,2,4],  [4,2,3], [0,4,3], [1,5,2]],
			center=true
		);

		// Hook
		translate([poleWidth/2, poleLength/2, poleHeight/2 - hookHeight])
		rotate ([0,0,90])
		polyhedron(
			points = [
			[0, 0, 5], [0, 4, 5], [0, 4, 0], [0, 0, 0], [2, 0, 0], [2, 4, 0],
			],
			faces = [
			[0,3,2],  [0,2,1],  [4,0,5],  [5,0,1],  [5,2,4],  [4,2,3],
			[0,4,3], [1,5,2]
			]
		);
	}
}

module ballLoader(){
	baseWidth = 10;
	baseLength = 10;
	baseHeight = 2;
}


module roundedLink(xr, yr, rc, rt) {
	difference () {
		linear_extrude(height=rt, center=true)
		polygon(points=[[0,0],[xr,yr],[0,yr]], paths=[[0,1,2]]);
		translate([xr, yr, 0])
		cylinder(r=rc, h=rt*1.2, center=true, $fn=fnroundnessRadius);
	}
}


module roundBox(bw, bh, bt, rb) {
	union () {
		cube([(bw-2*rb)*1.05, (bh-2*rb)*1.05, bt], center=true);

		translate([(bw-rb)/2, 0, 0])
		cube([rb, bh-2*rb, bt], center=true);

		translate([-(bw-rb)/2, 0, 0])
		cube([rb, bh-2*rb, bt], center=true);

		translate([0, -(bh-rb)/2, 0])
		cube([bw-2*rb, rb, bt], center=true);

		translate([0, (bh-rb)/2, 0])
		cube([bw-2*rb, rb, bt], center=true);

		translate([(-bw+2*rb)/2, (bh-2*rb)/2, 0])
		cylinder(r=rb, h = bt, center=true, $fn=fnroundnessRadius);

		translate([(bw-2*rb)/2, (bh-2*rb)/2, 0])
		cylinder(r=rb, h = bt, center=true, $fn=fnroundnessRadius);

		translate([(-bw+2*rb)/2, (-bh+2*rb)/2, 0])
		cylinder(r=rb, h = bt, center=true, $fn=fnroundnessRadius);

		translate([(bw-2*rb)/2, (-bh+2*rb)/2, 0])
		cylinder(r=rb, h = bt, center=true, $fn=fnroundnessRadius);
	}
}

//------------- Functions --------------

function hadamard(vector1, vector2) =
	[vector1[0] * vector2[0], vector1[1] * vector2[1], vector1[2] * vector2[2]];
