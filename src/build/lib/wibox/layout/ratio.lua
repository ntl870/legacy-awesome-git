---------------------------------------------------------------------------
--- A layout filling all the available space. Each widget is assigned a
-- ratio (percentage) of the total space. Multiple methods are available to
-- adjust this ratio.
--
--
--
--![Usage example](../images/AUTOGEN_wibox_layout_defaults_ratio.svg)
--
-- @usage
-- local w = wibox.widget {
--     generic_widget( 'first'  ),
--     generic_widget( 'second' ),
--     generic_widget( 'third'  ),
--     layout  = wibox.layout.ratio.horizontal
-- }
-- w:adjust_ratio(2, 0.44, 0.33, 0.22)
-- @author Emmanuel Lepage Vallee
-- @copyright 2016 Emmanuel Lepage Vallee
-- @layoutmod wibox.layout.ratio
-- @supermodule wibox.layout.flex
-- @see 03-declarative-layout.md
---------------------------------------------------------------------------

local base  = require("wibox.widget.base" )
local flex  = require("wibox.layout.flex" )
local table = table
local pairs = pairs
local floor = math.floor
local gmath = require("gears.math")
local gtable = require("gears.table")
local unpack = unpack or table.unpack -- luacheck: globals unpack (compatibility with Lua 5.1)

local ratio = {}

--- The widget used to fill the spacing between the layout elements.
--
-- By default, no widget is used.
--
--
--
--![Usage example](../images/AUTOGEN_wibox_layout_ratio_spacing_widget.svg)
--
-- @usage
-- -- Use the separator widget directly
-- local w1 = wibox.widget {
--     spacing        = 10,
--     spacing_widget = wibox.widget.separator,
--     layout         = wibox.layout.ratio.horizontal
-- }
-- -- Use a standard declarative widget construct
-- local w2 = wibox.widget {
--     spacing = 10,
--     spacing_widget = {
--         color  = '#00ff00',
--         shape  = gears.shape.circle,
--         widget = wibox.widget.separator,
--     },
--     layout = wibox.layout.ratio.horizontal
-- }
-- -- Use composed widgets
-- local w3 = wibox.widget {
--     spacing = 10,
--     spacing_widget = {
--         {
--             text   = 'F',
--             widget = wibox.widget.textbox,
--         },
--         bg     = '#ff0000',
--         widget = wibox.container.background,
--     },
--     layout = wibox.layout.ratio.horizontal
-- }
-- -- Use negative spacing to create a powerline effect
-- local w4 = wibox.widget {
--     spacing = -12,
--     spacing_widget = {
--         color  = '#ff0000',
--         shape  = gears.shape.powerline,
--         widget = wibox.widget.separator,
--     },
--     layout = wibox.layout.ratio.horizontal
-- }
--
-- @property spacing_widget
-- @tparam widget spacing_widget
-- @propemits true false
-- @interface layout

--- Add spacing between each layout widgets.
--
--
--
--![Usage example](../images/AUTOGEN_wibox_layout_ratio_spacing.svg)
--
-- @usage
-- for i=1, 5 do
--     local w = wibox.widget {
--         first,
--         second,
--         third,
--         spacing = i*3,
--         layout  = wibox.layout.ratio.horizontal
--     }
-- end
--
-- @property spacing
-- @tparam number spacing Spacing between widgets.
-- @propemits true false
-- @interface layout

-- Compute the sum of all ratio (ideally, it should be 1).
local function gen_sum(self, i_s, i_e)
    local sum, new_w = 0,0

    for i = i_s or 1, i_e or #self._private.widgets do
        if self._private.ratios[i] then
            sum = sum + self._private.ratios[i]
        else
            new_w = new_w + 1
        end
    end

    return sum, new_w
end

-- The ratios are expressed as percentages. For this to work, the sum of all
-- ratio must be 1. This function attempt to adjust them. Space can be taken
-- from or added to a ratio when widgets are being added or removed. If a
-- specific ratio must be enforced for a widget, it has to be done with the
-- `adjust_ratio` method after each insertion or deletion
local function normalize(self)
    local count = #self._private.widgets
    if count == 0 then return end

    -- Instead of adding "if" everywhere, just handle this common case
    if count == 1 then
        self._private.ratios = { 1 }
        return
    end

    local sum, new_w = gen_sum(self)
    local old_count  = #self._private.widgets - new_w

    local to_add = (sum == 0) and 1 or (sum / old_count)

    -- Make sure all widgets have a ratio
    for i=1, #self._private.widgets do
        if not self._private.ratios[i] then
            self._private.ratios[i] = to_add
        end
    end

    sum = sum + to_add*new_w

    local delta, new_sum =  (1 - sum) / count,0

    -- Increase or decrease each ratio so it the sum become 1
    for i=1, #self._private.widgets do
        self._private.ratios[i] = self._private.ratios[i] + delta
        new_sum = new_sum + self._private.ratios[i]
    end

    -- Floating points is not an exact science, but it should still be close
    -- to 1.00.
    assert(new_sum > 0.99 and new_sum < 1.01)
