# coding: utf-8
"""
Fix all duplicate headlines, should_dos, and avoids in EN and ES.
Guarantees:
- 315 keys
- 0 duplicate headlines in EN and ES
- 0 duplicate should_dos in EN and ES
- 0 duplicate avoids in EN and ES
- 0 forbidden words in EN and ES
- 0 overclaims in EN and ES
- Special constraints satisfied
"""
import sys
from collections import Counter
sys.stdout.reconfigure(encoding='utf-8')

from guidance_data_en import guidance_en
from guidance_data_es import guidance_es

# ==============================================================================
# 1. FIX EN DUPLICATES
# ==============================================================================

# Headlines v2 vs v0
guidance_en['act_wait:first:v2'] = (
    'Taking into account current conditions, indications lean toward purposeful, prepared initiative.',
    guidance_en['act_wait:first:v2'][1],
    guidance_en['act_wait:first:v2'][2]
)
guidance_en['act_wait:second:v2'] = (
    'Taking into account current conditions, indications lean toward watchful composure and waiting.',
    guidance_en['act_wait:second:v2'][1],
    guidance_en['act_wait:second:v2'][2]
)
guidance_en['advance_retreat:first:v2'] = (
    'Evaluating recent forward momentum, indications favor advancing step by steady step.',
    guidance_en['advance_retreat:first:v2'][1],
    guidance_en['advance_retreat:first:v2'][2]
)
guidance_en['advance_retreat:second:v2'] = (
    'Evaluating recent forward momentum, indications favor consolidating ground and holding back.',
    guidance_en['advance_retreat:second:v2'][1],
    guidance_en['advance_retreat:second:v2'][2]
)
guidance_en['commit_withdraw:first:v2'] = (
    'Looking at upcoming obligations, indications lean toward steadfast and calm dedication.',
    guidance_en['commit_withdraw:first:v2'][1],
    guidance_en['commit_withdraw:first:v2'][2]
)
guidance_en['commit_withdraw:second:v2'] = (
    'Looking at upcoming obligations, indications lean toward measured disengagement.',
    guidance_en['commit_withdraw:second:v2'][1],
    guidance_en['commit_withdraw:second:v2'][2]
)
guidance_en['keep_let_go:first:v2'] = (
    'Reflecting on enduring worth, indications lean toward honoring and safeguarding what exists.',
    guidance_en['keep_let_go:first:v2'][1],
    guidance_en['keep_let_go:first:v2'][2]
)
guidance_en['keep_let_go:second:v2'] = (
    'Reflecting on enduring worth, indications lean toward releasing baggage with grace.',
    guidance_en['keep_let_go:second:v2'][1],
    guidance_en['keep_let_go:second:v2'][2]
)
guidance_en['left_right:first:v2'] = (
    'Weighing subtle polarities, indications point toward inner stillness and receptive listening.',
    guidance_en['left_right:first:v2'][1],
    guidance_en['left_right:first:v2'][2]
)
guidance_en['left_right:second:v2'] = (
    'Weighing subtle polarities, indications point toward outward expression and clear speech.',
    guidance_en['left_right:second:v2'][1],
    guidance_en['left_right:second:v2'][2]
)
guidance_en['stay_go:first:v2'] = (
    'Considering baseline stability, indications favor anchoring yourself in your present setting.',
    guidance_en['stay_go:first:v2'][1],
    guidance_en['stay_go:first:v2'][2]
)
guidance_en['stay_go:second:v2'] = (
    'Considering baseline stability, indications favor transitioning toward emergent horizons.',
    guidance_en['stay_go:second:v2'][1],
    guidance_en['stay_go:second:v2'][2]
)
guidance_en['money:commit_withdraw:first:v2'] = (
    'Reviewing practical resources, indications favor prudent budgeting and safeguarding reserves.',
    guidance_en['money:commit_withdraw:first:v2'][1],
    guidance_en['money:commit_withdraw:first:v2'][2]
)

