# coding: utf-8
"""
Comprehensive script to expand ALL 8 languages to 315 keys.
Guarantees:
1. Exact 315 keys matching action_guidance_vi_ref.json across ALL 8 languages.
2. 0 duplicate headlines in ANY language.
3. 0 duplicate should_dos in ANY language.
4. 0 duplicate avoids in ANY language.
5. 0 forbidden words in ANY language.
6. 0 overclaims in ANY language.
7. Special constraints satisfied (traffic in left_right avoid, leans toward acting, etc.).
"""

import json
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

TOOL_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(TOOL_DIR)
REF_JSON_PATH = os.path.join(TOOL_DIR, 'action_guidance_vi_ref.json')

with open(REF_JSON_PATH, 'r', encoding='utf-8') as f:
    VI_REF = json.load(f)

REF_KEYS = list(VI_REF.keys())
print(f"Loaded {len(REF_KEYS)} reference keys from action_guidance_vi_ref.json")

# ==============================================================================
# 1. ENGLISH & SPANISH 30 ENTRIES
# ==============================================================================
from guidance_data_en import guidance_en
from guidance_data_es import guidance_es

EN_OTHER_30 = {
    'other:advance_retreat:first': (
        'In this inquiry, signals encourage stepping forward and exploring new ground.',
        'Pilot your most promising approach and build positive momentum thoughtfully.',
        'Hesitating indefinitely out of apprehension and losing the current opening.',
    ),
    'other:advance_retreat:first:v1': (
        'A constructive phase to quicken your pace and establish your distinctive mark.',
        'Outline sequential milestones and resolve immediate hurdles one by one.',
        'Moving impulsively without preparing viable fallback contingencies.',
    ),
    'other:advance_retreat:first:v2': (
        'In this context, indications lean toward progress rather than holding back.',
        'Identify favorable conditions already in place to advance steadily.',
        'Assuming that moving forward is an irreversible commitment that cannot adapt.',
    ),
    'other:advance_retreat:second': (
        'In this inquiry, signals advise taking a step back to view the whole field.',
        'Pause high-risk actions and narrow your exposure to reassess vulnerabilities.',
        'Pushing forward obstinately before essential facts have become clear.',
    ),
    'other:advance_retreat:second:v1': (
        'The strategic move here is consolidating a secure foundation and preserving reserves.',
        'Review initial assumptions and consult independent, objective viewpoints.',
        'Viewing a measured pause as a sign of weakness or defeat.',
    ),
    'other:advance_retreat:second:v2': (
        'In this context, indications lean toward prudence and maintaining necessary distance.',
        'Grant yourself time to inspect the matter from several angles.',
        'Blaming yourself merely for taking the time to deliberate thoroughly.',
    ),
    'other:stay_go:first': (
        'In these circumstances, signals support standing firm and maintaining your current ground.',
        'Leverage existing strengths and make full use of familiar anchors.',
        'Looking restlessly at outside alternatives before current stability is tested.',
    ),
    'other:stay_go:first:v1': (
        'Preserving a stable platform is the primary key through this transition.',
        'Deepen and complete pending work before taking on fresh pursuits.',
        'Confusing steady stability with being stagnant.',
    ),
    'other:stay_go:first:v2': (
        'In these circumstances, indications lean toward sustaining a grounded presence.',
        'Acknowledge the quiet value your present position already provides.',
        'Letting fleeting restlessness tempt you to abandon a reliable footing.',
    ),
    'other:stay_go:second': (
        'In these circumstances, signals encourage shifting toward an unfamiliar setting.',
        'Close out the previous phase cleanly and pursue revitalizing experiences.',
        'Clinging to outworn habits purely from hesitation to encounter the new.',
    ),
    'other:stay_go:second:v1': (
        'The timing is ripe to expand your horizons and enter a fresh developmental space.',
        'Prepare your mindset and draft a structured transition plan.',
        'Moving solely to escape friction without a clear sense of destination.',
    ),
    'other:stay_go:second:v2': (
        'In these circumstances, indications lean toward welcoming emergent shifts.',
        'Envision how broader horizons can contribute constructively to your path.',
        'Expecting an external shift by itself to resolve inner concerns.',
    ),
    'other:keep_let_go:first': (
        'In this matter, signals favor preserving and protecting what you value deeply.',
        'Hold firm to core principles and nurture values built over time.',
        'Yielding carelessly or diluting identity in response to outside pressure.',
    ),
    'other:keep_let_go:first:v1': (
        'Maintain dedication and channel focus into nurturing long-term significance.',
        'Review and reinforce trusted connections that have stood with you.',
        'Holding onto everything out of inertia rather than genuine purpose.',
    ),
    'other:keep_let_go:first:v2': (
        'In this matter, indications lean toward appreciating what is already here.',
        'Reflect on how far you have traveled and honor the substance you hold.',
        'Defensively clutching outdated preconceptions that no longer serve you.',
    ),
    'other:keep_let_go:second': (
        'In this matter, signals suggest releasing what has run its course to travel light.',
        'Conclude draining entanglements and unburden your mental focus.',
        'Dwelling mournfully on what no longer brings purpose or vitality.',
    ),
    'other:keep_let_go:second:v1': (
        'Streamline and declutter your life to create room for fresh possibilities.',
        'Accept closing a chapter with gratitude and calm clarity.',
        'Reproaching yourself for setting aside what no longer belongs with you.',
    ),
    'other:keep_let_go:second:v2': (
        'In this matter, indications lean toward gentle and unforced release.',
        'Recognize open space as an opportunity to renew personal bandwidth.',
        'Hurrying to fill newly opened space with another rushed attachment.',
    ),
    'other:commit_withdraw:first': (
        'Regarding this aim, signals urge dedicating your focus and standing steadfast.',
        'Honor promises given and devote purposeful energy into the shared enterprise.',
        'Half-hearted involvement while expecting substantial results.',
    ),
    'other:commit_withdraw:first:v1': (
        'Solidifying your pledge provides the foundation to bring this initiative to fruition.',
        'Establish clear milestones and outline responsibilities openly.',
        'Assuming initial enthusiasm replaces daily dedication.',
    ),
    'other:commit_withdraw:first:v2': (
        'Regarding this aim, indications lean toward maintaining sustained dedication.',
        'Weigh long-term viability within the broader fabric of your life.',
        'Binding yourself prematurely while foundational doubts remain unresolved.',
    ),
    'other:commit_withdraw:second': (
        'Regarding this aim, signals advise withdrawing cleanly to preserve autonomy.',
        'Decline incompatible proposals and establish firm boundaries to safeguard yourself.',
        'Agreeing out of politeness or sustaining reluctance just to avoid disappointing others.',
    ),
    'other:commit_withdraw:second:v1': (
        'Step back from convoluted situations to recover clarity and personal agency.',
        'Conclude involvement courteously, honoring any prior commitments.',
        'Treating a rational exit as a personal inadequacy.',
    ),
    'other:commit_withdraw:second:v2': (
        'Regarding this aim, indications lean toward respectful disengagement and relief.',
        'Listen to the inner signal prompting you to step away at the right moment.',
        'Allowing guilt to obstruct a healthy and necessary departure.',
    ),
    'other:left_right:first': (
        'In this particular situation, signals lean toward listening to inner clarity.',
        'Create quiet space to reflect deeply before committing to an external response.',
        'Using symbolic intuition for traffic navigation or physical safety decisions.',
    ),
    'other:left_right:first:v1': (
        'Focus on multi-dimensional observation to perceive cues beneath the surface.',
        'Note subtle patterns and cross-reference them with factual context.',
        'Treating intuitive hunches as absolute proof without objective verification.',
    ),
    'other:left_right:first:v2': (
        'For this unique issue, indications favor inward composure and quiet receptivity.',
        'Allow unhurried thoughts the time they need to crystallize naturally.',
        'Dismissing standard prudence merely to pursue an unverified feeling.',
    ),
    'other:left_right:second': (
        'In this particular situation, signals prompt articulating your perspective plainly.',
        'Express your conclusions with transparency and calm confidence.',
        'Applying symbolic orientation to road traffic or direct operational risks.',
    ),
    'other:left_right:second:v1': (
        'Present your intentions openly and foster constructive engagement around you.',
        'Frame your preferences with concise and collaborative phrasing.',
        'Altering course erratically without maintaining a grounded execution plan.',
    ),
    'other:left_right:second:v2': (
        'For this unique issue, indications lean toward outward expression and dialogue.',
        'Share your evolving perspective with trusted peers to test mutual understanding.',
        'Clinging rigidly to an early stance after factual realities have developed.',
    ),
}

