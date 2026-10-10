extends RefCounted
## ShopScreen — preload (res://scripts/ui/shop/shop_screen.gd).
##
## M43-C006 (SB-M43-078..089) — the real Shop destination, opened by Home SHOP, Home Scrub Bucks
## "+" and every insufficient-SB handoff (ShopHandoff ticket). One BasePopup in the approved
## popup family, every value live:
##
##   HEARTS       +1 Heart / full refill            -> ProductionActionFacade.buy_heart / refill_hearts
##   BOOSTERS     one saved charge of each booster  -> buy_booster_charge(id)
##   2X SPEED     15 / 30 / 60 min (+ "this level"   -> buy_timed_2x(seconds); per-level 2x is a
##                only inside a level)                  gameplay purchase, shown as such
##   SCRUB BUCKS  real-money packs                   -> DISABLED: gated by M57 products/provider
##   NO ADS       entitlement                        -> DISABLED: gated by M57 product definition
##
## One SB economy only (no second premium currency). The UI never mutates a balance: every buy
## is confirmed, then committed by the facade (atomic service debit + canonical save), then the
## caller-committed feedback popup reports the real result. Nothing celebrates before that.
## Closing the Shop finishes its ticket, so the originating acquisition popup resumes with its
## exact pending context (SB-M43-086).

const TouchScroll = preload("res://scripts/ui/components/touch_scroll.gd")
const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const Popups = preload("res://scripts/ui/popup/popups.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")

const ART := {
	"emblem": "res://assets/ui/final/shop/shop_header_emblem.png",
	"sb": "res://assets/ui/final/common/currencies/icon_currency_scrub_bucks.png",
	"heart": "res://assets/ui/final/common/currencies/icon_currency_heart.png",
	"hearts": "res://assets/ui/final/shop/shop_heart_bundle.png",
	"speed": "res://assets/ui/final/shop/shop_speed_2x_icon.png",
	"sb_bundle": "res://assets/ui/final/shop/shop_scrub_bucks_bundle.png",
	"no_ads": "res://assets/ui/final/home/shortcuts/icon_shortcut_no_ads.png",
	"plus_one_slot": "res://assets/ui/final/boosters/extra_slot.png",
	"random": "res://assets/ui/final/boosters/random.png",
	"selector": "res://assets/ui/final/boosters/selector.png",
	"tornado": "res://assets/ui/final/boosters/tornado.png",
}
const LIST_H := 1040.0

var popup: BasePopup
var _stack
var _economy
var _actions
var _ticket: Dictionary
var _finish: Callable
var _log: Array = []          ## [product, result] of committed buys (evidence)

## Build + push the Shop. `ticket` = ShopHandoff ticket; `finish` = Callable(ticket_id, outcome).
static func open(stack, economy, actions, ticket: Dictionary, finish: Callable):
	var s = load("res://scripts/ui/shop/shop_screen.gd").new()
	s._stack = stack
	s._economy = economy
	s._actions = actions
	s._ticket = ticket.duplicate(true)
	s._finish = finish
	s._build()
	if not stack.push(s.popup):
		s.popup.free()
		finish.call(String(ticket.get("ticket_id", "")), "cancelled")
		return null
	return s

