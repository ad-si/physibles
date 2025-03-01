motorWidth = 30;

module wall () {
	depth = 50;

	color("white")
	translate([-(depth/2), 0, 0])
	cube(size=[depth, 1000, 1000], center=true);
}

module clock () {

	module hull () {

		height = 50;
		depth = 30;
		width = 500;
		thickness = 5;
		hollow = [
			depth - (2 * thickness),
			width - (2 * thickness),
			height - (2 * thickness)
		];

		windowHeight = height / 2;
		windowWidth = width - (2 * motorWidth) - (2 * thickness);

		translate([depth/2, 0, 0])
		difference () {
			cube(size=[depth, width, height], center=true);
			cube(size=hollow, center=true);
			translate([depth/2, 0, (height/2) - (windowHeight/2) - thickness])
			cube(size=[
					depth,
					windowWidth,
					windowHeight
				],
				center=true
			);
		}

	}

	hull();
}


wall();
clock();