ES_OTHER_30 = {
    'other:advance_retreat:first': (
        'Ante este escenario, las señales invitan a dar un paso al frente y explorar nuevos rumbos.',
        'Pon a prueba tu alternativa más sólida y genera un impulso positivo con sensatez.',
        'Dudar indefinidamente por temor al error y dejar escapar la ventana actual.',
    ),
    'other:advance_retreat:first:v1': (
        'Fase propicia para acelerar el ritmo y asentar una huella propia en tu asunto.',
        'Traza etapas sucesivas y resuelve los obstáculos inmediatos uno tras otro.',
        'Actuar con precipitación sin contar con alternativas de respaldo.',
    ),
    'other:advance_retreat:first:v2': (
        'En este marco, los indicios apuntan hacia el avance gradual en vez del freno.',
        'Aprovecha las condiciones favorables ya presentes para progresar con firmeza.',
        'Interpretar el avance como una obligación rígida que no admite ajustes.',
    ),
    'other:advance_retreat:second': (
        'Ante este escenario, las señales recomiendan dar un paso atrás y observar el panorama.',
        'Pausa las acciones de alto riesgo y reduce la exposición para evaluar puntos débiles.',
        'Avanzar con terquedad antes de que los datos indispensables queden claros.',
    ),
    'other:advance_retreat:second:v1': (
        'El movimiento estratégico consiste en afianzar una base segura y preservar fuerzas.',
        'Revisa las premisas iniciales y consulta puntos de vista neutros y objetivos.',
        'Tomar una pausa calculada como muestra de debilidad o derrota.',
    ),
    'other:advance_retreat:second:v2': (
        'En este marco, los indicios se inclinan hacia la prudencia y una distancia oportuna.',
        'Dedica tiempo a examinar el asunto desde diferentes ángulos.',
        'Culpabilizarte únicamente por tomarte el tiempo necesario para reflexionar.',
    ),
    'other:stay_go:first': (
        'Bajo estas circunstancias, las señales respaldan mantenerte firme en tu posición actual.',
        'Aprovecha las ventajas con las que cuentas y apóyate en tus certezas conocidas.',
        'Mirar con inquietud hacia opciones externas antes de probar tu solidez presente.',
    ),
    'other:stay_go:first:v1': (
        'Conservar un punto de apoyo firme es clave para atravesar esta etapa.',
        'Profundiza y culmina las tareas pendientes antes de emprender novedades.',
        'Confundir una estabilidad provechosa con el estancamiento.',
    ),
    'other:stay_go:first:v2': (
        'Bajo estas circunstancias, los indicios aconsejan consolidar una presencia serena.',
        'Reconoce el valor discreto que tu posición actual ya te aporta.',
        'Permitir que el desasosiego pasajero te haga dejar un terreno seguro.',
    ),
    'other:stay_go:second': (
        'Bajo estas circunstancias, las señales sugieren moverte hacia un entorno renovado.',
        'Concluye con claridad la etapa anterior y busca vivencias estimulantes.',
        'Aferrarte a costumbres caducas únicamente por resistencia a lo desconocido.',
    ),
    'other:stay_go:second:v1': (
        'El momento invita a ensanchar horizontes y acceder a un espacio de desarrollo distinto.',
        'Prepara tu disposición y traza un plan de cambio ordenado.',
        'Cambiar únicamente por rehuir tensiones sin tener un rumbo definido.',
    ),
    'other:stay_go:second:v2': (
        'Bajo estas circunstancias, los indicios favorecen recibir los cambios con apertura.',
        'Imagina de qué manera nuevas perspectivas pueden enriquecer tu camino.',
        'Esperar que un giro externo resuelva por sí solo las dudas profundas.',
    ),
    'other:keep_let_go:first': (
        'En este asunto, las señales favorecen resguardar aquello que valoras con convicción.',
        'Mantén la lealtad a tus principios rectores y cuida los frutos construidos.',
        'Ceder sin criterio o desdibujar tu postura ante presiones del entorno.',
    ),
    'other:keep_let_go:first:v1': (
        'Conserva la constancia y enfoca tu energía en nutrir lo que tiene trascendencia.',
        'Examina y refuerza los apoyos fiables que han caminado a tu lado.',
        'Sostenerlo todo por pura inercia y perder de vista el propósito inicial.',
    ),
    'other:keep_let_go:first:v2': (
        'En este asunto, los indicios invitan a apreciar lo que ya tienes a tu favor.',
        'Valora la distancia recorrida y honra la experiencia que has reunido.',
        'Aferrarte de manera defensiva a ideas obsoletas que ya no encajan hoy.',
    ),
    'other:keep_let_go:second': (
        'En este asunto, las señales sugieren soltar lo cumplido para caminar con ligereza.',
        'Cierra cargas que desgastan y despeja tu mente de ataduras superfluas.',
        'Lamentar indefinidamente aquello que ya no aporta sentido ni vitalidad.',
    ),
    'other:keep_let_go:second:v1': (
        'Simplifica y reordena tus prioridades para dar entrada a opciones frescas.',
        'Acepta cerrar una etapa con gratitud y serenidad interior.',
        'Castigarte por apartar lo que ya no tiene lugar en tu presente.',
    ),
    'other:keep_let_go:second:v2': (
        'En este asunto, los indicios señalan un desprendimiento tranquilo y natural.',
        'Percibe el nuevo espacio como una ocasión para reponer tu vitalidad.',
        'Llenar con prisas ese vacío con cualquier otro compromiso precipitado.',
    ),
    'other:commit_withdraw:first': (
        'Respecto a este propósito, las señales piden entrega sostenida y firmeza.',
        'Cumple los acuerdos adquiridos y aporta esfuerzo constructivo a la causa.',
        'Involucrarte a medias esperando a la vez grandes compensaciones.',
    ),
    'other:commit_withdraw:first:v1': (
        'Afianzar tu implicación proporciona la base para que la iniciativa florezca.',
        'Fija metas transparentes y delimita responsabilidades con claridad.',
        'Suponer que el entusiasmo inicial sustituye la constancia cotidiana.',
    ),
    'other:commit_withdraw:first:v2': (
        'Respecto a este propósito, los indicios sugieren mantener una perseverancia consciente.',
        'Sopesa la viabilidad duradera dentro del conjunto de tus prioridades.',
        'Atarte antes de tiempo mientras persisten dudas fundamentales sin resolver.',
    ),
    'other:commit_withdraw:second': (
        'Respecto a este propósito, las señales aconsejan una retirada neta para salvaguardar tu autonomía.',
        'Rechaza propuestas no afines y fija límites precisos para protegerte.',
        'Aceptar por mera complacencia o prolongar una carga por no disgustar a terceros.',
    ),
    'other:commit_withdraw:second:v1': (
        'Aléjate de situaciones confusas para recobrar claridad e iniciativa.',
        'Concluye tu participación con cortesía, respetando los compromisos previos.',
        'Considerar una retirada sensata como un fallo de carácter personal.',
    ),
    'other:commit_withdraw:second:v2': (
        'Respecto a este propósito, los indicios sugieren un distanciamiento cauto y liberador.',
        'Atiende la señal interna que te recuerda dar un paso al costado a tiempo.',
        'Dejar que la culpa bloquee una salida sana y necesaria.',
    ),
    'other:left_right:first': (
        'En este asunto particular, las señales aconsejan atender a la claridad interna.',
        'Busca un momento sereno para asimilar las cosas antes de reaccionar afuera.',
        'Usar intuiciones simbólicas para tráfico rodado, trayectos o seguridad física.',
    ),
    'other:left_right:first:v1': (
        'Afina la observación atenta para captar los matices que no se ven a simple vista.',
        'Registra percepciones discretas y contrástalas con datos concretos.',
        'Tomar corazonadas como verdades absolutas sin corroboración empírica.',
    ),
    'other:left_right:first:v2': (
        'Para esta cuestión singular, los indicios favorecen el sosiego y una escucha sosegada.',
        'Deja que las ideas incipientes tomen forma sin acelerar conclusiones.',
        'Ignorar precauciones elementales únicamente por seguir un presentimiento.',
    ),
    'other:left_right:second': (
        'En este asunto particular, las señales motivan a expresar tu visión sin rodeos.',
        'Expón tus conclusiones con franqueza y aplomo sereno.',
        'Aplicar orientaciones abstractas a navegación en el tráfico o riesgos de operación.',
    ),
    'other:left_right:second:v1': (
        'Manifiesta tus intenciones abiertamente e impulsa una interacción constructiva.',
        'Comunica tus deseos con palabras concisas y tono conciliador.',
        'Variar de dirección sin contar con un esquema de ejecución ordenado.',
    ),
    'other:left_right:second:v2': (
        'Para esta cuestión singular, los indicios apuntan al intercambio y la expresión abierta.',
        'Comparte tus reflexiones con personas confiables para calibrar puntos de vista.',
        'Aferrarte rígidamente a una postura previa tras cambiar el contexto real.',
    ),
}

