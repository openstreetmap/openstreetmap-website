# Load presets
POTLATCH_PRESETS = Potlatch::Potlatch.get_presets

# Use SQL (faster) or Rails (more elegant) for common Potlatch reads
# getway speedup is approximately x2, whichways approximately x7
POTLATCH_USE_SQL = false
