# -*- coding: utf-8 -*-
"""
Heritage English variants for Smart Cultural Adaptor:
- EN_EASTERN_HERITAGE_MECHANISMS: For users born in East/SE Asia (VN, CN, JP, KR, TW, SG, HK) choosing English.
  Infused with Eastern philosophical depth (Yin-Yang equilibrium, meridian flow, inner grounding, mindful discernment).
- EN_VEDIC_HERITAGE_MECHANISMS: For users born in South Asia (IN, NP, LK, BD) choosing English.
  Infused with Vedic cosmic cycles (universal rhythm, inner consciousness, karmic resonance, calm detachment).

Both adhere strictly to:
- 0 forbidden words
- 0 overclaims
- act_wait:first contains 'leans toward acting', 'timing', 'everything else'
- 0 digits, 0 percent signs
- 100% unique strings across all 57 mechanisms
"""

# ==============================================================================
# EASTERN HERITAGE ENGLISH (for East Asian heritage users choosing English)
# ==============================================================================
EN_EASTERN_HERITAGE_MECHANISMS = {
    # Reason vs Emotion
    ('reason_emotion', 'first', 0): "your natal chart highlights lucid discernment rising above transient emotional waves; anchoring yourself in calm reason and verifiable facts reveals the true path.",
    ('reason_emotion', 'first', 1): "the analytical force of mindful clarity is dissolving inner hesitation; relying on objective evidence provides the most dependable foundation right now.",
    ('reason_emotion', 'first', 2): "the natural energetic rhythm favors tranquil contemplation over fleeting feelings; prioritizing disciplined logic keeps your footing steady and purposeful.",

    ('reason_emotion', 'second', 0): "your inner resonance is awakening deep intuitive awareness; listening to your heart and genuine feelings offers far deeper guidance than rigid calculations.",
    ('reason_emotion', 'second', 1): "the subtle emotional tide within is reaching a harmonious crest; honoring what feels genuinely right in your soul will guide you toward authentic peace.",
    ('reason_emotion', 'second', 2): "the universal indicators suggest that heartfelt sincerity carries greater wisdom than cold formulas; let your quiet inner voice guide this choice.",

    # Confront vs Avoid
    ('confront_avoid', 'first', 0): "the vital fire of decisive resolve is lending you strength; directly addressing the issue with candor will dissolve lingering friction far faster than avoiding it.",
    ('confront_avoid', 'first', 1): "an active forward momentum has gathered to overcome hesitation; stepping up to speak honestly will clear latent misunderstandings completely.",
    ('confront_avoid', 'first', 2): "the prevailing energetic climate encourages earnest courage; confronting the reality head-on releases the stagnant deadlock once and for all.",

    ('confront_avoid', 'second', 0): "the surrounding environment is experiencing turbulent friction; mindfully stepping back to avoid clashes is not retreat, but a wise way to safeguard inner serenity.",
    ('confront_avoid', 'second', 1): "current external currents carry unproductive friction; keeping a graceful distance and sidestepping tension preserves your vital reserves.",
    ('confront_avoid', 'second', 2): "the energetic signs warn that direct confrontation would only deplete your calm; holding peaceful boundaries serves your long-term harmony best.",

    # Act vs Wait (MUST contain 'leans toward acting', 'timing', 'everything else')
    ('act_wait', 'first', 0): "taking into account timing and everything else, the energetic current leans toward acting with purposeful resolve.",
    ('act_wait', 'first', 1): "balancing auspicious timing alongside everything else, the natural tide leans toward acting to seize the emerging rhythm.",
    ('act_wait', 'first', 2): "weighing immediate timing against everything else, the surrounding momentum leans toward acting rather than pausing.",

    ('act_wait', 'second', 0): "the cosmic rhythm advises measured patience; maintaining tranquil composure until conditions fully mature will prevent unforeseen missteps.",
    ('act_wait', 'second', 1): "external circumstances have not yet converged in balance; waiting patiently is the highest expression of sound discernment.",
    ('act_wait', 'second', 2): "enduring wisdom teaches that deliberate patience builds lasting strength; observing quietly from a centered space is far superior to rushing.",

    # Advance vs Retreat
    ('advance_retreat', 'first', 0): "the prevailing energetic tide is flowing smoothly in your favor; stepping forward with quiet confidence expands your natural advantage.",
    ('advance_retreat', 'first', 1): "momentum cultivated through past dedication provides a sturdy foundation; moving forward with clarity firmly establishes your presence.",
    ('advance_retreat', 'first', 2): "the path opens smoothly for earnest endeavor; taking an active step forward invites welcome opportunities for natural growth.",

    ('advance_retreat', 'second', 0): "surrounding currents face subtle resistance; strategically stepping back to survey the wider picture is the wiser tactical path.",
    ('advance_retreat', 'second', 1): "external friction exceeds comfortable thresholds; a dignified pause to consolidate inner strength safeguards your hard-won progress.",
    ('advance_retreat', 'second', 2): "knowing when to pause and gather yourself reflects true mastery; stepping back protects everything you have carefully nurtured.",

    # Stay vs Go
    ('stay_go', 'first', 0): "your current foundation still holds deep and nurturing roots; remaining steadfast to tend your ground will bring enduring fulfillment.",
    ('stay_go', 'first', 1): "the energy of rooted stability counsels against restless movement; staying centered in your present sphere offers the greatest safety.",
    ('stay_go', 'first', 2): "the vital nourishment of your current position continues to sustain you; staying to bring ongoing endeavors to completion is the sound choice.",

    ('stay_go', 'second', 0): "the present cycle has fulfilled its supportive purpose; courageously moving toward a new horizon will awaken renewed vitality.",
    ('stay_go', 'second', 1): "winds of renewal are calling you onward; departing now releases latent potential that has outgrown its current vessel.",
    ('stay_go', 'second', 2): "the present setting has reached its natural conclusion; venturing out to explore a fresh chapter brings a revitalizing breath of life.",

    # Keep vs Let Go
    ('keep_let_go', 'first', 0): "the core essence of what you hold still possesses genuine brilliance; patient stewardship will preserve its enduring worth.",
    ('keep_let_go', 'first', 1): "what you have built represents a foundation worth cherishing; holding onto it with care will bring deep satisfaction.",
    ('keep_let_go', 'first', 2): "the moment to release has not arrived; continuing to stand by this path will reveal its true significance over time.",

    ('keep_let_go', 'second', 0): "accumulated attachments have begun restricting your inner freedom; releasing them with ease opens the way for fresh blessings to enter.",
    ('keep_let_go', 'second', 1): "releasing what no longer harmonizes with your journey is natural healing; letting go of the past makes room for genuine renewal.",
    ('keep_let_go', 'second', 2): "stagnant energies need to be dispersed; loosening your grasp brings a welcome lightness of being and restored peace.",

    # Commit vs Withdraw
    ('commit_withdraw', 'first', 0): "the horizon ahead is revealing dependable long-term harmony; establishing a sincere commitment now will lay an unshakeable cornerstone.",
    ('commit_withdraw', 'first', 1): "natural indicators support dedicated devotion; binding your efforts with integrity fosters enduring trust and unity.",
    ('commit_withdraw', 'first', 2): "steadfast responsibility is the gateway to future fulfillment; committing wholeheartedly generates powerful forward traction.",

    ('commit_withdraw', 'second', 0): "the road ahead carries ambiguous uncertainties; stepping back safely is the prudent way to conserve your vital energy.",
    ('commit_withdraw', 'second', 1): "hidden complications remain unrefined; extricating yourself from entanglements spares you unnecessary burdens.",
    ('commit_withdraw', 'second', 2): "cautionary signals suggest avoiding deep involvement; withdrawing with poise is the clearest demonstration of wisdom.",

    # Left vs Right
    ('left_right', 'first', 0): "receptive yin energy is taking the lead; turning inward, listening quietly, and gentle acceptance will cultivate profound peace.",
    ('left_right', 'first', 1): "contemplative stillness invites you to retreat within; quiet discretion and receptive reflection hold subtle, enduring strength.",
    ('left_right', 'first', 2): "the energetic signs favor introspection; perceptive observation rather than outward display harmonizes with the natural order.",

    ('left_right', 'second', 0): "expressive yang energy is surging with initiative; stepping outward, expressing your vision, and engaging with vigor leads to success.",
    ('left_right', 'second', 1): "proactive motion is primed for decisive expression; step into the open and share your authentic presence with the world.",
    ('left_right', 'second', 2): "an outward stance creates welcome momentum; taking the initiative and articulating your perspective will meet ready resonance.",

    # Yes vs No
    ('yes_no', 'first', 0): "your natal indicators and the surrounding flow unite in supportive harmony; leaning into this opening will bring a fluid, constructive outcome.",
    ('yes_no', 'first', 1): "the energetic field opens wide to welcome affirmation; an affirmative choice right now enjoys the full backing of the natural flow.",
    ('yes_no', 'first', 2): "all signs converge in mutual agreement; moving forward with a confident affirmation sets positive transformations into motion.",

    ('yes_no', 'second', 0): "the indicators point to latent cross-currents and hidden obstacles; drawing a firm line and declining is the wiser course.",
    ('yes_no', 'second', 1): "external conditions are not aligned to sustain this venture; a clear refusal protects you from taking on unnecessary burdens.",
    ('yes_no', 'second', 2): "cautionary signposts suggest pulling back; maintaining healthy boundaries and answering with a no safeguards your well-being.",

    # Balanced
    ('balanced', 'balanced', 0): "the dual energetic currents currently rest in exact equilibrium; neither path holds an obvious advantage, so patient stillness is the wisest choice.",
    ('balanced', 'balanced', 1): "the scales of nature maintain a peaceful pause; avoid rushing into a decision while the indicators invite calm reflection.",
    ('balanced', 'balanced', 2): "opposing energetic forces are matched in equal measure; granting the situation a natural pause will allow clarity to emerge on its own.",
}

