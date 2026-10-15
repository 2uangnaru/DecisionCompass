# -*- coding: utf-8 -*-
"""
English & Spanish data for Cosmic Headline Composer.
Western cultural zone: Western Zodiac, Planetary alignments, Lunar phases, Cosmic resonance.
Accessible, articulate, 0 forbidden words, 0 overclaims.
"""

EN_CONTEXTS = {
    ('career', 'morning'): "As the morning sun brings renewed vitality to your professional ambitions",
    ('career', 'midday'): "At midday, as clarity illuminates your trajectory and external endeavors",
    ('career', 'afternoon'): "This afternoon, as strategic focus calls for a grounded anchor",
    ('career', 'evening'): "As evening settles and the demands of the working sphere quiet down",
    ('career', 'now'): "In this present moment, the cosmic current around your endeavors is actively aligning",

    ('love', 'morning'): "This morning, as fresh dawn lights up the subtle currents of affection",
    ('love', 'midday'): "At midday, as emotional awareness calls for honesty and sincere balance",
    ('love', 'afternoon'): "This afternoon, as interpersonal bonds shift into a rhythmic harmony",
    ('love', 'evening'): "Under the starlight as evening settles, deeper intuitive feelings awaken",
    ('love', 'now'): "In this present moment, the quiet resonance between hearts is flowing",

    ('money', 'morning'): "This morning, as daily vitality begins to activate your resource streams",
    ('money', 'midday'): "At midday, as practical affairs require disciplined stewardship and clarity",
    ('money', 'afternoon'): "This afternoon, as stability proves far wiser than sudden fluctuations",
    ('money', 'evening'): "As evening settles, celestial stillness favors safeguarding what you have built",
    ('money', 'now'): "In this present moment, material stability stands at a calm equilibrium",

    ('study', 'morning'): "This morning, as pristine dawn clears mental horizons for deep learning",
    ('study', 'midday'): "At midday, as intellectual curiosity demands sharp concentration and focus",
    ('study', 'afternoon'): "This afternoon, as newly absorbed insights benefit from structured order",
    ('study', 'evening'): "As evening settles, quiet contemplative space opens up reflective absorption",
    ('study', 'now'): "In this present moment, the intellect is primed with lucid mental acuity",

    ('friends', 'morning'): "This morning, as open skies invite positive social connections and shared warmth",
    ('friends', 'midday'): "At midday, as daily exchanges and social encounters gather momentum",
    ('friends', 'afternoon'): "This afternoon, as harmonic resonance deepens mutual understanding",
    ('friends', 'evening'): "As evening settles, peaceful tranquility makes room for genuine conversation",
    ('friends', 'now'): "In this present moment, the social field reflects meaningful shared presence",

    ('general', 'morning'): "This morning, as the celestial cycle initiates a fresh diurnal rhythm",
    ('general', 'midday'): "At midday, as energetic forces reach their peak illumination",
    ('general', 'afternoon'): "This afternoon, as active motion transitions into balanced steadiness",
    ('general', 'evening'): "As evening settles, the cosmic pace gently softens into restful calm",
    ('general', 'now'): "In this present moment, the surrounding cosmic field converges with clarity",

    ('other', 'morning'): "This morning, as external variables begin to set their course",
    ('other', 'midday'): "At midday, as unfolding circumstances present themselves distinctly",
    ('other', 'afternoon'): "This afternoon, as diverse elements settle into steady motion",
    ('other', 'evening'): "As evening settles, quiet stillness helps untangle lingering ambiguities",
    ('other', 'now'): "In this present moment, the broader circumstances reflect a coherent balance",
}