end

function ratio:layout(context, width, height)
    local preliminary_results = {}
    local pos,spacing = 0, self._private.spacing
    local strategy = self:get_inner_fill_strategy()
    local has_stragety = strategy ~= "default"
    local to_redistribute, void_count = 0, 0
    local dir = self._private.dir or "x"
    local spacing_widget = self._private.spacing_widget
    local abspace = math.abs(spacing)
    local spoffset = spacing < 0 and 0 or spacing
    local is_y = self._private.dir == "y"
    local is_x = not is_y

    for k, v in ipairs(self._private.widgets) do
        local space, is_void
        local x, y, w, h, fit_h, fit_w

        if dir == "y" then
            space = height * self._private.ratios[k]
            x, y = 0, gmath.round(pos)
            w, h = width, floor(space)
        else
            space = width * self._private.ratios[k]
            x, y = gmath.round(pos), 0
            w, h = floor(space), height
        end

        -- Keep track of the unused entries
        if has_stragety then
            fit_h, fit_w = base.fit_widget(
                self, context, v,
                dir == "x" and floor(space) or w,
                dir == "y" and floor(space) or h
            )

            is_void = (v.visible == false)
                or (dir == "x" and fit_w == 0)
                or (dir == "y" and fit_h == 0)

            if is_void then
                to_redistribute = to_redistribute + space + spacing
                void_count = void_count + 1
            end
        end

        table.insert(preliminary_results, {v, x, y, w, h, is_void})

        pos = pos + space + spacing

        -- Make sure all widgets fit in the layout, if they aren't, something
        -- went wrong
        if (dir == "y" and gmath.round(pos) >= height) or
            (dir ~= "y" and gmath.round(pos) >= width) then
            break
        end
    end

    local active = #preliminary_results - void_count
    local result, real_pos, space_front = {}, 0, strategy == "right" and
        to_redistribute or (
            strategy == "center" and math.floor(to_redistribute/2) or 0
        )

    -- The number of spaces between `n` element is `n-1`, if there is spaces
    -- outside, then it is `n+1`
    if strategy == "spacing" then
        space_front = (space_front+to_redistribute/(active + 1))
        to_redistribute = (to_redistribute/(active + 1))*(active - 1)
    end

    spacing = strategy:match("spacing")
        and to_redistribute/(active - 1) or 0

    -- Only the `justify` strategy changes the original widget size.
    to_redistribute = (strategy == "justify") and to_redistribute or 0

    for k, entry in ipairs(preliminary_results) do
        local v, x, y, w, h, is_void = unpack(entry)

        -- Redistribute the space or move the widgets
        if strategy ~= "default" then
            if dir == "y" then
                h = is_void and 0 or h + (to_redistribute / (active))
                y = space_front + real_pos
                real_pos = real_pos + h + (is_void and 0 or spacing)

            else
                w = is_void and 0 or w + (to_redistribute / (active))
                x = space_front + real_pos
                real_pos = real_pos + w + (is_void and 0 or spacing)
            end
        end

        if k > 1 and abspace > 0 and spacing_widget then
            table.insert(result, base.place_widget_at(
                spacing_widget, is_x and (x - spoffset) or x, is_y and (y - spoffset) or y,
                is_x and abspace or w, is_y and abspace or h
            ))
        end

        table.insert(result, base.place_widget_at(v, x, y, w, h))
    end

    return result
end

--- Increase the ratio of "widget".
-- If the increment produce an invalid ratio (not between 0 and 1), the method
-- do nothing.
--
--
--
--![Usage example](../images/AUTOGEN_wibox_layout_ratio_inc_ratio.svg)
--
-- @usage
-- local ret = wibox.layout.fixed.vertical()
-- local w = wibox.widget {
--     first,
--     second,
--     third,
--     layout  = wibox.layout.ratio.horizontal
-- }
-- for i=1, 5 do
--     w:inc_ratio(2, 0.1)
-- end
--
-- @method inc_ratio
-- @tparam number index The widget index to change
-- @tparam number increment An floating point value between -1 and 1 where the
--   end result is within 0 and 1
function ratio:inc_ratio(index, increment)
    if #self._private.widgets ==  1 or (not index) or (not self._private.ratios[index])
      or increment < -1 or increment > 1 then
        return
    end

    assert(self._private.ratios[index])

    self:set_ratio(index, self._private.ratios[index] + increment)
