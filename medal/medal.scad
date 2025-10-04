$fn = 64;

disc_height = 50;
surface_radius = 500;
medal_diameter = 300; // Contrained by image size of icon. Actual size (58 mm) must be set in slicer.
edge_chamfer = 10;


module base () {
    difference () {
        cylinder_height = 100; // Real height is constrained by curvature of recess below it
        height_above_0 = 1; // For unioning it
        translate([0,0, -cylinder_height + height_above_0]) 
            cylinder(h = cylinder_height, d = medal_diameter, center = false);
        translate([0,0, -surface_radius]) 
            sphere(r = surface_radius);
    }
}


// Chamfer instead of rounded edge for better printability
module emblem () {
    emblem_height = 10;
    chamfer_offset = 6;
    
    union () {
        translate([0, 0, chamfer_offset]) intersection() {
            translate([0, 0, 5])
                scale([1, 1, 0.05])
                surface(file = "surface@2x.png", center = true, invert = true);
//            // For debugging:
//            translate([0, 0, 2.5])
//                cube([400, 400, 5], center = true);
            cylinder(
                h = emblem_height-chamfer_offset,
                d1 = medal_diameter,
                d2 = medal_diameter - (2 * (emblem_height - chamfer_offset)),
                center = false
            );
        }       
        cylinder(h = chamfer_offset, d = medal_diameter, center = false);
    }
}


scale([0.5, 0.5, 1]) // Make it easier to handle. Exact size is set in slicer.
union () {
    emblem();
    base();
}
