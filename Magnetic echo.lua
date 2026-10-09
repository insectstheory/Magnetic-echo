-- Magnetic echo
-- Insects Theory 2026
--
-- ENC1 = time 
-- ENC2 = repeats 
-- ENC3 = mix
-- KEY2 = head select
-- KEY3 = play mod:off/play/repeat
-- KEY1 (hold) = Alt
-- ALT + ENC1 = Spacing 
-- ALT + ENC2 = Wear 
-- ALT + ENC3 = Lvl
-- ALT + KEY2 = Sound on sound: echo -> sos (overdub) -> loop (freeze)
-- ALT + KEY3 = Delete

local TAPE_MODES = {"echo", "sos", "loop"}
local HEAD_MODES = {"off", "play", "repeat"}
local LOOP = 3.2            -- lenght
local D1 = 0.4              -- distance
local D_MAX = D1 * 7        -- spacing massimo (2.0): testina 4 a D1 * (1 + 3 * 2)
local PAN = {-1, 1, -0.5, 0.5}
local WRITER = 1            -- 
local RATE_SLEW = 0.12      -- capstan start
local tape_mode = 1
local sel = 1               -- head select
local alt = false
local wobble_val = 0
local drop_gain, drop_until = 1, 0
local syncing, ready = false, false
local space_id = 0
local ui_metro, lfo_metro
local UI_FPS = 20
local INTRO_TIME = 4
local reel_angle, reel_spin = 0, 0
local vu_l, vu_r, vu = 0, 0, 0
local amp_polls = {}
local intro_start, intro_active = 0, false
local msg, msg_until = "", 0
local function flash(s)
  msg = s
  msg_until = util.time() + 1.2
end
local function head_voice(k) return k + 1 end
local function head_dist(k)
  return D1 * (1 + (k - 1) * params:get("spacing"))
end
local function head_mode(k) return params:get("head" .. k .. "_mode") end
-- Rate
local function base_rate()
  return D1 / (params:get("time") / 1000)
end

local function apply_rate()
  local r = base_rate() * (1 + wobble_val)
  for v = 1, 5 do softcut.rate(v, r) end
end

-- Lvl 

local function apply_levels()
  local mx = params:get("mix")
  local wet = math.min(1, 2 * mx) * params:get("out_level")
  audio.level_monitor(math.min(1, 2 * (1 - mx)))
  local spread = params:get("spread")
  for k = 1, 4 do
    local v = head_voice(k)
    local lvl = (head_mode(k) == 1) and 0 or params:get("head" .. k .. "_level")
    softcut.level(v, lvl * wet * drop_gain)
    softcut.pan(v, PAN[k] * spread)
  end
end

local function update_routing()
  local rep = params:get("repeats")
  local fb_n = 0
  for k = 1, 4 do if head_mode(k) == 3 then fb_n = fb_n + 1 end end

  local m = TAPE_MODES[tape_mode]
  if m == "echo" then
    softcut.rec_level(WRITER, 1.0)
    softcut.pre_level(WRITER, 0.0)   
  elseif m == "sos" then
    softcut.rec_level(WRITER, 1.0)
    softcut.pre_level(WRITER, rep)  
  else
    softcut.rec_level(WRITER, 0.0)
    softcut.pre_level(WRITER, 1.0)   
  end

  for k = 1, 4 do
    local g = 0
    if m == "echo" and head_mode(k) == 3 and fb_n > 0 then g = rep / fb_n end
    softcut.level_cut_cut(head_voice(k), WRITER, g)
  end
end

local function post(name)
  return softcut["post_filter_" .. name] or softcut["filter_" .. name]
end

local function apply_filter()
  local wear = params:get("wear")
  local gap = 15000 * (0.2 ^ wear)
  local fc = math.min(params:get("tone"), gap * 1.6)
  for k = 1, 4 do
    local v = head_voice(k)
    post("dry")(v, 0.0)
    post("lp")(v, 1.0)
    post("hp")(v, 0.0)
    post("bp")(v, 0.0)
    post("br")(v, 0.0)
    post("fc")(v, fc)
    post("rq")(v, 1.2)
  end
end