func _build() -> void:
	popup = BasePopup.new("shop")
	popup.set_frame("large")
	popup.set_title(UiText.t("SHOP_TITLE"))
	popup.context = {"ticket_id": String(_ticket.get("ticket_id", "")), "source": String(_ticket.get("source", ""))}
	popup.set_meta("shop_screen", self)
	var top := HBoxContainer.new()
	top.name = "Wallet"
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	popup.get_content().add_child(top)
	top.add_child(_icon("SbIcon", ART["sb"], 56))
	top.add_child(_value("SbValue"))
	top.add_child(_icon("HeartIcon", ART["heart"], 56))
	top.add_child(_value("HeartValue"))
	var want := String(_ticket.get("item_label", ""))
	if not want.is_empty():
		popup.add_body_line(UiText.t("SHOP_FOR", [want, UiText.num(int(_ticket.get("price_sb", 0)))]), "PendingProduct", BasePopup.ROYAL_EDGE, 26)
	var scroll := ScrollContainer.new()
	scroll.name = "ShopList"
	scroll.custom_minimum_size = Vector2(0, LIST_H)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	popup.get_content().add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "Items"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	scroll.add_child(list)
	TouchScroll.enable(scroll)   # M47-TOUCH-R01: finger swipe scrolls over rows / buttons
	_section(list, "SHOP_SECTION_HEARTS")
	_item(list, "heart_plus_one", ART["hearts"], UiText.t("LIFE_ITEM_HEART_PLUS_ONE"))
	_item(list, "heart_refill", ART["hearts"], UiText.t("LIFE_ITEM_HEART_REFILL"))
	_section(list, "SHOP_SECTION_BOOSTERS")
	for id in BoosterInventory.BOOSTERS:
		_item(list, "booster:" + id, ART[id], UiText.t("BOOSTER_NAME_" + id.to_upper()))
	_section(list, "SHOP_SECTION_SPEED")
	for prod in _economy.config.speed_timed_products():
		var secs := int(prod.get("seconds", 0))
		_item(list, "speed:%d" % secs, ART["speed"], UiText.t("SPEED_ITEM", [UiText.t("SPEED_LABEL_MINUTES", [secs / 60])]))
	_item(list, "speed:level", ART["speed"], UiText.t("SPEED_ITEM", [UiText.t("SPEED_LABEL_LEVEL")]))
	_section(list, "SHOP_SECTION_SB")
	_item(list, "sb_pack", ART["sb_bundle"], UiText.t("SHOP_SB_PACKS"))
	_section(list, "SHOP_SECTION_NO_ADS")
	_item(list, "no_ads", ART["no_ads"], UiText.t("SHOP_NO_ADS"))
	popup.add_action("back", UiText.t("SHOP_BACK_TO", [want]) if not want.is_empty() else UiText.t("SHOP_CLOSE"), "secondary", true)
	popup.action_selected.connect(_on_action)
	popup.closed.connect(func(_r): _finish.call(String(_ticket.get("ticket_id", "")), "cancelled"), CONNECT_ONE_SHOT)
	refresh()

func _section(list: VBoxContainer, key: String) -> void:
	var l := BasePopup.body_label(UiText.t(key), 28, BasePopup.ROYAL_EDGE)
	l.name = "Section_" + key
	list.add_child(l)

func _item(list: VBoxContainer, product: String, icon: String, title: String) -> void:
	var card := PanelContainer.new()
	card.name = "Item_" + product.replace(":", "_")
	card.set_meta("product", product)
	card.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROW, BasePopup.ROW_EDGE, 3, 22, 0), UiTokens.SPACE_SM, UiTokens.SPACE_XS))
	list.add_child(card)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	card.add_child(h)
	h.add_child(_icon("Icon", icon, 88))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	var t := BasePopup.body_label(title, 28, BasePopup.INK)
	t.name = "Title"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(t)
	var d := BasePopup.body_label("", 22, BasePopup.INK)
	d.name = "Detail"
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(d)
	var b := popup.add_action("buy:" + product, "", "primary", false, "", h)
	b.custom_minimum_size = Vector2(190, 88)

static func _icon(n: String, path: String, px: int) -> TextureRect:
	var i := HomeStyle.art(n)
	if ResourceLoader.exists(path):
		i.texture = load(path)
	i.custom_minimum_size = Vector2(px, px)
	return i

static func _value(n: String) -> Label:
	var l := BasePopup.body_label("", 32, BasePopup.INK)
	l.name = n
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l

# --------------------------------------------------------------------- state ----

## Live offer for one product: {available, price, detail, button, reason}. Read-only.
func offer(product: String) -> Dictionary:
	var e = _economy
	var bal: int = e.wallet.scrub_bucks()
	var o := {"available": false, "price": 0, "detail": "", "button": "", "reason": ""}
	match product:
		"heart_plus_one":
			o["price"] = int(e.config.hearts_plus_one_sb())
			o["available"] = e.hearts.hearts() < e.hearts.max_hearts()
			o["reason"] = "" if o["available"] else "hearts_full"
		"heart_refill":
			var missing: int = e.hearts.max_hearts() - e.hearts.hearts()
			o["price"] = missing * int(e.config.hearts_full_refill_sb_per_missing())
			o["available"] = missing > 0
			o["reason"] = "" if o["available"] else "hearts_full"
		"speed:level":
			o["reason"] = "in_level_only"
		"sb_pack", "no_ads":
			o["reason"] = "store_gated"
		_:
			if product.begins_with("booster:"):
				var id := product.substr(8)
				o["price"] = int(e.config.booster_price(id))
				o["available"] = true
				o["detail_owned"] = e.boosters.charges(id)
			elif product.begins_with("speed:"):
				var secs := int(product.substr(6))
				for p in e.config.speed_timed_products():
					if int(p.get("seconds", 0)) == secs:
						o["price"] = int(p.get("sb", 0))
				o["available"] = o["price"] > 0
				o["active_left"] = e.speed.timed_seconds_remaining()
	if o["available"] and bal < int(o["price"]):
		o["reason"] = "insufficient"
	return o