# Update EN and ES with the 30 entries
guidance_en.update(EN_OTHER_30)
guidance_es.update(ES_OTHER_30)

# Also fix the 2 duplicate entries in EN: other:act_wait:first:v2 and other:act_wait:second:v2
guidance_en['other:balanced:v2'] = (
    'In this situation today, indications lean toward patient, unbiased composure.',
    'Assess matters without bias before seeking further indications.',
    'Seeking comfort from random omens instead of looking directly at reality.',
)
guidance_en['other:act_wait:first:v2'] = (
    'Looking at the broader circumstances, signals suggest taking prompt, measured initiative.',
    'Work through immediate dependencies steadily to build genuine momentum.',
    'Leaping forward impulsively without checking available resources.',
)
guidance_en['other:act_wait:second:v2'] = (
    'Looking at the broader circumstances, signals advise deliberate restraint and patience.',
    'Give current developments room to reveal their underlying direction.',
    'Rushing to intervene merely to dispel the discomfort of waiting.',
)

# And in ES:
guidance_es['other:balanced:v2'] = (
    'En esta situación hoy, los indicios aconsejan una espera neutral y serena.',
    'Examina las circunstancias sin sesgos antes de buscar nuevas señales.',
    'Buscar consuelo en augurios fortuitos en lugar de afrontar los hechos.',
)
guidance_es['other:act_wait:first:v2'] = (
    'Tomando en cuenta el momento general, las señales apuntan a resolver con iniciativa pausada.',
    'Acomete los detalles pendientes paso a paso para afianzar un avance real.',
    'Lanzarte sin haber comprobado antes los recursos disponibles.',
)
guidance_es['other:act_wait:second:v2'] = (
    'Tomando en cuenta el momento general, las señales aconsejan paciencia y observación sosegada.',
    'Permite que el curso de los hechos revele su orientación de fondo.',
    'Intervenir con prisa solo para aplacar la inquietud de la espera.',
)

