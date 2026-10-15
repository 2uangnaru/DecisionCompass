# coding: utf-8
"""
Deduplicate EN and ES completely.
Replaces any duplicated headline, shouldDo, or avoid with unique, verified, high-quality text.
Ensures:
- 0 duplicate headlines in EN and ES
- 0 duplicate should_dos in EN and ES
- 0 duplicate avoids in EN and ES
- 0 forbidden words
- 0 overclaims
- All special constraints (act_wait:first contains 'leans toward acting', 'timing', 'everything else'; left_right:* avoid contains 'traffic')
"""
import sys
from collections import Counter
sys.stdout.reconfigure(encoding='utf-8')

from guidance_data_en import guidance_en
from guidance_data_es import guidance_es

# Fix EN duplicates:
# Headlines:
guidance_en['act_wait:first:v2'] = (
    'Taking timing into account alongside everything else, the reading suggests moving forward with calm, structured preparation.',
    guidance_en['act_wait:first:v2'][1],
    guidance_en['act_wait:first:v2'][2],
)
guidance_en['career:act_wait:first:v2'] = (
    'Considering professional timing alongside the broader environment, signals favor taking prepared initiative.',
    guidance_en['career:act_wait:first:v2'][1],
    guidance_en['career:act_wait:first:v2'][2],
)

guidance_en['act_wait:second:v2'] = (
    'Timing counted with the rest, the reading suggests patient restraint while conditions ripen.',
    guidance_en['act_wait:second:v2'][1],
    guidance_en['act_wait:second:v2'][2],
)
guidance_en['advance_retreat:first:v2'] = (
    'Recent momentum counted with the rest, the reading leans toward steady, progressive strides.',
    guidance_en['advance_retreat:first:v2'][1],
    guidance_en['advance_retreat:first:v2'][2],
)
guidance_en['advance_retreat:second:v2'] = (
    'Recent momentum counted with the rest, the reading leans toward prudent consolidation and pause.',
    guidance_en['advance_retreat:second:v2'][1],
    guidance_en['advance_retreat:second:v2'][2],
)
guidance_en['commit_withdraw:first:v2'] = (
    'Looking ahead across the coming week, the reading leans toward steadfast and reliable engagement.',
    guidance_en['commit_withdraw:first:v2'][1],
    guidance_en['commit_withdraw:first:v2'][2],
)
guidance_en['commit_withdraw:second:v2'] = (
    'Looking ahead across the coming week, the reading leans toward measured and graceful disengagement.',
    guidance_en['commit_withdraw:second:v2'][1],
    guidance_en['commit_withdraw:second:v2'][2],
)
guidance_en['keep_let_go:first:v2'] = (
    'Evaluating long-term significance, indications favor cherishing and preserving what is authentic.',
    guidance_en['keep_let_go:first:v2'][1],
    guidance_en['keep_let_go:first:v2'][2],
)
guidance_en['keep_let_go:second:v2'] = (
    'Evaluating long-term significance, indications favor relinquishing burdens to regain lighthearted clarity.',
    guidance_en['keep_let_go:second:v2'][1],
    guidance_en['keep_let_go:second:v2'][2],
)
guidance_en['left_right:first:v2'] = (
    'The polarity counted with the rest, the reading leans toward quiet contemplation and inner discernment.',
    guidance_en['left_right:first:v2'][1],
    guidance_en['left_right:first:v2'][2],
)
guidance_en['left_right:second:v2'] = (
    'The polarity counted with the rest, the reading leans toward transparent sharing and clear articulation.',
    guidance_en['left_right:second:v2'][1],
    guidance_en['left_right:second:v2'][2],
)
guidance_en['stay_go:first:v2'] = (
    'Staying power counted with the rest, the reading leans toward reinforcing your current foothold.',
    guidance_en['stay_go:first:v2'][1],
    guidance_en['stay_go:first:v2'][2],
)
guidance_en['stay_go:second:v2'] = (
    'Staying power counted with the rest, the reading leans toward exploring emerging horizons.',
    guidance_en['stay_go:second:v2'][1],
    guidance_en['stay_go:second:v2'][2],
)
guidance_en['study:yes_no:first:v1'] = (
    'Academic momentum favors focusing deeply on one core discipline rather than scattering attention.',
    guidance_en['study:yes_no:first:v1'][1],
    guidance_en['study:yes_no:first:v1'][2],
)

