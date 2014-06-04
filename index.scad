use <MCAD/boxes.scad>

renderAssembled = false;
//renderAssembled = true;
showBuildPlatform = false;
//showBuildPlatform = true;

buildWidth = 50;
buildLength = 50;
buildHeight= 50;

projectileDiameter = 10;
catapultWidth = 2/3 * projectileDiameter;
catapultLength = 50;
catapultThickness = 1.5;
arm_angle = 45;
play = 0.20;

baseOfHook = 42;


margin = 2;
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
baseRadius = 2;

trayHeight = 22;
trayAngle = 5;

catapult();

if(showBuildPlatform)
	color([0.5,0.8,1])
	translate([-buildWidth/2, -buildWidth/2, -1])
	cube([buildWidth, buildLength, 1]);


//------------------------- Modules --------------------------------------

module catapult(){

	function armTranslation()
		= renderAssembled ?
		[baseWidth/2, baseLength - catapultThickness, catapultThickness/3] : [-10, 0, ];
	function armRotation()
		= renderAssembled ? [arm_angle + 90,0,0] : [0,0,0];
	function armShift()
		= renderAssembled ? [0,0,0] : [-1,0,1];


	function trayTranslation() = renderAssembled ? [-2, 9, trayHeight-2] : [-28, 0, ];
	function trayRotation() = renderAssembled ? [trayAngle,0,90] : [0,0,0];
	function trayShift() = renderAssembled ? [0,0,0] : [-1,0,1];

	translate([-baseWidth + buildWidth/2 - 5, -buildLength/2, 0])
	union(){

		translate(armTranslation())
		rotate(armRotation())
		arm(shift=armShift());

		translate([0, 0, 0])
		base(shift=[1,1,1]);

		translate([baseWidth/2, 3, 0])
		hook(shift=[0,-1,1]);

		translate([baseRadius, 10, 0])
		ballLoader(shift=[-1,1,1]);

		translate(trayTranslation())
		rotate(trayRotation())
		ballTray();
	}
}


module arm() {

	translation = [catapultWidth/2, catapultLength/2, catapultThickness/2];

	translate(hadamard(translation, shift))
	translate([0,catapultLength - 8,0]) // TODO: replace hard-code with real values

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
			roundedBox([baseWidth, baseLength, baseThickness], 2, true, $fn = 50);

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
		roundedBox([catapultWidth, baseHoleLength, baseThickness * 2], 2, true, $fn = 50);

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
	baseWidth = 8;
	baseLength = 8;
	translation = [baseWidth/2, baseLength/2, baseThickness/2];

	poleHeight = 22;

	union(){
		// Base
		translate(hadamard(translation, shift))
		roundedBox([baseWidth, baseLength, baseThickness], 2, true, $fn=40);

		// Pole
		translate([-baseWidth, baseLength/2 - 2, 0])
		cube([2, 4, poleHeight]);
	}
}

module ballTray (){

	trayThickness = 2;
	trayLength = projectileDiameter * 3 + trayThickness;
	trayWidth = projectileDiameter;
	translation = [0, 0, poleHeight];

	translate(hadamard(translation, shift))
	difference(){
		union () {

			cube([trayWidth, trayLength * 0.2, trayThickness]);

			// Walls
			translate([trayWidth, 0, 0])
			rotate([0,-90,0])
			cube([trayWidth/2, trayLength, trayThickness]);

			translate([trayThickness, 0, 0])
			rotate([0,-90,0])
			cube([trayWidth/2, trayLength, trayThickness]);

			translate([0, trayLength, 0])
			rotate([90,0,0])
			cube([trayWidth, trayWidth/2 + projectileDiameter/2, trayThickness]);

		}

		rotate([-trayAngle,0,0])
		translate([projectileDiameter/2, 3, 0])
		cube([4 + play, 2 + play, 10 + play], center=true);
	}
}


module roundedLink(xr, yr, rc, rt) {
	difference () {
		linear_extrude(height=rt, center=true)
		polygon(points=[[0,0],[xr,yr],[0,yr]], paths=[[0,1,2]]);
		translate([xr, yr, 0])
		cylinder(r=rc, h=rt*1.2, center=true, $fn=fnroundnessRadius);
	}
}

//------------- Functions --------------

function hadamard(vector1, vector2) =
	[vector1[0] * vector2[0], vector1[1] * vector2[1], vector1[2] * vector2[2]];