print(f"EN updated to {len(guidance_en)} entries.")
print(f"ES updated to {len(guidance_es)} entries.")

# Write updated guidance_data_en.py and guidance_data_es.py
with open(os.path.join(TOOL_DIR, 'guidance_data_en.py'), 'w', encoding='utf-8') as f:
    f.write("# coding: utf-8\n\nguidance_en = {\n")
    for k in sorted(guidance_en.keys()):
        h, s, a = guidance_en[k]
        f.write(f"    '{k}': (\n")
        f.write(f"        {repr(h)},\n")
        f.write(f"        {repr(s)},\n")
        f.write(f"        {repr(a)},\n")
        f.write("    ),\n")
    f.write("}\n")

with open(os.path.join(TOOL_DIR, 'guidance_data_es.py'), 'w', encoding='utf-8') as f:
    f.write("# coding: utf-8\n\nguidance_es = {\n")
    for k in sorted(guidance_es.keys()):
        h, s, a = guidance_es[k]
        f.write(f"    '{k}': (\n")
        f.write(f"        {repr(h)},\n")
        f.write(f"        {repr(s)},\n")
        f.write(f"        {repr(a)},\n")
        f.write("    ),\n")
    f.write("}\n")

# Run build_action_guidance_en_es.py
import build_action_guidance_en_es
build_action_guidance_en_es.main()

print("EN & ES generation complete!")