# ==============================================================================
# VEDIC COSMIC HERITAGE ENGLISH (for South Asian heritage users choosing English)
# ==============================================================================
EN_VEDIC_HERITAGE_MECHANISMS = {
    # Reason vs Emotion
    ('reason_emotion', 'first', 0): "your inner awareness illuminates the true path above fleeting emotional noise; trusting steady intellect serves as your most dependable cosmic guide.",
    ('reason_emotion', 'first', 1): "analytical clarity is prevailing over momentary inner fluctuations; anchoring in objective truth offers unshakeable discernment right now.",
    ('reason_emotion', 'first', 2): "the universal rhythm aligns with lucid perception over emotional turbulence; prioritizing clear reason preserves your purposeful harmony.",

    ('reason_emotion', 'second', 0): "your inner consciousness is awakening profound intuitive insight; the subtle feelings of your deepest heart carry greater wisdom than dry calculations.",
    ('reason_emotion', 'second', 1): "the quiet resonance of the soul is swelling with truthful awareness; listening to your authentic intuition will lead you to rightful peace.",
    ('reason_emotion', 'second', 2): "the cosmic indicators reveal that heartfelt sincerity holds deeper truth than rigid analysis; allow your inner self to guide this resolution.",

    # Confront vs Avoid
    ('confront_avoid', 'first', 0): "an indomitable surge of courage is strengthening your resolve; facing the situation directly with honesty will dissolve lingering friction swiftly.",
    ('confront_avoid', 'first', 1): "the energy to overcome hesitation has fully coalesced; engaging in candid dialogue will dissolve unspoken barriers once and for all.",
    ('confront_avoid', 'first', 2): "the cosmic atmosphere urges you not to turn away from truth; stepping forward with upright resolve clears away stagnation completely.",

    ('confront_avoid', 'second', 0): "the surrounding environment is experiencing turbulent agitation; stepping back calmly to avoid conflict is not weakness, but a wise way to preserve inner tranquility.",
    ('confront_avoid', 'second', 1): "current external currents carry wasteful friction; keeping a serene distance protects your spiritual vitality and focus.",
    ('confront_avoid', 'second', 2): "the indicators warn that head-on clashes will only drain your vital energy; maintaining calm detachment serves your highest peace.",

    # Act vs Wait (MUST contain 'leans toward acting', 'timing', 'everything else')
    ('act_wait', 'first', 0): "taking into account timing and everything else, the cosmic flow leans toward acting with focused clarity.",
    ('act_wait', 'first', 1): "balancing universal timing alongside everything else, the planetary rhythm leans toward acting to manifest constructive momentum.",
    ('act_wait', 'first', 2): "weighing immediate timing against everything else, the karmic current leans toward acting rather than remaining stationary.",

    ('act_wait', 'second', 0): "the cosmic cycle advises patient endurance; waiting calmly for conditions to ripen naturally prevents unforeseen missteps.",
    ('act_wait', 'second', 1): "external forces have not yet gathered in your favor; abiding in patient contemplation is the highest form of spiritual discernment.",
    ('act_wait', 'second', 2): "deliberate stillness fosters unshakeable resilience; observing circumstances with a centered mind is far superior to premature action.",

    # Advance vs Retreat
    ('advance_retreat', 'first', 0): "the prevailing universal current is flowing smoothly forward; stepping ahead with confidence expands your rightful territory.",
    ('advance_retreat', 'first', 1): "steady dedication has built an enduring launchpad; advancing with determination establishes a powerful and clear presence.",
    ('advance_retreat', 'first', 2): "the cosmic gates open wide for courageous effort; moving forward actively invites welcoming opportunities for genuine elevation.",

    ('advance_retreat', 'second', 0): "the path ahead carries unseen counter-currents; pausing to survey the broader horizon is the wiser strategic course.",
    ('advance_retreat', 'second', 1): "external resistance exceeds comfortable bounds; stepping back gracefully to replenish your inner reservoir preserves your accomplishments.",
    ('advance_retreat', 'second', 2): "knowing when to halt and withdraw demonstrates spiritual maturity; stepping back safely protects your hard-earned progress.",

    # Stay vs Go
    ('stay_go', 'first', 0): "your present position still holds sturdy and supportive pillars; remaining grounded and cultivating your roots will bring enduring harvest.",
    ('stay_go', 'first', 1): "the principle of stability warns against restless shifting; staying committed to your current place offers profound security.",
    ('stay_go', 'first', 2): "the vital sustenance of your present setting continues to nurture you; staying to complete ongoing duties is the soundest choice.",

    ('stay_go', 'second', 0): "the present cycle has completed its evolutionary purpose; stepping forward into a new chapter unlocks dormant potentials.",
    ('stay_go', 'second', 1): "winds of transformation are urging you to embark; departing now frees your spirit from constraints that have outlived their time.",
    ('stay_go', 'second', 2): "the current realm has reached its natural limits; moving forward into unexplored horizons brings an invigorating rebirth of purpose.",

    # Keep vs Let Go
    ('keep_let_go', 'first', 0): "the core essence of what you possess retains genuine luminosity; guarding it with patient devotion will prove its lasting significance.",
    ('keep_let_go', 'first', 1): "what you have cultivated is an enduring treasure; protecting it mindfully will yield deeply gratifying fulfillment.",
    ('keep_let_go', 'first', 2): "the hour to relinquish has not arrived; continuing to uphold this path with honor will demonstrate its true value.",

    ('keep_let_go', 'second', 0): "accumulated attachments are weighing upon the freedom of your soul; relinquishing them gracefully invites fresh auspicious blessings.",
    ('keep_let_go', 'second', 1): "letting go of what no longer serves your spiritual growth is natural liberation; shedding the past makes space for the divine new.",
    ('keep_let_go', 'second', 2): "stagnant bonds need to be dissolved; releasing your attachment restores a profound and joyous lightness of being.",

    # Commit vs Withdraw
    ('commit_withdraw', 'first', 0): "the horizon ahead is revealing sturdy and enduring promise; pledging your sincere dedication now establishes a sacred cornerstone.",
    ('commit_withdraw', 'first', 1): "cosmic forces support devoted allegiance; binding your endeavors with integrity fosters deep trust and lasting harmony.",
    ('commit_withdraw', 'first', 2): "steadfast duty is the pathway to future fulfillment; dedicating yourself wholeheartedly generates unstoppable positive momentum.",

    ('commit_withdraw', 'second', 0): "the road ahead carries veiled ambiguities; stepping back peacefully is the prudent way to preserve vital energy.",
    ('commit_withdraw', 'second', 1): "hidden obligations remain obscure; disentangling yourself gracefully spares you from unwanted burdens.",
    ('commit_withdraw', 'second', 2): "discerning omens counsel against deeper entanglement; withdrawing with poise is the clearest sign of enlightened judgment.",

    # Left vs Right
    ('left_right', 'first', 0): "the receptive polarity is taking precedence; turning inward, observing silently, and accepting with grace brings unshakeable peace.",
    ('left_right', 'first', 1): "serene stillness calls you to return to the core; modest discretion and deep contemplation hold boundless spiritual power.",
    ('left_right', 'first', 2): "the cosmic alignment leans toward introspection; witnessing within rather than displaying outwardly accords with the supreme flow.",

    ('left_right', 'second', 0): "the active polarity is surging with creative fire; stepping outward, declaring your vision, and acting with zeal leads to fruition.",
    ('left_right', 'second', 1): "purposeful action is ripe for manifest expression; step into the light and share your authentic essence with the world.",
    ('left_right', 'second', 2): "an outward stance generates auspicious momentum; taking initiative and communicating your vision will find heartfelt accord.",

    # Yes vs No
    ('yes_no', 'first', 0): "your natal stars and universal timing are aligned in auspicious harmony; welcoming this opening will bring an unobstructed, radiant outcome.",
    ('yes_no', 'first', 1): "the universal gateway is receptive to affirmation; an affirmative choice right now is blessed with abundant cosmic support.",
    ('yes_no', 'first', 2): "all signs unite in peaceful agreement; stepping forward with confidence initiates profound positive transformations.",

    ('yes_no', 'second', 0): "the signs indicate latent cross-currents and conflicting forces; establishing a clear boundary and saying no is the enlightened choice.",
    ('yes_no', 'second', 1): "external circumstances are not prepared to sustain this; a firm refusal shields you from carrying unneeded burdens.",
    ('yes_no', 'second', 2): "protective warnings advise a quiet halt; maintaining sacred boundaries and declining preserves your peace of mind.",

    # Balanced
    ('balanced', 'balanced', 0): "the cosmic energies currently rest in perfect equilibrium; neither path holds superior advantage, so serene contemplation is the highest wisdom.",
    ('balanced', 'balanced', 1): "the universal scales maintain an auspicious pause; refrain from hurried choices while circumstances ripen in their own time.",
    ('balanced', 'balanced', 2): "opposing energetic forces are matched in equal measure; granting the situation a natural pause will allow the truth to illuminate itself.",
}
