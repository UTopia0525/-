# Terrain microdetail

`terrain-microdetail.png` is an original generated 2×2 material atlas: packed earth / short grass / worn stone / crop shoots. Generated source `/workspace/generated_images/exec-413ca2c6-c37c-4714-b616-ee0ebe30a01b.png` is preserved; the PNG is copied unchanged. No map layout, object or collision is baked into this asset.

`shaders/terrain_detail.gdshader` uses the local high-frequency material variation, fades tile seams and anchors sampling in world coordinates. It preserves the existing ground's broad color, roads, shore and field boundaries. Existing source ground textures are unchanged. It is a rendering improvement, not a reconstruction of missing ground artwork. Ordinary buildings, sprites, portraits and UI are unaffected.