EN_MECHANISMS = {
    # Reason vs Emotion
    ('reason_emotion', 'first', 0): "your chart shows Mercury (intellect and clarity) rising above emotional waves; grounding yourself in calm reason and verifiable facts will reveal the true path forward.",
    ('reason_emotion', 'first', 1): "analytical clarity is outweighing temporary emotional turbulence; relying on objective evidence provides the most dependable guidance right now.",
    ('reason_emotion', 'first', 2): "celestial geometry favors cool discernment over fleeting feelings; prioritizing logic keeps your footing steady and purposeful.",

    ('reason_emotion', 'second', 0): "the Moon is amplifying your inner intuition at its peak; your heartfelt instincts and subtle feelings are far more trustworthy right now than rigid logic.",
    ('reason_emotion', 'second', 1): "inner emotional resonance is reaching a powerful wave; honoring what feels intuitively right will guide you toward true harmony.",
    ('reason_emotion', 'second', 2): "the stars indicate that genuine personal resonance carries greater wisdom than cold calculations; let your heart speak in this choice.",

    # Confront vs Avoid
    ('confront_avoid', 'first', 0): "the decisive drive of Mars is lending you courage; directly addressing the matter now will untangle lingering knots far faster than avoiding it.",
    ('confront_avoid', 'first', 1): "constructive momentum has gathered sufficient force to break through hesitation; speaking candidly will dissolve quiet friction once and for all.",
    ('confront_avoid', 'first', 2): "the current atmosphere urges you not to shy away from necessary dialogue; stepping up with honest resolve will clear the air completely.",

    ('confront_avoid', 'second', 0): "the surrounding field is navigating turbulent friction; mindfully stepping back to avoid conflict is not weakness, but a wise strategy to preserve inner peace.",
    ('confront_avoid', 'second', 1): "current conditions carry unnecessary friction; maintaining a peaceful distance and steering clear of clashes protects your vital reserves.",
    ('confront_avoid', 'second', 2): "the indicators warn that head-on collisions would only drain your energy; keeping calm boundaries and sidestepping tension serves you best.",

    # Act vs Wait (MUST contain 'leans toward acting', 'timing', 'everything else')
    ('act_wait', 'first', 0): "taking into account timing and everything else, the reading leans toward acting with purposeful confidence right now.",
    ('act_wait', 'first', 1): "balancing favorable timing alongside everything else, the reading leans toward acting to seize the emerging initiative.",
    ('act_wait', 'first', 2): "weighing immediate timing against everything else, the reading leans toward acting rather than letting momentum fade away.",

    ('act_wait', 'second', 0): "cosmic timing advises measured patience; holding back calmly to let conditions ripen will prevent unforeseen missteps.",
    ('act_wait', 'second', 1): "external circumstances have not yet coalesced in your favor; waiting patiently is the highest expression of sound judgment.",
    ('act_wait', 'second', 2): "Saturn emphasizes the lasting value of deliberate patience; observing the landscape calmly is far superior to an unready start.",

    # Advance vs Retreat
    ('advance_retreat', 'first', 0): "the prevailing cosmic tide is flowing smoothly in your direction; stepping forward with confidence expands your advantage.",
    ('advance_retreat', 'first', 1): "momentum gathered over recent days has created a solid springboard; moving forward decisively establishes a clear presence.",
    ('advance_retreat', 'first', 2): "celestial winds favor bold initiative; an active forward step will open welcoming avenues for growth.",

    ('advance_retreat', 'second', 0): "surrounding currents face notable headwinds; strategically stepping back to survey the wider picture is the wiser tactical move.",
    ('advance_retreat', 'second', 1): "external friction is exceeding comfortable thresholds; a dignified retreat to regroup safeguards your progress.",
    ('advance_retreat', 'second', 2): "knowing when to pause and withdraw demonstrates true maturity; pulling back preserves all that you have achieved.",

    # Stay vs Go
    ('stay_go', 'first', 0): "your present foundation still holds strong, supportive anchors; staying steadfast to nurture your roots will yield enduring results.",
    ('stay_go', 'first', 1): "anchoring energy urges stability over restless motion; remaining committed to your present ground offers the greatest security.",
    ('stay_go', 'first', 2): "the vital nourishment of your current position continues to sustain you; staying to fulfill ongoing potential is the sound choice.",

    ('stay_go', 'second', 0): "the current cycle has completed its supportive mission; courageously stepping out toward fresh horizons will unlock renewed vitality.",
    ('stay_go', 'second', 1): "energies of renewal are calling you forward; moving on now releases latent potential that has outgrown its container.",
    ('stay_go', 'second', 2): "the current setting has reached its natural limits; departing to explore a new chapter brings an invigorating breath of fresh air.",

    # Keep vs Let Go
    ('keep_let_go', 'first', 0): "the core essence of what you hold still possesses genuine brilliance; patient stewardship will preserve its long-term significance.",
    ('keep_let_go', 'first', 1): "what you have built represents a foundation worth cherishing; holding onto it carefully will bring rewarding fulfillment.",
    ('keep_let_go', 'first', 2): "the moment to release has not arrived; continuing to protect and stand by this commitment proves its true worth over time.",

    ('keep_let_go', 'second', 0): "accumulated weight has begun restricting your inner freedom; releasing it gracefully makes room for fresh inspiration to enter.",
    ('keep_let_go', 'second', 1): "letting go of what no longer serves your journey is a natural healing process; releasing the past clears space for renewal.",
    ('keep_let_go', 'second', 2): "stagnant attachments need to be dissolved; releasing your grip brings a profound and welcome lightness of being.",

    # Commit vs Withdraw
    ('commit_withdraw', 'first', 0): "the horizon ahead is revealing dependable long-term promise; making a thoughtful commitment now will lay a sturdy cornerstone.",
    ('commit_withdraw', 'first', 1): "celestial indicators support enduring dedication; binding your efforts with integrity fosters lasting trust and strength.",
    ('commit_withdraw', 'first', 2): "steadfast responsibility is the gateway to future fulfillment; committing wholeheartedly generates powerful forward traction.",

    ('commit_withdraw', 'second', 0): "the road ahead carries ambiguous uncertainties; stepping back safely is the prudent way to conserve valuable resources.",
    ('commit_withdraw', 'second', 1): "unforeseen obligations remain murky and unrefined; extricating yourself from entanglements spares you needless burdens.",
    ('commit_withdraw', 'second', 2): "cautionary signals suggest avoiding deep commitments; withdrawing with poise is the clearest demonstration of discernment.",

    # Left vs Right
    ('left_right', 'first', 0): "receptive yin polarity is taking the lead; turning inward, listening quietly, and gentle acceptance will bring centered peace.",
    ('left_right', 'first', 1): "contemplative stillness invites you to retreat within; quiet discretion and receptive reflection hold subtle, profound strength.",
    ('left_right', 'first', 2): "celestial geometry leans toward introspection; perceptive observation rather than outward display harmonizes with the cosmic rhythm.",

    ('left_right', 'second', 0): "expressive yang polarity is surging with initiative; stepping outward, expressing your vision, and engaging with vigor leads to success.",
    ('left_right', 'second', 1): "proactive motion is primed for decisive expression; step into the open and share your authentic presence with the world.",
    ('left_right', 'second', 2): "an outward stance creates welcome momentum; taking the initiative and articulating your perspective will meet ready resonance.",

    # Yes vs No
    ('yes_no', 'first', 0): "your natal indicators and the cosmic tide unite in supportive harmony; leaning into this opening will bring a fluid, constructive outcome.",
    ('yes_no', 'first', 1): "the energy field opens wide to welcome affirmation; an affirmative choice right now enjoys the full backing of the natural flow.",
    ('yes_no', 'first', 2): "all signs converge in mutual agreement; moving forward with a confident affirmation sets positive transformations into motion.",

    ('yes_no', 'second', 0): "the indicators point to latent cross-currents and hidden obstacles; drawing a firm line and saying no is the wiser course.",
    ('yes_no', 'second', 1): "external conditions are not aligned to sustain this venture; a clear refusal protects you from taking on unnecessary burdens.",
    ('yes_no', 'second', 2): "cautionary signposts suggest pulling back; maintaining healthy boundaries and answering with a no safeguards your well-being.",

    # Balanced
    ('balanced', 'balanced', 0): "the cosmic currents currently rest in exact equilibrium; neither path holds an obvious advantage, so patient stillness is the wisest choice.",
    ('balanced', 'balanced', 1): "the celestial scales maintain a peaceful pause; avoid rushing into a decision while the indicators invite calm reflection.",
    ('balanced', 'balanced', 2): "opposing energetic forces are matched in equal measure; granting the situation a natural pause will allow clarity to emerge on its own.",
}

