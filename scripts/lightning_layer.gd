extends Node2D
## Draws lightning bolt overlays for Art Lightning discharges.

var simulator: Node # ParticleSimulator


func _draw() -> void:
    if simulator and simulator.has_method("draw_lightning"):
        simulator.draw_lightning(self)