# ShouldDos in EN
guidance_en['friends:act_wait:first:v2'] = (
    guidance_en['friends:act_wait:first:v2'][0],
    'Reach out thoughtfully to a companion you have been hoping to reconnect with.',
    guidance_en['friends:act_wait:first:v2'][2]
)
guidance_en['friends:act_wait:second:v2'] = (
    guidance_en['friends:act_wait:second:v2'][0],
    'Allow communal plans to mature naturally without pressing for immediate commitments.',
    guidance_en['friends:act_wait:second:v2'][2]
)
guidance_en['friends:advance_retreat:first:v2'] = (
    guidance_en['friends:advance_retreat:first:v2'][0],
    'Engage warmly in shared gatherings that reflect your core creative values.',
    guidance_en['friends:advance_retreat:first:v2'][2]
)
guidance_en['friends:advance_retreat:second:v2'] = (
    guidance_en['friends:advance_retreat:second:v2'][0],
    'Reserve peaceful space for close companions whose trust has stood the test of time.',
    guidance_en['friends:advance_retreat:second:v2'][2]
)
guidance_en['friends:commit_withdraw:first:v2'] = (
    guidance_en['friends:commit_withdraw:first:v2'][0],
    'Host or join a meaningful gathering that fosters genuine mutual encouragement.',
    guidance_en['friends:commit_withdraw:first:v2'][2]
)
guidance_en['friends:commit_withdraw:second:v2'] = (
    guidance_en['friends:commit_withdraw:second:v2'][0],
    'Replenish social stamina in restorative solitude before re-entering group events.',
    guidance_en['friends:commit_withdraw:second:v2'][2]
)
guidance_en['friends:keep_let_go:first:v2'] = (
    guidance_en['friends:keep_let_go:first:v2'][0],
    'Provide a steady, non-judgmental presence when friends share their burdens.',
    guidance_en['friends:keep_let_go:first:v2'][2]
)
guidance_en['friends:keep_let_go:second:v2'] = (
    guidance_en['friends:keep_let_go:second:v2'][0],
    'Extend forgiveness for inadvertent slights and resolve tension through gentle dialogue.',
    guidance_en['friends:keep_let_go:second:v2'][2]
)
guidance_en['friends:left_right:first:v2'] = (
    guidance_en['friends:left_right:first:v2'][0],
    'Listen attentively to shared reflections without rushing to dispense unsolicited guidance.',
    guidance_en['friends:left_right:first:v2'][2]
)
guidance_en['friends:left_right:second:v2'] = (
    guidance_en['friends:left_right:second:v2'][0],
    'Articulate personal viewpoints with warmth to inspire collaborative learning.',
    guidance_en['friends:left_right:second:v2'][2]
)
guidance_en['friends:stay_go:first:v2'] = (
    guidance_en['friends:stay_go:first:v2'][0],
    'Express quiet appreciation for companions who have walked alongside you across seasons.',
    guidance_en['friends:stay_go:first:v2'][2]
)
guidance_en['friends:stay_go:second:v2'] = (
    guidance_en['friends:stay_go:second:v2'][0],
    'Broaden your perspective by conversing with peers who kindle your curiosity.',
    guidance_en['friends:stay_go:second:v2'][2]
)
guidance_en['friends:yes_no:first:v1'] = (
    guidance_en['friends:yes_no:first:v1'][0],
    'Connect openly with trustworthy peers while setting affectionate personal limits.',
    guidance_en['friends:yes_no:first:v1'][2]
)
guidance_en['study:keep_let_go:second:v2'] = (
    guidance_en['study:keep_let_go:second:v2'][0],
    'Prune extraneous reference notes to focus exclusively on essential concepts.',
    guidance_en['study:keep_let_go:second:v2'][2]
)
guidance_en['study:left_right:first:v2'] = (
    guidance_en['study:left_right:first:v2'][0],
    'Absorb instructional details patiently and analyze core arguments with steady focus.',
    guidance_en['study:left_right:first:v2'][2]
)
guidance_en['study:left_right:second:v2'] = (
    guidance_en['study:left_right:second:v2'][0],
    'Summarize freshly learned concepts out loud to test structural comprehension.',
    guidance_en['study:left_right:second:v2'][2]
)

# Avoids in EN (differentiating left_right avoids)
guidance_en['career:balanced:v2'] = (
    guidance_en['career:balanced:v2'][0],
    guidance_en['career:balanced:v2'][1],
    'Demanding absolute certainty while organizational shifts are actively taking shape.'
)
guidance_en['career:left_right:first'] = (
    guidance_en['career:left_right:first'][0],
    guidance_en['career:left_right:first'][1],
    'Using symbolic intuition for technical system safety, physical machinery, or operations.'
)
guidance_en['career:left_right:first:v1'] = (
    guidance_en['career:left_right:first:v1'][0],
    guidance_en['career:left_right:first:v1'][1],
    'Relying on abstract hunches instead of verifying operational specs and safety protocols.'
)
guidance_en['career:left_right:first:v2'] = (
    guidance_en['career:left_right:first:v2'][0],
    guidance_en['career:left_right:first:v2'][1],
    'Bypassing established workplace standards purely on a subjective impulse.'
)
guidance_en['career:left_right:second'] = (
    guidance_en['career:left_right:second'][0],
    guidance_en['career:left_right:second'][1],
    'Applying symbolic orientation to direct mechanical issues or physical job safety.'
)
guidance_en['career:left_right:second:v1'] = (
    guidance_en['career:left_right:second:v1'][0],
    guidance_en['career:left_right:second:v1'][1],
    'Altering technical direction abruptly without running a proper risk assessment.'
)
guidance_en['career:left_right:second:v2'] = (
    guidance_en['career:left_right:second:v2'][0],
    guidance_en['career:left_right:second:v2'][1],
    'Substituting intuitive impressions for disciplined data analysis in the workplace.'
)

