include <polyScrewThread.scad>

$fn=50;

module gorillaPodMount () {
	
	height = 40;
	width = 32;
	depthRange = [3.1, 2.7]; //TODO: Implement long slope
	completeDepth = 6;
	shortSlopeLength = 8.5;
	shortSlopeAngle = 10;
	shaftLength = 20;
	shaftDiameter = 16;
	
	module adapterWithoutGap() {
		
		module basePlate() {	
			
			module basePlateHalf(){
				hull(){
					polygon(
						[[0,0],[height,0],[width,13.5],[30,14],[0,16]],
						[[0,1,2,3,4]]
					);
				
					// Corner ~~ (40, 11.5)
					translate([36, 7.5])
					circle(r=4);
				}
			}
			
			basePlateHalf();
			
			mirror([0,1,0])
			basePlateHalf();
		}

		module topPlate() {
			module topPlateHalf () {
				hull(){
					polygon([[0,0],[40,0],[0,11.5]], [[0,1,2]]);
					
					// Corner ~~ (40,8)
					translate([35,3])
					circle(r=5);
				}
			}
			
			topPlateHalf();
			
			mirror([0,1,0]) {
				topPlateHalf();
			}
		}

		difference() {
			linear_extrude(height = depthRange[1])
			basePlate();

			// Subtract short slope in the front
			translate([height - shortSlopeLength, -width/2, depthRange[1]])
			rotate([0, shortSlopeAngle, 0])
			cube(size=[20, width, depthRange[1]], center=false);
		}

		linear_extrude(height = completeDepth)
		topPlate();
	}

	module bottomGap() {
		translate([0,5,0])
		rotate([90,0,0])
		linear_extrude(height=10)
		polygon(
			[
				[39, -1],
				[39, 0],
				[38.5, 3],
				[34, 0],
				[34, -1]
			],
			[[0,1,2,3,4]
		]);
	}

	module gorillapodAdapter() {
		difference() {
			adapterWithoutGap();
			bottomGap();
		}
	}

	module thread () {

		translate([18, 0, 0]){
			translate([0, 0, shaftLength + completeDepth])
			screw_thread(shaftDiameter, 1.2, 55, 6, 1, 2);

			cylinder(d=shaftDiameter, h=shaftLength + completeDepth);
		}
	}


	gorillapodAdapter();
	thread();
}

gorillaPodMount();