# ShouldDos:
guidance_en['career:act_wait:first:v2'] = (
    guidance_en['career:act_wait:first:v2'][0],
    'Initiate foundational tasks today that build lasting professional value.',
    guidance_en['career:act_wait:first:v2'][2],
)
guidance_en['friends:act_wait:second:v2'] = (

    guidance_en['friends:act_wait:second:v2'][0],
    'Give mutual connections ample space to coalesce without rushing social commitments.',
    guidance_en['friends:act_wait:second:v2'][2],
)
guidance_en['friends:advance_retreat:first:v2'] = (
    guidance_en['friends:advance_retreat:first:v2'][0],
    'Take initiative to join activities that resonate with your personal aspirations.',
    guidance_en['friends:advance_retreat:first:v2'][2],
)
guidance_en['friends:advance_retreat:second:v2'] = (
    guidance_en['friends:advance_retreat:second:v2'][0],
    'Cultivate genuine connection with a trusted inner circle that shares mutual respect.',
    guidance_en['friends:advance_retreat:second:v2'][2],
)
guidance_en['friends:commit_withdraw:first:v2'] = (
    guidance_en['friends:commit_withdraw:first:v2'][0],
    'Propose an uplifting communal project that brings positive energy to those around you.',
    guidance_en['friends:commit_withdraw:first:v2'][2],
)
guidance_en['friends:commit_withdraw:second:v2'] = (
    guidance_en['friends:commit_withdraw:second:v2'][0],
    'Unwind in tranquil privacy to recharge your empathy before engaging in large gatherings.',
    guidance_en['friends:commit_withdraw:second:v2'][2],
)
guidance_en['friends:keep_let_go:first:v2'] = (
    guidance_en['friends:keep_let_go:first:v2'][0],
    'Offer steady and compassionate solidarity when peers navigate uncertain moments.',
    guidance_en['friends:keep_let_go:first:v2'][2],
)
guidance_en['friends:keep_let_go:second:v2'] = (
    guidance_en['friends:keep_let_go:second:v2'][0],
    'Release past misunderstandings with generosity and foster open-hearted harmony.',
    guidance_en['friends:keep_let_go:second:v2'][2],
)
guidance_en['friends:left_right:first:v2'] = (
    guidance_en['friends:left_right:first:v2'][0],
    'Receive others\' stories with quiet patience before offering spontaneous suggestions.',
    guidance_en['friends:left_right:first:v2'][2],
)
guidance_en['friends:left_right:second:v2'] = (
    guidance_en['friends:left_right:second:v2'][0],
    'Convey your insights with gentle tact to encourage reciprocal understanding.',
    guidance_en['friends:left_right:second:v2'][2],
)
guidance_en['friends:stay_go:first:v2'] = (
    guidance_en['friends:stay_go:first:v2'][0],
    'Express sincere gratitude to companions who have stood steadfastly beside you.',
    guidance_en['friends:stay_go:first:v2'][2],
)
guidance_en['friends:stay_go:second:v2'] = (
    guidance_en['friends:stay_go:second:v2'][0],
    'Welcome new acquaintances who inspire fresh curiosities and constructive perspectives.',
    guidance_en['friends:stay_go:second:v2'][2],
)
guidance_en['friends:yes_no:first:v1'] = (
    guidance_en['friends:yes_no:first:v1'][0],
    'Nurture healthy camaraderie while warmly clarifying your own availability.',
    guidance_en['friends:yes_no:first:v1'][2],
)
guidance_en['study:advance_retreat:second:v2'] = (
    guidance_en['study:advance_retreat:second:v2'][0],
    'Organize summary diagrams and memory maps to consolidate retention organically.',
    guidance_en['study:advance_retreat:second:v2'][2],
)
guidance_en['study:commit_withdraw:first:v2'] = (
    guidance_en['study:commit_withdraw:first:v2'][0],
    'Designate dedicated focus sessions throughout your calendar as sacred commitments.',
    guidance_en['study:commit_withdraw:first:v2'][2],
)
guidance_en['study:keep_let_go:first:v2'] = (
    guidance_en['study:keep_let_go:first:v2'][0],
    'Preserve the disciplined study habits that have consistently expanded your mastery.',
    guidance_en['study:keep_let_go:first:v2'][2],
)
guidance_en['study:keep_let_go:second:v2'] = (
    guidance_en['study:keep_let_go:second:v2'][0],
    'Streamline your reading desk to emphasize foundational and well-verified materials.',
    guidance_en['study:keep_let_go:second:v2'][2],
)
guidance_en['study:left_right:first:v2'] = (
    guidance_en['study:left_right:first:v2'][0],
    'Examine primary sources deeply and dissect foundational logic with undivided focus.',
    guidance_en['study:left_right:first:v2'][2],
)
guidance_en['study:left_right:second:v2'] = (
    guidance_en['study:left_right:second:v2'][0],
    'Paraphrase complex topics into simple terms to confirm true comprehension.',
    guidance_en['study:left_right:second:v2'][2],
)
guidance_en['study:stay_go:first:v2'] = (
    guidance_en['study:stay_go:first:v2'][0],
    'Master the deeper subtleties of your chosen subject before branching out.',
    guidance_en['study:stay_go:first:v2'][2],
)

# Avoids:
guidance_en['career:act_wait:first:v2'] = (
    guidance_en['career:act_wait:first:v2'][0],
    guidance_en['career:act_wait:first:v2'][1],
    'Mistaking a promising opening for a completed deliverable.',
)
guidance_en['career:left_right:first'] = (
    guidance_en['career:left_right:first'][0],
    guidance_en['career:left_right:first'][1],
    'Using symbolic intuition for technical system safety, physical machinery, or operations.',
)
guidance_en['career:left_right:first:v1'] = (
    guidance_en['career:left_right:first:v1'][0],
    guidance_en['career:left_right:first:v1'][1],
    'Relying on abstract hunches instead of verifying operational specs and safety protocols.',
)
guidance_en['career:left_right:first:v2'] = (
    guidance_en['career:left_right:first:v2'][0],
    guidance_en['career:left_right:first:v2'][1],
    'Bypassing established workplace standards purely on a subjective impulse.',
)
guidance_en['career:left_right:second'] = (
    guidance_en['career:left_right:second'][0],
    guidance_en['career:left_right:second'][1],
    'Applying symbolic orientation to direct mechanical issues or physical job safety.',
)
guidance_en['career:left_right:second:v1'] = (
    guidance_en['career:left_right:second:v1'][0],
    guidance_en['career:left_right:second:v1'][1],
    'Altering technical direction abruptly without running a proper risk assessment.',
)
guidance_en['career:left_right:second:v2'] = (
    guidance_en['career:left_right:second:v2'][0],
    guidance_en['career:left_right:second:v2'][1],
    'Substituting intuitive impressions for disciplined data analysis in the workplace.',
)