-- wow & flutter 
local function lfo_tick()
  local amt = params:get("wobble")
  local wear = params:get("wear")
  local t = util.time()
  local depth = amt * (0.002 + 0.012 * wear)
  local w = 0
  if depth > 0 then
    w = depth * (math.sin(t * 2 * math.pi * 0.6)
      + 0.5 * math.sin(t * 2 * math.pi * 1.9 + 1.1)
      + 0.4 * math.sin(t * 2 * math.pi * 4.7 + 2.3))
  end
  if w ~= wobble_val then
    wobble_val = w
    apply_rate()
  end

  local dg = 1
  if t < drop_until then
    dg = 0.3
  elseif wear > 0.35 and math.random() < (wear - 0.35) * 0.02 then
    drop_until = t + 0.04 + math.random() * 0.08
    dg = 0.3
  end
  if dg ~= drop_gain then
    drop_gain = dg
    apply_levels()
  end
end

-- sync

local function resync()
  if syncing then return end
  syncing = true
  clock.run(function()
    for k = 1, 4 do softcut.level(head_voice(k), 0) end
    clock.sleep(0.06)
    for v = 1, 5 do
      softcut.rate_slew_time(v, 0)
      softcut.rate(v, 0)
    end
    clock.sleep(0.02)
    softcut.position(WRITER, 0)
    for k = 1, 4 do
      softcut.position(head_voice(k), (LOOP - head_dist(k)) % LOOP)
    end
    clock.sleep(0.04)
    local r = base_rate()
    for v = 1, 5 do softcut.rate(v, r) end
    clock.sleep(0.02)
    for v = 1, 5 do softcut.rate_slew_time(v, RATE_SLEW) end
    apply_levels()
    syncing = false
  end)
end

local function clear_tape()
  softcut.buffer_clear_region_channel(1, 0, LOOP + 0.5, 0, 0)
  flash("cleared")
end

-- input