EN_NEW_MODES_GUIDANCE = {
    'reason_emotion:first': (
        "Verify facts independently and outline pros and cons clearly before settling on a choice.",
        "Letting temporary moods or emotional pressure from others force an unready decision."
    ),
    'reason_emotion:second': (
        "Listen to your quiet intuition and deepest heartfelt feelings to choose the path of inner peace.",
        "Suppressing genuine emotions just to squeeze into rigid, cold analytical molds."
    ),
    'confront_avoid:first': (
        "Communicate candidly and address unresolved tensions directly to clear lingering friction.",
        "Allowing prolonged silence or avoidance to let misunderstandings grow more complicated."
    ),
    'confront_avoid:second': (
        "Step back mindfully to avoid head-on friction, giving yourself space to observe and recharge.",
        "Jumping into hostile arguments when external conditions are clearly not favorable."
    ),
}

# SPANISH (Español) - Cálido, reflexivo, sin palabras prohibidas
ES_CONTEXTS = {
    ('career', 'morning'): "Esta mañana, cuando la luz del alba infunde vitalidad a tus aspiraciones",
    ('career', 'midday'): "Hacia el mediodía, cuando la claridad ilumina tus proyectos y actividades",
    ('career', 'afternoon'): "Esta tarde, cuando el enfoque estratégico requiere un apoyo firme",
    ('career', 'evening'): "Al caer la tarde, cuando el ritmo de las responsabilidades se va serenando",
    ('career', 'now'): "En este instante presente, la corriente en torno a tus metas se alinea con nitidez",

    ('love', 'morning'): "Esta mañana, cuando el amanecer ilumina las corrientes del afecto compartido",
    ('love', 'midday'): "Hacia el mediodía, cuando la sintonía del corazón pide honestidad y equilibrio",
    ('love', 'afternoon'): "Esta tarde, cuando las energías de conexión fluyen con serena armonía",
    ('love', 'evening'): "Bajo la quietud nocturna al caer la tarde, los sentimientos profundos despiertan",
    ('love', 'now'): "En este instante presente, la sintonía entre almas fluye con ternura",

    ('money', 'morning'): "Esta mañana, cuando la energía del día comienza a activar tus recursos",
    ('money', 'midday'): "Hacia el mediodía, cuando la prudencia requiere orden y visión clara",
    ('money', 'afternoon'): "Esta tarde, cuando la constancia demuestra ser más sabia que la agitación",
    ('money', 'evening'): "Al caer la tarde, la calma astral aconseja proteger lo construido con esmero",
    ('money', 'now'): "En este instante presente, la estabilidad material se encuentra en sereno equilibrio",

    ('study', 'morning'): "Esta mañana, cuando el alba despeja el horizonte mental para el aprendizaje",
    ('study', 'midday'): "Hacia el mediodía, cuando la curiosidad intelectual exige concentración y agudeza",
    ('study', 'afternoon'): "Esta tarde, cuando los conocimientos asimilados se consolidan con orden",
    ('study', 'evening'): "Al caer la tarde, la tranquilidad abre espacio para una asimilación profunda",
    ('study', 'now'): "En este instante presente, la mente se encuentra despierta y lúcida",

    ('friends', 'morning'): "Esta mañana, cuando el día invita a compartir calidez y cercanía sincera",
    ('friends', 'midday'): "Hacia el mediodía, cuando las conversaciones cotidianas toman buen ritmo",
    ('friends', 'afternoon'): "Esta tarde, cuando la empatía mutua afianza los lazos compartidos",
    ('friends', 'evening'): "Al caer la tarde, la serenidad propicia un diálogo apacible y transparente",
    ('friends', 'now'): "En este instante presente, la convivencia refleja una armonía genuina",

    ('general', 'morning'): "Esta mañana, cuando el ciclo astral inicia un nuevo compás vital",
    ('general', 'midday'): "Hacia el mediodía, cuando las corrientes energéticas alcanzan su cenit",
    ('general', 'afternoon'): "Esta tarde, cuando el movimiento se encamina hacia una serena estabilidad",
    ('general', 'evening'): "Al caer la tarde, el pulso del entorno se sosiega suavemente",
    ('general', 'now'): "En este instante presente, las fuerzas celestes convergen con nitidez",

    ('other', 'morning'): "Esta mañana, cuando las circunstancias exteriores comienzan a definirse",
    ('other', 'midday'): "Hacia el mediodía, cuando el panorama se manifiesta con mayor transparencia",
    ('other', 'afternoon'): "Esta tarde, cuando los distintos factores se asientan en su cauce",
    ('other', 'evening'): "Al caer la tarde, la calma ayuda a despejar cualquier incertidumbre",
    ('other', 'now'): "En este instante presente, el conjunto de los elementos guarda un equilibrio fiel",
}