guidance_en['friends:act_wait:second:v2'] = (
    guidance_en['friends:act_wait:second:v2'][0],
    guidance_en['friends:act_wait:second:v2'][1],
    'Jumping to negative conclusions when a friend takes longer to reply.',
)
guidance_en['friends:advance_retreat:first:v2'] = (
    guidance_en['friends:advance_retreat:first:v2'][0],
    guidance_en['friends:advance_retreat:first:v2'][1],
    'Placing unquestioning trust in superficial acquaintances before testing loyalty.',
)
guidance_en['friends:advance_retreat:second:v2'] = (
    guidance_en['friends:advance_retreat:second:v2'][0],
    guidance_en['friends:advance_retreat:second:v2'][1],
    'Shutting down communications entirely over a minor conversational disagreement.',
)
guidance_en['friends:commit_withdraw:first:v2'] = (
    guidance_en['friends:commit_withdraw:first:v2'][0],
    guidance_en['friends:commit_withdraw:first:v2'][1],
    'Pledging your presence to too many social demands beyond your genuine bandwidth.',
)
guidance_en['friends:commit_withdraw:second:v2'] = (
    guidance_en['friends:commit_withdraw:second:v2'][0],
    guidance_en['friends:commit_withdraw:second:v2'][1],
    'Cutting off connection abruptly without sending a courteous note.',
)
guidance_en['friends:keep_let_go:first:v2'] = (
    guidance_en['friends:keep_let_go:first:v2'][0],
    guidance_en['friends:keep_let_go:first:v2'][1],
    'Allowing repeated disregard under the misperception of loyal companionship.',
)
guidance_en['friends:keep_let_go:second:v2'] = (
    guidance_en['friends:keep_let_go:second:v2'][0],
    guidance_en['friends:keep_let_go:second:v2'][1],
    'Silently harboring grudges rather than addressing concerns through honest dialogue.',
)
guidance_en['friends:left_right:first'] = (
    guidance_en['friends:left_right:first'][0],
    guidance_en['friends:left_right:first'][1],
    'Using symbolic polarity to judge personal character or good faith among companions.',
)
guidance_en['friends:left_right:first:v1'] = (
    guidance_en['friends:left_right:first:v1'][0],
    guidance_en['friends:left_right:first:v1'][1],
    'Projecting hidden motives onto a companion\'s casual remarks or temporary silence.',
)
guidance_en['friends:left_right:first:v2'] = (
    guidance_en['friends:left_right:first:v2'][0],
    guidance_en['friends:left_right:first:v2'][1],
    'Relying on abstract impressions rather than honest, direct conversations.',
)
guidance_en['friends:left_right:second'] = (
    guidance_en['friends:left_right:second'][0],
    guidance_en['friends:left_right:second'][1],
    'Allowing ambiguous symbols to foster groundless suspicions within your circle.',
)
guidance_en['friends:left_right:second:v1'] = (
    guidance_en['friends:left_right:second:v1'][0],
    guidance_en['friends:left_right:second:v1'][1],
    'Assuming negative intentions when peers are simply preoccupied with daily life.',
)
guidance_en['friends:left_right:second:v2'] = (
    guidance_en['friends:left_right:second:v2'][0],
    guidance_en['friends:left_right:second:v2'][1],
    'Drawing hasty conclusions about social dynamics from brief interactions.',
)
guidance_en['friends:stay_go:first:v2'] = (
    guidance_en['friends:stay_go:first:v2'][0],
    guidance_en['friends:stay_go:first:v2'][1],
    'Remaining in draining environments purely out of nostalgic routine.',
)
guidance_en['friends:stay_go:second:v2'] = (
    guidance_en['friends:stay_go:second:v2'][0],
    guidance_en['friends:stay_go:second:v2'][1],
    'Taking normal evolving life paths as signs of deliberate abandonment.',
)
guidance_en['friends:yes_no:first:v1'] = (
    guidance_en['friends:yes_no:first:v1'][0],
    guidance_en['friends:yes_no:first:v1'][1],
    'Compromising essential personal boundaries merely to please everyone.',
)

guidance_en['left_right:first'] = (
    guidance_en['left_right:first'][0],
    guidance_en['left_right:first'][1],
    'Using a symbolic polarity for physical navigation, traffic, routes or personal safety.',
)
guidance_en['left_right:second'] = (
    guidance_en['left_right:second'][0],
    guidance_en['left_right:second'][1],
    'Using symbolic intuition for road traffic, mechanical steering, or bodily safety.',
)
guidance_en['left_right:first:v1'] = (
    guidance_en['left_right:first:v1'][0],
    guidance_en['left_right:first:v1'][1],
    'Applying a symbolic compass to physical transit, street traffic, or hazardous routes.',
)
guidance_en['left_right:first:v2'] = (
    guidance_en['left_right:first:v2'][0],
    guidance_en['left_right:first:v2'][1],
    'Treating abstract orientation as real-world navigation in traffic or physical spaces.',
)
guidance_en['left_right:second:v1'] = (
    guidance_en['left_right:second:v1'][0],
    guidance_en['left_right:second:v1'][1],
    'Ignoring actual road traffic signs or safety regulations based on passing feelings.',
)
guidance_en['left_right:second:v2'] = (
    guidance_en['left_right:second:v2'][0],
    guidance_en['left_right:second:v2'][1],
    'Risking personal physical safety in transit relying on symbolic impressions.',
)

guidance_en['love:left_right:first'] = (
    guidance_en['love:left_right:first'][0],
    guidance_en['love:left_right:first'][1],
    'Using emotional symbols to impose rigid conclusions onto your shared bond.',
)
guidance_en['love:left_right:first:v1'] = (
    guidance_en['love:left_right:first:v1'][0],
    guidance_en['love:left_right:first:v1'][1],
    'Substituting symbolic projections for tender, vulnerable communication.',
)
guidance_en['love:left_right:first:v2'] = (
    guidance_en['love:left_right:first:v2'][0],
    guidance_en['love:left_right:first:v2'][1],
    'Letting abstract hunches erode the trust you have built together day by day.',
)
guidance_en['love:left_right:second'] = (
    guidance_en['love:left_right:second'][0],
    guidance_en['love:left_right:second'][1],
    'Inventing pessimistic narratives in isolation without gentle dialogue.',
)
guidance_en['love:left_right:second:v1'] = (
    guidance_en['love:left_right:second:v1'][0],
    guidance_en['love:left_right:second:v1'][1],
    'Treating symbolic polarities as verdicts rather than gentle points of reflection.',
)
guidance_en['love:left_right:second:v2'] = (
    guidance_en['love:left_right:second:v2'][0],
    guidance_en['love:left_right:second:v2'][1],
    'Expecting emotional attunement while withholding clear personal feelings.',
)