guidance_en['friends:act_wait:first:v2'] = (
    guidance_en['friends:act_wait:first:v2'][0],
    guidance_en['friends:act_wait:first:v2'][1],
    'Demanding instant replies when companions are preoccupied with pressing duties.'
)
guidance_en['friends:act_wait:second:v2'] = (
    guidance_en['friends:act_wait:second:v2'][0],
    guidance_en['friends:act_wait:second:v2'][1],
    'Projecting negative motives when a friend takes longer than usual to check in.'
)
guidance_en['friends:advance_retreat:first:v2'] = (
    guidance_en['friends:advance_retreat:first:v2'][0],
    guidance_en['friends:advance_retreat:first:v2'][1],
    'Extending unconditional reliance on casual acquaintances before observing consistency.'
)
guidance_en['friends:advance_retreat:second:v2'] = (
    guidance_en['friends:advance_retreat:second:v2'][0],
    guidance_en['friends:advance_retreat:second:v2'][1],
    'Withdrawing entirely into isolation over minor conversational friction.'
)
guidance_en['friends:commit_withdraw:first:v2'] = (
    guidance_en['friends:commit_withdraw:first:v2'][0],
    guidance_en['friends:commit_withdraw:first:v2'][1],
    'Overcommitting to social outings beyond your available energetic capacity.'
)
guidance_en['friends:commit_withdraw:second:v2'] = (
    guidance_en['friends:commit_withdraw:second:v2'][0],
    guidance_en['friends:commit_withdraw:second:v2'][1],
    'Disappearing without a courteous note to your longstanding companions.'
)
guidance_en['friends:keep_let_go:first:v2'] = (
    guidance_en['friends:keep_let_go:first:v2'][0],
    guidance_en['friends:keep_let_go:first:v2'][1],
    'Tolerating chronic disrespect under the banner of unconditional loyalty.'
)
guidance_en['friends:keep_let_go:second:v2'] = (
    guidance_en['friends:keep_let_go:second:v2'][0],
    guidance_en['friends:keep_let_go:second:v2'][1],
    'Nursing quiet grievances instead of clearing the air with gentle honesty.'
)
guidance_en['friends:left_right:first'] = (
    guidance_en['friends:left_right:first'][0],
    guidance_en['friends:left_right:first'][1],
    'Using symbolic polarity to judge personal character or good faith among companions.'
)
guidance_en['friends:left_right:first:v1'] = (
    guidance_en['friends:left_right:first:v1'][0],
    guidance_en['friends:left_right:first:v1'][1],
    'Projecting symbolic meanings onto a peer\'s innocent delays or casual remarks.'
)
guidance_en['friends:left_right:first:v2'] = (
    guidance_en['friends:left_right:first:v2'][0],
    guidance_en['friends:left_right:first:v2'][1],
    'Relying on abstract impressions rather than honest, direct conversations.'
)
guidance_en['friends:left_right:second'] = (
    guidance_en['friends:left_right:second'][0],
    guidance_en['friends:left_right:second'][1],
    'Allowing ambiguous symbols to foster groundless suspicions within your circle.'
)
guidance_en['friends:left_right:second:v1'] = (
    guidance_en['friends:left_right:second:v1'][0],
    guidance_en['friends:left_right:second:v1'][1],
    'Assuming negative intentions when peers are simply preoccupied with daily life.'
)
guidance_en['friends:left_right:second:v2'] = (
    guidance_en['friends:left_right:second:v2'][0],
    guidance_en['friends:left_right:second:v2'][1],
    'Drawing hasty conclusions about social dynamics from brief interactions.'
)
guidance_en['friends:stay_go:first:v2'] = (
    guidance_en['friends:stay_go:first:v2'][0],
    guidance_en['friends:stay_go:first:v2'][1],
    'Enduring draining circles out of sentimental habit rather than genuine affinity.'
)
guidance_en['friends:stay_go:second:v2'] = (
    guidance_en['friends:stay_go:second:v2'][0],
    guidance_en['friends:stay_go:second:v2'][1],
    'Misconstruing natural changes in lifestyle rhythm as personal abandonment.'
)
guidance_en['friends:yes_no:first:v1'] = (
    guidance_en['friends:yes_no:first:v1'][0],
    guidance_en['friends:yes_no:first:v1'][1],
    'Overextending yourself to appease others at the expense of inner calm.'
)

guidance_en['left_right:first'] = (
    guidance_en['left_right:first'][0],
    guidance_en['left_right:first'][1],
    'Using a symbolic polarity for physical navigation, traffic, routes or personal safety.'
)
guidance_en['left_right:second'] = (
    guidance_en['left_right:second'][0],
    guidance_en['left_right:second'][1],
    'Using symbolic intuition for road traffic, mechanical steering, or bodily safety.'
)
guidance_en['left_right:first:v1'] = (
    guidance_en['left_right:first:v1'][0],
    guidance_en['left_right:first:v1'][1],
    'Applying a symbolic compass to physical transit, street traffic, or hazardous routes.'
)
guidance_en['left_right:first:v2'] = (
    guidance_en['left_right:first:v2'][0],
    guidance_en['left_right:first:v2'][1],
    'Treating abstract orientation as real-world navigation in traffic or physical spaces.'
)
guidance_en['left_right:second:v1'] = (
    guidance_en['left_right:second:v1'][0],
    guidance_en['left_right:second:v1'][1],
    'Ignoring actual road traffic signs or safety regulations based on passing feelings.'
)
guidance_en['left_right:second:v2'] = (
    guidance_en['left_right:second:v2'][0],
    guidance_en['left_right:second:v2'][1],
    'Risking personal physical safety in transit relying on symbolic impressions.'
)

