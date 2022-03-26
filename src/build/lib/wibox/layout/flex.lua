---------------------------------------------------------------------------
--
--
--
--![Usage example](../images/AUTOGEN_wibox_layout_defaults_flex.svg)
--
-- @usage
-- wibox.widget {
--     generic_widget( 'first'  ),
--     generic_widget( 'second' ),
--     generic_widget( 'third'  ),
--     layout  = wibox.layout.flex.horizontal
-- }
-- @author Uli Schlachter
-- @copyright 2010 Uli Schlachter
-- @layoutmod wibox.layout.flex
-- @supermodule wibox.layout.fixed
---------------------------------------------------------------------------

local base = require("wibox.widget.base")
local fixed = require("wibox.layout.fixed")
local table = table
local pairs = pairs
local gmath = require("gears.math")
local gtable = require("gears.table")

local flex = {}

-- {{{ Override inherited properties we want to hide

--- From `wibox.layout.fixed`.
-- @property fill_space
-- @tparam boolean fill_space
-- @propemits true false
-- @hidden

-- }}}

--- Add some widgets to the given fixed layout.
--
-- @tparam widget ... Widgets that should be added (must at least be one).
-- @method add
-- @interface layout

--- Remove a widget from the layout.
--
-- @tparam index The widget index to remove.
-- @treturn boolean index If the operation is successful.
-- @method remove
-- @interface layout

--- Remove one or more widgets from the layout.
--
-- The last parameter can be a boolean, forcing a recursive seach of the
-- widget(s) to remove.
--
-- @tparam widget ... Widgets that should be removed (must at least be one).
-- @treturn boolean If the operation is successful.
-- @method remove_widgets
-- @interface layout

--- Insert a new widget in the layout at position `index`.
--
-- @tparam number index The position
-- @tparam widget widget The widget
-- @treturn boolean If the operation is successful
-- @method insert
-- @emits widget::inserted
-- @emitstparam widget::inserted widget self The fixed layout.
-- @emitstparam widget::inserted widget widget index The inserted widget.
-- @emitstparam widget::inserted number count The widget count.
-- @interface layout