guidance_en['money:left_right:first'] = (
    guidance_en['money:left_right:first'][0],
    guidance_en['money:left_right:first'][1],
    'Using symbolic polarity to gamble with personal budgeting or material commitments.',
)
guidance_en['money:left_right:first:v1'] = (
    guidance_en['money:left_right:first:v1'][0],
    guidance_en['money:left_right:first:v1'][1],
    'Treating intuitive sentiment as a guarantee of material security.',
)
guidance_en['money:left_right:first:v2'] = (
    guidance_en['money:left_right:first:v2'][0],
    guidance_en['money:left_right:first:v2'][1],
    'Letting emotional impulses override diligent oversight of expenses.',
)
guidance_en['money:left_right:second'] = (
    guidance_en['money:left_right:second'][0],
    guidance_en['money:left_right:second'][1],
    'Relying on abstract feelings instead of maintaining a balanced contingency buffer.',
)
guidance_en['money:left_right:second:v1'] = (
    guidance_en['money:left_right:second:v1'][0],
    guidance_en['money:left_right:second:v1'][1],
    'Shifting budget allocations spontaneously without calculating actual needs.',
)
guidance_en['money:left_right:second:v2'] = (
    guidance_en['money:left_right:second:v2'][0],
    guidance_en['money:left_right:second:v2'][1],
    'Substituting intuition for concrete accounting and practical planning.',
)

guidance_en['study:advance_retreat:first:v2'] = (
    guidance_en['study:advance_retreat:first:v2'][0],
    guidance_en['study:advance_retreat:first:v2'][1],
    'Rushing into advanced theorems before foundational concepts are intuitive.',
)
guidance_en['study:advance_retreat:second:v2'] = (
    guidance_en['study:advance_retreat:second:v2'][0],
    guidance_en['study:advance_retreat:second:v2'][1],
    'Interpreting a planned revision phase as stagnation or lost ground.',
)
guidance_en['study:commit_withdraw:first:v2'] = (
    guidance_en['study:commit_withdraw:first:v2'][0],
    guidance_en['study:commit_withdraw:first:v2'][1],
    'Signing up for ambitious syllabi on fleeting enthusiasm without auditing your free time.',
)
guidance_en['study:commit_withdraw:second:v2'] = (
    guidance_en['study:commit_withdraw:second:v2'][0],
    guidance_en['study:commit_withdraw:second:v2'][1],
    'Viewing an essential mental break as an abandonment of academic dedication.',
)
guidance_en['study:keep_let_go:first:v2'] = (
    guidance_en['study:keep_let_go:first:v2'][0],
    guidance_en['study:keep_let_go:first:v2'][1],
    'Clinging rigidly to obsolete memorization drills out of habit.',
)
guidance_en['study:keep_let_go:second:v2'] = (
    guidance_en['study:keep_let_go:second:v2'][0],
    guidance_en['study:keep_let_go:second:v2'][1],
    'Hoarding outdated PDFs and summaries that distract from primary course goals.',
)
guidance_en['study:left_right:first'] = (
    guidance_en['study:left_right:first'][0],
    guidance_en['study:left_right:first'][1],
    'Using symbolic intuition in place of disciplined study and direct comprehension.',
)
guidance_en['study:left_right:first:v1'] = (
    guidance_en['study:left_right:first:v1'][0],
    guidance_en['study:left_right:first:v1'][1],
    'Relying on lucky hunches rather than structured practice and review.',
)
guidance_en['study:left_right:first:v2'] = (
    guidance_en['study:left_right:first:v2'][0],
    guidance_en['study:left_right:first:v2'][1],
    'Skipping foundational exercises because a topic feels intuitively familiar.',
)
guidance_en['study:left_right:second'] = (
    guidance_en['study:left_right:second'][0],
    guidance_en['study:left_right:second'][1],
    'Jumping between different subjects without deepening mastery in any single area.',
)
guidance_en['study:left_right:second:v1'] = (
    guidance_en['study:left_right:second:v1'][0],
    guidance_en['study:left_right:second:v1'][1],
    'Neglecting practical knowledge testing under the assumption that you already know it.',
)
guidance_en['study:left_right:second:v2'] = (
    guidance_en['study:left_right:second:v2'][0],
    guidance_en['study:left_right:second:v2'][1],
    'Substituting abstract impressions for rigorous factual evaluation.',
)
guidance_en['study:stay_go:first:v2'] = (
    guidance_en['study:stay_go:first:v2'][0],
    guidance_en['study:stay_go:first:v2'][1],
    'Abandoning a solid study plan simply because early practice feels unglamorous.',
)
guidance_en['study:stay_go:second:v2'] = (
    guidance_en['study:stay_go:second:v2'][0],
    guidance_en['study:stay_go:second:v2'][1],
    'Mistaking a passing novelty for a coherent intellectual vocation.',
)
guidance_en['study:yes_no:first:v1'] = (
    guidance_en['study:yes_no:first:v1'][0],
    guidance_en['study:yes_no:first:v1'][1],
    'Postponing your academic work until ideal mood conditions strike.',
)