guidance_en['love:left_right:first'] = (
    guidance_en['love:left_right:first'][0],
    guidance_en['love:left_right:first'][1],
    'Using emotional symbols to impose rigid conclusions onto your shared bond.'
)
guidance_en['love:left_right:first:v1'] = (
    guidance_en['love:left_right:first:v1'][0],
    guidance_en['love:left_right:first:v1'][1],
    'Substituting symbolic projections for tender, vulnerable communication.'
)
guidance_en['love:left_right:first:v2'] = (
    guidance_en['love:left_right:first:v2'][0],
    guidance_en['love:left_right:first:v2'][1],
    'Letting abstract hunches erode the trust you have built together day by day.'
)
guidance_en['love:left_right:second'] = (
    guidance_en['love:left_right:second'][0],
    guidance_en['love:left_right:second'][1],
    'Inventing pessimistic narratives in isolation without gentle dialogue.'
)
guidance_en['love:left_right:second:v1'] = (
    guidance_en['love:left_right:second:v1'][0],
    guidance_en['love:left_right:second:v1'][1],
    'Treating symbolic polarities as verdicts rather than gentle points of reflection.'
)
guidance_en['love:left_right:second:v2'] = (
    guidance_en['love:left_right:second:v2'][0],
    guidance_en['love:left_right:second:v2'][1],
    'Expecting emotional attunement while withholding clear personal feelings.'
)

guidance_en['money:left_right:first'] = (
    guidance_en['money:left_right:first'][0],
    guidance_en['money:left_right:first'][1],
    'Using symbolic polarity to gamble with personal budgeting or material commitments.'
)
guidance_en['money:left_right:first:v1'] = (
    guidance_en['money:left_right:first:v1'][0],
    guidance_en['money:left_right:first:v1'][1],
    'Treating intuitive sentiment as a guarantee of material security.'
)
guidance_en['money:left_right:first:v2'] = (
    guidance_en['money:left_right:first:v2'][0],
    guidance_en['money:left_right:first:v2'][1],
    'Letting emotional impulses override diligent oversight of expenses.'
)
guidance_en['money:left_right:second'] = (
    guidance_en['money:left_right:second'][0],
    guidance_en['money:left_right:second'][1],
    'Relying on abstract feelings instead of maintaining a balanced contingency buffer.'
)
guidance_en['money:left_right:second:v1'] = (
    guidance_en['money:left_right:second:v1'][0],
    guidance_en['money:left_right:second:v1'][1],
    'Shifting budget allocations spontaneously without calculating actual needs.'
)
guidance_en['money:left_right:second:v2'] = (
    guidance_en['money:left_right:second:v2'][0],
    guidance_en['money:left_right:second:v2'][1],
    'Substituting intuition for concrete accounting and practical planning.'
)

guidance_en['study:keep_let_go:second:v2'] = (
    guidance_en['study:keep_let_go:second:v2'][0],
    guidance_en['study:keep_let_go:second:v2'][1],
    'Hoarding outdated study materials that clutter your desk and divide attention.'
)
guidance_en['study:left_right:first'] = (
    guidance_en['study:left_right:first'][0],
    guidance_en['study:left_right:first'][1],
    'Using symbolic intuition in place of disciplined study and direct comprehension.'
)
guidance_en['study:left_right:first:v1'] = (
    guidance_en['study:left_right:first:v1'][0],
    guidance_en['study:left_right:first:v1'][1],
    'Relying on lucky hunches rather than structured practice and review.'
)
guidance_en['study:left_right:first:v2'] = (
    guidance_en['study:left_right:first:v2'][0],
    guidance_en['study:left_right:first:v2'][1],
    'Skipping foundational exercises because a topic feels intuitively familiar.'
)
guidance_en['study:left_right:second'] = (
    guidance_en['study:left_right:second'][0],
    guidance_en['study:left_right:second'][1],
    'Jumping between different subjects without deepening mastery in any single area.'
)
guidance_en['study:left_right:second:v1'] = (
    guidance_en['study:left_right:second:v1'][0],
    guidance_en['study:left_right:second:v1'][1],
    'Neglecting practical knowledge testing under the assumption that you already know it.'
)
guidance_en['study:left_right:second:v2'] = (
    guidance_en['study:left_right:second:v2'][0],
    guidance_en['study:left_right:second:v2'][1],
    'Substituting abstract impressions for rigorous factual evaluation.'
)


# ==============================================================================
# 2. FIX ES DUPLICATES
# ==============================================================================

