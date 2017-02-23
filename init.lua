-- internationalization boilerplate
local MP = minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")

local data = {}

local node_sound
if minetest.get_modpath("default") then
	node_sound = default.node_sound_wood_defaults()
end

local particles = minetest.setting_get("enable_particles")
if particles == "true" or particles == nil then
	particles = true -- default true
else
	particles = false
end

minetest.register_node("sounding_line:sounding_line", {
	description = S("Sounding Line"),
	_doc_items_longdesc = S("A spool of marked line with a weight on the end used for measuring depths."),
    _doc_items_usagehelp = S("Build this item over the location whose depths you wish to plumb. Right click on it to take a reading. The sounding line will give a reading indicating how far down the sounding line encountered water (if any) and how far down the first solid obstruction is.\n\nIf lava is encountered this will be indicated by a burnt end on the line. Sounding lines can't measure the depth of lava, only how far it is to the lava's surface.\n\nIf the sounding line reports encountering an \"unknown void\" it has reached a region that has not yet been generated by map generation."),
	groups = {cracky = 3, oddly_breakable_by_hand=3},
	drop = "sounding_line:sounding_line",
	tiles = {"sounding_line_top.png","sounding_line_bottom.png",
		"sounding_line_side.png","sounding_line_side.png^[transformFX",
		"sounding_line_front.png","sounding_line_front.png^[transformFX"},
	sounds = node_sound,
	climbable = true,
	walkable = false,
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.375, 0.125, -0.0625, 0.375, 0.25, 0.0625}, -- crossbar
			{-0.5, 0.125, -0.5, -0.375, 0.25, 0.5}, -- leg
			{0.375, 0.125, -0.5, 0.5, 0.25, 0.5}, -- leg
			{0.1875, -0.125, -0.3125, 0.3125, 0.5, 0.3125}, -- spool
			{-0.3125, -0.125, -0.3125, -0.1875, 0.5, 0.3125}, -- spool
			{-0.1875, -0.0625, -0.25, 0.1875, 0.4375, 0.25}, -- line_roll
			{-0.0625, -0.25, -0.25, 0, -0.0625, -0.1875}, -- hanging_line
			{-0.125, -0.5, -0.3125, 0.0625, -0.25, -0.125}, -- weight
		}
	},

	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		local top = pos.y-1
		local bottom = pos.y-15
		local voxel_manip = minetest.get_voxel_manip()
		
		local end_depth, water_depth
		local encountered_lava, encountered_ignore
		
		while not end_depth do
			local emin, emax = voxel_manip:read_from_map({x=pos.x, y=bottom, z=pos.z}, {x=pos.x, y=top, z=pos.z})
			voxel_manip:get_data(data)
			local voxel_area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
			bottom = emin.y			
			for y= top, bottom, -1 do
				local index = voxel_area:index(pos.x, y, pos.z)
				local name = minetest.get_name_from_content_id(data[index])
				if name == "ignore" then
					encountered_ignore = true
					end_depth = pos.y - y
				end
				if not water_depth and minetest.get_item_group(name, "water") > 0 then
					water_depth = pos.y - y
				end
				if not encountered_lava and minetest.get_item_group(name, "lava") > 0 then
					end_depth = y - pos.y
					encountered_lava = true
				end
				local def = minetest.registered_nodes[name]
				if def.walkable then
					end_depth = pos.y - y
				end
				
				if end_depth then
					break
				end
			end
			top = bottom - 1
			bottom = bottom - 15
		end
		
		local status = S("Most recent reading:")
		if water_depth then
			status = status .. "\n" .. string.format(S("Water %dm down"), water_depth)
		end
		if encountered_lava then
			status = status .. "\n" .. string.format(S("Line burned %dm down"), end_depth)
		elseif encountered_ignore then
			status = status .. "\n" .. string.format(S("Unknown void %dm down"), end_depth)
		else
			status = status .. "\n" .. string.format(S("Obstruction %dm down"), end_depth)
		end
		
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", status)
		
		if particles then
			minetest.add_particlespawner({
				amount = 50,
				time = 1,
				minpos = pos,
				maxpos = pos,
				minvel = {x=0, y=-10, z=0},
				maxvel = {x=0, y=-10, z=0},
				minacc = {x=0, y=0, z=0},
				maxacc = {x=0, y=0, z=0},
				minexptime = 1,
				maxexptime = 1,
				minsize = 8,
				maxsize = 8,
				collisiondetection = true,
				vertical = true,
				texture = "sounding_line_particle.png",
			})
		end
		
		minetest.sound_play("sounding_line_whooshing", {pos=pos, gain=0.5})
	end,
})

if minetest.get_modpath("default") then
	if minetest.get_modpath("farming") then
		minetest.register_craft({
			output = "sounding_line:sounding_line",
			recipe =  {
				{'group:stick','group:stick','group:stick'},
				{'farming:cotton','farming:cotton','farming:cotton'},
				{'','default:steel_ingot',''}
			}
		})
	end
	if minetest.get_modpath("vines") then
		minetest.register_craft({
			output = "sounding_line:sounding_line",
			recipe =  {
				{'group:stick','group:stick','group:stick'},
				{'','group:vines',''},
				{'','default:steel_ingot',''}
			}
		})
	end
end

if minetest.get_modpath("loot") then
	loot.register_loot({
		weights = { generic = 50 },
		payload = {
			stack = ItemStack("sounding_line:sounding_line"),
			min_size = 1,
			max_size = 4,
		},
	})
end
