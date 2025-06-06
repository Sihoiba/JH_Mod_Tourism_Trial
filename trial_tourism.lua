function neuterAny(being)
    if being.data and being.data.ai and being.data.ai.group ~= "player" then
        being.data.ai.state = "idle"
        being.data.ai.smell = nil
        being.data.ai.alert = 1
        being.minimap.color = 0
        being.target.entity = nil
        being.data.ai.group = "demon_n"
    end
end

register_blueprint "runtime_tourism"
{
    flags = { EF_NOPICKUP },
    text = {
        denied = "Not a suitable souvenir!",
    },
    data = {
        swordmaster_open = false
    },
    attributes = {
        cannot_pick_up = true
    },
    callbacks = {
        can_pickup = [[
            function( self, player, item )
                if item and item.weapon then
                    ui:set_hint( self.text.denied, 1001, 0 )
                    world:play_voice( "vo_refuse" )
                    return -1
                end
                return 0
            end
        ]],
        on_enter_level = [[
            function ( self, entity, reenter )
                nova.log("on enter level runtime tourism")
                if not reenter then
                    local level = world:get_level()
                    for e in level:enemies() do
                        neuterAny(e)
                    end
                    for c in level:coords( { "elevator", "portal", "floor_exit", "elevator_branch", "elevator_special" } ) do
                        level:set_explored( c, true )
                    end
                    for c in level:coords( { "elevator", "elevator_branch", "elevator_mini", "elevator_special", } ) do
                        local flames = level:get_entity( c, "ghostflames" )
                        if flames then
                            nova.log("destroying ghostflames")
                            world:mark_destroy( flames )
                        end
                        for e in level:entities() do
                            local mod_gatekeeper_lock = e:child("mod_exalted_gatekeeper_elevator_inactive")
                            if mod_gatekeeper_lock then
                                world:mark_destroy( mod_gatekeeper_lock )
                            end
                        end
                    end
                    world:flush_destroy()
                end
            end
        ]],
        on_timer = [[
            function ( self, first )
                nova.log("on timer runtime tourism")
                if first then return 49 end
                local level = world:get_level()
                for t in level:targets( world:get_player(), 8 ) do
                    if t.data and t.data.ai.group ~= "demon_n" then
                        ui:spawn_fx( t, "fx_convert", t )
                    end
                    neuterAny(t)
                end

                if world.data.current == 22 then
                    nova.log("Adding swordmaster portal")
                    local wd = world.data.level[ world.data.current ]
                    if wd.special and not self.data.swordmaster_open then
                        local e = level:place_entity( "portal_01", level:find_coord( "portal_off" ) )
                        world:play_sound( "summon", e )
                        ui:spawn_fx( nil, "fx_summon", nil, world:get_position( e ) )
                        self.data.swordmaster_open = true
                    end
                end

                -- level 59-61 is the Abbatoir
                nova.log("world data current"..tostring(world.data.current))
                if world.data.current > 50 then
                    nova.log("Checking for bloodflames")
                    for c in level:coords( {"door_frame"} ) do
                        local b = level:get_entity(c, "bloodflames")
                        if b then
                            nova.log("destroying bloodflames")
                            world:mark_destroy( b )
                            level:set_cell_flag( c, EF_NOPATH, false )
                        end
                    end
                end
                return 50
            end
        ]],
    },
}
register_blueprint "trial_tourism"
{
    text = {
        name        = "Tourism",
        desc        = "{!TOURISM MOD}\nYou aren't here to battle the hordes of hell, you are just here for a tour of the moons of Jupiter. You can't use weapons, but enemies won't attack you either. Rumour has it a particularly crafty tourist might find a way to send the Harbinger back where he came from. \n\nRecommend setting camera-eye-distance to 10 so you can view the model details up close.\n\nRating   : {GTOURIST}\n",
        rating      = "TOURIST",
        abbr        = "Tour",
        mortem_line = "He was just seeing the sights!"
    },
    challenge = {
        type  = "trial",
        group = "trial_tourism",
        score = false,
    },
    callbacks = {
        on_create_player = [[
            function( self, player )
                nova.log("on create player")
                local weapon  = player:child("pistol") or player:child("rpistol") or player:child("pipe_wrench")
                if weapon then world:destroy( weapon ) end
                local eammo = player:child("ammo_9mm") or player:child("ammo_44")
                if eammo then world:destroy( eammo ) end
                player:attach( "kit_phase" )
                player:attach( "kit_phase" )
                player:attach( "kit_phase" )
                player:attach( "runtime_tourism" )
                player.equipment.count = 0
            end
        ]],
    },
}

