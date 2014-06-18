// All sizes in SI-units

use <propeller.scad>


$fn=100;
zoomFactor = 100;

bodyDiameter = 0.06 * zoomFactor;
bodyHeight = 0.25 * zoomFactor;
bodyThickness = 0.002 * zoomFactor;
waterline = 0.6 * bodyHeight;

motorLength = 0.047 * zoomFactor;
motorDiameter = 0.023 * zoomFactor;
motorAxleDiameter = 0.002 * zoomFactor;
motorAxleLength = 0.0095 * zoomFactor;
//play = 0.0001 * zoomFactor;
overlap = 0.01 * zoomFactor;
//weight = 0.0422

axleExtensionLength = 0.08 * zoomFactor;
axleAngle = 15;

translate([0, 0, bodyHeight - waterline])
boat();

%water(80, 80, bodyHeight * 1.2);



//----------- Modules --------------

module boat(){

    color([1, 0.9, 0.6])
    hull();
    
    translate([0, 0, -motorDiameter])
    propulsion();
}

module propulsion(){
    rotate(axleAngle, [1,0,0])
    propulsionUnit(motorLength, motorDiameter, motorAxleLength, motorAxleDiameter);

    translate([0, 0, -1.1 * motorDiameter])
    rotate(120, [0,0,1])
    propulsionUnit(motorLength, motorDiameter, motorAxleLength, motorAxleDiameter);

    translate([0, 0, -2.2 * motorDiameter])
    rotate(axleAngle, [1,0,0])
    rotate(-120, [0,0,1])
    propulsionUnit(motorLength, motorDiameter, motorAxleLength, motorAxleDiameter);
}

module hull(){
    
    tubeHeight = bodyHeight - bodyDiameter/2;

    translate([0, 0, -tubeHeight])
    difference(){
        union(){
            sphere(d=bodyDiameter, [0,0,0]);
            cylinder(tubeHeight, d=bodyDiameter, [0,0,0]);
        }
        
        translate([0, 0, bodyThickness])
        union(){
            sphere(d=bodyDiameter - (2 * bodyThickness), [0,0,0]);
            cylinder(
                bodyHeight - bodyThickness + overlap,
                d=bodyDiameter - (2 * bodyThickness),
                [0,0,0]
            );
        }
        
        // Profile
        translate([1, -5, -5])
        cube([10, 10, bodyHeight]);
    }
}

module propulsionUnit(length, diameter, axleLength, axleDiameter){

    translate([0, -(length - axleLength)/2, 0])
    rotate([-90,0,0])
    union(){
        color([0.8, 0.8, 0.8])
        motor(length, diameter, axleLength, axleDiameter);
        
		// Shaft
        translate([0, 0, -(axleExtensionLength + axleLength)])
        color("gray")
        cylinder(axleExtensionLength, d=(axleDiameter * 1.2), [0,0,0]);

        translate([0, 0, -(axleExtensionLength + axleLength)])
		propeller(3, 0.040 * zoomFactor, 0.01 * zoomFactor, 0.002 * zoomFactor);
    }
}

module motor(length, diameter, axleLength, axleDiameter){
    union(){
        // Body
        cylinder(length - axleLength, d=diameter, [0,0,0]);
        
        // Axle
        translate([0, 0, -axleLength])
        cylinder(axleLength + overlap, d=axleDiameter, [0,0,0]);
    }
}

module water(width, depth, height){
    
    translate([-width/2, -depth/2, -height])
    color([0.2, 0.5, 0.8, 0.4])
    cube([width, depth, height]);
}