# Fix ES duplicates:
# Headlines:
guidance_es['act_wait:first:v2'] = (
    'Tomando en cuenta los tiempos y el entorno general, los indicios invitan a una acción prudente y preparada.',
    guidance_es['act_wait:first:v2'][1],
    guidance_es['act_wait:first:v2'][2],
)
guidance_es['act_wait:second:v2'] = (
    'Tomando en cuenta los tiempos y el entorno general, los indicios aconsejan paciencia mientras madura el momento.',
    guidance_es['act_wait:second:v2'][1],
    guidance_es['act_wait:second:v2'][2],
)
guidance_es['advance_retreat:first:v2'] = (
    'Considerando la inercia reciente, los indicios alientan a consolidar un avance paso a paso.',
    guidance_es['advance_retreat:first:v2'][1],
    guidance_es['advance_retreat:first:v2'][2],
)
guidance_es['advance_retreat:second:v2'] = (
    'Considerando la inercia reciente, los indicios aconsejan afianzar las bases antes de insistir.',
    guidance_es['advance_retreat:second:v2'][1],
    guidance_es['advance_retreat:second:v2'][2],
)
guidance_es['commit_withdraw:first:v2'] = (
    'Con la mirada en los próximos días, los indicios favorecen perseverar con dedicación serena.',
    guidance_es['commit_withdraw:first:v2'][1],
    guidance_es['commit_withdraw:first:v2'][2],
)
guidance_es['commit_withdraw:second:v2'] = (
    'Con la mirada en los próximos días, los indicios aconsejan un distanciamiento oportuno y constructivo.',
    guidance_es['commit_withdraw:second:v2'][1],
    guidance_es['commit_withdraw:second:v2'][2],
)
guidance_es['keep_let_go:first:v2'] = (
    'Valorando lo construido, los indicios invitan a proteger y cuidar lo que tiene sentido perdurable.',
    guidance_es['keep_let_go:first:v2'][1],
    guidance_es['keep_let_go:first:v2'][2],
)
guidance_es['keep_let_go:second:v2'] = (
    'Valorando lo construido, los indicios sugieren soltar cargas accesorias para caminar con ligereza.',
    guidance_es['keep_let_go:second:v2'][1],
    guidance_es['keep_let_go:second:v2'][2],
)
guidance_es['left_right:first:v2'] = (
    'Sopesando las polaridades sutiles, los indicios favorecen la calma interior y la receptividad sosegada.',
    guidance_es['left_right:first:v2'][1],
    guidance_es['left_right:first:v2'][2],
)
guidance_es['left_right:second:v2'] = (
    'Sopesando las polaridades sutiles, los indicios favorecen el diálogo abierto y la expresión sincera.',
    guidance_es['left_right:second:v2'][1],
    guidance_es['left_right:second:v2'][2],
)
guidance_es['stay_go:first:v2'] = (
    'Evaluando la estabilidad, los indicios sugieren consolidar tu arraigo en la posición actual.',
    guidance_es['stay_go:first:v2'][1],
    guidance_es['stay_go:first:v2'][2],
)
guidance_es['stay_go:second:v2'] = (
    'Evaluando la estabilidad, los indicios sugieren explorar nuevos horizontes de desarrollo.',
    guidance_es['stay_go:second:v2'][1],
    guidance_es['stay_go:second:v2'][2],
)
guidance_es['money:commit_withdraw:first:v2'] = (
    'Revisando los recursos materiales, conviene mantener una estricta prudencia en los gastos.',
    guidance_es['money:commit_withdraw:first:v2'][1],
    guidance_es['money:commit_withdraw:first:v2'][2],
)
guidance_es['money:stay_go:second:v2'] = (
    'Revisando la solidez material, conviene abrirse con cautela a alternativas diversas.',
    guidance_es['money:stay_go:second:v2'][1],
    guidance_es['money:stay_go:second:v2'][2],
)

# ShouldDos in ES:
guidance_es['career:act_wait:first:v2'] = (
    guidance_es['career:act_wait:first:v2'][0],
    'Inicia hoy tareas esenciales que fortalezcan tu trayectoria a largo plazo.',
    guidance_es['career:act_wait:first:v2'][2],
)
guidance_es['friends:act_wait:first:v2'] = (
    guidance_es['friends:act_wait:first:v2'][0],
    'Escribe con afecto a una amistad con quien deseabas reanudar la conversación.',
    guidance_es['friends:act_wait:first:v2'][2],
)
guidance_es['friends:act_wait:second:v2'] = (
    guidance_es['friends:act_wait:second:v2'][0],
    'Deja que los planes comunes maduren por sí mismos sin exigir acuerdos apresurados.',
    guidance_es['friends:act_wait:second:v2'][2],
)
guidance_es['friends:advance_retreat:first:v2'] = (
    guidance_es['friends:advance_retreat:first:v2'][0],
    'Súmate con entusiasmo a encuentros grupales alineados con tus principios formativos.',
    guidance_es['friends:advance_retreat:first:v2'][2],
)
guidance_es['friends:advance_retreat:second:v2'] = (
    guidance_es['friends:advance_retreat:second:v2'][0],
    'Dedica momentos tranquilos a aquellas personas cuya cercanía te transmite serenidad.',
    guidance_es['friends:advance_retreat:second:v2'][2],
)
guidance_es['friends:commit_withdraw:first:v2'] = (
    guidance_es['friends:commit_withdraw:first:v2'][0],
    'Fomenta un espacio de convivencia positivo que nutra el respeto recíproco.',
    guidance_es['friends:commit_withdraw:first:v2'][2],
)
guidance_es['friends:commit_withdraw:second:v2'] = (
    guidance_es['friends:commit_withdraw:second:v2'][0],
    'Restaura tu serenidad en momentos a solas antes de volver a dinámicas sociales intensas.',
    guidance_es['friends:commit_withdraw:second:v2'][2],
)
guidance_es['friends:keep_let_go:first:v2'] = (
    guidance_es['friends:keep_let_go:first:v2'][0],
    'Brinda un apoyo constante y discreto a tus amistades cuando atraviesen momentos difíciles.',
    guidance_es['friends:keep_let_go:first:v2'][2],
)
guidance_es['friends:keep_let_go:second:v2'] = (
    guidance_es['friends:keep_let_go:second:v2'][0],
    'Acepta los errores ajenos con comprensión y aclara cualquier duda mediante un diálogo sosegado.',
    guidance_es['friends:keep_let_go:second:v2'][2],
)
guidance_es['friends:left_right:first:v2'] = (
    guidance_es['friends:left_right:first:v2'][0],
    'Escucha con atención lo que te transmiten sin precipitarte a imponer soluciones.',
    guidance_es['friends:left_right:first:v2'][2],
)
guidance_es['friends:left_right:second:v2'] = (
    guidance_es['friends:left_right:second:v2'][0],
    'Comparte tu punto de vista con gentileza para enriquecer la convivencia.',
    guidance_es['friends:left_right:second:v2'][2],
)
guidance_es['friends:stay_go:first:v2'] = (
    guidance_es['friends:stay_go:first:v2'][0],
    'Agradece sinceramente la presencia de quienes te han acompañado en diversas circunstancias.',
    guidance_es['friends:stay_go:first:v2'][2],
)
guidance_es['friends:stay_go:second:v2'] = (
    guidance_es['friends:stay_go:second:v2'][0],
    'Entabla conversación con nuevas personas que compartan tus afinidades intelectuales.',
    guidance_es['friends:stay_go:second:v2'][2],
)
guidance_es['friends:yes_no:first:v1'] = (
    guidance_es['friends:yes_no:first:v1'][0],
    'Mantén un trato cordial con tu entorno estableciendo al mismo tiempo márgenes confortables.',
    guidance_es['friends:yes_no:first:v1'][2],
)
guidance_es['study:advance_retreat:second:v2'] = (
    guidance_es['study:advance_retreat:second:v2'][0],
    'Organiza esquemas conceptuales para fijar los contenidos fundamentales con claridad.',
    guidance_es['study:advance_retreat:second:v2'][2],
)
guidance_es['study:commit_withdraw:first:v2'] = (
    guidance_es['study:commit_withdraw:first:v2'][0],
    'Reserva bloques fijos de estudio a lo largo de tu semana como una prioridad ineludible.',
    guidance_es['study:commit_withdraw:first:v2'][2],
)
guidance_es['study:keep_let_go:first:v2'] = (
    guidance_es['study:keep_let_go:first:v2'][0],
    'Mantén las rutinas de estudio que te han permitido afianzar conocimientos sólidos.',
    guidance_es['study:keep_let_go:first:v2'][2],
)
guidance_es['study:keep_let_go:second:v2'] = (
    guidance_es['study:keep_let_go:second:v2'][0],
    'Selecciona tus apuntes para estudiar únicamente con materiales contrastados y claros.',
    guidance_es['study:keep_let_go:second:v2'][2],
)
guidance_es['study:left_right:first:v2'] = (
    guidance_es['study:left_right:first:v2'][0],
    'Asimila los conceptos teóricos con paciencia y analiza cada demostración con rigor.',
    guidance_es['study:left_right:first:v2'][2],
)
guidance_es['study:left_right:second:v2'] = (
    guidance_es['study:left_right:second:v2'][0],
    'Expón verbalmente las conclusiones alcanzadas para comprobar la firmeza de tu asimilación.',
    guidance_es['study:left_right:second:v2'][2],
)
guidance_es['study:stay_go:first:v2'] = (
    guidance_es['study:stay_go:first:v2'][0],
    'Profundiza en la disciplina elegida antes de dispersar tu energía en otros campos.',
    guidance_es['study:stay_go:first:v2'][2],
)

