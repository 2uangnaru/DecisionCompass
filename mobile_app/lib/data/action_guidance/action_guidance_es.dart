/// Spanish copy for Action Guidance.
///
/// Contains base reflections per decision mode plus context lenses for
/// career, love, finances (money), study, friends, and other.
///
/// Adheres strictly to responsible use:
/// - Never tells the reader to buy, sell, quit, marry, or divorce.
/// - Free from forbidden words: 'invertir', 'dinero', 'sueldo', 'préstamo',
///   'comprar', 'vender', 'relación', 'pareja', 'romper', 'renunciar',
///   'casarte', 'divorcio'.
/// - Avoids overclaims like 'más alineado', 'mejor momento'.
const Map<String, (String, String, String)> actionGuidanceEs =
    <String, (String, String, String)>{
  // ---------------------------------------------------------------------------
  // Base entries (General / Universal)
  // ---------------------------------------------------------------------------
  'balanced': (
    'Hoy las señales no se inclinaron hacia ningún lado.',
    'Anota lo que ya crees, antes de buscar más señales.',
    'Preguntar otra vez en otro modo hasta que la respuesta se parezca a lo que querías.',
  ),
  'yes_no:first': (
    'Hoy las señales se inclinan hacia la apertura más que hacia la resistencia.',
    'Fíjate hacia dónde ya te inclinabas y qué te dice eso.',
    'Usar una inclinación simbólica como permiso para saltarte tu propio juicio.',
  ),
  'yes_no:second': (
    'Hoy las señales se inclinan hacia la resistencia más que hacia la apertura.',
    'Ponle nombre a la duda que ya sientes, con calma, antes de discutir con ella.',
    'Interpretar la resistencia como una condena en vez de como un motivo para mirar otra vez.',
  ),
  'act_wait:first': (
    'Tomando en cuenta los tiempos y todo lo demás, la lectura se inclina por actuar.',
    'Pregúntate qué podrías empezar hoy que siga siendo tuyo mañana.',
    'Confundir una oportunidad con una decisión ya tomada.',
  ),
  'act_wait:second': (
    'Tomando en cuenta los tiempos y todo lo demás, la lectura se inclina por esperar.',
    'Deja que la duda repose y observa si cambia de forma al caer la tarde.',
    'Confundir la paciencia con evitar el asunto, o la prisa con la valentía.',
  ),
  'advance_retreat:first': (
    'Tomando en cuenta el impulso reciente y todo lo demás, la lectura se inclina por avanzar.',
    'Observa qué ha cambiado de verdad desde que empezó la semana.',
    'Dar por hecho que el impulso se mantendrá solo.',
  ),
  'advance_retreat:second': (
    'Tomando en cuenta el impulso reciente y todo lo demás, la lectura se inclina por retroceder.',
    'Pregúntate qué perderías en realidad por mantener tu posición un poco más.',
    'Ver un día tranquilo como un paso atrás.',
  ),
  'stay_go:first': (
    'Tomando en cuenta la firmeza y todo lo demás, la lectura se inclina por mantener tu lugar.',
    'Piensa en lo que realmente te aporta el terreno donde estás.',
    'Confundir la quietud con estar estancado.',
  ),
  'stay_go:second': (
    'Tomando en cuenta la firmeza y todo lo demás, la lectura se inclina por moverte.',
    'Pregúntate qué te llevarías contigo y qué dejarías atrás.',
    'Tratar la inquietud como si fuera un plan.',
  ),
  'keep_let_go:first': (
    'Las señales se inclinan hacia conservar más que hacia soltar.',
    'Mira lo que sostienes y pregúntate si lo elegiste o lo heredaste.',
    'Sostener por costumbre y llamarlo compromiso.',
  ),
  'keep_let_go:second': (
    'Las señales se inclinan hacia soltar más que hacia conservar.',
    'Pregúntate qué tendría espacio para crecer si liberaras tu atención.',
    'Tomar una inclinación simbólica como motivo para decidir por otra persona.',
  ),
  'commit_withdraw:first': (
    'Tomando en cuenta la semana que viene y todo lo demás, la lectura se inclina por comprometerte.',
    'Piensa en semanas y no en horas, a ver si la pregunta se sostiene.',
    'Confundir una semana estable con una garantía.',
  ),
  'commit_withdraw:second': (
    'Tomando en cuenta la semana que viene y todo lo demás, la lectura se inclina por dar un paso atrás.',
    'Pregúntate qué tendría que pasar para que esto se sintiera más firme.',
    'Ver una semana movida como un estado permanente.',
  ),
  'left_right:first': (
    'Tomando en cuenta la polaridad y todo lo demás, la lectura se inclina hacia adentro, receptiva.',
    'Dale espacio a la lectura más tranquila y menos evidente de tu pregunta.',
    'Usar una polaridad simbólica para algo físico: tráfico, rutas o seguridad personal.',
  ),
  'left_right:second': (
    'Tomando en cuenta la polaridad y todo lo demás, la lectura se inclina hacia afuera, expresiva.',
    'Intenta decir aquello a lo que le has estado dando vueltas, al menos para ti.',
    'Usar una polaridad simbólica para algo físico: tráfico, rutas o seguridad personal.',
  ),

  // ---------------------------------------------------------------------------
  // Career (Ámbito laboral / Trabajo)
  // ---------------------------------------------------------------------------
  'career:balanced': (
    'En el ámbito laboral hoy, las señales se mantienen en sobrio equilibrio.',
    'Reúne tus datos y tu postura con serenidad antes de buscar nuevas pautas.',
    'Preguntar reiteradamente para forzar una respuesta que confirme tus deseos.',
  ),
  'career:yes_no:first': (
    'En el trabajo, las señales se inclinan hacia recibir oportunidades con apertura.',
    'Pregúntate si este paso sirve con autenticidad a tus metas profesionales de fondo.',
    'Confundir el entusiasmo pasajero con una estrategia de acción bien calculada.',
  ),
  'career:yes_no:second': (
    'En el trabajo, las señales se inclinan hacia la prudencia y el examen de obstáculos.',
    'Examina las incertidumbres del proyecto antes de apresurar la marcha.',
    'Interpretar un obstáculo temporal como un fracaso en lugar de un ajuste.',
  ),
  'career:act_wait:first': (
    'Tomando en cuenta los tiempos en tu labor, la lectura se inclina por actuar.',
    'Pon en marcha tareas concretas hoy que sigan construyendo valor mañana.',
    'Confundir un buen momento con un proyecto ya terminado.',
  ),
  'career:act_wait:second': (
    'Tomando en cuenta los tiempos en tu labor, la lectura se inclina por esperar.',
    'Dedica tiempo a reunir información y verificar pormenores antes del cierre.',
    'Apresurar el ritmo antes de que las bases técnicas estén verdaderamente firmes.',
  ),
  'career:advance_retreat:first': (
    'Con el impulso profesional reciente, la lectura se inclina por avanzar con decisión.',
    'Aprovecha el progreso logrado para proponer nuevas iniciativas o ampliar alcance.',
    'Asumir que el impulso favorable se prolongará sin dedicación constante.',
  ),
  'career:advance_retreat:second': (
    'Con el impulso profesional reciente, la lectura se inclina por consolidar y observar.',
    'Conserva tu posición actual para auditar métodos y evitar dispersión de esfuerzos.',
    'Ver una pausa de replanteamiento estratégico como un retroceso en tu camino.',
  ),
  'career:stay_go:first': (
    'Con la firmeza en el trabajo, la lectura se inclina por mantener tu posición.',
    'Valora la experiencia acumulada y la seguridad que tu rol actual te brinda.',
    'Confundir la estabilidad profesional con una falta de proyección.',
  ),
  'career:stay_go:second': (
    'Con la firmeza en el trabajo, la lectura se inclina por cambiar de rumbo.',
    'Ten claro qué destrezas quieres llevarte y qué métodos es prudente soltar.',
    'Confundir una inquietud momentánea con una visión vocacional completa.',
  ),
  'career:keep_let_go:first': (
    'En tu trabajo, las señales se inclinan por proteger lo que has construido.',
    'Reafirma los valores medulares de tu labor y mantén la consistencia.',
    'Aferrarte a rutinas desgastadas solo por incomodidad ante lo nuevo.',
  ),
  'career:keep_let_go:second': (
    'En tu trabajo, las señales se inclinan por aligerar cargas secundarias.',
    'Libera tareas de escaso impacto para centrarte en lo verdaderamente prioritario.',
    'Desatender compromisos compartidos sin previa conversación clara.',
  ),
  'career:commit_withdraw:first': (
    'Mirando la semana laboral, la lectura se inclina por un compromiso sostenido.',
    'Proyecta tus planes en meses y trimestres para calibrar su solidez.',
    'Confundir unos días fluidos con una garantía permanente de éxito.',
  ),
  'career:commit_withdraw:second': (
    'Mirando la semana laboral, la lectura se inclina por tomar distancia para reorganizar.',
    'Identifica qué condiciones hacen falta para devolverle firmeza al proyecto.',
    'Interpretar una semana exigente como un indicio de colapso definitivo.',
  ),
  'career:left_right:first': (
    'En el trabajo, la lectura se inclina hacia la escucha atenta y la asimilación.',
    'Da cabida a opiniones críticas y estudia el entorno antes de resolver.',
    'Usar una polaridad simbólica para algo físico: tráfico, rutas o seguridad personal.',
  ),
  'career:left_right:second': (
    'En el trabajo, la lectura se inclina hacia la comunicación clara de ideas.',
    'Expón tus propuestas con franqueza y solidez ante colegas o responsables.',
    'Usar una polaridad simbólica para algo físico: tráfico, rutas o seguridad personal.',
  ),

  // ---------------------------------------------------------------------------
  // Love (Vínculos personales & Afecto)
  // ---------------------------------------------------------------------------
  'love:balanced': (
    'En los vínculos personales hoy, las señales permanecen en serenidad.',
    'Examina tus sentimientos íntimos con franqueza antes de buscar señales externas.',
    'Insistir en buscar respuestas para acallar una inquietud emocional pasajera.',
  ),
  'love:yes_no:first': (
    'En los vínculos personales, las señales se inclinan hacia la apertura y cercanía.',
    'Expresa lo que sientes con sinceridad en lugar de levantar murallas defensivas.',
    'Esperar que los demás adivinen tus emociones sin un diálogo transparente.',
  ),
  'love:yes_no:second': (
    'En los vínculos personales, las señales se inclinan hacia la prudencia y el espacio.',
    'Presta atención a tu propia cautela y concédete un respiro para reflexionar.',
    'Tomar la distancia saludable como un final en lugar de una invitación a la comprensión.',
  ),
  'love:act_wait:first': (
    'Tomando en cuenta los tiempos afectivos, la lectura se inclina por dar el paso.',
    'Muestra consideración genuina y abre un puente de entendimiento sincero.',
    'Exigir una respuesta inmediata cuando la otra persona necesita su tiempo.',
  ),
  'love:act_wait:second': (
    'Tomando en cuenta los tiempos afectivos, la lectura se inclina por la paciencia.',
    'Brinda tiempo y sosiego para que las emociones se asienten de forma natural.',
    'Confundir el silencio evasivo con la comprensión paciente y respetuosa.',
  ),
  'love:advance_retreat:first': (
    'Con la cercanía reciente, la lectura se inclina por afianzar la unión.',
    'Aprecia los momentos de confianza compartida que se han manifestado.',
    'Dar por resueltas cuestiones profundas sin darles el debido cuidado.',
  ),
  'love:advance_retreat:second': (
    'Con la cercanía reciente, la lectura se inclina por moderar el ritmo.',
    'Favorece un espacio de sosiego para que ambos aclaren sus propios sentimientos.',
    'Interpretar un día silencioso como desapego o un retroceso definitivo.',
  ),
  'love:stay_go:first': (
    'Con la firmeza afectiva, la lectura se inclina por valorar la unión existente.',
    'Reconoce la calidez y el trayecto compartido que han sostenido el lazo.',
    'Confundir la tranquilidad cotidiana con desinterés o estancamiento.',
  ),
  'love:stay_go:second': (
    'Con la firmeza afectiva, la lectura se inclina por renovar las dinámicas compartidas.',
    'Incorpora hábitos frescos e iniciativas que aporten nueva vitalidad.',
    'Permitir que un aburrimiento momentáneo motive reacciones desmedidas.',
  ),
  'love:keep_let_go:first': (
    'En los vínculos personales, las señales se inclinan por cultivar lo valioso.',
    'Distingue si tu apego brota de un afecto sincero o de la mera rutina.',
    'Forzar una armonía superficial para eludir conversaciones necesarias.',
  ),
  'love:keep_let_go:second': (
    'En los vínculos personales, las señales se inclinan por soltar expectativas rígidas.',
    'Suelta la pretensión de controlar las respuestas o sentimientos ajenos.',
    'Valerte de señales simbólicas para decidir sobre los sentimientos de otros.',
  ),
  'love:commit_withdraw:first': (
    'Pensando en los días venideros, la lectura se inclina por un cuidado constante.',
    'Piensa en la cercanía a lo largo del tiempo más que en emociones fugaces.',
    'Creer que un periodo armónico exime de seguir cuidando el vínculo.',
  ),
  'love:commit_withdraw:second': (
    'Pensando en los días venideros, la lectura se inclina por tomar un respiro personal.',
    'Atiende tu propio bienestar para ofrecer una presencia más centrada.',
    'Ver un momento de distanciamiento reflexivo como un daño irreparable.',
  ),
  'love:left_right:first': (
    'En los lazos personales, la lectura se inclina hacia la escucha receptiva.',
    'Escucha con plena atención lo que se expresa más allá de las palabras.',
    'Usar una polaridad simbólica para algo físico: tráfico, rutas o seguridad personal.',
  ),
  'love:left_right:second': (
    'En los lazos personales, la lectura se inclina hacia la expresión afectuosa.',
    'Comunica tus deseos y sentimientos con serenidad y valentía.',
    'Usar una polaridad simbólica para algo físico: tráfico, rutas o seguridad personal.',
  ),

  // ---------------------------------------------------------------------------
  // Finances (Finanzas & Recursos)
  // ---------------------------------------------------------------------------
  'money:balanced': (
    'En el plano financiero hoy, las señales guardan un balance sereno.',
    'Toma nota de las reservas existentes y mantén las asignaciones previstas.',
    'Buscar justificaciones simbólicas para solventar gastos repentinos o emocionales.',
  ),
  'money:yes_no:first': (
    'En las finanzas, las señales se inclinan hacia la claridad y la viabilidad.',
    'Verifica que la decisión responda a una necesidad auténtica y meditada.',
    'Asumir compromisos materiales antes de conocer los costos con total transparencia.',
  ),
  'money:yes_no:second': (
    'En las finanzas, las señales se inclinan hacia la cautela y la contención.',
    'Revisa tus fondos de contingencia y da prioridad a la protección de recursos.',
    'Ver la moderación como escasez en vez de como una prudente defensa.',
  ),
  'money:act_wait:first': (
    'Tomando en cuenta los tiempos financieros, la lectura se inclina por actuar.',
    'Ejecuta distribuciones de recursos que ya fueron estudiadas y previstas.',
    'Ampliar presupuestos más allá de lo fijado solo por una sensación favorable.',
  ),
  'money:act_wait:second': (
    'Tomando en cuenta los tiempos financieros, la lectura se inclina por esperar.',
    'Conserva la calma y tómate unos días antes de comprometer fondos mayores.',
    'Apresurarse a destinar recursos por temor a perder una ocasión pasajera.',
  ),
  'money:advance_retreat:first': (
    'Con el impulso financiero reciente, la lectura se inclina por un crecimiento medido.',
    'Aprovecha la estabilidad para consolidar la disciplina en tus previsiones.',
    'Creer que el orden en tus recursos perdurará sin atención metódica.',
  ),
  'money:advance_retreat:second': (
    'Con el impulso financiero reciente, la lectura se inclina por replegar y reforzar.',
    'Recorta salidas accesorias que no aporten valor sustancial a largo plazo.',
    'Considerar la disciplina de gastos como un castigo en lugar de una protección.',
  ),
  'money:stay_go:first': (
    'Con la firmeza financiera, la lectura se inclina por mantener la estructura.',
    'Reconoce la tranquilidad y la solidez que tu método actual te procura.',
    'Confundir la seguridad de tus reservas con un estancamiento de opciones.',
  ),
  'money:stay_go:second': (
    'Con la firmeza financiera, la lectura se inclina por reordenar asignaciones.',
    'Identifica qué partidas conviene reducir para respaldar metas principales.',
    'Hacer alteraciones bruscas por una impaciencia sin fundamento.',
  ),
  'money:keep_let_go:first': (
    'En finanzas, las señales se inclinan por salvaguardar lo acumulado.',
    'Examina con rigor la utilidad y el respaldo de lo que mantienes reservado.',
    'Mantener gastos recurrentes por simple descuido en la revisión de cuentas.',
  ),
  'money:keep_let_go:second': (
    'En finanzas, las señales se inclinan por eliminar fugas innecesarias.',
    'Aprecia el desahogo presupuestario al suprimir consumos superfluos.',
    'Recortar indiscriminadamente en aspectos esenciales para tu bienestar.',
  ),
  'money:commit_withdraw:first': (
    'Para la semana venidera en finanzas, la lectura se inclina por la constancia.',
    'Proyecta tus decisiones materiales en horizontes mensuales o trimestrales.',
    'Interpretar unos días de gasto controlado como excusa para bajar la guardia.',
  ),
  'money:commit_withdraw:second': (
    'Para la semana venidera en finanzas, la lectura se inclina por pausar compromisos.',
    'Establece qué certezas requieres antes de autorizar nuevos desembolsos.',
    'Ver un gasto imprevisto como una catástrofe insalvable.',
  ),
  'money:left_right:first': (
    'En materia financiera, la lectura se inclina por el análisis detallado.',
    'Coteja balances y condiciones formales antes de firmar o resolver.',
    'Usar intuiciones simbólicas para arriesgar recursos esenciales.',
  ),
  'money:left_right:second': (
    'En materia financiera, la lectura se inclina por resolver cuentas con prontitud.',
    'Finiquita trámites o pendientes con determinación y orden.',
    'Usar intuiciones simbólicas para arriesgar recursos esenciales.',
  ),

  // ---------------------------------------------------------------------------
  // Study (Aprendizaje & Superación)
  // ---------------------------------------------------------------------------
  'study:balanced': (
    'En el aprendizaje hoy, las señales sugieren asimilar con tranquilidad.',
    'Repasa fundamentos consolidados antes de abordar materias más complejas.',
    'Pretender abarcar múltiples lecciones cuando la mente necesita pausa.',
  ),
  'study:yes_no:first': (
    'En el estudio, las señales se inclinan hacia absorber nuevos saberes.',
    'Elige la destreza que deseas perfeccionar y concéntrate plenamente en ella.',
    'Abrir demasiados frentes a la vez sin la perseverancia para culminarlos.',
  ),
  'study:yes_no:second': (
    'En el estudio, las señales se inclinan por apuntalar los conocimientos base.',
    'Dedica tiempo a aclarar dudas previas antes de intentar seguir avanzando.',
    'Desanimarte porque la asimilación profunda demande constancia y tiempo.',
  ),
  'study:act_wait:first': (
    'Tomando en cuenta los tiempos de estudio, la lectura se inclina por empezar ya.',
    'Inicia ejercicios concretos a diario para forjar un hábito sólido.',
    'Diseñar temarios grandilocuentes sin sentarte a estudiar en la práctica.',
  ),
  'study:act_wait:second': (
    'Tomando en cuenta los tiempos de estudio, la lectura se inclina por la reflexión.',
    'Concede tiempo a tu entendimiento para digerir los conceptos con madurez.',
    'Confundir la lectura apresurada con una comprensión auténtica y sólida.',
  ),

  // ---------------------------------------------------------------------------
  // Friends (Amistades & Círculo social)
  // ---------------------------------------------------------------------------
  'friends:balanced': (
    'En el círculo social hoy, las señales reflejan una serena tranquilidad.',
    'Disfruta de tus momentos de soledad antes de buscar planes en grupo.',
    'Buscar aceptación forzada cuando en realidad necesitas descanso.',
  ),
  'friends:yes_no:first': (
    'En las amistades, las señales se inclinan hacia la cercanía auténtica.',
    'Dedica tiempo a las amistades que te aportan energía sana y apoyo sincero.',
    'Intentar agradar a todo el mundo a costa de tus propios límites personales.',
  ),
  'friends:yes_no:second': (
    'En las amistades, las señales se inclinan por guardar límites saludables.',
    'Reconoce los encuentros que te agotan y atrévete a declinar amablemente.',
    'Sentir culpa por no poder acudir a todas las invitaciones de amigos.',
  ),

  // ---------------------------------------------------------------------------
  // Other / Situational (Contexto específico)
  // ---------------------------------------------------------------------------
  'other:balanced': (
    'En esta situación hoy, las señales permanecen en neutralidad.',
    'Observa el panorama con objetividad sin anticipar prejuicios previos.',
    'Impacientarte por ver desenlaces inmediatos cuando todo sigue en curso.',
  ),
  'other:yes_no:first': (
    'En este asunto, las señales se inclinan hacia la flexibilidad y adaptación.',
    'Aborda el reto desde un ángulo novedoso que antes no habías considerado.',
    'Aplicar mecánicamente fórmulas antiguas a una coyuntura diferente.',
  ),
  'other:yes_no:second': (
    'En este asunto, las señales se inclinan por la prudencia y mantener terreno.',
    'Sopesa cada aspecto y calcula las consecuencias antes de dar un veredicto.',
    'Resolver deprisa solo para disipar una incertidumbre pasajera.',
  ),
};
