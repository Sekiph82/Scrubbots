extends RefCounted
## StoreProvider — preload (res://scripts/economy/store_provider.gd).
##
## SB-M57-012/013 + SB-M43-084 provider-neutral real-money store seam (Google Play Billing /
## StoreKit plug in here). This base class IS the shipping default (the null provider): the
## store is unavailable, no product has a price, nothing can be bought or restored, so the
## Shop stays honestly UNAVAILABLE (release gate SB-M60-004).
##
## Contract for a real provider (and test doubles). Callbacks may run synchronously or later:
##   is_available() -> bool                     store connected and allowed to sell?
##   query_products(ids, deliver) -> bool       deliver.call({id: localized price string})
##       the string is shown verbatim (currency, separators, tax: the store's, never ours).
##   purchase(id, deliver) -> bool              true = the store purchase sheet was started;
##       deliver.call({"product_id", "token", "outcome": "purchased"|"cancelled"|"failed"|"pending"})
##       once per result. A provider also delivers any unfinished purchase it finds at launch.
##   restore(deliver) -> bool                   deliver.call([{"product_id", "token"}, ...]) =
##       the owned non-consumables.
##   acknowledge(token, consume)                called after the grant is saved (consume = SB pack).

func is_available() -> bool:
	return false

func query_products(_ids: Array, _deliver: Callable) -> bool:
	return false

func purchase(_product_id: String, _deliver: Callable) -> bool:
	return false

func restore(_deliver: Callable) -> bool:
	return false

func acknowledge(_token: String, _consume: bool) -> void:
	pass