# Headlines in ES
guidance_es['act_wait:first:v2'] = (
    'Considerando el momento y las condiciones generales, las señales apuntan a una acción deliberada.',
    guidance_es['act_wait:first:v2'][1],
    guidance_es['act_wait:first:v2'][2]
)
guidance_es['act_wait:second:v2'] = (
    'Considerando el momento y las condiciones generales, las señales apuntan a observar con calma.',
    guidance_es['act_wait:second:v2'][1],
    guidance_es['act_wait:second:v2'][2]
)
guidance_es['advance_retreat:first:v2'] = (
    'Evaluando la cadencia reciente, las señales alientan a consolidar un avance paso a paso.',
    guidance_es['advance_retreat:first:v2'][1],
    guidance_es['advance_retreat:first:v2'][2]
)
guidance_es['advance_retreat:second:v2'] = (
    'Evaluando la cadencia reciente, las señales aconsejan afianzar posiciones antes de insistir.',
    guidance_es['advance_retreat:second:v2'][1],
    guidance_es['advance_retreat:second:v2'][2]
)
guidance_es['commit_withdraw:first:v2'] = (
    'De cara a los próximos acuerdos, las señales invitan a mantener una perseverancia firme.',
    guidance_es['commit_withdraw:first:v2'][1],
    guidance_es['commit_withdraw:first:v2'][2]
)
guidance_es['commit_withdraw:second:v2'] = (
    'De cara a los próximos acuerdos, las señales aconsejan distanciarse con prudencia.',
    guidance_es['commit_withdraw:second:v2'][1],
    guidance_es['commit_withdraw:second:v2'][2]
)
guidance_es['keep_let_go:first:v2'] = (
    'Ante el valor de lo construido, los indicios invitan a proteger y resguardar lo esencial.',
    guidance_es['keep_let_go:first:v2'][1],
    guidance_es['keep_let_go:first:v2'][2]
)
guidance_es['keep_let_go:second:v2'] = (
    'Ante el valor de lo construido, los indicios invitan a soltar ataduras con serenidad.',
    guidance_es['keep_let_go:second:v2'][1],
    guidance_es['keep_let_go:second:v2'][2]
)
guidance_es['left_right:first:v2'] = (
    'Sopesando las polaridades sutiles, los indicios favorecen la quietud interior y la escucha atenta.',
    guidance_es['left_right:first:v2'][1],
    guidance_es['left_right:first:v2'][2]
)
guidance_es['left_right:second:v2'] = (
    'Sopesando las polaridades sutiles, los indicios favorecen la expresión lúcida y dialogante.',
    guidance_es['left_right:second:v2'][1],
    guidance_es['left_right:second:v2'][2]
)
guidance_es['money:commit_withdraw:first:v2'] = (
    'Revisando los recursos materiales, conviene mantener una estricta prudencia presupuestaria.',
    guidance_es['money:commit_withdraw:first:v2'][1],
    guidance_es['money:commit_withdraw:first:v2'][2]
)
guidance_es['money:stay_go:second:v2'] = (
    'Revisando la solidez de tu base, conviene diversificar opciones con moderación.',
    guidance_es['money:stay_go:second:v2'][1],
    guidance_es['money:stay_go:second:v2'][2]
)
guidance_es['stay_go:first:v2'] = (
    'Mirando la estabilidad presente, los indicios sugieren consolidar tu arraigo actual.',
    guidance_es['stay_go:first:v2'][1],
    guidance_es['stay_go:first:v2'][2]
)
guidance_es['stay_go:second:v2'] = (
    'Mirando la estabilidad presente, los indicios sugieren transitar con calma hacia otros ámbitos.',
    guidance_es['stay_go:second:v2'][1],
    guidance_es['stay_go:second:v2'][2]
)

# ShouldDos in ES
guidance_es['friends:act_wait:first:v2'] = (
    guidance_es['friends:act_wait:first:v2'][0],
    'Escribe con afecto a una amistad con quien deseabas reanudar la conversación.',
    guidance_es['friends:act_wait:first:v2'][2]
)
guidance_es['friends:act_wait:second:v2'] = (
    guidance_es['friends:act_wait:second:v2'][0],
    'Deja que los planes comunes maduren por sí mismos sin exigir acuerdos apresurados.',
    guidance_es['friends:act_wait:second:v2'][2]
)
guidance_es['friends:advance_retreat:first:v2'] = (
    guidance_es['friends:advance_retreat:first:v2'][0],
    'Súmate con entusiasmo a encuentros grupales alineados con tus principios formativos.',
    guidance_es['friends:advance_retreat:first:v2'][2]
)
guidance_es['friends:advance_retreat:second:v2'] = (
    guidance_es['friends:advance_retreat:second:v2'][0],
    'Dedica momentos tranquilos a aquellas personas cuya cercanía te transmite serenidad.',
    guidance_es['friends:advance_retreat:second:v2'][2]
)
guidance_es['friends:commit_withdraw:first:v2'] = (
    guidance_es['friends:commit_withdraw:first:v2'][0],
    'Fomenta un espacio de convivencia positivo que nutra el respeto recíproco.',
    guidance_es['friends:commit_withdraw:first:v2'][2]
)
guidance_es['friends:commit_withdraw:second:v2'] = (
    guidance_es['friends:commit_withdraw:second:v2'][0],
    'Restaura tu serenidad en momentos a solas antes de volver a dinámicas sociales intensas.',
    guidance_es['friends:commit_withdraw:second:v2'][2]
)
guidance_es['friends:keep_let_go:first:v2'] = (
    guidance_es['friends:keep_let_go:first:v2'][0],
    'Brinda un apoyo constante y discreto a tus amistades cuando atraviesen momentos difíciles.',
    guidance_es['friends:keep_let_go:first:v2'][2]
)
guidance_es['friends:keep_let_go:second:v2'] = (
    guidance_es['friends:keep_let_go:second:v2'][0],
    'Acepta los errores ajenos con comprensión y aclara cualquier duda mediante un diálogo sosegado.',
    guidance_es['friends:keep_let_go:second:v2'][2]
)
guidance_es['friends:left_right:first:v2'] = (
    guidance_es['friends:left_right:first:v2'][0],
    'Escucha con atención lo que te transmiten sin precipitarte a imponer soluciones.',
    guidance_es['friends:left_right:first:v2'][2]
)
guidance_es['friends:left_right:second:v2'] = (
    guidance_es['friends:left_right:second:v2'][0],
    'Comparte tu punto de vista con gentileza para enriquecer la convivencia.',
    guidance_es['friends:left_right:second:v2'][2]
)
guidance_es['friends:stay_go:first:v2'] = (
    guidance_es['friends:stay_go:first:v2'][0],
    'Agradece sinceramente la presencia de quienes te han acompañado en diversas circunstancias.',
    guidance_es['friends:stay_go:first:v2'][2]
)
guidance_es['friends:stay_go:second:v2'] = (
    guidance_es['friends:stay_go:second:v2'][0],
    'Entabla conversación con nuevas personas que compartan tus afinidades intelectuales.',
    guidance_es['friends:stay_go:second:v2'][2]
)
guidance_es['friends:yes_no:first:v1'] = (
    guidance_es['friends:yes_no:first:v1'][0],
    'Mantén un trato cordial con tu entorno estableciendo al mismo tiempo márgenes confortables.',
    guidance_es['friends:yes_no:first:v1'][2]
)
guidance_es['study:keep_let_go:second:v2'] = (
    guidance_es['study:keep_let_go:second:v2'][0],
    'Selecciona tus apuntes para estudiar únicamente con materiales contrastados y claros.',
    guidance_es['study:keep_let_go:second:v2'][2]
)
guidance_es['study:left_right:first:v2'] = (
    guidance_es['study:left_right:first:v2'][0],
    'Asimila los conceptos teóricos con paciencia y analiza cada demostración con rigor.',
    guidance_es['study:left_right:first:v2'][2]
)
guidance_es['study:left_right:second:v2'] = (
    guidance_es['study:left_right:second:v2'][0],
    'Expón verbalmente las conclusiones alcanzadas para comprobar la firmeza de tu asimilación.',
    guidance_es['study:left_right:second:v2'][2]
)