func refresh() -> void:
	if popup == null or not is_instance_valid(popup):
		return
	(popup.find_child("SbValue", true, false) as Label).text = UiText.t("SHOP_SB_VALUE", [UiText.num(_economy.wallet.scrub_bucks())])
	(popup.find_child("HeartValue", true, false) as Label).text = UiText.t("LIFE_HEARTS", [UiText.num(_economy.hearts.hearts()), UiText.num(_economy.hearts.max_hearts())])
	for card in popup.find_children("Item_*", "PanelContainer", true, false):
		var product := String(card.get_meta("product"))
		var o := offer(product)
		var detail: Label = card.find_child("Detail", true, false)
		var b: Button = popup.get_action_button("buy:" + product)
		var reason := String(o["reason"])
		var text := ""
		if o.has("detail_owned"):
			text = UiText.t("BOOSTER_OWNED", [UiText.num(int(o["detail_owned"]))])
		elif int(o.get("active_left", 0)) > 0:
			text = UiText.t("SHOP_SPEED_ACTIVE", ["%02d:%02d" % [int(o["active_left"]) / 60, int(o["active_left"]) % 60]])
		match reason:
			"insufficient":
				text = UiText.t("SHOP_NEED_MORE", [UiText.num(int(o["price"]) - _economy.wallet.scrub_bucks())])
			"hearts_full":
				text = UiText.t("LIFE_FULL")
			"in_level_only":
				text = UiText.t("SHOP_SPEED_IN_LEVEL")
			"store_gated":
				text = UiText.t("SHOP_STORE_LATER")
		detail.text = text
		b.text = UiText.t("SHOP_PRICE", [UiText.num(int(o["price"]))]) if int(o["price"]) > 0 else UiText.t("SHOP_UNAVAILABLE")
		popup.set_action_blocked("buy:" + product, not (bool(o["available"]) and reason.is_empty()))

# --------------------------------------------------------------------- buying ----

func _on_action(id: String, _ctx: Dictionary) -> void:
	if not id.begins_with("buy:"):
		return
	var product := id.substr(4)
	var o := offer(product)
	if not (bool(o["available"]) and String(o["reason"]).is_empty()):
		popup.rearm()
		return
	var c = Popups.confirm({"id": "shop_confirm", "title": UiText.t("SHOP_CONFIRM_TITLE"),
		"body": UiText.t("SHOP_CONFIRM_BODY", [_label_of(product), UiText.num(int(o["price"]))]),
		"confirm_text": UiText.t("SHOP_CONFIRM_BUY"), "context": {"product": product}})
	c.action_selected.connect(func(a, ctx): if a == "confirm": _buy(String(ctx["product"])))
	c.closed.connect(func(_r): _after())
	if not _stack.push(c):
		c.free()
		popup.rearm()

## The ONE purchase path: the facade commits (atomic debit + grant + save) or refuses.
func _buy(product: String) -> Dictionary:
	var r: Dictionary
	if product == "heart_plus_one":
		r = _actions.buy_heart()
	elif product == "heart_refill":
		r = _actions.refill_hearts()
	elif product.begins_with("booster:"):
		r = _actions.buy_booster_charge(product.substr(8))
	elif product.begins_with("speed:"):
		r = _actions.buy_timed_2x(int(product.substr(6)))
	else:
		r = {"ok": false, "reason": "unavailable"}
	_log.append([product, r.duplicate()])
	var fb = Popups.feedback({"ok": bool(r.get("ok", false)), "reason": String(r.get("reason", "failed")),
		"text": UiText.t("SHOP_BOUGHT", [_label_of(product)]) if bool(r.get("ok", false)) else ""})
	if not _stack.push(fb):
		fb.free()
	refresh()
	return r

func _after() -> void:
	if popup != null and is_instance_valid(popup) and popup.is_open():
		popup.rearm_soon()
		refresh()

func _label_of(product: String) -> String:
	if product == "heart_plus_one":
		return UiText.t("LIFE_ITEM_HEART_PLUS_ONE")
	if product == "heart_refill":
		return UiText.t("LIFE_ITEM_HEART_REFILL")
	if product.begins_with("booster:"):
		return UiText.t("BOOSTER_NAME_" + product.substr(8).to_upper())
	if product.begins_with("speed:"):
		return UiText.t("SPEED_ITEM", [UiText.t("SPEED_LABEL_MINUTES", [int(product.substr(6)) / 60])])
	return product

func purchase_log() -> Array:
	return _log.duplicate(true)

static func of(p) -> RefCounted:
	return p.get_meta("shop_screen") if p != null and p.has_meta("shop_screen") else null
