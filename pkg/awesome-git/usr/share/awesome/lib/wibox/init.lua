---------------------------------------------------------------------------
-- @author Uli Schlachter
-- @copyright 2010 Uli Schlachter
-- @popupmod wibox
---------------------------------------------------------------------------

local capi = {
    drawin = drawin,
    root = root,
    awesome = awesome,
    screen = screen
}
local setmetatable = setmetatable
local pairs = pairs
local type = type
local object = require("gears.object")
local grect =  require("gears.geometry").rectangle
local beautiful = require("beautiful")
local base = require("wibox.widget.base")
local cairo = require("lgi").cairo


--- This provides widget box windows. Every wibox can also be used as if it were
-- a drawin. All drawin functions and properties are also available on wiboxes!
-- wibox
local wibox = { mt = {}, object = {} }
wibox.layout = require("wibox.layout")
wibox.container = require("wibox.container")
wibox.widget = require("wibox.widget")
wibox.drawable = require("wibox.drawable")
wibox.hierarchy = require("wibox.hierarchy")

local force_forward = {
    shape_bounding = true,
    shape_clip = true,
    shape_input = true,
}

----- Border width.
--
-- @baseclass wibox
-- @property border_width
-- @param integer
-- @propemits false false

--- Border color.
--
-- Please note that this property only support string based 24 bit or 32 bit
-- colors:
--
--    Red Blue
--     _|  _|
--    #FF00FF
--       T‾
--     Green
--
--
--    Red Blue
--     _|  _|
--    #FF00FF00
--       T‾  ‾T
--    Green   Alpha
--
-- @baseclass wibox
-- @property border_color
-- @param string
-- @propemits false false

--- On top of other windows.
--
-- @baseclass wibox
-- @property ontop
-- @param boolean
-- @propemits false false

--- The mouse cursor.
--
-- @baseclass wibox
-- @property cursor
-- @param string
-- @see mouse
-- @propemits false false

--- Visibility.
--
-- @baseclass wibox
-- @property visible
-- @param boolean
-- @propemits false false

--- The opacity of the wibox, between 0 and 1.
--
-- @baseclass wibox
-- @property opacity
-- @tparam number opacity (between 0 and 1)
-- @propemits false false

--- The window type (desktop, normal, dock, ...).
--
-- @baseclass wibox
-- @property type
-- @param string
-- @see client.type
-- @propemits false false

--- The x coordinates.
--
-- @baseclass wibox
-- @property x
-- @param integer
-- @propemits false false

--- The y coordinates.
--
-- @baseclass wibox
-- @property y
-- @param integer
-- @propemits false false

--- The width of the wibox.
--
-- @baseclass wibox
-- @property width
-- @param width
-- @propemits false false

--- The height of the wibox.
--
-- @baseclass wibox
-- @property height
-- @param height
-- @propemits false false

--- The wibox screen.
--
-- @baseclass wibox
-- @property screen
-- @param screen
-- @propemits true false

---  The wibox's `drawable`.
--
-- @baseclass wibox
-- @property drawable
-- @tparam drawable drawable
-- @propemits false false

--- The widget that the `wibox` displays.
-- @baseclass wibox
-- @property widget
-- @param widget
-- @propemits true false

--- The X window id.
--
-- @baseclass wibox
-- @property window
-- @param string
-- @see client.window
-- @propemits false false

--- The wibox's bounding shape as a (native) cairo surface.
--
-- If you want to set a shape, let say some rounded corners, use
-- the `shape` property rather than this. If you want something
-- very complex, for example, holes, then use this.
--
-- @baseclass wibox
-- @property shape_bounding
-- @param surface._native
-- @propemits false false
-- @see shape

--- The wibox's clip shape as a (native) cairo surface.
--
-- The clip shape is the shape of the window *content* rather
-- than the outer window shape.
--
-- @baseclass wibox
-- @property shape_clip
-- @param surface._native
-- @propemits false false
-- @see shape

--- The wibox's input shape as a (native) cairo surface.
--
-- The input shape allows to disable clicks and mouse events
-- on part of the window. This is how `input_passthrough` is
-- implemented.
--
-- @baseclass wibox
-- @property shape_input
-- @param surface._native
-- @propemits false false
-- @see input_passthrough

