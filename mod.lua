-- example language mod

local language_table = {}

return {

  -- load our csv file with our new language
  load = function(mod_id)

    -- first we load the csv file
    -- the csv file is the same as the one you have in the full-game, but just reduced to one non-english language column
    -- this column is labelled 'rb'
    -- we use the special 'mod.read' API method to load files from our mod's folder
    -- we need to pass our mod's 'id' to use this
    local csv = mod.read(mod_id, 'locale.csv')

    -- then we're going to read the csv file into a format to use later
    -- see the start of 'ev_load' for how the game does this normally
    local language = tn.internals.csv.openstring(csv, {
      header = true
    })
    for fields in language:lines() do
      language_table[fields.key] = fields['rb']
    end

    -- next we'll add a new settings button to the settings menu
    -- see 'game/class/cl_controller:181' for how the game does this normally
    -- we're going to use the last language button (simplified chinese) to set a position
    local chinese = game.g.controller.props.settings['language_cn']
    local new_button = game.class.ui_language:new(chinese.ox + 18, chinese.oy, game.g.controller.props.settings, 'rb')
    print('Making button', new_button)

    -- at this point we have a button, but it's default function will crash because the game won't find a 'rb' column
    -- in the main 'game.g.locale_csv' global table
    -- so we're going to overwrite the click script of the new button
    -- see 'game/ui/ui_language' for the class and 'game/modules/md_ui:2756' for the 'setLanguage' function the game uses normally
    new_button.scripts.click = function()
      print('Setting custom language!')
      game.g.language = 'rb'
      -- save selection
      game.g.settings.language = 'rb'
      game.world.saveSettings()
      tn.internals.font_char_active = tn.internals.font_char
      tn.internals.font_char_special = ''
      -- else use default
      for fields in game.g.locale_csv:lines() do
        game.g.locale[fields.key] = language_table[fields.key]
      end
      game.ui.recacheLanguage()
    end


    -- then we'll add the new language to the languages list
    -- and a reference to our button on the controller, like other language buttons
    -- this means it'll position itself properly when the game resizes or changes between gamepad/mkb
    table.insert(game.g.language_list, 'rb')
    game.g.controller.props.settings['language_rb'] = new_button

    -- now when the game loads we'll have a button in the settings menu, and clicking it runs our scripts!
    -- however the button is blank, we need a new sprite for it!
    -- first we'll have to load an image containing our new sprite
    -- we build a special path using 'mod_id' to our mod's folder on disc
    local spritesheet = tn.class.texture:new('my_spritesheet', mod_id .. '/spritesheet.png')

    -- then we need to create the 'sprite' for our button
    -- if you look at the game's spritesheet (open .asesprite file, search slices for 'sp_button_language_en')
    -- you'll see language buttons all use the same generic button
    -- then have a special flag sprite drawn on top
    -- so we just need to add one new sprite called 'sp_button_language_rb'
    spritesheet:load({
      -- name of sprite, x pos, y pos, width, height, no. of frames
      { "sp_button_language_rb", 0, 0, 15, 11, 1},
    })

    -- finally, because we're setting our new language to the settings in the button script above
    -- that means when the game loads next time it'll try reading a 'rb' column
    -- but that doesn't exist yet as the mod isn't loaded!
    -- so we check if the game's language is set to our custom one and if so run our button script
    if game.g.language == 'rb' then
      new_button.scripts.click()
    end

    return true
  end

}
