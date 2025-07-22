class Firefighter
  attr_gtk

  def tick
    defaults
    render
    process_inputs
    calc
  end

  def defaults
    state.left_poles = [0, 2, 4]
    state.right_poles = [1, 3, 5]
    state.pole_index ||= 2
    state.speed = 10
    state.offset_left = 70
    state.offset_right = -7
    state.bug_offsetleft = 30
    state.bug_offsetright = -15
    state.bugs ||= []
    state.smokes ||= []
    state.score ||= 0
    state.hi_score ||= 0
    state.scene ||=  :menu
    state.bug_speed = 2.5
  end

  def get_fireman_x
    pole_x = state.poles_id[state.pole_index]

    if state.left_poles.include? (state.pole_index)
      return pole_x - state.offset_left
    elsif state.right_poles.include? (state.pole_index)
      return pole_x - state.offset_right
    else
      return pole_x
    end
  end

  def get_bug_x
    state.bug_x = state.poles_id.sample
  end

  def render
    play_bgm
    render_score
    render_menu
    render_game
  end

  def play_bgm
    state.bgm_mute ||= false
    if inputs.keyboard.key_down.m
      state.bgm_mute = !state.bgm_mute
      audio[:firefighter_sound] = { input: "sounds/firefighter-sound.ogg", paused: state.bgm_mute }
    end
    if state.tick_count == 0
      audio[:firefighter_sound] = { input: "sounds/firefighter-sound.ogg", looping: true, paused: state.bgm_mute }
    end
  end

  def render_score
    outputs.primitives << {x: 1110, y: 710, text: "HI SCORE: #{state.hi_score}", size_enum: 10, **large_white_typeset}
    outputs.primitives << {x: 10, y: 710, text: "SCORE: #{state.score}", size_enum: 10, **large_white_typeset}
  end

  def render_menu
    return unless state.scene == :menu
    render_overlay

    outputs.labels << {x: 640, y:410 , text: "FIREFIGHTER VS BUGS", size_enum: 15, alignment_enum: 1, **white}
    outputs.labels << {x: 640, y: 340, text: "Instructions: Press Arrows to Move", size_enum: 4, alignment_enum: 1, **white}
    outputs.labels << {x: 640, y:310 , text: "[Down] to Kill Bugs", size_enum: 4, alignment_enum: 1, **white}
    outputs.labels << {x: 640, y:280 , text: "[Enter] to Start", size_enum: 4, alignment_enum: 1, **white}
    outputs.labels << {x: 640, y:250 , text: "[M] to Mute Music", size_enum: 4, alignment_enum: 1, **white}

    outputs.labels << {x: 10, y: 60, text: "Code, Art, Music: maurmischief", **white}
    outputs.labels << {x: 10, y: 40, text: "Engine: DragonRuby GTK", **white}
  end

  def render_overlay
    overlay_rect = grid.rect.scale_rect(1.1, 0, 0)
    outputs.primitives << { x: overlay_rect.x, y: overlay_rect.y, w: overlay_rect.w, h: overlay_rect.h, r: 5, g: 0, b: 0, a: 230 }.solid!
  end

  def render_game
    render_game_over
    render_background
    render_poles
    render_bugs
    render_smoke
    render_fireman
    render_loser
  end

  def render_game_over
    return unless state.scene == :game_over
    render_loser
    outputs.labels << {x: 638, y: 358, text: score_text, size_enum: 20, alignment_enum: 1}
    outputs.labels << {x: 635, y: 360, text: score_text, size_enum: 20, alignment_enum: 1, r: 255, g: 255, b:255}
    outputs.labels << {x: 640, y: 300, text: "PLAY AGAIN? PRESS [ENTER]", size_enum: 10, alignment_enum: 1}
    outputs.labels << {x: 637, y: 302, text: "PLAY AGAIN? PRESS [ENTER]", size_enum: 10, alignment_enum: 1, r: 255, g: 255, b:255}
    outputs.labels << {x: 640, y: 262, text: "[ESC] Back to Menu", size_enum: 10, alignment_enum: 1}
    outputs.labels << {x: 637, y: 262, text: "[ESC] Back to Menu", size_enum: 10, alignment_enum: 1, r: 255, g: 255, b:255}
  end

  def render_background
    outputs.sprites << {x: 0, y: 0, w: 1280, h: 720, path: 'sprites/misc/firestation-bg.png'}
  end

  def render_poles
    state.P1 ||= {x: 145, y: 0, w: 35, h: 720, path: 'sprites/misc/pole-l.png'}
    state.P2 ||= {x: 595, y: 0, w: 35, h: 720, path: 'sprites/misc/pole-l.png'}
    state.P3 ||= {x: 1055, y: 0, w: 35, h: 720, path: 'sprites/misc/pole-l.png'}
    state.P4 ||= {x: 160, y: 0, w: 38, h: 720, path: 'sprites/misc/pole-r.png'}
    state.P5 ||= {x: 610, y: 0, w: 38, h: 720, path: 'sprites/misc/pole-r.png'}
    state.P6 ||= {x: 1070, y: 0, w: 38, h: 720, path: 'sprites/misc/pole-r.png'}

    outputs.sprites << [state.P1, state.P2, state.P3, state.P4, state.P5, state.P6]
    state.poles_id ||= [
      state.P1[:x],
      state.P4[:x],
      state.P2[:x],
      state.P5[:x],
      state.P3[:x],
      state.P6[:x],
    ]
  end

  def render_fireman
    state.firemen ||= {
      y: 590,
      w: 100,
      h: 100,
      path: 'sprites/misc/fireleft.png',
    }
    state.firemen.x = get_fireman_x

    if state.left_poles.include?(state.pole_index)
      state.firemen.path = 'sprites/misc/fireleft.png'
    elsif state.right_poles.include? (state.pole_index)
      state.firemen.path = 'sprites/misc/fireright.png'
    end

    if state.firemen.dead && state.left_poles.include?(state.pole_index)
      outputs.sprites << {
        x: get_fireman_x,
        y: state.firemen.y,
        w: 100,
        h: 100,
        path: 'sprites/misc/crybaby_left.png',
      }
    elsif state.firemen.dead && state.right_poles.include?(state.pole_index)
      outputs.sprites << {
        x: get_fireman_x,
        y: state.firemen.y,
        w: 100,
        h: 150,
        path: 'sprites/misc/crybaby_right.png',
      }  
    else
      outputs.sprites << state.firemen
    end
  end

  def render_bugs
    sprite_index = 0.frame_index(count: 2, hold_for: 10, repeat: true)

    state.bugs.each do |bug|
      sprite_path = case bug[:name]
                    when :ant
                      "sprites/misc/ant/ant_#{sprite_index}.png"
                    when :bee
                      "sprites/misc/bee/bee_#{sprite_index}.png"
                    when :ladybug
                      "sprites/misc/ladybug/ladybug_#{sprite_index}.png"
                    when :rhinobug
                      "sprites/misc/rhinobug/rhinobug_#{sprite_index}.png"
                    when :dragonfly
                      "sprites/misc/dragonfly/dragonfly_#{sprite_index}.png"
                    end
                                      
      outputs.sprites << {
        x: bug.x,
        y: bug.y,
        w: bug.w,
        h: bug.h,
        path: sprite_path,
        flip_horizontally: bug[:flip_horizontally] || false
      }
    end
  end

  def render_smoke
    state.smokes.each do |s| 
      outputs.sprites << {
        x: s.x,
        y: s.y,
        w: s.w,
        h: s.h,
        path: s.path,
      }
    end
  end

  def render_loser
    return unless state.scene == :game_over
    state.losers ||= {
      x: 470,
      y: 410,
      w: 300,
      h: 250,
    }
    state.losers_tick_start ||= state.tick_count

    if state.tick_count - state.losers_tick_start < 240
      losers_sprite_index = 0.frame_index(count: 3, hold_for: 10, repeat: true)
      state.losers.path = "sprites/misc/crier_#{losers_sprite_index}.png"
      outputs.primitives << { x: 460, y: 400, w: 310, h: 260, r: 0, g: 0, b: 0, a: 10 }.solid!
      outputs.sprites << state.losers
    end
  end

  def process_inputs
    process_inputs_menu
    process_inputs_game
    process_inputs_reset
  end

  def process_inputs_menu
    return unless state.scene == :menu
    changediff = inputs.keyboard.key_down.tab || inputs.controller_one.key_down.select
    if inputs.mouse.click
      p = inputs.mouse.click.point
      if (p.y >= 165) && (p.y < 200) && (p.x >= 500) && (p.x < 800)
        changediff = true
      end
    end

    if inputs.keyboard.key_down.enter || inputs.controller_one.key_down.start || inputs.controller_one.key_down.a
      reset_game
    end

    if inputs.keyboard.key_down.escape || (inputs.mouse.click && !changediff) || inputs.controller_one.key_down.b
      render_game
    end
  end

  def process_inputs_game
    return unless state.scene == :game
    if inputs.up
      state.firemen.y += state.speed
    elsif inputs.down
      state.firemen.y -= state.speed

      state.bugs.each do |bug|
        next if bug.dead
        if geometry.intersect_rect?(state.firemen, bug)
          bug.dead = true
          state.smokes << {
            x: bug.x,
            y: bug.y,
            w: 32,
            h: 32,
            path: 'sprites/misc/explosion-2.png',
            tick_count: 0
          }
          state.score += 1
          outputs.sounds << "sounds/fart-sound.wav"
        end
      end
      state.bugs.reject! { |b| b[:dead]}
    end

    if inputs.keyboard.key_down.left && state.pole_index > 0
      state.pole_index -= 1
      outputs.sounds << "sounds/fwip-sound.wav"
    elsif inputs.keyboard.key_down.right && 
    state.pole_index <
    state.poles_id.length - 1
      state.pole_index += 1
      outputs.sounds << "sounds/fwip-sound.wav"
    end

    if state.firemen.x + state.firemen.w > grid.w
      state.firemen.x = grid.w - state.firemen.w
    end

    if state.firemen.x < 0
      state.firemen.x = 0
    end

    if state.firemen.y + state.firemen.h > grid.h - 40
      state.firemen.y = grid.h - state.firemen.h - 40
    end

    if state.firemen.y < 0
      state.firemen.y = 0
    end
  end

  def process_inputs_reset
    return unless state.scene == :game_over
    changediff = inputs.keyboard.key_down.tab || inputs.controller_one.key_down.select
    if inputs.mouse.click
      p = inputs.mouse.click.point
      if (p.y >= 165) && (p.y < 200) && (p.x >= 500) && (p.x < 800)
        changediff = true
      end
    end

    if inputs.keyboard.key_down.enter || inputs.controller_one.key_down.start || inputs.controller_one.key_down.a
      reset_game
    end

    if inputs.keyboard.key_down.escape || (inputs.mouse.click && !changediff) || inputs.controller_one.key_down.b
      change_to_scene :menu
    end
  end

  def calc
    return unless state.scene == :game
    calc_game_over
    calc_bugs_spawn
    calc_bugs_movement
    calc_smokes
  end

  def calc_bugs_spawn
    state.spawn_timer ||= 0
    state.spawn_timer += 12
    return unless state.spawn_timer > 120
    state.spawn_timer = 0
    state.bug_types ||= [
      {name: :ant, w: 50, h: 50},
      {name: :bee, w: 50, h: 50},
      {name: :ladybug, w: 50, h: 50},
      {name: :rhinobug, w: 50, h: 50},
      {name: :dragonfly, w: 50, h: 50},
    ]

    template = state.bug_types.sample
    pole_nim = (state.left_poles + state.right_poles).sample
    pole_x = state.poles_id[pole_nim]

    is_left = state.left_poles.include?(pole_nim)
    bug_x = pole_x - (is_left ? state.bug_offsetleft : state.bug_offsetright)
    new_bug = {
      name: template[:name],
      x: bug_x,
      y: rand(11) - 40,
      w: template[:w],
      h: template[:h],
      flip_horizontally: !is_left
    }
    state.bugs << new_bug
  end

  def calc_bugs_movement
    return if game_over?
    state.bugs.each do |b|
      b[:y] += state.bug_speed
    end
    state.bugs.reject! { |b| b[:y] > 700}
  end

  def calc_smokes
    state.smokes.each do |s|
      s[:tick_count] ||= 0
      s[:tick_count] += 1
    end
    state.smokes.reject! { |s| s[:tick_count] > 10}
  end

  def calc_game_over
    return if game_over?

    state.bugs.each do |bug|
      next if bug.dead
      if geometry.intersect_rect?(state.firemen, bug)
        unless inputs.down
          state.firemen.dead = true
          state.scene = :game_over
          state.hi_score = state.hi_score.greater(state.score)
          outputs.sounds << "sounds/cry-sound.wav"
          return
        end
      end
    end
    state.losers_tick_start = nil
  end

  def game_over?
    state.firemen.dead 
  end

  def white
    { r: 255, g: 255, b: 255, font: "fonts/western.ttf" }
  end

  def large_white_typeset
    {size_enum: 5, alignment_enum: 0, r: 255, g: 255, b: 255, font: "fonts/vanillawhale.otf"}
  end

  def score_text
    return "SCORE: 0 (WOMP WOMP)" if state.score == 0
    return "HI SCORE: #{state.score}" if state.score == state.hi_score
    return "SCORE: #{state.score}"
  end

  def reset_game
    change_to_scene :game
    state.bugs = []
    state.smokes =[]
    state.score = 0
    state.firemen.dead = false
    state.firemen.y = 590
    state.pole_index = 2
  end

  def change_to_scene scene
    state.scene = scene
    inputs.keyboard.clear
    inputs.controller_one.clear
  end
end

def tick args
  $firefighter ||= Firefighter.new
  $firefighter.args = args
  $firefighter.tick
end

$firefighter = nil


