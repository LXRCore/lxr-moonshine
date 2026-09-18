--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-MOONSHINE — Locale: English (canonical)
     Developer   : iBoss21 | Brand : LXRCore | https://www.lxrcore.com
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

Locale.Register('en', {
    error = { rate = 'Slow down.', invalid = 'Not here.', too_far = 'Get closer.', town = 'Too close to town. The law would smell it.', too_close = 'Too close to another still.', too_many = 'You already have a still standing.', no_kit = 'You have no still.', not_yours = 'Not your still.', busy = 'The still is working.', missing = 'You are short of %{label}.', not_ready = 'Not done yet.', too_heavy = 'You cannot carry the %{label}.', not_law = 'Only the law smashes stills.', dismount = 'Get down first.' },
    info = { placed = 'The still stands.', loaded = 'The %{recipe} is on.', collected = 'You take %{amount} × %{label}.', picked_up = 'You pack the still up.', smashed = 'The still is in pieces.' },
    call = { still = 'Smoke in the trees', still_msg = 'A wire about a copper smell and smoke where nobody lives.' },
    recipe = { mash = 'Corn mash', run = 'First run', age = 'Aging', berry = 'Berry infusion' },
    ui = { still = 'Copper still', load = 'Start: %{recipe}', collect = 'Collect', pickup = 'Pack up the still', smash = 'Smash the still', idle = 'Cold', load_hint = 'load a recipe', ready = 'ready', left = '%{time} left', not_yours = 'not yours' },
})