--- The wibar's shape.
--
-- @baseclass wibox
-- @property shape
-- @tparam gears.shape shape
-- @propemits true false
-- @see gears.shape

--- Forward the inputs to the client below the wibox.
--
-- This replace the `shape_input` mask with an empty area. All mouse and
-- keyboard events are sent to the object (such as a client) positioned below
-- this wibox. When used alongside compositing, it allows, for example, to have
-- a subtle transparent wibox on top a fullscreen client to display important
-- data such as a low battery warning.
--
-- @baseclass wibox
-- @property input_passthrough
-- @param[opt=false] boolean
-- @see shape_input
-- @propemits true false

--- Get or set mouse buttons bindings to a wibox.
--
-- @baseclass wibox
-- @property buttons
-- @param buttons_table A table of buttons objects, or nothing.
-- @propemits false false

--- Get or set wibox geometry. That's the same as accessing or setting the x,
-- y, width or height properties of a wibox.
--
-- @baseclass wibox
-- @param A table with coordinates to modify.
-- @return A table with wibox coordinates and geometry.
-- @method geometry
-- @emits property::geometry When the geometry change.
-- @emitstparam property::geometry table geo The geometry table.

--- Get or set wibox struts.
--
-- Struts are the area which should be reserved on each side of
-- the screen for this wibox. This is used to make bars and
-- docked displays. Note that `awful.wibar` implements all the
-- required boilerplate code to make bar. Only use this if you
-- want special type of bars (like bars not fully attached to
-- the side of the screen).
--
-- @baseclass wibox
-- @param strut A table with new strut, or nothing
-- @return The wibox strut in a table.
-- @method struts
-- @see client.struts
-- @emits property::struts

--- The default background color.
--
-- The background color can be transparent. If there is a
-- compositing manager such as compton, then it will be
-- real transparency and may include blur (provided by the
-- compositor). When there is no compositor, it will take
-- a picture of the wallpaper and blend it.
--
-- @baseclass wibox
-- @beautiful beautiful.bg_normal
-- @param color
-- @see bg

--- The default foreground (text) color.
-- @baseclass wibox
-- @beautiful beautiful.fg_normal
-- @param color
-- @see fg

--- Set a declarative widget hierarchy description.
-- See [The declarative layout system](../documentation/03-declarative-layout.md.html)
-- @param args An array containing the widgets disposition
-- @baseclass wibox
-- @method setup

--- The background of the wibox.
--
-- The background color can be transparent. If there is a
-- compositing manager such as compton, then it will be
-- real transparency and may include blur (provided by the
-- compositor). When there is no compositor, it will take
-- a picture of the wallpaper and blend it.
--
-- @baseclass wibox
-- @property bg
-- @tparam c The background to use. This must either be a cairo pattern object,
--   nil or a string that gears.color() understands.
-- @see gears.color
-- @propemits true false
-- @usebeautiful beautiful.bg_normal The default (fallback) bg color.

--- The background image of the drawable.
--
-- If `image` is a function, it will be called with `(context, cr, width, height)`
-- as arguments. Any other arguments passed to this method will be appended.
--
-- @tparam gears.suface|string|function image A background image or a function.
-- @baseclass wibox
-- @property bgimage
-- @see gears.surface
-- @propemits true false

--- The foreground (text) of the wibox.
-- @tparam color c The foreground to use. This must either be a cairo pattern object,
--   nil or a string that gears.color() understands.
-- @baseclass wibox
-- @property fg
-- @param color
-- @see gears.color
-- @propemits true false
-- @usebeautiful beautiful.fg_normal The default (fallback) fg color.

--- Find a widget by a point.
-- The wibox must have drawn itself at least once for this to work.
-- @tparam number x X coordinate of the point
-- @tparam number y Y coordinate of the point
-- @treturn table A sorted table of widgets positions. The first element is the biggest
-- container while the last is the topmost widget. The table contains *x*, *y*,
-- *width*, *height* and *widget*.
-- @baseclass wibox
-- @method find_widgets

