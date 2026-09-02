.DEFAULT_GOAL := help

LUACAD ?= luacad
OPENSCAD ?= openscad
SAMPLES ?= 128
RENDER_FLAGS ?= --raytrace --samples $(SAMPLES)

# One source model per physible. Physibles without a LuaCAD/OpenSCAD
# source (SVG cutting plans, FreeCAD or mesh-only models) are not listed.
MODELS := \
	canon_ef_body_cap/canon_ef_cap.lua \
	canon_ef_lens_cap/canon_ef_lens_cap.lua \
	chess/index.lua \
	fan_mount/fan_mount.lua \
	glasses/glasses.lua \
	gorilla_pod_mount/index.lua \
	iphone_mount/iphone_mount.lua \
	keyboard_connector/keyboard_connector.lua \
	medal/medal.lua \
	pipe_plug/pipe_plug.lua \
	radiator_towel_hanger/radiator_towel_hanger.lua \
	saxophone_stand/bell_rest.lua \
	toilet_spacer/toilet_spacer.lua

# Models that need features LuaCAD lacks (DXF import, the MCAD library):
# OpenSCAD exports the mesh first, then LuaCAD raytraces the STL.
VIA_OPENSCAD := \
	boat/cad/index.scad \
	catapult/index.scad

# The render lands in the physible's top-level directory,
# even when the source sits in a subdirectory (e.g. boat/cad).
physible_dir = $(firstword $(subst /, ,$(1)))
RENDERS := \
	$(foreach m,$(MODELS) $(VIA_OPENSCAD),$(call physible_dir,$(m))/render.png)


.PHONY: help
help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "%-10s %s\n", $$1, $$2}'


.PHONY: render
render: $(RENDERS) ## Raytrace a render.png for every physible

# Run luacad from the model's own directory so that relative
# import() paths inside the script resolve correctly.
define RENDER_RULE
$(call physible_dir,$(1))/render.png: $(1)
	cd $(dir $(1)) && $$(LUACAD) render $$(RENDER_FLAGS) $(notdir $(1)) $$(abspath $$@)
endef
$(foreach m,$(MODELS),$(eval $(call RENDER_RULE,$(m))))

define VIA_OPENSCAD_RULE
$(call physible_dir,$(1))/build/render.stl: $(1)
	mkdir -p $$(dir $$@)
	$$(OPENSCAD) -o $$@ $$<

$(call physible_dir,$(1))/render.png: $(call physible_dir,$(1))/build/render.stl
	printf 'return import("render.stl")\n' > $$(dir $$<)render.lua
	cd $$(dir $$<) && $$(LUACAD) render $$(RENDER_FLAGS) render.lua $$(abspath $$@)
endef
$(foreach m,$(VIA_OPENSCAD),$(eval $(call VIA_OPENSCAD_RULE,$(m))))

# Extra inputs of the boat assembly
boat/build/render.stl: boat/cad/propeller.scad boat/cad/airfoil.dxf


.PHONY: clean
clean: ## Delete all generated renders and intermediates
	rm -f $(RENDERS) \
		$(foreach m,$(VIA_OPENSCAD),\
			$(call physible_dir,$(m))/build/render.stl \
			$(call physible_dir,$(m))/build/render.lua)