--- The widget used to fill the spacing between the layout elements.
--
-- By default, no widget is used.
--
--
--
--![Usage example](../images/AUTOGEN_wibox_layout_flex_spacing_widget.svg)
--
-- @usage
-- -- Use the separator widget directly
-- local w1 = wibox.widget {
--     spacing        = 10,
--     spacing_widget = wibox.widget.separator,
--     layout         = wibox.layout.flex.horizontal
-- }
-- -- Use a standard declarative widget construct
-- local w2 = wibox.widget {
--     spacing = 10,
--     spacing_widget = {
--         color  = '#00ff00',
--         shape  = gears.shape.circle,
--         widget = wibox.widget.separator,
--     },
--     layout = wibox.layout.flex.horizontal
-- }
-- -- Use composed widgets
-- local w3 = wibox.widget {
--     spacing = 10,
--     spacing_widget = {
--         {
--             text = 'F',
--             widget = wibox.widget.textbox,
--         },
--         bg     = '#ff0000',
--         widget = wibox.container.background,
--     },
--     layout = wibox.layout.flex.horizontal
-- }
-- -- Use negative spacing to create a powerline effect
-- local w4 = wibox.widget {
--     spacing = -12,
--     spacing_widget = {
--         color  = '#ff0000',
--         shape  = gears.shape.powerline,
--         widget = wibox.widget.separator,
--     },
--     layout = wibox.layout.flex.horizontal
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
--![Usage example](../images/AUTOGEN_wibox_layout_flex_spacing.svg)
--
-- @usage
-- for i=1, 5 do
--     local w = wibox.widget {
--         first,
--         second,
--         third,
--         spacing = i*5,
--         layout  = wibox.layout.flex.horizontal
--     }
-- end
--
-- @property spacing
-- @tparam number spacing Spacing between widgets.
-- @propemits true false

function flex:layout(_, width, height)
    local result = {}
    local spacing = self._private.spacing
    local num = #self._private.widgets
    local total_spacing = (spacing*(num-1))
    local spacing_widget = self._private.spacing_widget
    local abspace = math.abs(spacing)
    local spoffset = spacing < 0 and 0 or spacing
    local is_y = self._private.dir == "y"
    local is_x = not is_y

    local space_per_item
    if is_y then
        space_per_item = height / num - total_spacing/num
    else
        space_per_item = width / num - total_spacing/num
    end

    if self._private.max_widget_size then
        space_per_item = math.min(space_per_item, self._private.max_widget_size)
    end

    local pos, pos_rounded = 0, 0
    for k, v in pairs(self._private.widgets) do
        local x, y, w, h

        local next_pos = pos + space_per_item
        local next_pos_rounded = gmath.round(next_pos)

        if is_y then
            x, y = 0, pos_rounded
            w, h = width, next_pos_rounded - pos_rounded
        else
            x, y = pos_rounded, 0
            w, h = next_pos_rounded - pos_rounded, height
        end

        pos = next_pos + spacing
        pos_rounded = next_pos_rounded + spacing

        table.insert(result, base.place_widget_at(v, x, y, w, h))

        if k > 1 and spacing ~= 0 and spacing_widget then
            table.insert(result, base.place_widget_at(
                spacing_widget, is_x and (x - spoffset) or x, is_y and (y - spoffset) or y,
                is_x and abspace or w, is_y and abspace or h
            ))
        end
    end

    return result
end

-- Fit the flex layout into the given space.
-- @param context The context in which we are fit.
-- @param orig_width The available width.
-- @param orig_height The available height.
function flex:fit(context, orig_width, orig_height)
    local used_in_dir = 0
    local used_in_other = 0

    -- Figure out the maximum size we can give out to sub-widgets
    local sub_height = self._private.dir == "x" and orig_height or orig_height / #self._private.widgets
    local sub_width  = self._private.dir == "y" and orig_width  or orig_width / #self._private.widgets

    for _, v in pairs(self._private.widgets) do
        local w, h = base.fit_widget(self, context, v, sub_width, sub_height)

        local max = self._private.dir == "y" and w or h
        if max > used_in_other then
            used_in_other = max
        end

        used_in_dir = used_in_dir + (self._private.dir == "y" and h or w)
    end

    if self._private.max_widget_size then
        used_in_dir = math.min(used_in_dir,
            #self._private.widgets * self._private.max_widget_size)
    end

    local spacing = self._private.spacing * (#self._private.widgets-1)

    if self._private.dir == "y" then
        return used_in_other, used_in_dir + spacing
    end
    return used_in_dir + spacing, used_in_other
end

--- Set the maximum size the widgets in this layout will take.
--
--That is, maximum width for horizontal and maximum height for vertical.
--
-- @property max_widget_size
-- @tparam number max_widget_size
-- @propemits true false

function flex:set_max_widget_size(val)
    if self._private.max_widget_size ~= val then
        self._private.max_widget_size = val
        self:emit_signal("widget::layout_changed")
        self:emit_signal("property::max_widget_size", val)
    end
end

local function get_layout(dir, widget1, ...)
    local ret = fixed[dir](widget1, ...)

    gtable.crush(ret, flex, true)

    ret._private.fill_space = nil

    return ret
end

--- Returns a new horizontal flex layout.
--
-- A flex layout shares the available space.
-- equally among all widgets. Widgets can be added via `:add(widget)`.
--
-- @tparam widget ... Widgets that should be added to the layout.
-- @constructorfct wibox.layout.flex.horizontal
function flex.horizontal(...)
    return get_layout("horizontal", ...)
end

--- Returns a new vertical flex layout.
--
-- A flex layout shares the available space
-- equally among all widgets. Widgets can be added via `:add(widget)`.
--
-- @tparam widget ... Widgets that should be added to the layout.
-- @constructorfct wibox.layout.flex.vertical
function flex.vertical(...)
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

return flex

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