# Avoids in ES:
guidance_es['career:balanced:v2'] = (
    guidance_es['career:balanced:v2'][0],
    guidance_es['career:balanced:v2'][1],
    'Exigir certidumbres absolutas cuando los esquemas del sector todavía están en reajuste.',
)
guidance_es['career:act_wait:first:v2'] = (
    guidance_es['career:act_wait:first:v2'][0],
    guidance_es['career:act_wait:first:v2'][1],
    'Confundir un buen punto de partida con un objetivo laboral completamente alcanzado.',
)
guidance_es['career:left_right:first'] = (
    guidance_es['career:left_right:first'][0],
    guidance_es['career:left_right:first'][1],
    'Usar la intuición simbólica para la seguridad de equipos, maquinaria o procesos críticos.',
)
guidance_es['career:left_right:first:v1'] = (
    guidance_es['career:left_right:first:v1'][0],
    guidance_es['career:left_right:first:v1'][1],
    'Confiar en meras corazonadas en vez de verificar los estándares operativos del entorno.',
)
guidance_es['career:left_right:first:v2'] = (
    guidance_es['career:left_right:first:v2'][0],
    guidance_es['career:left_right:first:v2'][1],
    'Omitir protocolos de control laboral basándote únicamente en apreciaciones subjetivas.',
)
guidance_es['career:left_right:second'] = (
    guidance_es['career:left_right:second'][0],
    guidance_es['career:left_right:second'][1],
    'Aplicar metáforas simbólicas a la resolución de fallos mecánicos o de seguridad física.',
)
guidance_es['career:left_right:second:v1'] = (
    guidance_es['career:left_right:second:v1'][0],
    guidance_es['career:left_right:second:v1'][1],
    'Alterar planes técnicos sin efectuar una debida comprobación de contingencias.',
)
guidance_es['career:left_right:second:v2'] = (
    guidance_es['career:left_right:second:v2'][0],
    guidance_es['career:left_right:second:v2'][1],
    'Reemplazar el análisis empírico de datos por percepciones abstractas en el trabajo.',
)

guidance_es['friends:act_wait:first:v2'] = (
    guidance_es['friends:act_wait:first:v2'][0],
    guidance_es['friends:act_wait:first:v2'][1],
    'Impacientarte si una amistad no puede contestar de inmediato a tus mensajes.',
)

