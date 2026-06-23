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
6. Al morir aparece un resumen de partida.
7. El jugador puede:
   - Ver anuncio simulado para continuar una vez.
   - Empezar una nueva run.
   - Gastar oro permanente en mejoras base.

## Sistemas incluidos

- Feedback textual tras cada enemigo derrotado.
- Oro por enemigo.
- XP por enemigo.
- Drops configurados desde enemies `.tres`.
- Revive con botón `Watch Ad To Continue`.
- Resumen de partida al morir.
- Mejoras permanentes de personaje:
  - Daño base.
  - Armadura base.
  - Vida base.
  - Multiplicador de oro.
- Guardado local con `ConfigFile`.

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

## Nota sobre anuncios

El botón de anuncio está simulado. Para producción habría que conectar AdMob, AppLovin, Unity Ads u otra red.

La función donde conectar el anuncio real es:

```gdscript
func _on_revive_button_pressed() -> void:
```

Cuando el rewarded ad termine correctamente, debe llamar a:

```gdscript
player.revive_from_ad()
```

## Descargar

Usa:

`Code > Download ZIP`

O descarga directamente:

`https://github.com/JoseVicente1988/GameTest/archive/refs/heads/main.zip`