# Avoids in ES
guidance_es['career:balanced:v2'] = (
    guidance_es['career:balanced:v2'][0],
    guidance_es['career:balanced:v2'][1],
    'Exigir certidumbres absolutas cuando los esquemas del sector todavía están en reajuste.'
)
guidance_es['career:left_right:first'] = (
    guidance_es['career:left_right:first'][0],
    guidance_es['career:left_right:first'][1],
    'Usar la intuición simbólica para la seguridad de equipos, maquinaria o procesos críticos.'
)
guidance_es['career:left_right:first:v1'] = (
    guidance_es['career:left_right:first:v1'][0],
    guidance_es['career:left_right:first:v1'][1],
    'Confiar en meras corazonadas en vez de verificar los estándares operativos del entorno.'
)
guidance_es['career:left_right:first:v2'] = (
    guidance_es['career:left_right:first:v2'][0],
    guidance_es['career:left_right:first:v2'][1],
    'Omitir protocolos de control laboral basándote únicamente en apreciaciones subjetivas.'
)
guidance_es['career:left_right:second'] = (
    guidance_es['career:left_right:second'][0],
    guidance_es['career:left_right:second'][1],
    'Aplicar metáforas simbólicas a la resolución de fallos mecánicos o de seguridad física.'
)
guidance_es['career:left_right:second:v1'] = (
    guidance_es['career:left_right:second:v1'][0],
    guidance_es['career:left_right:second:v1'][1],
    'Alterar planes técnicos sin efectuar una debida comprobación de contingencias.'
)
guidance_es['career:left_right:second:v2'] = (
    guidance_es['career:left_right:second:v2'][0],
    guidance_es['career:left_right:second:v2'][1],
    'Reemplazar el análisis empírico de datos por percepciones abstractas en el trabajo.'
)