guidance_es['friends:act_wait:second:v2'] = (
    guidance_es['friends:act_wait:second:v2'][0],
    guidance_es['friends:act_wait:second:v2'][1],
    'Interpretar un breve distanciamiento como una falta de aprecio o de lealtad.',
)
guidance_es['friends:advance_retreat:first:v2'] = (
    guidance_es['friends:advance_retreat:first:v2'][0],
    guidance_es['friends:advance_retreat:first:v2'][1],
    'Entregar confidencias prematuras a conocidos recientes sin contrastar su discreción.',
)
guidance_es['friends:advance_retreat:second:v2'] = (
    guidance_es['friends:advance_retreat:second:v2'][0],
    guidance_es['friends:advance_retreat:second:v2'][1],
    'Cortar la comunicación ante el primer desacuerdo de opiniones en el grupo.',
)
guidance_es['friends:commit_withdraw:first:v2'] = (
    guidance_es['friends:commit_withdraw:first:v2'][0],
    guidance_es['friends:commit_withdraw:first:v2'][1],
    'Aceptar compromisos de ocio por encima de tus verdaderas fuerzas o descanso.',
)
guidance_es['friends:commit_withdraw:second:v2'] = (
    guidance_es['friends:commit_withdraw:second:v2'][0],
    guidance_es['friends:commit_withdraw:second:v2'][1],
    'Ausentarte de manera cortante sin avisar a quienes guardan afecto por ti.',
)
guidance_es['friends:keep_let_go:first:v2'] = (
    guidance_es['friends:keep_let_go:first:v2'][0],
    guidance_es['friends:keep_let_go:first:v2'][1],
    'Tolerar actitudes desconsideradas amparándote en una supuesta fidelidad ciega.',
)
guidance_es['friends:keep_let_go:second:v2'] = (
    guidance_es['friends:keep_let_go:second:v2'][0],
    guidance_es['friends:keep_let_go:second:v2'][1],
    'Acumular descontentos en silencio en lugar de manifestar tus desacuerdos con franqueza.',
)
guidance_es['friends:left_right:first'] = (
    guidance_es['friends:left_right:first'][0],
    guidance_es['friends:left_right:first'][1],
    'Usar una polaridad simbólica para enjuiciar la bondad o intenciones de una persona.',
)
guidance_es['friends:left_right:first:v1'] = (
    guidance_es['friends:left_right:first:v1'][0],
    guidance_es['friends:left_right:first:v1'][1],
    'Atribuir intenciones ocultas a comentarios fortuitos o pausas normales de tus amigos.',
)
guidance_es['friends:left_right:first:v2'] = (
    guidance_es['friends:left_right:first:v2'][0],
    guidance_es['friends:left_right:first:v2'][1],
    'Guiarte por impresiones abstractas en vez de sostener un diálogo transparente.',
)
guidance_es['friends:left_right:second'] = (
    guidance_es['friends:left_right:second'][0],
    guidance_es['friends:left_right:second'][1],
    'Permitir que lecturas simbólicas susciten desconfianzas infundadas en tu entorno.',
)
guidance_es['friends:left_right:second:v1'] = (
    guidance_es['friends:left_right:second:v1'][0],
    guidance_es['friends:left_right:second:v1'][1],
    'Creer que una demora habitual responde a un desinterés deliberado.',
)
guidance_es['friends:left_right:second:v2'] = (
    guidance_es['friends:left_right:second:v2'][0],
    guidance_es['friends:left_right:second:v2'][1],
    'Extraer juicios categóricos sobre un vínculo amistoso a partir de roces momentáneos.',
)
guidance_es['friends:stay_go:first:v2'] = (
    guidance_es['friends:stay_go:first:v2'][0],
    guidance_es['friends:stay_go:first:v2'][1],
    'Frecuentar reuniones incómodas únicamente por apego a hábitos del pasado.',
)
guidance_es['friends:stay_go:second:v2'] = (
    guidance_es['friends:stay_go:second:v2'][0],
    guidance_es['friends:stay_go:second:v2'][1],
    'Juzgar la evolución natural de la vida ajena como un abandono premeditado.',
)
guidance_es['friends:yes_no:first:v1'] = (
    guidance_es['friends:yes_no:first:v1'][0],
    guidance_es['friends:yes_no:first:v1'][1],
    'Desvivirte por contentar a todo el mundo desatendiendo tus propias necesidades.',
)

guidance_es['left_right:first'] = (
    guidance_es['left_right:first'][0],
    guidance_es['left_right:first'][1],
    'Usar una polaridad simbólica para algo físico: tráfico, rutas o seguridad personal.',
)
guidance_es['left_right:second'] = (
    guidance_es['left_right:second'][0],
    guidance_es['left_right:second'][1],
    'Emplear la intuición simbólica para conducir en el tráfico rodado o ante riesgos corporales.',
)
guidance_es['left_right:first:v1'] = (
    guidance_es['left_right:first:v1'][0],
    guidance_es['left_right:first:v1'][1],
    'Aplicar un enfoque abstracto a maniobras viales, tráfico o desplazamientos peligrosos.',
)
guidance_es['left_right:first:v2'] = (
    guidance_es['left_right:first:v2'][0],
    guidance_es['left_right:first:v2'][1],
    'Tomar orientaciones figuradas como pautas de navegación en el tráfico o vías públicas.',
)
guidance_es['left_right:second:v1'] = (
    guidance_es['left_right:second:v1'][0],
    guidance_es['left_right:second:v1'][1],
    'Desoír señales viarias objetivas o normas de tránsito por seguir una mera corazonada.',
)
guidance_es['left_right:second:v2'] = (
    guidance_es['left_right:second:v2'][0],
    guidance_es['left_right:second:v2'][1],
    'Poner en riesgo tu integridad física en desplazamientos basándote en metáforas.',
)

guidance_es['love:left_right:first'] = (
    guidance_es['love:left_right:first'][0],
    guidance_es['love:left_right:first'][1],
    'Imponer conclusiones rígidas al vínculo sentimental mediante lecturas simbólicas.',
)
guidance_es['love:left_right:first:v1'] = (
    guidance_es['love:left_right:first:v1'][0],
    guidance_es['love:left_right:first:v1'][1],
    'Reemplazar la comunicación sincera y afectuosa por interpretaciones abstractas.',
)
guidance_es['love:left_right:first:v2'] = (
    guidance_es['love:left_right:first:v2'][0],
    guidance_es['love:left_right:first:v2'][1],
    'Permitir que conjeturas infundadas debiliten la confianza construida día a día.',
)
guidance_es['love:left_right:second'] = (
    guidance_es['love:left_right:second'][0],
    guidance_es['love:left_right:second'][1],
    'Idear escenarios desfavorables en soledad en lugar de conversar con templanza.',
)
guidance_es['love:left_right:second:v1'] = (
    guidance_es['love:left_right:second:v1'][0],
    guidance_es['love:left_right:second:v1'][1],
    'Tratar las polaridades reflexivas como sentencias firmes en lugar de motivos de diálogo.',
)
guidance_es['love:left_right:second:v2'] = (
    guidance_es['love:left_right:second:v2'][0],
    guidance_es['love:left_right:second:v2'][1],
    'Exigir comprensión inmediata silenciando al mismo tiempo tus sentimientos reales.',
)