function key(n, z)
  if intro_active then return end
  if n == 1 then
    alt = (z == 1)
  elseif n == 2 and z == 1 then
    if alt then
      tape_mode = tape_mode % #TAPE_MODES + 1
      update_routing()
      flash(TAPE_MODES[tape_mode])
    else
      sel = sel % 4 + 1
    end
  elseif n == 3 and z == 1 then
    if alt then
      clear_tape()
    else
      params:set("head" .. sel .. "_mode", head_mode(sel) % #HEAD_MODES + 1)
    end
  end
  redraw()
end

function enc(n, d)
  if intro_active then return end
  if alt then
    if n == 1 then
      params:delta("spacing", d)
    elseif n == 2 then
      params:delta("wear", d)
    elseif n == 3 then
      params:delta("head" .. sel .. "_level", d)
    end
  else
    if n == 1 then
      params:delta("time", d)
    elseif n == 2 then
      params:delta("repeats", d)
    elseif n == 3 then
      params:delta("mix", d)
    end
  end
  redraw()
end

-- display

local function circle(x, y, r)
  screen.move(x + r, y)
  screen.circle(x, y, r)
end

local function anim_tick(dt)
  local target = base_rate() * 4
  if tape_mode == 3 then target = target * 0.6 end
  reel_spin = reel_spin + (target - reel_spin) * 0.2
  reel_angle = (reel_angle + reel_spin * dt) % (2 * math.pi)
  vu = math.max(vu_l, vu_r)
end

local function draw_reel(cx, cy, r, lv)
  screen.level(lv)
  circle(cx, cy, r)
  screen.stroke()
  for i = 0, 2 do
    local a = reel_angle + i * 2 * math.pi / 3
    screen.move(cx, cy)
    screen.line(cx + math.cos(a) * (r - 2), cy + math.sin(a) * (r - 2))
    screen.stroke()
  end
end

local function draw_intro()
  local t = (util.time() - intro_start) / INTRO_TIME
  if t >= 1 then
    intro_active = false
    return
  end
  local fade = math.min(1, (1 - t) / 0.15)
  local function L(x) return math.max(0, math.floor(x * fade + 0.5)) end

  local grow = math.min(1, t / 0.35)
  grow = 1 - (1 - grow) ^ 3
  local r = 11 * grow
  local ang = 24 * (1 - (1 - t) ^ 2)
  reel_angle = ang
  draw_reel(40, 22, r, L(12))
  draw_reel(88, 22, r, L(12))
  screen.level(L(6))
  screen.move(40 + r, 22)
  screen.line(88 - r, 22)
  screen.stroke()

  local word = "magnetic echo"
  local n = 0
  if t >= 0.3 then n = math.min(#word, math.floor((t - 0.3) / 0.4 * #word) + 1) end
  screen.font_size(12)
  local x0 = 64 - screen.text_extents(word) / 2
  screen.level(L(15))
  screen.move(x0, 54)
  screen.text(word:sub(1, n))

  screen.font_size(8)
  if t > 0.7 then
    screen.level(L(6))
    screen.move(64, 63)
    screen.text_center("4-head echo")
  end
end

local function fmt2(v) return string.format("%.2f", v) end

function redraw()
  screen.clear()
  screen.aa(0)
  if intro_active then
    draw_intro()
    if intro_active then
      screen.update()
      return
    end
  end
  screen.font_size(8)

  screen.level(15)
  screen.move(0, 8)
  screen.text("magnetic echo")
  if util.time() < msg_until then
    screen.level(15)
    screen.move(72, 8)
    screen.text(msg)
  else
    screen.level(tape_mode == 1 and 6 or 15)
    screen.move(72, 8)
    screen.text(TAPE_MODES[tape_mode])
  end
  screen.level(alt and 15 or 2)
  screen.move(110, 8)
  screen.text("ALT")

  -- 4 head, 4 horseman, 4 seasons
  local ty = 30
  draw_reel(12, ty, 9, 8)
  draw_reel(116, ty, 9, 8)
  screen.level(5)
  screen.move(21, ty)
  screen.line(107, ty)
  screen.stroke()

  local rec_x = 30
  local rec_lv = 8
  if tape_mode == 2 then rec_lv = (math.floor(util.time() * 4) % 2 == 0) and 15 or 5 end
  screen.level(rec_lv)
  circle(rec_x, ty, 2 + math.floor(vu * 3))
  screen.fill()

  local sp = params:get("spacing")
  for k = 1, 4 do
    local x = rec_x + 10 + (head_dist(k) / D_MAX) * 66
    local m = head_mode(k)
    local lvl = params:get("head" .. k .. "_level")
    if m == 1 then
      screen.level(3)
      screen.rect(x - 1, ty - 1, 2, 2)
      screen.fill()
    else
      local h = 4 + math.floor(lvl * 14)
      screen.level(k == sel and 15 or 8)
      screen.rect(x - 2, ty - h / 2, 4, h)
      if m == 3 then screen.fill() else screen.stroke() end
    end
    screen.level(k == sel and 15 or 4)
    screen.move(x, 47)
    screen.text_center(tostring(k))
  end

  screen.level(15)
  if alt then
    screen.move(0, 54)
    screen.text("space " .. fmt2(sp) .. "  wear " .. fmt2(params:get("wear")))
    screen.move(0, 63)
    screen.text("H" .. sel .. " lvl " .. fmt2(params:get("head" .. sel .. "_level")))
  else
    screen.move(0, 54)
    screen.text("time " .. math.floor(params:get("time")) .. "ms  rep " .. fmt2(params:get("repeats")))
    screen.move(0, 63)
    screen.text("mix " .. fmt2(params:get("mix")) .. "  H" .. sel .. " " .. HEAD_MODES[head_mode(sel)])
  end

  screen.update()
end

function init()
  audio.level_adc_cut(1.0)
  for i = 1, 3 do
    norns.enc.sens(i, 1)
    norns.enc.accel(i, true)
  end

  softcut.buffer_clear()

  for v = 1, 5 do
    softcut.enable(v, 1)
    softcut.buffer(v, 1)            
    softcut.pan(v, 0.0)
    softcut.rate(v, 1.0)
    softcut.rate_slew_time(v, RATE_SLEW)
    softcut.level_slew_time(v, 0.03)
    softcut.fade_time(v, 0.01)
    softcut.recpre_slew_time(v, 0.01)
    softcut.loop(v, 1)
    softcut.loop_start(v, 0)
    softcut.loop_end(v, LOOP)
    softcut.position(v, 0)
    softcut.play(v, 1)             
    softcut.rec(v, 0)
    softcut.rec_level(v, 0.0)
    softcut.pre_level(v, 1.0)
    softcut.level(v, 0.0)
    softcut.level_input_cut(1, v, 0.0)
    softcut.level_input_cut(2, v, 0.0)
  end

  softcut.rec(WRITER, 1)
  softcut.level_input_cut(1, WRITER, 1.0)
  softcut.level_input_cut(2, WRITER, 1.0)

  params:add_separator("magnetic echo")
  params:add_control("time", "time (tape speed)", controlspec.new(100, 1600, "exp", 1, 400, "ms"))
  params:set_action("time", function() apply_rate() end)
  params:add_control("repeats", "repeats", controlspec.new(0, 1, "lin", 0.01, 0.45))
  params:set_action("repeats", function() if ready then update_routing() end end)
  params:add_control("mix", "mix", controlspec.new(0, 1, "lin", 0.01, 0.5))
  params:set_action("mix", function() if ready then apply_levels() end end)
  params:add_control("spacing", "spacing", controlspec.new(0.25, 2.0, "lin", 0.01, 1.0))
  params:set_action("spacing", function()
    if not ready then return end
    space_id = space_id + 1
    local id = space_id
    clock.run(function()
      clock.sleep(0.3)
      if id == space_id then resync() end
    end)
  end)

  params:add_control("wear", "wear (tape age)", controlspec.new(0, 1, "lin", 0.01, 0.25))
  params:set_action("wear", function() if ready then apply_filter() end end)
  params:add_control("wobble", "wow & flutter", controlspec.new(0, 1, "lin", 0.01, 0.3))
  params:add_control("tone", "tone", controlspec.new(800, 16000, "exp", 1, 9000, "hz"))
  params:set_action("tone", function() if ready then apply_filter() end end)
  params:add_control("spread", "stereo spread", controlspec.new(0, 1, "lin", 0.01, 0.6))
  params:set_action("spread", function() if ready then apply_levels() end end)
  params:add_control("input", "input level", controlspec.new(0, 1, "lin", 0.01, 1.0))
  params:set_action("input", function(v)
    softcut.level_input_cut(1, WRITER, v)
    softcut.level_input_cut(2, WRITER, v)
  end)

  -- level + compressor
  params:add_control("out_level", "echo output level", controlspec.new(0, 2, "lin", 0.01, 1.4))
  params:set_action("out_level", function() if ready then apply_levels() end end)

  params:add_option("comp", "output compressor", {"off", "on"}, 1)
  params:set_action("comp", function(v) audio.comp_mix(v - 1) end)

  params:add_trigger("resync", "resync heads")
  params:set_action("resync", function() if ready then resync() end end)

  local def_mode = {3, 2, 2, 2}
  local def_lvl = {1.0, 0.7, 0.5, 0.35}
  for k = 1, 4 do
    params:add_option("head" .. k .. "_mode", "head " .. k, HEAD_MODES, def_mode[k])
    params:set_action("head" .. k .. "_mode", function()
      if ready then update_routing(); apply_levels() end
    end)
    params:add_control("head" .. k .. "_level", "head " .. k .. " level",
      controlspec.new(0, 1, "lin", 0.01, def_lvl[k]))
    params:set_action("head" .. k .. "_level", function() if ready then apply_levels() end end)
  end

  for i, side in ipairs({"l", "r"}) do
    local p = poll.set("amp_in_" .. side)
    p.time = 1 / 20
    p.callback = function(v)
      local x = math.min(1, v * 4)
      if side == "l" then vu_l = vu_l * 0.5 + x * 0.5 else vu_r = vu_r * 0.5 + x * 0.5 end
    end
    p:start()
    amp_polls[i] = p
  end
  ui_metro = metro.init(function()
    anim_tick(1 / UI_FPS)
    redraw()
  end, 1 / UI_FPS, -1)
  ui_metro:start()
  lfo_metro = metro.init(lfo_tick, 1 / 30, -1)
  lfo_metro:start()
  params:bang()
  ready = true
  apply_filter()
  update_routing()
  apply_rate()
  resync()
  intro_start = util.time()
  intro_active = true
  redraw()
end

function cleanup()
  for _, p in ipairs(amp_polls) do p:stop() end
  if ui_metro then ui_metro:stop() end
  if lfo_metro then lfo_metro:stop() end
  audio.level_monitor(1.0)
end

-- This is not the end , but you will never see me