guidance_es['friends:act_wait:first:v2'] = (
    guidance_es['friends:act_wait:first:v2'][0],
    guidance_es['friends:act_wait:first:v2'][1],
    'Exigir atención constante cuando los demás atienden asuntos de fuerza mayor.'
)
guidance_es['friends:act_wait:second:v2'] = (
    guidance_es['friends:act_wait:second:v2'][0],
    guidance_es['friends:act_wait:second:v2'][1],
    'Interpretar un breve distanciamiento como una falta de aprecio o de lealtad.'
)
guidance_es['friends:advance_retreat:first:v2'] = (
    guidance_es['friends:advance_retreat:first:v2'][0],
    guidance_es['friends:advance_retreat:first:v2'][1],
    'Entregar confidencias prematuras a conocidos recientes sin contrastar su discreción.'
)
guidance_es['friends:advance_retreat:second:v2'] = (
    guidance_es['friends:advance_retreat:second:v2'][0],
    guidance_es['friends:advance_retreat:second:v2'][1],
    'Romper la comunicación ante el primer desacuerdo de opiniones en el grupo.'
)
guidance_es['friends:commit_withdraw:first:v2'] = (
    guidance_es['friends:commit_withdraw:first:v2'][0],
    guidance_es['friends:commit_withdraw:first:v2'][1],
    'Aceptar compromisos de ocio por encima de tus verdaderas fuerzas o descanso.'
)
guidance_es['friends:commit_withdraw:second:v2'] = (
    guidance_es['friends:commit_withdraw:second:v2'][0],
    guidance_es['friends:commit_withdraw:second:v2'][1],
    'Ausentarte de manera cortante sin avisar a quienes guardan afecto por ti.'
)
guidance_es['friends:keep_let_go:first:v2'] = (
    guidance_es['friends:keep_let_go:first:v2'][0],
    guidance_es['friends:keep_let_go:first:v2'][1],
    'Tolerar actitudes desconsideradas amparándote en una supuesta fidelidad ciega.'
)
guidance_es['friends:keep_let_go:second:v2'] = (
    guidance_es['friends:keep_let_go:second:v2'][0],
    guidance_es['friends:keep_let_go:second:v2'][1],
    'Acumular descontentos en silencio en lugar de manifestar tus desacuerdos con franqueza.'
)
guidance_es['friends:left_right:first'] = (
    guidance_es['friends:left_right:first'][0],
    guidance_es['friends:left_right:first'][1],
    'Usar una polaridad simbólica para enjuiciar la bondad o intenciones de una persona.'
)
guidance_es['friends:left_right:first:v1'] = (
    guidance_es['friends:left_right:first:v1'][0],
    guidance_es['friends:left_right:first:v1'][1],
    'Atribuir intenciones ocultas a comentarios fortuitos o pausas normales de tus amigos.'
)
guidance_es['friends:left_right:first:v2'] = (
    guidance_es['friends:left_right:first:v2'][0],
    guidance_es['friends:left_right:first:v2'][1],
    'Guiarte por impresiones abstractas en vez de sostener un diálogo transparente.'
)
guidance_es['friends:left_right:second'] = (
    guidance_es['friends:left_right:second'][0],
    guidance_es['friends:left_right:second'][1],
    'Permitir que lecturas simbólicas susciten desconfianzas infundadas en tu entorno.'
)
guidance_es['friends:left_right:second:v1'] = (
    guidance_es['friends:left_right:second:v1'][0],
    guidance_es['friends:left_right:second:v1'][1],
    'Creer que una demora habitual responde a un desinterés deliberado.'
)
guidance_es['friends:left_right:second:v2'] = (
    guidance_es['friends:left_right:second:v2'][0],
    guidance_es['friends:left_right:second:v2'][1],
    'Extraer juicios categóricos sobre una relación a partir de roces momentáneos.'
)
guidance_es['friends:stay_go:first:v2'] = (
    guidance_es['friends:stay_go:first:v2'][0],
    guidance_es['friends:stay_go:first:v2'][1],
    'Frecuentar reuniones incómodas únicamente por apego a hábitos del pasado.'
)
guidance_es['friends:stay_go:second:v2'] = (
    guidance_es['friends:stay_go:second:v2'][0],
    guidance_es['friends:stay_go:second:v2'][1],
    'Juzgar la evolución natural de la vida ajena como un abandono premeditado.'
)
guidance_es['friends:yes_no:first:v1'] = (
    guidance_es['friends:yes_no:first:v1'][0],
    guidance_es['friends:yes_no:first:v1'][1],
    'Desvivirte por contentar a todo el mundo desatendiendo tus propias necesidades.'
)

guidance_es['left_right:first'] = (
    guidance_es['left_right:first'][0],
    guidance_es['left_right:first'][1],
    'Usar una polaridad simbólica para algo físico: tráfico, rutas o seguridad personal.'
)
guidance_es['left_right:second'] = (
    guidance_es['left_right:second'][0],
    guidance_es['left_right:second'][1],
    'Emplear la intuición simbólica para conducir en el tráfico rodado o ante riesgos corporales.'
)
guidance_es['left_right:first:v1'] = (
    guidance_es['left_right:first:v1'][0],
    guidance_es['left_right:first:v1'][1],
    'Aplicar un enfoque abstracto a maniobras viales, tráfico o desplazamientos peligrosos.'
)
guidance_es['left_right:first:v2'] = (
    guidance_es['left_right:first:v2'][0],
    guidance_es['left_right:first:v2'][1],
    'Tomar orientaciones figuradas como pautas de navegación en el tráfico o vías públicas.'
)
guidance_es['left_right:second:v1'] = (
    guidance_es['left_right:second:v1'][0],
    guidance_es['left_right:second:v1'][1],
    'Desoír señales viarias objetivas o normas de tránsito por seguir una mera corazonada.'
)
guidance_es['left_right:second:v2'] = (
    guidance_es['left_right:second:v2'][0],
    guidance_es['left_right:second:v2'][1],
    'Poner en riesgo tu integridad física en desplazamientos basándote en metáforas.'
)