function wibox:set_widget(widget)
    local w = base.make_widget_from_value(widget)
    self._drawable:set_widget(w)
    self:emit_signal("property::widget", widget)
end

function wibox:get_widget()
    return self._drawable.widget
end

wibox.setup = base.widget.setup

function wibox:set_bg(c)
    self._drawable:set_bg(c)
    self:emit_signal("property::bg", c)
end

function wibox:set_bgimage(image, ...)
    self._drawable:set_bgimage(image, ...)
    self:emit_signal("property::bgimage", ...)
end

function wibox:set_fg(c)
    self._drawable:set_fg(c)
    self:emit_signal("property::fg", c)
end

function wibox:find_widgets(x, y)
    return self._drawable:find_widgets(x, y)
end

function wibox:_buttons(btns)
    -- The C code uses the argument count, `nil` counts.
    return btns and self.drawin:_buttons(btns) or self.drawin:_buttons()
end

--- Create a widget that reflects the current state of this wibox.
-- @treturn widget A new widget.
-- @method to_widget
function wibox:to_widget()
    local bw = self.border_width or beautiful.border_width or 0
    return wibox.widget {
        {
            self:get_widget(),
            margins = bw,
            widget  = wibox.container.margin
        },
        bg                 = self.bg or beautiful.bg_normal or "#ffffff",
        fg                 = self.fg or beautiful.fg_normal or "#000000",
        shape_border_color = self.border_color or beautiful.border_color or "#000000",
        shape_border_width = bw*2,
        shape_clip         = true,
        shape              = self._shape,
        forced_width       = self:geometry().width  + 2*bw,
        forced_height      = self:geometry().height + 2*bw,
        widget             = wibox.container.background
    }
end

--- Save a screenshot of the wibox to `path`.
-- @tparam string path The path.
-- @tparam[opt=nil] table context A widget context.
-- @method save_to_svg
function wibox:save_to_svg(path, context)
    wibox.widget.draw_to_svg_file(
        self:to_widget(), path, self:geometry().width, self:geometry().height, context
    )
end

function wibox:_apply_shape()
    local shape = self._shape

    if not shape then
        self.shape_bounding = nil
        self.shape_clip = nil
        return
    end

    local geo = self:geometry()
    local bw = self.border_width

    -- First handle the bounding shape (things including the border)
    local img = cairo.ImageSurface(cairo.Format.A1, geo.width + 2*bw, geo.height + 2*bw)
    local cr = cairo.Context(img)

    -- We just draw the shape in its full size
    shape(cr, geo.width + 2*bw, geo.height + 2*bw)
    cr:set_operator(cairo.Operator.SOURCE)
    cr:fill()
    self.shape_bounding = img._native
    img:finish()

    -- Now handle the clip shape (things excluding the border)
    img = cairo.ImageSurface(cairo.Format.A1, geo.width, geo.height)
    cr = cairo.Context(img)

    -- We give the shape the same arguments as for the bounding shape and draw
    -- it in its full size (the translate is to compensate for the smaller
    -- surface)
    cr:translate(-bw, -bw)
    shape(cr, geo.width + 2*bw, geo.height + 2*bw)
    cr:set_operator(cairo.Operator.SOURCE)
    cr:fill_preserve()
    -- Now we remove an area of width 'bw' again around the shape (We use 2*bw
    -- since half of that is on the outside and only half on the inside)
    cr:set_source_rgba(0, 0, 0, 0)
    cr:set_line_width(2*bw)
    cr:stroke()
    self.shape_clip = img._native
    img:finish()
end

function wibox:set_shape(shape)
    self._shape = shape
    self:_apply_shape()
    self:emit_signal("property::shape", shape)
end

function wibox:get_shape()
    return self._shape
end

function wibox:set_input_passthrough(value)
    rawset(self, "_input_passthrough", value)

    if not value then
        self.shape_input = nil
    else
        local img = cairo.ImageSurface(cairo.Format.A1, 0, 0)
        self.shape_input = img._native
        img:finish()
    end

    self:emit_signal("property::input_passthrough", value)
end

function wibox:get_input_passthrough()
    return self._input_passthrough
end

