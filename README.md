# Pocket Dungeon Merge - Godot 4.x Android Base

Base jugable para un roguelite casual vertical orientado a Android.

## Loop actual

1. El jugador entra a la dungeon.
2. El combate es automático.
3. Cada enemigo derrotado da oro y XP.
4. El oro se suma a:
   - `Run Gold`: oro ganado en la partida actual.
   - `Bank Gold`: oro permanente guardado en `user://pocket_dungeon_save.cfg`.
5. Al subir de nivel aparecen 2 opciones de mejora para la run.
6. Durante la run hay opciones de rewarded ads simuladas.
7. Al morir aparece un resumen de partida.
8. El jugador puede:
   - Ver anuncio simulado para continuar una vez.
   - Ver anuncio simulado para doblar el oro de la run.
   - Ver anuncio simulado para recibir oro patrocinado.
   - Ver anuncio simulado para subir `Ad Training`.
   - Empezar una nueva run.
   - Gastar oro permanente en mejoras base.

## Sistemas incluidos

- Feedback textual tras cada enemigo derrotado.
- Oro por enemigo.
- XP por enemigo.
- Drops configurados desde enemies `.tres`.
- Revive con botón `Watch Ad To Continue`.
- Resumen de partida al morir.
- Rewarded ad simulado para doblar el oro de la run.
- Rewarded ad simulado para recibir `+120` oro patrocinado.
- Rewarded ad simulado para subir `Ad Training` permanente.
- Mejoras permanentes de personaje:
  - Daño base.
  - Armadura base.
  - Vida base.
  - Multiplicador de oro.
  - All Stats.
  - Ad Training.
- Guardado local con `ConfigFile`.

## Base stats

Las mejoras permanentes están en `scripts/player.gd`:

- `permanent_damage_level`: suma daño base.
- `permanent_armor_level`: suma armadura base.
- `permanent_health_level`: suma vida máxima base.
- `permanent_gold_level`: mejora el multiplicador de oro.
- `permanent_all_stats_level`: mejora daño, armadura y vida a la vez.
- `ad_training_level`: mejora base permanente obtenida por rewarded ad simulado.

## Puntos de monetización simulados

En `scripts/game_auto.gd`:

```gdscript
func _on_revive_button_pressed() -> void:
```

Sirve para rewarded ad de continuar.

```gdscript
func _on_double_gold_button_pressed() -> void:
```

Sirve para rewarded ad de doblar el oro al morir.

```gdscript
func _on_ad_gold_button_pressed() -> void:
```

Sirve para rewarded ad de oro patrocinado durante la run.

```gdscript
func _on_ad_training_button_pressed() -> void:
```

Sirve para rewarded ad de mejora base permanente.

Ahora mismo los anuncios están simulados. Para producción habría que conectar AdMob, AppLovin, Unity Ads u otra red. La lógica correcta es: al pulsar botón, abrir anuncio real; cuando el callback del anuncio sea `rewarded`, ejecutar la recompensa.

## Archivos importantes

- `project.godot`
- `scenes/MainMenu.tscn`
- `scenes/GameAuto.tscn`
- `scripts/game_auto.gd`
- `scripts/player.gd`
- `scripts/resources/enemy_data.gd`
- `scripts/resources/item_data.gd`
- `scripts/resources/upgrade_data.gd`
- `resources/enemies/*.tres`
- `resources/items/*.tres`
- `resources/upgrades/*.tres`

## Descargar

Usa:

`Code > Download ZIP`

O descarga directamente:

`https://github.com/JoseVicente1988/GameTest/archive/refs/heads/main.zip`