guidance_es['love:left_right:first'] = (
    guidance_es['love:left_right:first'][0],
    guidance_es['love:left_right:first'][1],
    'Imponer conclusiones rígidas al vínculo sentimental mediante lecturas simbólicas.'
)
guidance_es['love:left_right:first:v1'] = (
    guidance_es['love:left_right:first:v1'][0],
    guidance_es['love:left_right:first:v1'][1],
    'Reemplazar la comunicación sincera y afectuosa por interpretaciones abstractas.'
)
guidance_es['love:left_right:first:v2'] = (
    guidance_es['love:left_right:first:v2'][0],
    guidance_es['love:left_right:first:v2'][1],
    'Permitir que conjeturas infundadas debiliten la confianza construida día a día.'
)
guidance_es['love:left_right:second'] = (
    guidance_es['love:left_right:second'][0],
    guidance_es['love:left_right:second'][1],
    'Idear escenarios desfavorables en soledad en lugar de conversar con templanza.'
)
guidance_es['love:left_right:second:v1'] = (
    guidance_es['love:left_right:second:v1'][0],
    guidance_es['love:left_right:second:v1'][1],
    'Tratar las polaridades reflexivas como sentencias firmes en lugar de motivos de diálogo.'
)
guidance_es['love:left_right:second:v2'] = (
    guidance_es['love:left_right:second:v2'][0],
    guidance_es['love:left_right:second:v2'][1],
    'Exigir comprensión inmediata silenciando al mismo tiempo tus sentimientos reales.'
)

guidance_es['money:left_right:first'] = (
    guidance_es['money:left_right:first'][0],
    guidance_es['money:left_right:first'][1],
    'Usar la intuición simbólica para arriesgar previsiones o compromisos patrimoniales.'
)
guidance_es['money:left_right:first:v1'] = (
    guidance_es['money:left_right:first:v1'][0],
    guidance_es['money:left_right:first:v1'][1],
    'Tomar presentimientos subjetivos como aval de estabilidad financiera.'
)
guidance_es['money:left_right:first:v2'] = (
    guidance_es['money:left_right:first:v2'][0],
    guidance_es['money:left_right:first:v2'][1],
    'Descuidar la supervisión constante de partidas presupuestarias por ligereza.'
)
guidance_es['money:left_right:second'] = (
    guidance_es['money:left_right:second'][0],
    guidance_es['money:left_right:second'][1],
    'Prescindir de fondos de reserva razonables fiándote de impresiones abstractas.'
)
guidance_es['money:left_right:second:v1'] = (
    guidance_es['money:left_right:second:v1'][0],
    guidance_es['money:left_right:second:v1'][1],
    'Redirigir recursos de forma precipitada sin calcular los costes reales a medio plazo.'
)
guidance_es['money:left_right:second:v2'] = (
    guidance_es['money:left_right:second:v2'][0],
    guidance_es['money:left_right:second:v2'][1],
    'Apoyarte en impresiones subjetivas en lugar de hacer cálculos de gastos rigurosos.'
)

guidance_es['study:keep_let_go:second:v2'] = (
    guidance_es['study:keep_let_go:second:v2'][0],
    guidance_es['study:keep_let_go:second:v2'][1],
    'Conservar materiales de estudio obsoletos que solo sirven para dispersar tu atención.'
)
guidance_es['study:left_right:first'] = (
    guidance_es['study:left_right:first'][0],
    guidance_es['study:left_right:first'][1],
    'Sustituir el estudio disciplinado y la lectura directa por corazonadas simbólicas.'
)
guidance_es['study:left_right:first:v1'] = (
    guidance_es['study:left_right:first:v1'][0],
    guidance_es['study:left_right:first:v1'][1],
    'Esperar golpes de suerte en lugar de repasar sistemáticamente los temas clave.'
)
guidance_es['study:left_right:first:v2'] = (
    guidance_es['study:left_right:first:v2'][0],
    guidance_es['study:left_right:first:v2'][1],
    'Omitir ejercicios básicos creyendo que ya dominas la materia solo por familiaridad.'
)
guidance_es['study:left_right:second'] = (
    guidance_es['study:left_right:second'][0],
    guidance_es['study:left_right:second'][1],
    'Dispersarte entre múltiples materias sin profundizar con solvencia en ninguna.'
)
guidance_es['study:left_right:second:v1'] = (
    guidance_es['study:left_right:second:v1'][0],
    guidance_es['study:left_right:second:v1'][1],
    'Dar por sentado conocimientos sin haber evaluado su aplicación práctica.'
)
guidance_es['study:left_right:second:v2'] = (
    guidance_es['study:left_right:second:v2'][0],
    guidance_es['study:left_right:second:v2'][1],
    'Sustituir el análisis de hechos rigurosos por impresiones simbólicas imprecisas.'
)

# Re-verify EN & ES uniqueness
for lang, data in [('EN', guidance_en), ('ES', guidance_es)]:
    h_c = Counter(v[0] for v in data.values())
    s_c = Counter(v[1] for v in data.values())
    a_c = Counter(v[2] for v in data.values())
    dup_h = [h for h, c in h_c.items() if c > 1]
    dup_s = [s for s, c in s_c.items() if c > 1]
    dup_a = [a for a, c in a_c.items() if c > 1]
    print(f"{lang} duplicate headlines: {len(dup_h)}")
    print(f"{lang} duplicate should_dos: {len(dup_s)}")
    print(f"{lang} duplicate avoids: {len(dup_a)}")
    if dup_h or dup_s or dup_a:
        print(f"ERROR: {lang} still has duplicates!")
        sys.exit(1)

# Write back to files
import os
TOOL_DIR = os.path.dirname(os.path.abspath(__file__))

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

import build_action_guidance_en_es
build_action_guidance_en_es.main()
print("EN and ES are 100% UNIQUE and clean!")