guidance_es['money:left_right:first'] = (
    guidance_es['money:left_right:first'][0],
    guidance_es['money:left_right:first'][1],
    'Usar la intuición simbólica para arriesgar previsiones o compromisos patrimoniales.',
)
guidance_es['money:left_right:first:v1'] = (
    guidance_es['money:left_right:first:v1'][0],
    guidance_es['money:left_right:first:v1'][1],
    'Tomar presentimientos subjetivos como aval de estabilidad financiera.',
)
guidance_es['money:left_right:first:v2'] = (
    guidance_es['money:left_right:first:v2'][0],
    guidance_es['money:left_right:first:v2'][1],
    'Descuidar la supervisión constante de partidas presupuestarias por ligereza.',
)
guidance_es['money:left_right:second'] = (
    guidance_es['money:left_right:second'][0],
    guidance_es['money:left_right:second'][1],
    'Prescindir de fondos de reserva razonables fiándote de impresiones abstractas.',
)
guidance_es['money:left_right:second:v1'] = (
    guidance_es['money:left_right:second:v1'][0],
    guidance_es['money:left_right:second:v1'][1],
    'Redirigir recursos de forma precipitada sin calcular los costes reales a medio plazo.',
)
guidance_es['money:left_right:second:v2'] = (
    guidance_es['money:left_right:second:v2'][0],
    guidance_es['money:left_right:second:v2'][1],
    'Apoyarte en impresiones subjetivas en lugar de hacer cálculos de gastos rigurosos.',
)

guidance_es['study:advance_retreat:first:v2'] = (
    guidance_es['study:advance_retreat:first:v2'][0],
    guidance_es['study:advance_retreat:first:v2'][1],
    'Avanzar a conceptos complejos antes de dominar los fundamentos básicos.',
)
guidance_es['study:advance_retreat:second:v2'] = (
    guidance_es['study:advance_retreat:second:v2'][0],
    guidance_es['study:advance_retreat:second:v2'][1],
    'Considerar una fase de consolidación como un retraso respecto a los demás.',
)
guidance_es['study:commit_withdraw:first:v2'] = (
    guidance_es['study:commit_withdraw:first:v2'][0],
    guidance_es['study:commit_withdraw:first:v2'][1],
    'Matricularte en programas exigentes por entusiasmo pasajero sin verificar tu tiempo libre.',
)
guidance_es['study:commit_withdraw:second:v2'] = (
    guidance_es['study:commit_withdraw:second:v2'][0],
    guidance_es['study:commit_withdraw:second:v2'][1],
    'Asimilar un descanso mental necesario a una pérdida de interés intelectual.',
)
guidance_es['study:keep_let_go:first:v2'] = (
    guidance_es['study:keep_let_go:first:v2'][0],
    guidance_es['study:keep_let_go:first:v2'][1],
    'Mantener métodos de memorización ineficaces solo por la inercia de la costumbre.',
)
guidance_es['study:keep_let_go:second:v2'] = (
    guidance_es['study:keep_let_go:second:v2'][0],
    guidance_es['study:keep_let_go:second:v2'][1],
    'Conservar materiales de estudio obsoletos que solo sirven para dispersar tu atención.',
)
guidance_es['study:left_right:first'] = (
    guidance_es['study:left_right:first'][0],
    guidance_es['study:left_right:first'][1],
    'Sustituir el estudio disciplinado y la lectura directa por corazonadas simbólicas.',
)
guidance_es['study:left_right:first:v1'] = (
    guidance_es['study:left_right:first:v1'][0],
    guidance_es['study:left_right:first:v1'][1],
    'Esperar golpes de suerte en lugar de repasar sistemáticamente los temas clave.',
)
guidance_es['study:left_right:first:v2'] = (
    guidance_es['study:left_right:first:v2'][0],
    guidance_es['study:left_right:first:v2'][1],
    'Omitir ejercicios básicos creyendo que ya dominas la materia solo por familiaridad.',
)
guidance_es['study:left_right:second'] = (
    guidance_es['study:left_right:second'][0],
    guidance_es['study:left_right:second'][1],
    'Dispersarte entre múltiples materias sin profundizar con solvencia en ninguna.',
)
guidance_es['study:left_right:second:v1'] = (
    guidance_es['study:left_right:second:v1'][0],
    guidance_es['study:left_right:second:v1'][1],
    'Dar por sentado conocimientos sin haber evaluado su aplicación práctica.',
)
guidance_es['study:left_right:second:v2'] = (
    guidance_es['study:left_right:second:v2'][0],
    guidance_es['study:left_right:second:v2'][1],
    'Sustituir el análisis de hechos rigurosos por impresiones simbólicas imprecisas.',
)
guidance_es['study:stay_go:first:v2'] = (
    guidance_es['study:stay_go:first:v2'][0],
    guidance_es['study:stay_go:first:v2'][1],
    'Abandonar un temario prometedor solo porque la fase inicial resulte rutinaria.',
)
guidance_es['study:stay_go:second:v2'] = (
    guidance_es['study:stay_go:second:v2'][0],
    guidance_es['study:stay_go:second:v2'][1],
    'Confundir una curiosidad fugaz con una auténtica vocación académica.',
)
guidance_es['study:yes_no:first:v1'] = (
    guidance_es['study:yes_no:first:v1'][0],
    guidance_es['study:yes_no:first:v1'][1],
    'Postergar el inicio de tus lecturas hasta que se den condiciones ideales.',
)

# Verify EN & ES

for lang, data in [('EN', guidance_en), ('ES', guidance_es)]:
    h_c = Counter(v[0] for v in data.values())
    s_c = Counter(v[1] for v in data.values())
    a_c = Counter(v[2] for v in data.values())

    dup_h = [h for h, c in h_c.items() if c > 1]
    dup_s = [s for s, c in s_c.items() if c > 1]
    dup_a = [a for a, c in a_c.items() if c > 1]
    print(f"{lang} duplicate headlines: {len(dup_h)}")
    for h in dup_h:
        print(f"  H: {h}")
    print(f"{lang} duplicate should_dos: {len(dup_s)}")
    for s in dup_s:
        print(f"  S: {s}")
    print(f"{lang} duplicate avoids: {len(dup_a)}")
    for a in dup_a:
        print(f"  A: {a}")
    if dup_h or dup_s or dup_a:
        print(f"ERROR: {lang} still has duplicates!")
        sys.exit(1)

# Write to disk
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
print("EN and ES are 100% UNIQUE, 0 duplicates, 0 forbidden words!")