function wibox:get_screen()
    if self.screen_assigned and self.screen_assigned.valid then
        return self.screen_assigned
    else
        self.screen_assigned = nil
    end
    local sgeos = {}

    for s in capi.screen do
        sgeos[s] = s.geometry
    end

    return grect.get_closest_by_coord(sgeos, self.x, self.y)
end

function wibox:set_screen(s)
    s = capi.screen[s or 1]
    if s ~= self:get_screen() then
        self.x = s.geometry.x
        self.y = s.geometry.y
    end

    -- Remember this screen so things work correctly if screens overlap and
    -- (x,y) is not enough to figure out the correct screen.
    self.screen_assigned = s
    self._drawable:_force_screen(s)
    self:emit_signal("property::screen", s)
end

function wibox:get_children_by_id(name)
    --TODO v5: Move the ID management to the hierarchy.
    if rawget(self, "_by_id") then
        --TODO v5: Remove this, it's `if` nearly dead code, keep the `elseif`
        return rawget(self, "_by_id")[name]
    elseif self._drawable.widget
      and self._drawable.widget._private
      and self._drawable.widget._private.by_id then
          return self._drawable.widget._private.by_id[name]
    end

    return {}
end

-- Proxy those properties to decorate their accessors with an extra flag to
-- define when they are set by the user. This allows to "manage" the value of
-- those properties internally until they are manually overridden.
for _, prop in ipairs { "border_width", "border_color", "opacity" } do
    wibox["get_"..prop] = function(self)
        return self["_"..prop]
    end
    wibox["set_"..prop] = function(self, value)
        self._private["_user_"..prop] = true
        self["_"..prop] = value
    end
end

for _, k in ipairs{ "struts", "geometry", "get_xproperty", "set_xproperty" } do
    wibox[k] = function(self, ...)
        return self.drawin[k](self.drawin, ...)
    end
end

object.properties._legacy_accessors(wibox.object, "buttons", "_buttons", true, function(new_btns)
    return new_btns[1] and (
        type(new_btns[1]) == "button" or new_btns[1]._is_capi_button
    ) or false
end, true)

local function setup_signals(_wibox)
    local obj
    local function clone_signal(name)
        -- When "name" is emitted on wibox.drawin, also emit it on wibox
        obj:connect_signal(name, function(_, ...)
            _wibox:emit_signal(name, ...)
        end)
    end

    obj = _wibox.drawin
    clone_signal("property::border_color")
    clone_signal("property::border_width")
    clone_signal("property::buttons")
    clone_signal("property::cursor")
    clone_signal("property::height")
    clone_signal("property::ontop")
    clone_signal("property::opacity")
    clone_signal("property::struts")
    clone_signal("property::visible")
    clone_signal("property::width")
    clone_signal("property::x")
    clone_signal("property::y")
    clone_signal("property::geometry")
    clone_signal("property::shape_bounding")
    clone_signal("property::shape_clip")
    clone_signal("property::shape_input")

    obj = _wibox._drawable
    clone_signal("button::press")
    clone_signal("button::release")
    clone_signal("mouse::enter")
    clone_signal("mouse::leave")
    clone_signal("mouse::move")
    clone_signal("property::surface")
end

--- Create a wibox.
-- @tparam[opt=nil] table args
-- @tparam integer args.border_width Border width.
-- @tparam string args.border_color Border color.
-- @tparam[opt=false] boolean args.ontop On top of other windows.
-- @tparam string args.cursor The mouse cursor.
-- @tparam boolean args.visible Visibility.
-- @tparam[opt=1] number args.opacity The opacity, between 0 and 1.
-- @tparam string args.type The window type (desktop, normal, dock, …).
-- @tparam integer args.x The x coordinates.
-- @tparam integer args.y The y coordinates.
-- @tparam integer args.width The width.
-- @tparam integer args.height The height.
-- @tparam screen args.screen The wibox screen.
-- @tparam wibox.widget args.widget The widget that the wibox displays.
-- @param args.shape_bounding The wibox’s bounding shape as a (native) cairo surface.
-- @param args.shape_clip The wibox’s clip shape as a (native) cairo surface.
-- @param args.shape_input The wibox’s input shape as a (native) cairo surface.
-- @tparam color args.bg The background.
-- @tparam surface args.bgimage The background image of the drawable.
-- @tparam color args.fg The foreground (text) color.
-- @tparam gears.shape args.shape The shape.
-- @tparam[opt=false] boolean args.input_passthrough If the inputs are
--  forward to the element below.
-- @treturn wibox The new wibox
-- @constructorfct wibox