register_world "trial_tourism"
{
    on_create = function( seed )
        local data = world.setup( seed )
        data.cot = {}
        world.add_branch {
            name       = "CALLISTO",
            depth      = 1,
            episode    = 1,
            size       = 7,
            enemy_list = "callisto",
            quest = {
                list = "callisto",
            },
            events     = {
                { "event_volatile_storage", 2.0, max_level = 3 },
                { "event_lockdown", 2.0, },
                "event_desolation",
                "event_low_light",
                { "event_infestation", 1.0, min_level = 4, },
                { "event_vault", 1.0, min_level = 4, },
                { "event_contamination", 1.0, min_level = 5, },
            },
            event      = { 100, math.random_pick{2,3,5,6,4,2,3,5}, },
            blueprint     = "level_callisto",
            rewards       = {
                { { "pipe_wrench", stash = true }, level = 2, },
                { { "crowbar", stash = true }, level = 6, },
                "lootbox_medical",
                { "lootbox_armor", level = 2, },
                { "medical_station", swap = 1, level = 4, },
            },
            lootbox_count = 3,
            intermission = {
                scene = "intermission_callisto",
                music = "music_callisto_intermission",
            },
        }
        data.level[1].blueprint = "level_callisto_intro"
        data.level[2].force_terminal = true
        if DIFFICULTY < 3 then
            table.insert( data.level[2].rewards, 1, "lootbox_special_2" )
        else
            data.level[2].terminal = data.level[2].terminal or {}
            table.insert( data.level[2].terminal, "terminal_boon" )
        end
        data.level[4].blueprint = "level_callisto_hub"
        data.level[5].blueprint = "level_callisto_civilian"
        data.level[6].blueprint = "level_callisto_civilian"
        data.level[7].blueprint = "level_callisto_spaceport"
        data.level[7].next      = 10008

        world.add_branch {
            name       = "EUROPA",
            depth      = 8,
            episode    = 2,
            size       = 7,
            enemy_list = "europa",
            quest = {
                list = "europa",
            },
            events     = {
                "event_low_light",
                { "event_volatile_storage", 2.0, max_level = 3 },
                "event_infestation",
                "event_lockdown",
                "event_vault",
                { "event_windchill", 2.0 },
            },
            event      = { 100, math.random(4) + 1, },
            blueprint  = "level_europa",
            rewards    = {
                "lootbox_medical",
                { { "axe", stash = true }, level = 2, },
                { "manufacture_station", level = 1, },
                { "medical_station", swap = 1, level = 4, },
                { "technical_station", level = 2, },
                { "terminal_ammo", level = 5, },
                { "lootbox_armor", level = 4, },
            },
            lootbox_count = 3,
            intermission = {
                scene = "intermission_europa",
                music = "music_europa_intermission",
            },
        }
        data.level[8].blueprint = "level_europa_intro"
        data.level[9].force_terminal = true
        data.level[11].blueprint = "level_europa_concourse"
        data.level[12].blueprint = "level_europa_civilian"
        data.level[13].blueprint = "level_europa_ice"
        data.level[14].blueprint = "level_europa_central_dig"
        data.level[14].next      = 10015


        world.add_branch {
            name       = "IO",
            depth      = 15,
            episode    = 3,
            size       = 7,
            enemy_list = "io",
            quest = {
                list = "io",
            },
            enemy_mod  = {
                [5] = { cri = 0.5, demon = 1.5 },
                [6] = { cri = 0.5, demon = 1.5 },
            },
            events     = {
                "event_low_light",
                { "event_volatile_storage", 2.0, max_level = 3 },
                "event_infestation",
                "event_lockdown",
                "event_vault",
                "event_exalted_summons",
                "event_contamination",
            },
            event      = { 100, math.random(4) + 1, },
            blueprint = "level_io",
            rewards   = {
                "lootbox_medical",
                { { "chainsaw", stash = true }, level = 2, },
                { { "rail_rifle", stash = true }, level = 3, },
                { "medical_station", swap = 1, level = 4, },
                { "technical_station", level = 1, },
                { { "energy_cannon", stash = true }, level = 6, },
                { "lootbox_armor", level = 2, },
            },
            lootbox_count = 4,
            intermission = {
                scene = "intermission_io",
                music = "music_io_intermission",
            },
        }
        data.level[15].blueprint = "level_io_intro"
        data.level[16].force_terminal = true
        data.level[18].blueprint = "level_io_nexus"
        data.level[19].blueprint = "level_io_deep"
        data.level[20].blueprint = "level_io_deep"
        data.level[21].blueprint = "level_io_gateway"
        data.level[21].next      = 10022

        world.add_branch {
            name       = "Dante Station",
            depth      = 22,
            episode    = 4,
            size       = 5,
            quest = {
                no_info = true,
                list = "dante",
            },
            enemy_list = "dante",
            events     = {
                { "event_exalted_summons", 3.0, },
            },
            event      = { DIFFICULTY*25, math.random(2) + 1, },
            blueprint = "level_dante",
            rewards       = {
                "dante_lootbox_medical",
                "dante_lootbox_ammo",
                { math.random_pick{  "dante_medical_station", "dante_technical_station", "dante_lootbox_special_2", "dante_lootbox_armor" }, level = 3, }
            },
            lootbox_count = 4,
            lootbox_table = "dante_lootbox",
            intermission = {
                scene     = "intermission_dante",
                music     = "music_main_01",
                game_over = true,
            },
        }
        data.level[22].blueprint = "level_dante_intro"
        data.level[22].force_terminal = true
        data.level[22].lootbox_count  = 3
        data.level[22].lootbox_table = nil
        data.level[23].blueprint = "level_dante_halls"
        data.level[24].blueprint = "level_dante_colosseum"
        data.level[25].blueprint = "level_dante_rafters"
        data.level[26].blueprint = "level_dante_altar"
        data.cot.boss_index = 26
        local mines_data = {
            name           = "Callisto Mines",
            episode        = 1,
            depth          = 3,
            size           = 3,
            enemy_list     = "callisto",
            enemy_mod      = { bot = 0, drone = 0.5, demon = 2, },
            blueprint      = "level_callisto_mines",
            lootbox_count  = 4,
            quest = {
                list = "callisto",
                flavor = "mines",
            },
            rewards        = {
                "lootbox_medical",
                { "medical_station", swap = 1, },
                { "lootbox_armor" },
            },
            events     = {
                "event_desolation",
                "event_infestation",
            },
            event      = { 100, math.random(3), },
            special = {
                blueprint      = "level_callisto_anomaly",
                ilevel_mod     = 2,
                dlevel_mod     = 1,
                returnable     = true,
            },
        }

        local rift_data = {
            name           = "Callisto Rift",
            episode        = 1,
            depth          = 3,
            size           = 2,
            enemy_list     = "callisto",
            enemy_mod      = { bot = 0, drone = 0.5, demon = 2, },
            blueprint      = "level_callisto_rift",
            lootbox_count  = 4,
            quest = {
                list = "callisto",
                flavor = "rift",
            },
            rewards        = {
                "lootbox_medical",
                { "medical_station", swap = 1, },
                { { "lootbox_ammo", attach = "smoke_grenade" }, level = 2, },
                { { "lootbox_general", attach = "enviropack" }, level = 1, },
                { "lootbox_armor" },
            },
            events     = {
                { "event_infestation", 3.0, },
                "event_exalted_summons",
            },
            event      = { 100, math.random(3), },
            special = {
                blueprint  = "level_callisto_crevice",
                ilevel_mod = 2,
                dlevel_mod = 1,
                returnable = true,
            },

        }

        local valhalla_data = {
            name           = "Valhalla Terminal",
            episode        = 1,
            depth          = 4,
            size           = 2,
            enemy_list     = "callisto",
            enemy_mod      = { demon2 = 0, civilian = 2, },
            blueprint      = "level_callisto_valhalla",
            item_mod       = { ammo_44 = 3, },
            lootbox_count  = 4,
            quest = {
                list = "callisto",
                flavor = "valhalla",
            },
            rewards        = {
                "lootbox_medical",
                { "medical_station", swap = 1, },
                { "lootbox_armor" },
            },
            events     = {
                "event_low_light",
                "event_desolation",
                "event_infestation",
            },
            event      = { 100, math.random(3), },
            special = {
                blueprint  = "level_callisto_command",
                ilevel_mod = 2,
                dlevel_mod = 1,
                returnable = true,
            },
        }

        local mimir_data = {
            name           = "Mimir Habitat",
            episode        = 1,
            depth          = 4,
            size           = 3,
            enemy_list     = "callisto",
            enemy_mod      = { demon1 = 0.3, demon2 = 0, },
            blueprint      = "level_callisto_mimir",
            item_mod       = { ammo_44 = 2, },
            lootbox_count  = 4,
            quest = {
                list = "callisto",
                flavor = "mimir",
            },
            rewards        = {
                "lootbox_medical",
                { "medical_station", swap = 1, },
                { "lootbox_armor" },
            },
            events     = {
                { "event_lockdown", 2.0, },
                "event_low_light",
                "event_infestation",
            },
            event      = { 100, math.random(3), },
            special = {
                blueprint      = "level_callisto_calsec",
                ilevel_mod     = 2,
                dlevel_mod     = 1,
                returnable     = true,
            },
        }

        local early_branch
        local mid_branch
        local late_branch

        -- place Mines
        if math.random(2) == 1 then
            early_branch = mines_data
            early_branch.size  = 3
        else
            mid_branch = mines_data
            mid_branch.size  = 2
        end

        -- place Terminal
        if math.random(3) > 1 then
            if mid_branch then
                late_branch = valhalla_data
                late_branch.size = 2
            else
                mid_branch = valhalla_data
                mid_branch.size = 3
            end
        end

        -- place rest
        local remain = { rift_data, mimir_data }
        if not early_branch then
            early_branch = table.remove( remain, math.random( #remain ) )
            early_branch.size = 3
        end
        if not mid_branch then
            mid_branch = table.remove( remain, math.random( #remain ) )
        end
        if not late_branch then
            late_branch = table.remove( remain, math.random( #remain ) )
            late_branch.size = 2
        end

        early_branch.depth = 3
        mid_branch.depth   = 4
        late_branch.depth  = 5

        data.level[2].branch = world.add_branch( early_branch )
        data.level[3].branch = world.add_branch( mid_branch )
        data.level[4].branch = world.add_branch( late_branch )

        local conamara_data = {
            name           = "Conamara Chaos Biolabs",
            episode        = 2,
            depth          = 0,
            size           = 2,
            enemy_list     = "europa",
            enemy_mod      = { demon = 2, cryo = 0.5 },
            blueprint      = "level_europa_biolabs",
            dlevel_mod     = 1,
            lootbox_count  = 4,
            quest = {
                list = "europa",
                flavor = "conamara",
            },
            rewards        = {
                "lootbox_medical",
                { "medical_station", swap = 1, },
                { "lootbox_armor" },
            },
            events     = {
                "event_low_light",
                "event_volatile_storage",
                "event_infestation",
                "event_lockdown",
                "event_vault",
                "event_exalted_summons",
                "event_contamination",
                { "event_windchill", 2.0 },
            },
            event      = { 100, math.random(3), },
            special = {
                blueprint      = "level_europa_containment",
                ilevel_mod     = 3,
                dlevel_mod     = 1,
                returnable     = true,
            },
        }

        local dig_data = {
            name           = "Europa Dig Zone",
            episode        = 2,
            depth          = 0,
            size           = 3,
            enemy_list     = "europa",
            enemy_mod      = { demon = 2, },
            blueprint      = "level_europa_dig_zone",
            dlevel_mod     = 1,
            lootbox_count  = 4,
            quest = {
                list = "europa",
                flavor = "dig_zone",
            },
            rewards        = {
                "lootbox_medical",
                { "medical_station", swap = 1, },
                { "lootbox_armor" },
            },
            events     = {
                { "event_exalted_summons", 2.0, },
                "event_vault",
                "event_exalted_curse",
            },
            event   = { 100, math.random(3), },
            special = {
                blueprint      = "level_europa_tyre",
                ilevel_mod     = 3,
                dlevel_mod     = 1,
                returnable     = true,
            },
        }

        local asterius_data = {
            name           = "Asterius Habitat",
            episode        = 2,
            depth          = 0,
            size           = 3,
            enemy_list     = "europa",
            enemy_mod      = { demon = 0.5, demon2 = 0.5, civilian = 1.5, },
            blueprint      = "level_europa_asterius",
            dlevel_mod     = 1,
            lootbox_count  = 4,
            quest = {
                list = "europa",
                flavor = "asterius",
            },
            rewards        = {
                "lootbox_medical",
                { "medical_station", swap = 1, },
                { "lootbox_armor" },
            },
            events     = {
                "event_low_light",
                "event_infestation",
                "event_lockdown",
                "event_exalted_summons",
                "event_contamination",
                { "event_windchill", 2.0 },
            },
            event   = { 100, math.random(3), },
            special = {
                blueprint      = "level_europa_breach",
                ilevel_mod     = 3,
                dlevel_mod     = 1,
                returnable     = true,
            },
        }

        local ruins_data = {
            name           = "Europa Ruins",
            episode        = 2,
            depth          = 0,
            size           = 2,
            enemy_list     = "europa",
            enemy_mod      = { cryo = 2, bot = 0.5 },
            blueprint      = "level_europa_ruins",
            dlevel_mod     = 1,
            lootbox_count  = 4,
            quest = {
                list = "europa",
                flavor = "ruins",
            },
            rewards        = {
                "lootbox_medical",
                { "medical_station", swap = 1, },
                { "lootbox_armor" },
            },
            events     = {
                { "event_exalted_summons", 2.0, },
                "event_vault",
                "event_exalted_curse",
                { "event_windchill", 2.0 },
            },
            event   = { 100, math.random(3), },
            special = {
                blueprint      = "level_europa_temple",
                ilevel_mod     = 3,
                dlevel_mod     = 1,
                returnable     = true,
            },
        }

        local europa_lists = {
            { asterius_data, ruins_data, conamara_data },
            { asterius_data, ruins_data, dig_data },
            { conamara_data, ruins_data, dig_data },
            { conamara_data, asterius_data, ruins_data, },
            { asterius_data, dig_data, ruins_data, },
            { conamara_data, dig_data, ruins_data, },
        }
        local europa_pick = europa_lists[math.random( #europa_lists )]
        early_branch = europa_pick[1]
        mid_branch   = europa_pick[2]
        late_branch  = europa_pick[3]

        early_branch.depth = 10
        mid_branch.depth   = 11
        late_branch.depth  = 12
        early_branch.size  = 3
        late_branch.size   = 2

        data.level[9].branch  = world.add_branch( early_branch )
        data.level[10].branch = world.add_branch( mid_branch )
        data.level[11].branch = world.add_branch( late_branch )

        local blacksite_data = {
            name           = "Io Black Site",
            episode        = 3,
            depth          = 0,
            size           = 2,
            enemy_list     = "beyond",
            enemy_mod      = { former = 2, },
            blueprint      = "level_io_blacksite",
            dlevel_mod     = 1,
            lootbox_count  = 5,
            quest = {
                list = "io",
                flavor = "blacksite",
            },
            rewards        = {
                "lootbox_medical",
                { "medical_station", swap = 1, },
            },
            events     = {
                "event_volatile_storage",
                "event_infestation",
                "event_vault",
                "event_exalted_summons",
                "event_exalted_curse",
                "event_contamination",
                { "event_desolation", 2.0 },
            },
            event   = { 100, math.random(3), },
            special = {
                blueprint      = "level_io_vault",
                ilevel_mod     = 3,
                dlevel_mod     = 1,
                returnable     = true,
            },
        }

        local crilab_data = {
            name           = "CRI Laboratory",
            episode        = 3,
            depth          = 0,
            size           = 2,
            enemy_list     = "cri",
            blueprint      = "level_io_cri_labs",
            dlevel_mod     = 1,
            lootbox_count  = 5,
            quest = {
                list = "io",
                flavor = "laboratory",
            },
            rewards        = {
                "lootbox_medical",
                { "medical_station", swap = 1, },
            },
            events     = {
                "event_low_light",
                "event_vault",
                "event_exalted_summons",
            },
            event   = { 100, math.random(3), },
            special = {
                blueprint      = "level_io_armory",
                ilevel_mod     = 3,
                dlevel_mod     = 1,
                returnable     = true,
            },
        }

        local nox_data = {
            name           = "Mephitic Mines",
            episode        = 3,
            depth          = 0,
            size           = 2,
            enemy_list     = "io",
            blueprint      = "level_io_mephitic",
            enemy_mod      = { cri = 0.0, toxic = 4.0, },
            dlevel_mod     = 1,
            lootbox_count  = 5,
            quest = {
                list = "io",
                flavor = "mephitic",
            },
            rewards        = {
                "lootbox_medical",
                { "medical_station", swap = 1, },
                { "terminal_ammo", level = 2, },
            },
            events     = {
                "event_exalted_summons",
                "event_exalted_curse",
            },
            event   = { 100, math.random(3), },
            special = {
                blueprint      = "level_io_noxious",
                ilevel_mod     = 3,
                dlevel_mod     = 1,
                returnable     = true,
            },
        }

        local halls_data = {
            name           = "Shadow Halls",
            episode        = 3,
            depth          = 0,
            size           = 3,
            enemy_list     = "io",
            enemy_mod      = { former = 0.5, bot = 0.5, cri = 0 },
            blueprint      = "level_io_halls",
            dlevel_mod     = 1,
            lootbox_count  = 5,
            quest = {
                list = "io",
                flavor = "halls",
            },
            rewards        = {
                "lootbox_medical",
                { "medical_station", swap = 1, },
                { "terminal_ammo", level = 2, },
            },
            events     = {
                "event_low_light",
                "event_volatile_storage",
                "event_infestation",
                "event_vault",
                "event_exalted_summons",
                "event_exalted_curse",
            },
            event   = { 100, math.random(3), },
            special = {
                blueprint      = "level_io_cathedral",
                ilevel_mod     = 3,
                dlevel_mod     = 1,
                returnable     = true,
            },
        }

        local io_pick = { blacksite_data, crilab_data, nox_data }
        -- remove one, add ruins
        table.remove( io_pick, math.random( #io_pick ) )
        io_pick[3] = halls_data

        early_branch  = table.remove( io_pick, math.random( #io_pick ) )
        mid_branch    = table.remove( io_pick, math.random( #io_pick ) )
        late_branch   = table.remove( io_pick, math.random( #io_pick ) )

        early_branch.depth = 17
        mid_branch.depth   = 18
        late_branch.depth  = 19
        early_branch.size  = 3
        late_branch.size   = 2

        data.level[16].branch = world.add_branch( early_branch )
        data.level[17].branch = world.add_branch( mid_branch )
        data.level[18].branch = world.add_branch( late_branch )

        local ossuary_data = {
            name           = "Ossuary",
            episode        = 4,
            depth          = 23,
            size           = 2,
            enemy_list     = "dante",
            enemy_mod      = { demon = 2.0 },

            blueprint      = "level_dante_ossuary",
            dlevel_mod     = 1,
            lootbox_count  = 4,
            quest = {
                no_info = true,
                list = "dante",
            },
            rewards       = {
                "dante_lootbox_medical",
                "dante_lootbox_ammo",
            },
            events     = {
                { "event_exalted_summons", 3.0, },
                { "event_hunt", 2.0, },
            },
            lootbox_table = "dante_lootbox",
            event      = { DIFFICULTY*25, math.random(2), },
            special = {
                blueprint      = "level_ossuary_abattoir",
                ilevel_mod     = 3,
                dlevel_mod     = 1,
                returnable     = true,
            },
        }

        data.level[22].branch = world.add_branch( ossuary_data )

        local level_5 = "level_callisto_docks"
        if math.random(2) == 1 then
            level_5 = "level_callisto_military"
        end
        data.level[5].special = world.add_special{
            episode        = 1,
            depth          = 5,
            blueprint      = level_5,
            ilevel_mod     = 2,
            dlevel_mod     = 1,
            branch_index   = 1,
            returnable     = true,
        }

        local level_12 = "level_europa_refueling"
        if math.random(2) ~= 1 then
            level_12 = "level_europa_pit"
        end

        data.level[12].special = world.add_special{
            episode        = 2,
            depth          = 12,
            blueprint      = level_12,
            ilevel_mod     = 3,
            dlevel_mod     = 1,
            branch_index   = 2,
            returnable     = true,
        }

        local level_19 = "level_io_warehouse"
        if math.random(2) > 1 then
            level_19 = "level_io_lock"
        end

        data.level[19].special = world.add_special{
            episode        = 3,
            depth          = 19,
            blueprint      = level_19,
            ilevel_mod     = 3,
            dlevel_mod     = 1,
            branch_index   = 3,
            returnable     = true,
        }

        data.level[22].special = world.add_special{
            episode        = 4,
            depth          = 22,
            next           = 23,
            blueprint      = "level_beyond_crucible",
            ilevel_mod     = 3,
            dlevel_mod     = 1,
            branch_index   = 4,
        }
        data.level[22].special_hidden = true

        data.level[23].special = world.add_special{
            episode        = 4,
            depth          = 23,
            blueprint      = "level_dante_inferno",
            ilevel_mod     = 3,
            dlevel_mod     = 1,
            branch_index   = 4,
        }

        data.cot.level_index = world.add_special{
            episode        = 1,
            depth          = 1,
            blueprint      = "level_cot",
            lootbox_count  = 4,
            ilevel_mod     = 1,
            dlevel_mod     = 1,
            branch_index   = 1,
            returnable     = true,
            rewards        = {},
        }

        for _,linfo in ipairs( data.level ) do
            linfo.lootbox_count = linfo.lootbox_count or 0
            linfo.rewards       = linfo.rewards or {}
            if linfo.lootbox_count > 0 then
                if DIFFICULTY == 0 then
                    linfo.lootbox_count = linfo.lootbox_count + 1
                elseif DIFFICULTY == 1 then
                    if math.random( 100 ) > 33 then
                        linfo.lootbox_count = linfo.lootbox_count + 1
                    end
                end
            end

            assert( linfo.blueprint )
            if blueprints[linfo.blueprint].text then
                local name = blueprints[linfo.blueprint].text.name
                if type( name ) == "string" then
                    linfo.name = name
                end
            end
            linfo.name = linfo.name or ""
        end
        world.data.special_levels = 8

        -- pick guaranteed unique location
        local roll = math.random(100)
        if roll <= 20 then
            world.data.unique.guaranteed = 1
        elseif roll <= 60 then
            world.data.unique.guaranteed = 2
        else
            world.data.unique.guaranteed = 3
        end
    end,
    on_setup = function( )
        if DIFFICULTY == 0 then
            core.global_mod.vhard = 0.0
            core.global_mod.hard  = 0.5
        elseif DIFFICULTY == 1 then
            core.global_mod.vhard = 0.5
            core.global_mod.hard  = 0.5
        end
    end,
    on_next = function( next )
        local index = world.next( next )
        return index
    end,
    on_load = function( player )
        world.initialize()
        world.set_klass( gtk.get_klass_id( player ) )
    end,
    on_init = function( player )
        local klass_id = gtk.get_klass_id( player )
        world.set_klass( klass_id )

        player.statistics.data.special_levels.generated  = world.data.special_levels
        player.statistics.data.special_levels.accessible = 4

        if world.data.no_quests then return end

        -- generate quests
        local quest_used = {}

        for _,b in ipairs( world.data.branch ) do
            if b.quest and b.quest.list and not b.quest.no_info then
                local ilist = core.lists.quest_info[b.quest.list]
                local slist = core.lists.quest_short[b.quest.list]
                if ilist then
                    local target
                    local source
                    if #b.index <= 3 then
                        target  = b.index[ math.random( math.min( #b.index, 2 ) ) ]
                        local entry   = b.index[1]
                        local pbranch = world.data.branch[ b.prev_branch ]
                        local epoint
                        for idx,id in ipairs( pbranch.index ) do
                            if world.data.level[id].branch == entry then
                                epoint = idx
                                break
                            end
                        end
                        local pos = 1 + math.random( epoint - 1 )
                        source = pbranch.index[ pos ]
                    else
                        target  = b.index[2 + math.random( 3 )]
                        source  = b.index[2]
                    end
                    local sid
                    local short = true
                    if #b.index < 3 and math.random(2) == 1 then
                        short = false
                    end
                    if short then
                        if #b.index < 3 then
                            target = b.index[1]
                        elseif #b.index > 3 then
                            target = b.index[6]
                        end
                        sid = slist:roll( world.data.level[target].depth, quest_used, true )
                    end
                    if not sid then
                        sid = ilist:roll( world.data.level[target].depth, quest_used, true )
                    end
                    quest_used[sid] = 0
                    local idx = world:add_quest( player, world:create_entity( sid, target ) )
                    table.insert( world.data.level[source].quest, idx )
                end
            end
        end

        -- extra quest for deep branches
        for _,b in ipairs( world.data.branch ) do
            if #b.index >= 3 and b.quest and b.quest.list and not b.quest.no_info then
                local ilist = core.lists.quest_info[b.quest.list]
                if ilist then
                    local tgt = 3
                    local src = 1
                    if #b.index > 3 then -- main branch
                        tgt = 4 + math.random( #b.index - 5 )
                        src = 1 + math.random( 3 )
                    end
                    local qid = ilist:roll( world.data.level[b.index[tgt]].depth, quest_used, true )
                    quest_used[qid] = 0
                    local idx = world:add_quest( player, world:create_entity( qid, b.index[tgt] ) )
                    table.insert( world.data.level[b.index[src]].quest, idx )
                end
            end
        end
        -- generate lock events
        for _,b in ipairs( world.data.branch ) do
            local list = core.lists.quest_branch_lock[b.quest.list]
            if #(b.index) > 5 then
                local tidx = b.index[2]
                local lidx = b.index[2+math.random(2)]
                if world.data.level[lidx].branch then
                    local qid = list:roll( world.data.level[tidx].depth, quest_used, true )
                    quest_used[qid] = 0
                    local idx = world:add_quest( player, world:create_entity( qid, lidx ) )
                    table.insert( world.data.level[tidx].quest, idx )
                end
            end
        end
    end,
    on_end   = function( player, result )
        if result > 0 then
            ui:alert{
                delay = 3000,
                position = ivec2( -1, 18 ),
                size = ivec2( 30, 6 ),
                content = "     {R"..ui:text("ui.lua.common.connection_lost").."}\n "..ui:text("ui.lua.common.continue"),
                footer = " ",
                win = true,
            }
            world:lua_callback( player, "on_win_game" )
            world:play_voice( "vo_beyond_ending" )
        elseif result == 0 then
            ui:post_mortem( result, true )
            ui:dead_alert()
        elseif result < 0 then
            ui:post_mortem( result, true )
        end
    end,
    on_stats = function( player, win )
        if win then
            return
        end
    end,
    on_entity = function( entity )
        world.on_entity( entity )
    end,
}