ES_MECHANISMS = {
    # Reason vs Emotion
    ('reason_emotion', 'first', 0): "la configuración astral muestra a Mercurio (la lucidez mental) prevaleciendo sobre las mareas emocionales; apoyarte en la razón serena y en los hechos reales te brindará la máxima claridad ahora.",
    ('reason_emotion', 'first', 1): "el análisis objetivo supera la agitación pasajera de los ánimos; confiar en la evidencia tangible es la guía más segura en este instante.",
    ('reason_emotion', 'first', 2): "el mapa astral favorece la mente despejada frente a impulsos efímeros; dar prioridad a la lógica mantendrá tu rumbo firme y certero.",

    ('reason_emotion', 'second', 0): "la influencia lunar exalta tu intuición con notable intensidad; los latidos y percepciones de tu voz interna resultan más fieles que los cálculos fríos.",
    ('reason_emotion', 'second', 1): "la sensibilidad íntima alcanza una marea luminosa; escuchar con atención lo que tu corazón percibe te orientará hacia la verdadera concordia.",
    ('reason_emotion', 'second', 2): "los astros sugieren que una emoción auténtica encierra mayor sabiduría que fórmulas rígidas; permite que tu sensibilidad hable en esta elección.",

    # Confront vs Avoid
    ('confront_avoid', 'first', 0): "el impulso firme de Marte te otorga determinación; abordar el asunto de frente resolverá tensiones mucho más pronto que esquivarlo.",
    ('confront_avoid', 'first', 1): "la energía acumulada reúne la fuerza suficiente para vencer cualquier duda; un diálogo sincero disipará fricciones que llevaban tiempo latentes.",
    ('confront_avoid', 'first', 2): "el clima actual te anima a no rehuir las conversaciones necesarias; dar el paso con franqueza despejará el camino por completo.",

    ('confront_avoid', 'second', 0): "el entorno atraviesa momentos de fricción; apartarse con prudencia no es debilidad, sino una sabia táctica para cuidar tu paz mental.",
    ('confront_avoid', 'second', 1): "las circunstancias presentes conllevan choques innecesarios; tomar una distancia prudente te protege de desgastes infructuosos.",
    ('confront_avoid', 'second', 2): "las señales indican que un choque frontal solo restaría energías; conservar la calma y sortear la polémica es tu mejor escudo.",

    # Act vs Wait
    ('act_wait', 'first', 0): "la alineación astral favorece la iniciativa decidida; ponerte en marcha ahora generará un impulso muy superior a la vacilación.",
    ('act_wait', 'first', 1): "la coyuntura actual abre una senda propicia para avanzar; actuar con determinación tiene la virtud de desbloquear el horizonte.",
    ('act_wait', 'first', 2): "considerando el momento y los factores en juego, la lectura aconseja actuar con seguridad para aprovechar la ocasión.",

    ('act_wait', 'second', 0): "el ritmo cósmico sugiere una pausa prudente; aguardar con paciencia a que el terreno madure evitará contratiempos inesperados.",
    ('act_wait', 'second', 1): "las condiciones exteriores aún no se han conjugado plenamente; esperar con serenidad es la prueba más alta de sensatez.",
    ('act_wait', 'second', 2): "Saturno recuerda el valor imperecedero de la calma; observar los acontecimientos supera con creces a una acción apresurada.",

    # Advance vs Retreat
    ('advance_retreat', 'first', 0): "la marea astral sopla favorablemente a tus espaldas; dar un paso al frente con confianza afianzará tu posición.",
    ('advance_retreat', 'first', 1): "el impulso reunido en días previos sirve de firme plataforma; avanzar con firmeza consolida tus horizontes.",
    ('advance_retreat', 'first', 2): "los vientos cósmicos acompañan la audacia reflexiva; tomar la delantera abrirá valiosas oportunidades de desarrollo.",

    ('advance_retreat', 'second', 0): "las corrientes del entorno presentan notables resistencias; retroceder un compás para observar el cuadro entero es una decisión sagaz.",
    ('advance_retreat', 'second', 1): "el roce exterior supera los márgenes de comodidad; una retirada a tiempo para reorganizar tus fuerzas preserva lo logrado.",
    ('advance_retreat', 'second', 2): "saber cuándo detenerse y dar un paso atrás demuestra templanza; replegarse con elegancia protege tu bienestar.",

    # Stay vs Go
    ('stay_go', 'first', 0): "tu base actual aún ofrece cimientos muy firmes; permanecer con constancia y nutrir tus raíces dará frutos duraderos.",
    ('stay_go', 'first', 1): "la energía de arraigo aconseja estabilidad antes que movimientos dispersos; afianzarte en tu lugar actual te brinda gran seguridad.",
    ('stay_go', 'first', 2): "la savia de tu entorno presente continúa alimentando tu crecimiento; quedarte para completar lo comenzado es un acierto.",

    ('stay_go', 'second', 0): "el ciclo que te cobijaba ha concluido su ciclo protector; dar el salto con valor hacia otros rumbos despertará renovadas energías.",
    ('stay_go', 'second', 1): "vientos de renovación reclaman tu partida; marcharte ahora liberará dones que ya no cabían en el marco antiguo.",
    ('stay_go', 'second', 2): "el espacio presente ha colmado su medida; emprender camino hacia una nueva etapa te traerá un soplo vital muy necesario.",

    # Keep vs Let Go
    ('keep_let_go', 'first', 0): "la esencia de lo que atesoras guarda un brillo genuino; custodiarlo con paciencia preservará su valor a largo plazo.",
    ('keep_let_go', 'first', 1): "lo que has edificado con esmero merece ser preservado; sostenerlo con cuidado te brindará satisfacciones auténticas.",
    ('keep_let_go', 'first', 2): "el momento de desprenderse no ha llegado aún; seguir protegiendo esto demostrará su auténtico peso con el tiempo.",

    ('keep_let_go', 'second', 0): "la carga acumulada empezaba a frenar tu libertad interior; soltarla con dulzura abre paso a la serenidad.",
    ('keep_let_go', 'second', 1): "dejar ir aquello que ya no acompasa tu camino es un acto de sanación; liberarte de lo pretérito hace sitio a lo nuevo.",
    ('keep_let_go', 'second', 2): "las adherencias estancadas precisan diluirse; soltar las amarras te devolverá la ligereza de espíritu que anhelabas.",

    # Commit vs Withdraw
    ('commit_withdraw', 'first', 0): "el horizonte revela una promesa de solidez continuada; sellar un compromiso sereno ahora sentará una base perdurable.",
    ('commit_withdraw', 'first', 1): "los indicios astrales respaldan una entrega sincera; ligar tus esfuerzos con lealtad construirá una alianza inquebrantable.",
    ('commit_withdraw', 'first', 2): "la constancia y la responsabilidad abren las puertas del porvenir; comprometerte a fondo generará un salto cualitativo.",

    ('commit_withdraw', 'second', 0): "el camino venidero encierra incertidumbres difusas; apartarte con cautela es la vía sensata para resguardar tus energías.",
    ('commit_withdraw', 'second', 1): "las ataduras y riesgos permanecen poco diáfanos; desvincularte a tiempo te librará de complicaciones innecesarias.",
    ('commit_withdraw', 'second', 2): "las señales de precaución desaconsejan involucrarse en exceso; retirarse con prudencia es una muestra de sabiduría.",

    # Left vs Right
    ('left_right', 'first', 0): "la polaridad receptiva toma la iniciativa; volver la mirada hacia dentro, escuchar en silencio y acoger con suavidad te traerá paz.",
    ('left_right', 'first', 1): "la quietud interior te invita a recogerte; una discreta serenidad y una mirada atenta encierran una fuerza profunda.",
    ('left_right', 'first', 2): "el mapa celeste se inclina hacia la introspección; observar con agudeza antes que exhibirse afina tu sintonía con el cosmos.",

    ('left_right', 'second', 0): "la polaridad activa emerge con brío; manifestarte, compartir tus ideas y actuar con entusiasmo te abrirá las puertas del éxito.",
    ('left_right', 'second', 1): "la energía exteriorizadora está lista para expresarse; sal al encuentro de los demás y muestra tu autenticidad.",
    ('left_right', 'second', 2): "una actitud extrovertida despierta una respuesta inmediata; tomar la delantera y comunicar tu visión hallará eco sincero.",

    # Yes vs No
    ('yes_no', 'first', 0): "los astros y el flujo universal aúnan sus fuerzas para apoyarte; acoger esta oportunidad con un sí te abrirá senderos despejados.",
    ('yes_no', 'first', 1): "la corriente vital se abre generosa a la afirmación; una respuesta positiva goza del respaldo sincero del entorno.",
    ('yes_no', 'first', 2): "todos los signos coinciden en armonía; asentir con seguridad desencadenará transformaciones enriquecedoras.",

    ('yes_no', 'second', 0): "los indicios advierten de roces ocultos y barreras latentes; cerrar el paso y pronunciar una negativa es la opción lúcida.",
    ('yes_no', 'second', 1): "las circunstancias exteriores no están dispuestas para esta propuesta; declinar con firmeza te librará de ataduras no deseadas.",
    ('yes_no', 'second', 2): "las señales de cautela recomiendan detenerse; preservar tus márgenes y decir que no salvaguarda tu serenidad.",

    # Balanced
    ('balanced', 'balanced', 0): "las corrientes astrales guardan un exacto equilibrio; ninguna senda aventaja a la otra, por lo que la calma reflexiva es tu mejor guía.",
    ('balanced', 'balanced', 1): "la balanza del cielo sostiene una pausa compasiva; no te apresures a decidir mientras las señales te invitan a madurar la situación.",
    ('balanced', 'balanced', 2): "las fuerzas en juego muestran igual vigor; otorgar un compás de espera permitirá que la claridad brote por su propio peso.",
}

ES_NEW_MODES_GUIDANCE = {
    'reason_emotion:first': (
        "Examina los datos de forma independiente y sopesa pros y contras con calma antes de resolverte.",
        "Dejar que un estado de ánimo pasajero o la prisa de terceros te obligue a cerrar un veredicto precoz."
    ),
    'reason_emotion:second': (
        "Presta oídos a tu intuición serena y al pálpito de tu corazón para elegir la senda de mayor paz.",
        "Reprimir tus verdaderos sentimientos solo para amoldarte a esquemas excesivamente fríos."
    ),
    'confront_avoid:first': (
        "Comunícate con franqueza y afronta las diferencias pendientes para sanear cualquier tensión acumulada.",
        "Alimentar silencios prolongados o esquivar el diálogo, permitiendo que la confusión crezca sin control."
    ),
    'confront_avoid:second': (
        "Toma distancia con prudencia para eludir fricciones innecesarias, dándote espacio para observar y renovarte.",
        "Enzarzarte en discusiones hostiles cuando el entorno exterior no resulta propicio para el entendimiento."
    ),
}