end

--- Increment the ratio of the first instance of `widget`.
-- If the increment produce an invalid ratio (not between 0 and 1), the method
-- do nothing.
--
-- @method inc_widget_ratio
-- @tparam widget widget The widget to adjust
-- @tparam number increment An floating point value between -1 and 1 where the
--   end result is within 0 and 1
function ratio:inc_widget_ratio(widget, increment)
    if not widget or not increment then return end

    local index = self:index(widget)

    self:inc_ratio(index, increment)
end

--- Set the ratio of the widget at position `index`.
--
-- @method set_ratio
-- @tparam number index The index of the widget to change
-- @tparam number percent An floating point value between 0 and 1
function ratio:set_ratio(index, percent)
    if not percent or #self._private.widgets ==  1 or not index or not self._private.widgets[index]
        or percent < 0 or percent > 1 then
        return
    end

    local old = self._private.ratios[index]

    -- Remove what has to be cleared from all widget
    local delta = ( (percent-old) / (#self._private.widgets-1) )

    for k in pairs(self._private.widgets) do
        self._private.ratios[k] = self._private.ratios[k] - delta
    end

    -- Set the new ratio
    self._private.ratios[index] = percent

    -- As some widgets may now have a slightly negative ratio, normalize again
    normalize(self)

    self:emit_signal("widget::layout_changed")
end

--- Get the ratio at `index`.
--
-- @method get_ratio
-- @tparam number index The widget index to query
-- @treturn number The index (between 0 and 1)
function ratio:get_ratio(index)
    if not index then return end
    return self._private.ratios[index]
end

--- Set the ratio of `widget` to `percent`.
--
-- @method set_widget_ratio
-- @tparam widget widget The widget to adjust.
-- @tparam number percent A floating point value between 0 and 1.
function ratio:set_widget_ratio(widget, percent)
    local index = self:index(widget)

    self:set_ratio(index, percent)
end

--- Update all widgets to match a set of a ratio.
-- The sum of before, itself and after must be 1 or nothing will be done.
--
--
--
--![Usage example](../images/AUTOGEN_wibox_layout_ratio_adjust_ratio.svg)
--
-- @usage
-- local ret = wibox.layout.fixed.vertical()
-- local w = wibox.widget {
--     first,
--     second,
--     third,
--     layout  = wibox.layout.ratio.horizontal
-- }
-- local values = {
--     {0.25, 0.50, 0.25},
--     {0.33, 0.55, 0.12},
--     {0.123, 0.456, 0.789},
--     {0.123, 0, 0.789},
--     {0, 1, 0},
-- }
-- for i=1, 5 do
--     w:adjust_ratio(2, unpack(values[i]))
-- end
--
-- @method adjust_ratio
-- @tparam number index The index of the widget to change
-- @tparam number before The sum of the ratio before the widget
-- @tparam number itself The ratio for "widget"
-- @tparam number after The sum of the ratio after the widget
function ratio:adjust_ratio(index, before, itself, after)
    if not self._private.widgets[index] or not before or not itself or not after then
        return
    end

    local sum = before + itself + after

    -- As documented, it is the caller job to come up with valid numbers
    if math.min(before, itself, after) < 0 then return end
    if sum > 1.01 or sum < -0.99 then return end

    -- Compute the before and after offset to be applied to each widgets
    local before_count, after_count = index-1, #self._private.widgets - index

    local b, a = gen_sum(self, 1, index-1), gen_sum(self, index+1)

    local db, da = (before - b)/before_count, (after - a)/after_count

    -- Apply the new ratio
    self._private.ratios[index] = itself

    -- Equality split the delta among widgets before and after
    for i = 1, index -1 do
        self._private.ratios[i] = self._private.ratios[i] + db
    end
    for i = index+1, #self._private.widgets do
        self._private.ratios[i] = self._private.ratios[i] + da
    end

    -- Remove potential negative ratio
    normalize(self)

    self:emit_signal("widget::layout_changed")
end
--- Update all widgets to match a set of a ratio.
--
-- This method is kept for backwards compatibility, please use `:adjust_ratio` instead.
-- @see wibox.layout.ratio.adjust_ratio
-- @deprecated wibox.layout.ratio.ajust_ratio
-- @tparam number index The index of the widget to change
-- @tparam number index The index of the widget to change
-- @tparam number before The sum of the ratio before the widget
-- @tparam number before The sum of the ratio before the widget
-- @tparam number itself The ratio for "widget"
-- @tparam number itself The ratio for "widget"
-- @tparam number after The sum of the ratio after the widget
-- @tparam number after The sum of the ratio after the widget
function ratio:ajust_ratio(...)
    require('gears.debug').deprecate(
        "Use `:adjust_ratio` rather than `:ajust_ratio`",
        { deprecated_in = 5 }
    )
    return self:adjust_ratio(...)
end

--- Update all widgets to match a set of a ratio.
--
-- @method adjust_widget_ratio
-- @tparam widget widget The widget to adjust
-- @tparam number before The sum of the ratio before the widget
-- @tparam number itself The ratio for "widget"
-- @tparam number after The sum of the ratio after the widget
function ratio:adjust_widget_ratio(widget, before, itself, after)
    local index = self:index(widget)
    self:adjust_ratio(index, before, itself, after)
end
--- Update all widgets to match a set of a ratio.
--
-- This method is kept for backwards compatibility, please use `:adjust_widget_ratio` instead.
-- @see wibox.layout.ratio.adjust_widget_ratio
-- @deprecated wibox.layout.ratio.ajust_widget_ratio
-- @tparam widget widget The widget to adjust
-- @tparam number before The sum of the ratio before the widget
-- @tparam number before The sum of the ratio before the widget
-- @tparam number itself The ratio for "widget"
-- @tparam number itself The ratio for "widget"
-- @tparam number after The sum of the ratio after the widget
-- @tparam number after The sum of the ratio after the widget
function ratio:ajust_widget_ratio(...)
    require('gears.debug').deprecate(
        "Use `:adjust_widget_ratio` rather than `:ajust_widget_ratio`",
        { deprecated_in = 5 }
    )
    return self:adjust_widget_ratio(...)
end

--- Add some widgets to the given fixed layout.
--
-- @method add
-- @tparam widget ... Widgets that should be added (must at least be one)
-- @emits widget::added All new widgets are passed in the parameters.
-- @emitstparam widget::added widget self The layout.
function ratio:add(...)
    -- No table.pack in Lua 5.1 :-(
    local args = { n=select('#', ...), ... }
    assert(args.n > 0, "need at least one widget to add")
    for i=1, args.n do
        local w = base.make_widget_from_value(args[i])
        base.check_widget(w)
        table.insert(self._private.widgets, w)
    end

    normalize(self)
    self:emit_signal("widget::layout_changed")
    self:emit_signal("widget::added", ...)
end

--- Remove a widget from the layout.
--
-- @method remove
-- @tparam number index The widget index to remove
-- @treturn boolean index If the operation is successful
-- @emits widget::removed
-- @emitstparam widget::removed widget self The fixed layout.
-- @emitstparam widget::removed widget widget index The removed widget.
-- @emitstparam widget::removed number index The removed index.
function ratio:remove(index)
    if not index or not self._private.widgets[index] then return false end

    local w = self._private.widgets[index]

    table.remove(self._private.ratios, index)
    table.remove(self._private.widgets, index)

    normalize(self)

    self:emit_signal("widget::layout_changed")
    self:emit_signal("widget::removed", w, index)

    return true
end

--- Insert a new widget in the layout at position `index`.
--
-- @method insert
-- @tparam number index The position.
-- @tparam widget widget The widget.
-- @emits widget::inserted
-- @emitstparam widget::inserted widget self The ratio layout.
-- @emitstparam widget::inserted widget widget index The inserted widget.
-- @emitstparam widget::inserted number count The widget count.
function ratio:insert(index, widget)
    if not index or index < 1 or index > #self._private.widgets + 1 then return false end

    base.check_widget(widget)

    table.insert(self._private.widgets, index, widget)

    normalize(self)

    self:emit_signal("widget::layout_changed")
    self:emit_signal("widget::inserted", widget, #self._private.widgets)
end

--- Set how the space of invisible or `0x0` sized widget is redistributed.
--
-- Possible values:
--
-- * "default": Honor the ratio and do not redistribute the space.
-- * "justify": Distribute the space among remaining widgets.
-- * "center": Squash remaining widgets and leave equal space on both side.
-- * "inner_spacing": Add equal spacing between all widgets.
-- * "spacing": Add equal spacing between all widgets and on the outside.
-- * "left": Squash remaining widgets and leave empty space on the left.
-- * "right": Squash remaining widgets and leave empty space on the right.
--
--
--
--![Usage example](../images/AUTOGEN_wibox_layout_ratio_strategy.svg)
--
--
-- @property inner_fill_strategy
-- @tparam string inner_fill_strategy One of the value listed above.
-- @propemits true false

function ratio:get_inner_fill_strategy()
    return self._private.inner_fill_strategy or "default"
end

local valid_strategies = {
    default       = true,
    justify       = true,
    center        = true,
    inner_spacing = true,
    spacing       = true,
    left          = true,
    right         = true
}

function ratio:set_inner_fill_strategy(strategy)
    assert(valid_strategies[strategy] ~= nil, "Invalid strategy: "..(strategy or ""))

    self._private.inner_fill_strategy = strategy
    self:emit_signal("widget::layout_changed")
    self:emit_signal("property::inner_fill_strategy", strategy)
end

local function get_layout(dir, widget1, ...)
    local ret = flex[dir](widget1, ...)

    gtable.crush(ret, ratio, true)

    ret._private.fill_space = nil

    ret._private.ratios = {}

    return ret
end

--- Returns a new horizontal ratio layout. A ratio layout shares the available space.
-- equally among all widgets. Widgets can be added via :add(widget).
-- @constructorfct wibox.layout.ratio.horizontal
-- @tparam widget ... Widgets that should be added to the layout.
function ratio.horizontal(...)
    return get_layout("horizontal", ...)
end

--- Returns a new vertical ratio layout. A ratio layout shares the available space.
-- equally among all widgets. Widgets can be added via :add(widget).
-- @constructorfct wibox.layout.ratio.vertical
-- @tparam widget ... Widgets that should be added to the layout.
function ratio.vertical(...)
    return get_layout("vertical", ...)
end

----- Set a widget at a specific index, replace the current one.
--
-- @tparam number index A widget or a widget index
-- @tparam widget widget2 The widget to take the place of the first one
-- @treturn boolean If the operation is successful
-- @method set
-- @emits widget::replaced
-- @emitstparam widget::replaced widget self The layout.
-- @emitstparam widget::replaced widget widget index The inserted widget.
-- @emitstparam widget::replaced widget previous The previous widget.
-- @emitstparam widget::replaced number index The replaced index.
-- @interface layout

--- Replace the first instance of `widget` in the layout with `widget2`.
--
-- **Signal:** widget::replaced The argument is the new widget and the old one
-- and the index.
-- @tparam widget widget The widget to replace
-- @tparam widget widget2 The widget to replace `widget` with
-- @tparam[opt=false] boolean recursive Dig in all compatible layouts to find the widget.
-- @treturn boolean If the operation is successful
-- @method replace_widget
-- @emits widget::replaced
-- @emitstparam widget::replaced widget self The layout.
-- @emitstparam widget::replaced widget widget index The inserted widget.
-- @emitstparam widget::replaced widget previous The previous widget.
-- @emitstparam widget::replaced number index The replaced index.
-- @interface layout

--- Swap 2 widgets in a layout.
--
-- @tparam number index1 The first widget index
-- @tparam number index2 The second widget index
-- @treturn boolean If the operation is successful
-- @method swap
-- @emits widget::swapped
-- @emitstparam widget::swapped widget self The layout.
-- @emitstparam widget::swapped widget widget1 index The first widget.
-- @emitstparam widget::swapped widget widget2 index The second widget.
-- @emitstparam widget::swapped number index1 The first index.
-- @emitstparam widget::swapped number index1 The second index.
-- @interface layout

--- Swap 2 widgets in a layout.
-- If widget1 is present multiple time, only the first instance is swapped
-- **Signal:** widget::swapped The arguments are both widgets and both (new) indexes.
-- if the layouts not the same, then only `widget::replaced` will be emitted.
-- @tparam widget widget1 The first widget
-- @tparam widget widget2 The second widget
-- @tparam[opt=false] boolean recursive Dig in all compatible layouts to find the widget.
-- @treturn boolean If the operation is successful
-- @method swap_widgets
-- @emits widget::swapped
-- @emitstparam widget::swapped widget self The layout.
-- @emitstparam widget::swapped widget widget1 index The first widget.
-- @emitstparam widget::swapped widget widget2 index The second widget.
-- @emitstparam widget::swapped number index1 The first index.
-- @emitstparam widget::swapped number index1 The second index.
-- @interface layout

--- Reset a ratio layout. This removes all widgets from the layout.
-- @method reset
-- @emits widget::reset
-- @emitstparam widget::reset widget self The layout.
-- @interface layout

return ratio

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80