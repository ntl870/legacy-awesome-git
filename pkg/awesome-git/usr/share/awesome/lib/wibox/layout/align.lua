---------------------------------------------------------------------------
--
--
--
--![Usage example](../images/AUTOGEN_wibox_layout_defaults_align.svg)
--
-- @usage
-- wibox.widget {
--     generic_widget( 'first'  ),
--     generic_widget( 'second' ),
--     generic_widget( 'third'  ),
--     layout  = wibox.layout.align.horizontal
-- }
-- @author Uli Schlachter
-- @copyright 2010 Uli Schlachter
-- @layoutmod wibox.layout.align
-- @supermodule wibox.widget.base
---------------------------------------------------------------------------

local table = table
local pairs = pairs
local type = type
local floor = math.floor
local gtable = require("gears.table")
local base = require("wibox.widget.base")

local align = {}

-- Calculate the layout of an align layout.
-- @param context The context in which we are drawn.
-- @param width The available width.
-- @param height The available height.
function align:layout(context, width, height)
    local result = {}

    -- Draw will have to deal with all three align modes and should work in a
    -- way that makes sense if one or two of the widgets are missing (if they
    -- are all missing, it won't draw anything.) It should also handle the case
    -- where the fit something that isn't set to expand (for instance the
    -- outside widgets when the expand mode is "inside" or any of the widgets
    -- when the expand mode is "none" wants to take up more space than is
    -- allowed.
    local size_first = 0
    -- start with all the space given by the parent, subtract as we go along
    local size_remains = self._private.dir == "y" and height or width
    -- This is only set & used if expand ~= "inside" and we have second width.
    -- It contains the size allocated to the second widget.
    local size_second

    -- we will prioritize the middle widget unless the expand mode is "inside"
    --  if it is, we prioritize the first widget by not doing this block also,
    --  if the second widget doesn't exist, we will prioritise the first one
    --  instead
    if self._private.expand ~= "inside" and self._private.second then
        local w, h = base.fit_widget(self, context, self._private.second, width, height)
        size_second = self._private.dir == "y" and h or w
        -- if all the space is taken, skip the rest, and draw just the middle
        -- widget
        if size_second >= size_remains then
            return { base.place_widget_at(self._private.second, 0, 0, width, height) }
        else
            -- the middle widget is sized first, the outside widgets are given
            --  the remaining space if available we will draw later
            size_remains = floor((size_remains - size_second) / 2)
        end
    end
    if self._private.first then
        local w, h, _ = width, height, nil
        -- we use the fit function for the "inside" and "none" modes, but
        --  ignore it for the "outside" mode, which will force it to expand
        --  into the remaining space
        if self._private.expand ~= "outside" then
            if self._private.dir == "y" then
                _, h = base.fit_widget(self, context, self._private.first, width, size_remains)
                size_first = h
                -- for "inside", the third widget will get a chance to use the
                --  remaining space, then the middle widget. For "none" we give
                --  the third widget the remaining space if there was no second
                --  widget to take up any space (as the first if block is skipped
                --  if this is the case)
                if self._private.expand == "inside" or not self._private.second then
                    size_remains = size_remains - h
                end
            else
                w, _ = base.fit_widget(self, context, self._private.first, size_remains, height)
                size_first = w
                if self._private.expand == "inside" or not self._private.second then
                    size_remains = size_remains - w
                end
            end
        else
            if self._private.dir == "y" then
                h = size_remains
            else
                w = size_remains
            end
        end
        table.insert(result, base.place_widget_at(self._private.first, 0, 0, w, h))
    end
    -- size_remains will be <= 0 if first used all the space
    if self._private.third and size_remains > 0 then
        local w, h, _ = width, height, nil
        if self._private.expand ~= "outside" then
            if self._private.dir == "y" then
                _, h = base.fit_widget(self, context, self._private.third, width, size_remains)
                -- give the middle widget the rest of the space for "inside" mode
                if self._private.expand == "inside" then
                    size_remains = size_remains - h
                end
            else
                w, _ = base.fit_widget(self, context, self._private.third, size_remains, height)
                if self._private.expand == "inside" then
                    size_remains = size_remains - w
                end
            end
        else
            if self._private.dir == "y" then
                h = size_remains
            else
                w = size_remains
            end
        end
        local x, y = width - w, height - h
        table.insert(result, base.place_widget_at(self._private.third, x, y, w, h))
    end
    -- here we either draw the second widget in the space set aside for it
    -- in the beginning, or in the remaining space, if it is "inside"
    if self._private.second and size_remains > 0 then
        local x, y, w, h = 0, 0, width, height
        if self._private.expand == "inside" then
            if self._private.dir == "y" then
                h = size_remains
                x, y = 0, size_first
            else
                w = size_remains
                x, y = size_first, 0
            end
        else
            local _
            if self._private.dir == "y" then
                _, h = base.fit_widget(self, context, self._private.second, width, size_second)
                y = floor( (height - h)/2 )
            else
                w, _ = base.fit_widget(self, context, self._private.second, size_second, height)
                x = floor( (width -w)/2 )
            end
        end
        table.insert(result, base.place_widget_at(self._private.second, x, y, w, h))
    end
    return result
end

--- Set the layout's first widget.
-- This is the widget that is at the left/top
-- @property first
-- @tparam widget first
-- @propemits true false

function align:set_first(widget)
    if self._private.first == widget then
        return
    end
    self._private.first = widget
    self:emit_signal("widget::layout_changed")
    self:emit_signal("property::first", widget)
end

--- Set the layout's second widget. This is the centered one.
-- @property second
-- @tparam widget second
-- @propemits true false

function align:set_second(widget)
    if self._private.second == widget then
        return
    end
    self._private.second = widget
    self:emit_signal("widget::layout_changed")
    self:emit_signal("property::second", widget)
end

--- Set the layout's third widget.
-- This is the widget that is at the right/bottom
-- @property third
-- @tparam widget third
-- @propemits true false

function align:set_third(widget)
    if self._private.third == widget then
        return
    end
    self._private.third = widget
    self:emit_signal("widget::layout_changed")
    self:emit_signal("property::third", widget)
end

for _, prop in ipairs {"first", "second", "third", "expand" } do
    align["get_"..prop] = function(self)
        return self._private[prop]
    end
end

function align:get_children()
    return gtable.from_sparse {self._private.first, self._private.second, self._private.third}
end

function align:set_children(children)
    self:set_first(children[1])
    self:set_second(children[2])
    self:set_third(children[3])
end

-- Fit the align layout into the given space. The align layout will
-- ask for the sum of the sizes of its sub-widgets in its direction
-- and the largest sized sub widget in the other direction.
-- @param context The context in which we are fit.
-- @param orig_width The available width.
-- @param orig_height The available height.
function align:fit(context, orig_width, orig_height)
    local used_in_dir = 0
    local used_in_other = 0

    for _, v in pairs{self._private.first, self._private.second, self._private.third} do
        local w, h = base.fit_widget(self, context, v, orig_width, orig_height)

        local max = self._private.dir == "y" and w or h
        if max > used_in_other then
            used_in_other = max
        end

        used_in_dir = used_in_dir + (self._private.dir == "y" and h or w)
    end

    if self._private.dir == "y" then
        return used_in_other, used_in_dir
    end
    return used_in_dir, used_in_other
end

--- Set the expand mode which determines how sub widgets expand to take up
-- unused space.
--
-- The following values are valid:
--
-- * "inside" - Default option. Size of outside widgets is determined using
--   their fit function. Second, middle, or center widget expands to fill
--   remaining space.
-- * "outside" - Center widget is sized using its fit function and placed in
--   the center of the allowed space. Outside widgets expand (or contract) to
--   fill remaining space on their side.
-- * "none" - All widgets are sized using their fit function, drawn to only the
--   returned space, or remaining space, whichever is smaller. Center widget
--   gets priority.
--
-- @property expand
-- @tparam[opt=inside] string mode How to use unused space.

function align:set_expand(mode)
    if mode == "none" or mode == "outside" then
        self._private.expand = mode
    else
        self._private.expand = "inside"
    end
    self:emit_signal("widget::layout_changed")
    self:emit_signal("property::expand", mode)
end

function align:reset()
    for _, v in pairs({ "first", "second", "third" }) do
        self[v] = nil
    end
    self:emit_signal("widget::layout_changed")
end

local function get_layout(dir, first, second, third)
    local ret = base.make_widget(nil, nil, {enable_properties = true})
    ret._private.dir = dir

    for k, v in pairs(align) do
        if type(v) == "function" then
            rawset(ret, k, v)
        end
    end

    ret:set_expand("inside")
    ret:set_first(first)
    ret:set_second(second)
    ret:set_third(third)

    -- An align layout allow set_children to have empty entries
    ret.allow_empty_widget = true

    return ret
end

--- Returns a new horizontal align layout. An align layout can display up to
-- three widgets. The widget set via :set_left() is left-aligned. :set_right()
-- sets a widget which will be right-aligned. The remaining space between those
-- two will be given to the widget set via :set_middle().
-- @constructorfct wibox.layout.align.horizontal
-- @tparam[opt] widget left Widget to be put to the left.
-- @tparam[opt] widget middle Widget to be put to the middle.
-- @tparam[opt] widget right Widget to be put to the right.
function align.horizontal(left, middle, right)
    local ret = get_layout("x", left, middle, right)

    rawset(ret, "set_left"  , ret.set_first  )
    rawset(ret, "set_middle", ret.set_second )
    rawset(ret, "set_right" , ret.set_third  )

    return ret
end

--- Returns a new vertical align layout. An align layout can display up to
-- three widgets. The widget set via :set_top() is top-aligned. :set_bottom()
-- sets a widget which will be bottom-aligned. The remaining space between those
-- two will be given to the widget set via :set_middle().
-- @constructorfct wibox.layout.align.vertical
-- @tparam[opt] widget top Widget to be put to the top.
-- @tparam[opt] widget middle Widget to be put to the middle.
-- @tparam[opt] widget bottom Widget to be put to the right.
function align.vertical(top, middle, bottom)
    local ret = get_layout("y", top, middle, bottom)

    rawset(ret, "set_top"   , ret.set_first  )
    rawset(ret, "set_middle", ret.set_second )
    rawset(ret, "set_bottom", ret.set_third  )

    return ret
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

return align

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