local function new(args)
    args = args or {}
    local ret = object()
    local w = capi.drawin(args)

    function w.get_wibox()
        return ret
    end

    ret.drawin = w
    ret._drawable = wibox.drawable(w.drawable, { wibox = ret },
        "wibox drawable (" .. object.modulename(3) .. ")")

    function ret._drawable.get_wibox()
        return ret
    end

    ret._drawable:_inform_visible(w.visible)
    w:connect_signal("property::visible", function()
        ret._drawable:_inform_visible(w.visible)
    end)

    --TODO v5 deprecate this and use `wibox.object`.
    for k, v in pairs(wibox) do
        if (not rawget(ret, k)) and type(v) == "function" then
            ret[k] = v
        end
    end

    setup_signals(ret)
    ret.draw = ret._drawable.draw

    -- Set the default background
    ret:set_bg(args.bg or beautiful.bg_normal)
    ret:set_fg(args.fg or beautiful.fg_normal)

    -- Add __tostring method to metatable.
    local mt = {}
    local orig_string = tostring(ret)
    mt.__tostring = function()
        return string.format("wibox: %s (%s)",
                             tostring(ret._drawable), orig_string)
    end
    ret = setmetatable(ret, mt)

    -- Make sure the wibox is drawn at least once
    ret.draw()

    ret:connect_signal("property::geometry", ret._apply_shape)
    ret:connect_signal("property::border_width", ret._apply_shape)

    -- If a value is not found, look in the drawin
    setmetatable(ret, {
        __index = function(self, k)
            if rawget(self, "get_"..k) then
                return self["get_"..k](self)
            else
                return w[k]
            end
        end,
        __newindex = function(self, k,v)
            if rawget(self, "set_"..k) then
                self["set_"..k](self, v)
            elseif force_forward[k] or w[k] ~= nil then
                w[k] = v
            else
                rawset(self, k, v)
            end
        end
    })

    -- Set other wibox specific arguments
    if args.bgimage then
        ret:set_bgimage( args.bgimage )
    end

    if args.widget then
        ret:set_widget ( args.widget  )
    end

    if args.screen then
        ret:set_screen ( args.screen  )
    end

    if args.shape then
        ret.shape = args.shape
    end

    if args.border_width then
        ret.border_width = args.border_width
    end

    if args.border_color then
        ret.border_color = args.border_color
    end

    if args.opacity then
        ret.opacity = args.opacity
    end

    if args.input_passthrough then
        ret.input_passthrough = args.input_passthrough
    end

    -- Make sure all signals bubble up
    ret:_connect_everything(wibox.emit_signal)

    return ret
end

--- Redraw a wibox. You should never have to call this explicitely because it is
-- automatically called when needed.
-- @param wibox
-- @method draw

--- Connect a global signal on the wibox class.
--
-- Functions connected to this signal source will be executed when any
-- wibox object emits the signal.
--
-- It is also used for some generic wibox signals such as
-- `request::geometry`.
--
-- @tparam string name The name of the signal
-- @tparam function func The function to attach
-- @staticfct wibox.connect_signal
-- @usage wibox.connect_signal("added", function(notif)
--    -- do something
-- end)

--- Emit a wibox signal.
-- @tparam string name The signal name.
-- @param ... The signal callback arguments
-- @staticfct wibox.emit_signal

--- Disconnect a signal from a source.
-- @tparam string name The name of the signal
-- @tparam function func The attached function
-- @staticfct wibox.disconnect_signal
-- @treturn boolean If the disconnection was successful

function wibox.mt:__call(...)
    return new(...)
end

-- Extend the luaobject
object.properties(capi.drawin, {
    getter_class = wibox.object,
    setter_class = wibox.object,
    auto_emit    = true,
})

capi.drawin.object = wibox.object

object._setup_class_signals(wibox)

return setmetatable(wibox, wibox.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
