// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'AstraCue';

  @override
  String get analyticsConsentTitle => 'Estadísticas de uso (opcional)';

  @override
  String get analyticsConsentBody =>
      'Permite que Firebase/Google Analytics recopile información de uso de la app y del dispositivo para mejorar AstraCue. No enviamos tu nombre, datos de nacimiento ni cartas. Puedes desactivarlo en Uso responsable.';

  @override
  String get analyticsConsentSaveFailed =>
      'No se pudo guardar esta preferencia. Las estadísticas están desactivadas en esta sesión.';

  @override
  String get continueAction => 'Continuar';

  @override
  String get backAction => 'Volver';

  @override
  String get closeAction => 'Cerrar';

  @override
  String get tryAgain => 'Volver a intentar';

  @override
  String get responsibleUse => 'Uso responsable';

  @override
  String get history => 'Historial';

  @override
  String get onboardingTitle =>
      'Escucha las señales del universo y tu intuición.';

  @override
  String get onboardingLanguageHint =>
      'Toca el icono del globo de arriba para cambiar de idioma.';

  @override
  String get yourProfile => 'TU PERFIL';

  @override
  String get signAfterBirthDate =>
      'TU SIGNO APARECERÁ AL INDICAR TU FECHA DE NACIMIENTO';

  @override
  String get buildPattern => 'Descubre tu propia energía.';

  @override
  String get profileExplainer => 'Define los ciclos utilizados en el análisis.';

  @override
  String get nameField => 'Nombre';

  @override
  String get dateOfBirth => 'Fecha de nacimiento';

  @override
  String get selectBirthDate => 'Selecciona tu fecha de nacimiento';

  @override
  String get birthDateRequired =>
      'Selecciona tu fecha de nacimiento para continuar.';

  @override
  String get birthDay => 'Día';

  @override
  String get birthMonth => 'Mes';

  @override
  String get birthYear => 'Año';

  @override
  String get birthDateScroll => 'Deslizar';

  @override
  String get birthDateType => 'Escribir';

  @override
  String get birthDateInvalid => 'Introduce una fecha válida entre 1900 y hoy.';

  @override
  String get birthTimeUnknown => 'No sé mi hora de nacimiento';

  @override
  String get birthTimeUnknownDetail =>
      'Si no sabes tu hora de nacimiento, el algoritmo usará el horario más cercano a tu personalidad.';

  @override
  String get timeOfBirth => 'Hora de nacimiento';

  @override
  String get countryOfBirth => 'País de nacimiento';

  @override
  String get selectBirthCountry => 'Busca y selecciona un país';

  @override
  String get birthCountryRequired =>
      'Selecciona tu país de nacimiento para continuar.';

  @override
  String get createCompass => 'Crear mi brújula';

  @override
  String get birthPrivacyPrototype =>
      'En este prototipo, tus datos de nacimiento se mantienen privados.';

  @override
  String get homeEyebrow => 'UNA BRÚJULA QUE GUÍA TU CAMINO';

  @override
  String get homeTitle => '¿No sabes qué camino elegir?';

  @override
  String get areaQuestion => '¿Sobre qué tema?';

  @override
  String get findDirection => 'Encuentra tu camino';

  @override
  String get todaySignals => 'SEÑALES DE HOY';

  @override
  String get dailyEnergy => 'Energía de hoy';

  @override
  String get yourColorsToday => 'Colores de hoy:';

  @override
  String get luckyNumberToday => 'Número de hoy:';

  @override
  String get categoryOverall => 'General';

  @override
  String get categoryLove => 'Amor y relaciones';

  @override
  String get categoryCareer => 'Trabajo';

  @override
  String get categoryMoney => 'Finanzas';

  @override
  String get categoryStudy => 'Estudios y crecimiento';

  @override
  String get categoryFriends => 'Amistades';

  @override
  String get categoryOther => 'Otro tema';

  @override
  String get periodQuestion => '¿Para qué momento lo estás considerando?';

  @override
  String get periodNow => 'AHORA';

  @override
  String get periodMorning => 'Mañana';

  @override
  String get periodMidday => 'Mediodía';

  @override
  String get periodAfternoon => 'Tarde';

  @override
  String get periodEvening => 'Noche';

  @override
  String get periodPassed => 'Pasado';

  @override
  String get periodTooLittleTime => 'Pasado';

  @override
  String get periodCheckingTimezone => 'Comprobando la zona horaria';

  @override
  String get periodTimezoneUnknown => 'Zona horaria desconocida';

  @override
  String get timezoneUnavailableNotice =>
      'No se pudo leer tu zona horaria, así que solo está disponible AHORA. Vuelve a intentarlo para elegir un periodo.';

  @override
  String periodHasPassed(String period) {
    return '$period ya pasó. Elige otro momento.';
  }

  @override
  String periodNotEnoughTimeLeft(String period) {
    return 'Hoy ya no queda tiempo suficiente en $period. Elige otro momento.';
  }

  @override
  String get reveal => 'ANALIZAR';

  @override
  String get aligning => 'ALINEANDO';

  @override
  String get tapWhenReady => 'Toca cuando estés listo';

  @override
  String get keepChoiceInMind =>
      'Ten presente la decisión que estás considerando.';

  @override
  String get ritualSafety =>
      'Solo para reflexionar sobre asuntos cotidianos. Nunca para decisiones médicas, de inversión, de préstamos, políticas o que puedan causar daño.';

  @override
  String get loadingLocalMoment => 'LEYENDO TU MOMENTO LOCAL';

  @override
  String get loadingReassurance =>
      'Un momento, por favor: las señales cósmicas se están alineando.';

  @override
  String readingForCategory(String category) {
    return 'Lectura sobre $category';
  }

  @override
  String get yourDirection => 'TU DIRECCIÓN';

  @override
  String get resultBasis =>
      'Basado en la energía y las señales cósmicas para ti en este momento.';

  @override
  String get percentageCaveat =>
      'Los porcentajes muestran una afinidad simbólica, no una probabilidad real.';

  @override
  String get balancedHeading => 'EQUILIBRIO';

  @override
  String get balancedResult => 'EQUILIBRADO';

  @override
  String get balancedExplanation =>
      'Por ahora, ninguna opción predomina. La lectura indica equilibrio, no una respuesta oculta.';

  @override
  String get currentMoment => 'Esta lectura refleja tu momento actual.';

  @override
  String get luckyTimesCaveat =>
      'Cada porcentaje indica una afinidad simbólica con ese horario; no es una probabilidad ni una posibilidad de éxito. Los intervalos se valoran por separado, por lo que no suman 100%.';

  @override
  String get tryAnotherDirection => 'Explorar otra dirección';

  @override
  String get viewHistory => 'Ver en el historial';

  @override
  String get yourReadings => 'Tus lecturas';

  @override
  String get noReadings =>
      'Aún no hay lecturas. Explora tu primera dirección para iniciar tu historial.';

  @override
  String get historySnapshot =>
      'Los resultados se guardan tal como aparecieron; no se vuelven a calcular.';

  @override
  String get everydayReflection =>
      'Solo para reflexionar sobre asuntos cotidianos. Las decisiones importantes requieren información real y ayuda profesional.';

  @override
  String get luckyTimesMorning => 'Tus momentos de mayor suerte esta mañana';

  @override
  String get luckyTimesMidday => 'Tus momentos de mayor suerte al mediodía';

  @override
  String get luckyTimesAfternoon => 'Tus momentos de mayor suerte esta tarde';

  @override
  String get luckyTimesEvening => 'Tus momentos de mayor suerte esta noche';

  @override
  String get loadingLocalTime => 'Sincronizando tu hora y momento local';

  @override
  String get loadingBaZi => 'Leyendo el equilibrio de elementos de BaZi';

  @override
  String get loadingZiWei => 'Trazando los ciclos de Zi Wei de este momento';

  @override
  String get loadingVedic =>
      'Relacionando los Nakshatras védicos y las mansiones lunares';

  @override
  String get loadingNumerology =>
      'Explorando numerología y ritmos lunares y planetarios';

  @override
  String get loadingYinYang =>
      'Equilibrando las señales del Yin y el Yang para sugerir una dirección';

  @override
  String get loadingModeYesNo => 'Comparando apertura y resistencia';

  @override
  String get loadingModeActWait => 'Equilibrando impulso y paciencia';

  @override
  String get loadingModeAdvanceRetreat =>
      'Comparando el impulso de hoy con los últimos días';

  @override
  String get loadingModeStayGo => 'Comparando arraigo y movimiento';

  @override
  String get loadingModeKeepLetGo => 'Sopesando continuidad y desprendimiento';

  @override
  String get loadingModeForwardBackward => 'Trazando avance y retorno';

  @override
  String get loadingModeCommitWithdraw => 'Equilibrando compromiso y retirada';

  @override
  String get loadingModeLeftRight =>
      'Equilibrando los polos receptivo y expresivo';

  @override
  String get orbitMoment => 'MOMENTO';

  @override
  String get orbitRhythm => 'RITMO';

  @override
  String get orbitBalance => 'EQUILIBRIO';

  @override
  String get orbitAlmanac => 'ALMANAQUE';

  @override
  String get orbitBaZi => 'BAZI';

  @override
  String get orbitZiWei => 'ZI WEI';

  @override
  String get orbitVedic => 'ASTROLOGÍA VÉDICA';

  @override
  String get orbitNumerology => 'NUMEROLOGÍA';

  @override
  String get orbitLunarPhase => 'FASE LUNAR';

  @override
  String get orbitPlanetary => 'PLANETAS';

  @override
  String get orbitYinYang => 'YIN / YANG';

  @override
  String get safetyHeading => 'LÍMITES Y USO RESPONSABLE';

  @override
  String get safetyTitle => 'UNA MIRADA PARA LOS MOMENTOS COTIDIANOS';

  @override
  String get safetyIntro =>
      'AstraCue ofrece perspectivas simbólicas basadas en ritmos astronómicos y ciclos personales. Está pensado para la reflexión cotidiana y el entretenimiento, no como una orden, predicción ni certeza factual.';

  @override
  String get prohibitedUses => 'USOS PROHIBIDOS';

  @override
  String get harmTitle => 'Daño a uno mismo o a otras personas';

  @override
  String get harmDetail =>
      'Nunca lo uses para autolesiones, suicidio, violencia física ni para poner en peligro a nadie.';

  @override
  String get navigationTitle => 'Conducción y orientación física';

  @override
  String get navigationDetail =>
      'IZQUIERDA / DERECHA y AVANZAR / REPLEGARSE son opciones simbólicas. Nunca las uses para el tráfico, la conducción, elegir rutas ni la seguridad física.';

  @override
  String get politicsTitle => 'Política y conflictos sociales';

  @override
  String get politicsDetail =>
      'Nunca lo uses para campañas políticas, decisiones electorales, disturbios civiles ni actividades extremistas.';

  @override
  String get medicalTitle => 'Salud, medicina y emergencias';

  @override
  String get medicalDetail =>
      'No sustituye la atención médica profesional, el tratamiento de salud mental, los medicamentos ni la respuesta a emergencias.';

  @override
  String get legalTitle => 'Asuntos legales, delitos y contratos importantes';

  @override
  String get legalDetail =>
      'Nunca lo uses para conductas delictivas, procesos judiciales, testimonios ni contratos legales de alto impacto.';

  @override
  String get financeTitle => 'Inversiones y apuestas';

  @override
  String get financeDetail =>
      'La sección Finanzas solo sirve para reflexionar sobre compras pequeñas y habituales. Nunca uses una lectura para invertir, pedir préstamos, apostar con criptoactivos, jugar dinero ni tomar decisiones financieras importantes.';

  @override
  String get consentTitle => 'Consentimiento, menores y relaciones';

  @override
  String get consentDetail =>
      'Nunca lo uses para pasar por alto el consentimiento o la autonomía de otra persona, ni para decidir sobre custodia o tutela de menores.';

  @override
  String get importantLimitsHeading => 'LÍMITES IMPORTANTES';

  @override
  String get importantLimitsBody =>
      'AstraCue no está diseñado para niños. No ofrece asesoramiento médico, legal ni financiero. Para decisiones importantes, consulta información fiable y busca la ayuda profesional adecuada. La elección sigue siendo tuya.';

  @override
  String get crisisSupport =>
      'Si tú u otra persona están en peligro inmediato o en una crisis emocional, contacta ahora a los servicios de emergencia locales o a una línea de ayuda de confianza de tu zona.';

  @override
  String get acknowledge => 'Entiendo y acepto';

  @override
  String get acknowledgementOnce =>
      'Esta confirmación aparece una sola vez antes de tu primera lectura.';

  @override
  String get safetyScrollToContinue =>
      'Desplázate hasta el final y lee todo el contenido para continuar.';

  @override
  String get knowBirthTime => 'Sé mi hora de nacimiento';

  @override
  String get knowBirthTimeDetail =>
      'Una hora exacta afina los ciclos basados en la hora.';

  @override
  String get selectBirthTime => 'Selecciona tu hora de nacimiento';

  @override
  String get birthTimeRequired =>
      'Selecciona tu hora de nacimiento para continuar, o desactiva esta opción si no la sabes.';

  @override
  String get languageSetting => 'Idioma';

  @override
  String get chooseLanguage => 'Elige tu idioma';

  @override
  String get changeLanguage => 'Cambiar idioma';

  @override
  String get languageNotSaved =>
      'No se pudo guardar tu preferencia de idioma, así que puede no recordarse la próxima vez.';

  @override
  String get profileNotSaved =>
      'No se pudo guardar tu perfil. Inténtalo de nuevo.';

  @override
  String get choiceYes => 'SÍ';

  @override
  String get choiceNo => 'NO';

  @override
  String get choiceAct => 'ACTUAR';

  @override
  String get choiceWait => 'ESPERAR';

  @override
  String get choiceAdvance => 'AVANZAR';

  @override
  String get choiceRetreat => 'REPLEGARSE';

  @override
  String get choiceStay => 'QUEDARSE';

  @override
  String get choiceGo => 'IRSE';

  @override
  String get choiceKeep => 'CONSERVAR';

  @override
  String get choiceLetGo => 'SOLTAR';

  @override
  String get choiceForward => 'HACIA DELANTE';

  @override
  String get choiceBackward => 'HACIA ATRÁS';

  @override
  String get choiceCommit => 'COMPROMETERSE';

  @override
  String get choiceWithdraw => 'RETIRARSE';

  @override
  String get choiceLeft => 'IZQUIERDA';

  @override
  String get choiceRight => 'DERECHA';

  @override
  String get energyLevelQuiet => 'SERENA';

  @override
  String get energyLevelSoft => 'SUAVE';

  @override
  String get energyLevelSteady => 'ESTABLE';

  @override
  String get energyLevelLively => 'VIVA';

  @override
  String get energyLevelBright => 'LUMINOSA';

  @override
  String get energyLevelRadiant => 'RADIANTE';

  @override
  String get energyLevelFocused => 'ENFOCADA';

  @override
  String get energyLevelFlowing => 'FLUIDA';

  @override
  String get colorCedar => 'Cedro';

  @override
  String get colorJade => 'Jade';

  @override
  String get colorSage => 'Salvia';

  @override
  String get colorMint => 'Menta';

  @override
  String get colorEmber => 'Brasa';

  @override
  String get colorSolarCoral => 'Coral solar';

  @override
  String get colorRose => 'Rosa';

  @override
  String get colorBlossom => 'Floración';

  @override
  String get colorOchre => 'Ocre';

  @override
  String get colorAmber => 'Ámbar';

  @override
  String get colorSand => 'Arena';

  @override
  String get colorClay => 'Arcilla';

  @override
  String get colorSilver => 'Plata';

  @override
  String get colorSteel => 'Acero';

  @override
  String get colorPearl => 'Perla';

  @override
  String get colorChampagne => 'Champán';

  @override
  String get colorOceanBlue => 'Azul océano';

  @override
  String get colorAzure => 'Azul celeste';

  @override
  String get colorIndigo => 'Índigo';

  @override
  String get colorMistBlue => 'Azul bruma';

  @override
  String get homeDescription00 =>
      '¿Qué podría estar diciéndote hoy el universo? Piensa en lo que te inquieta y explora las señales de este momento.';

  @override
  String get homeDescription01 =>
      '¿Sientes que dos caminos te atraen? Deja que las señales cósmicas de hoy te ofrezcan otra forma de ver tu elección.';

  @override
  String get homeDescription02 =>
      'Las estrellas no deciden por ti, pero sus patrones quizá te ayuden a mirar de otro modo tu próximo paso.';

  @override
  String get homeDescription03 =>
      'Cuando el camino no está claro, detente y observa con atención. ¿Qué sugieren las señales de hoy?';

  @override
  String get homeDescription04 =>
      'Cada momento tiene su propia energía. Piensa en lo que te inquieta y descubre hacia dónde podría apuntar.';

  @override
  String get homeDescription05 =>
      'Quizá el universo te invite a bajar el ritmo. Explora las señales de hoy antes de elegir tu camino.';

  @override
  String get homeDescription06 =>
      '¿Estás en una encrucijada? Observa cómo se relacionan los patrones celestes de hoy con tu pregunta.';

  @override
  String get homeDescription07 =>
      'Escucha el ritmo de este momento. Los símbolos de hoy quizá revelen una dirección que valga la pena considerar.';

  @override
  String get homeDescription08 =>
      '¿Qué intenta mostrarte este momento? Explora las señales y luego confía en ti para elegir.';

  @override
  String get homeDescription09 =>
      'Una perspectiva cósmica puede aportar claridad. Piensa en lo importante hoy y observa hacia dónde apuntan las señales.';

  @override
  String get homeDescription10 =>
      '¿Sigues dándole vueltas a la misma elección? Mira qué pone de relieve la energía cósmica de hoy.';

  @override
  String get homeDescription11 =>
      'Cuando tus pensamientos van en una dirección y tu intuición en otra, explora las señales que rodean este día.';

  @override
  String get homeDescription12 =>
      '¿No sabes si avanzar o esperar? Deja que el ritmo de hoy te ofrezca un punto de partida más sereno.';

  @override
  String get homeDescription13 =>
      '¿Y si la claridad comenzara con otra perspectiva? Mira los patrones celestes de hoy.';

  @override
  String get homeDescription14 =>
      'Hay una pregunta que vuelve a tu mente. Descubre qué te invitan a notar los símbolos de hoy.';

  @override
  String get homeDescription15 =>
      'Algunas elecciones pesan más en ciertos momentos. Explora la energía de este antes de decidir.';

  @override
  String get homeDescription16 =>
      'Puede que tu camino no esté claro ahora. ¿Qué podrían iluminar las estrellas detrás de esa duda?';

  @override
  String get homeDescription17 =>
      'Antes de seguir un impulso repentino, respira y observa qué sugieren las señales cósmicas de hoy.';

  @override
  String get homeDescription18 =>
      'No todas las encrucijadas exigen una respuesta inmediata. Deja que la lectura de hoy te dé espacio para reflexionar.';

  @override
  String get homeDescription19 =>
      '¿Te preguntas si este es el momento? Explora los patrones de hoy y busca una perspectiva más firme.';

  @override
  String get homeDescription20 =>
      'Cuando todo parece posible y nada seguro, deja que los patrones del cielo te inspiren otra forma de mirar.';

  @override
  String get homeDescription21 =>
      'La elección es tuya. Las señales de hoy quizá te ayuden a comprender qué importa más.';

  @override
  String get homeDescription22 =>
      'Cuando la duda nubla tu próximo paso, explora qué iluminan tu signo zodiacal y la energía de hoy.';

  @override
  String get homeDescription23 =>
      'Tal vez no necesites una respuesta más fuerte, sino un momento de calma con los símbolos de hoy.';

  @override
  String get homeDescription24 =>
      '¿Tu intuición te pide actuar o esperar? Observa qué podría reflejar el ritmo cósmico de hoy.';

  @override
  String get homeDescription25 =>
      'Entre lo que deseas y lo que temes hay espacio para detenerte. Deja que las señales de hoy te ayuden a mirar de nuevo.';

  @override
  String get homeDescription26 =>
      'Ya has reconocido tu pregunta. Ahora presta atención al momento. ¿Qué sugieren las señales celestes de hoy?';

  @override
  String get homeDescription27 =>
      'Cuando una decisión parece enredada, los símbolos antiguos y el momento de hoy quizá revelen otro ángulo.';

  @override
  String get homeDescription28 =>
      'Tal vez sea momento de acercarte o de dar espacio. Explora la energía que rodea tu elección.';

  @override
  String get homeDescription29 =>
      'No tienes que encontrar certeza aquí. Busca un momento de calma, una pista cósmica y una dirección para considerar.';

  @override
  String get energyQuiet00 =>
      'La energía simbólica de hoy mira hacia dentro y deja espacio para reflexionar en silencio.';

  @override
  String get energyQuiet01 =>
      'El ritmo cósmico de hoy mira hacia dentro; la quietud quizá revele lo que el ruido ocultaba.';

  @override
  String get energyQuiet02 =>
      'El tono simbólico del cielo es sereno hoy; deja que tus pensamientos se asienten.';

  @override
  String get energyQuiet03 =>
      'Una corriente tranquila recorre el día y te invita a observar en vez de apresurarte.';

  @override
  String get energyQuiet04 =>
      'Las señales de hoy sugieren reflexión; una pausa también puede ser parte de avanzar.';

  @override
  String get energyQuiet05 =>
      'Cuando el día se siente apagado, tu brújula interior quizá se escuche con más claridad.';

  @override
  String get energyQuiet06 =>
      'La energía de hoy deja espacio para escuchar antes de ponerle nombre a una respuesta.';

  @override
  String get energyQuiet07 =>
      'No todas las señales llegan con fuerza; las de hoy quizá se noten mejor si bajas el ritmo.';

  @override
  String get energySoft00 =>
      'La energía simbólica de hoy se mueve con suavidad y deja espacio para el cuidado y los pequeños pasos.';

  @override
  String get energySoft01 =>
      'Una corriente cósmica suave pasa por hoy; los pasos pequeños quizá se sientan más naturales que los grandes saltos.';

  @override
  String get energySoft02 =>
      'La energía de hoy deja espacio para cuidarte; mira tu elección sin exigirte certeza.';

  @override
  String get energySoft03 =>
      'El ritmo más suave del día quizá te ayude a empezar por lo que sientes manejable.';

  @override
  String get energySoft04 =>
      'Un enfoque amable también puede ser fuerte; observa dónde necesitas calma en lugar de presión.';

  @override
  String get energySoft05 =>
      'Las señales de hoy sugieren un toque ligero: lo suficiente para empezar, sin forzar el ritmo.';

  @override
  String get energySoft06 =>
      'La corriente de hoy es sutil; las acciones sencillas y pensadas pueden tener más significado.';

  @override
  String get energySoft07 =>
      'Incluso una pequeña oportunidad puede importar; el patrón suave de hoy te deja espacio para explorarla.';

  @override
  String get energySteady00 =>
      'La energía simbólica de hoy mantiene un ritmo parejo y con los pies en la tierra.';

  @override
  String get energySteady01 =>
      'La energía simbólica de hoy mantiene un ritmo constante; confía en el paso que puedes sostener.';

  @override
  String get energySteady02 =>
      'El patrón cósmico se siente estable y deja espacio para pensar y actuar con intención.';

  @override
  String get energySteady03 =>
      'Una corriente constante recorre el día; prestar atención quizá te sirva más que la urgencia.';

  @override
  String get energySteady04 =>
      'Las señales de hoy apuntan al equilibrio, sin pedirte que te quedes inmóvil.';

  @override
  String get energySteady05 =>
      'La constancia tiene fuerza; observa qué próximo paso sigue teniendo sentido después de una pausa.';

  @override
  String get energySteady06 =>
      'El día trae una energía mesurada y deja que tu elección tome forma.';

  @override
  String get energySteady07 =>
      'Un ritmo tranquilo también puede guiarte; avanzar hoy no tiene que ser algo espectacular.';

  @override
  String get energyLively00 =>
      'Una chispa juguetona anima la energía simbólica de hoy y despierta curiosidad y movimiento.';

  @override
  String get energyLively01 =>
      'Una chispa de curiosidad anima la energía simbólica de hoy; quizá valga la pena explorar otro ángulo.';

  @override
  String get energyLively02 =>
      'El día se siente más activo; nota qué capta tu atención sin lanzarte de inmediato.';

  @override
  String get energyLively03 =>
      'El ritmo cósmico de hoy invita a descubrir, sin dejar de pensar con claridad.';

  @override
  String get energyLively04 =>
      'Una corriente alegre recorre el día; pueden aparecer posibilidades donde menos lo esperas.';

  @override
  String get energyLively05 =>
      'La curiosidad quizá sea una señal útil hoy; observa adónde apunta antes de comprometerte.';

  @override
  String get energyLively06 =>
      'Hay movimiento en las señales de hoy; puedes explorar sin decidir demasiado pronto.';

  @override
  String get energyLively07 =>
      'La energía se siente viva; deja que amplíe tus opciones antes de reducirlas.';

  @override
  String get energyBright00 =>
      'La energía simbólica de hoy brilla con impulso y espacio para expresarte.';

  @override
  String get energyBright01 =>
      'La energía simbólica de hoy ilumina un poco más lo que quieres expresar.';

  @override
  String get energyBright02 =>
      'Una corriente cósmica más luminosa quizá te ayude a ver qué posibilidad merece atención.';

  @override
  String get energyBright03 =>
      'Las señales de hoy se sienten abiertas; quizá te resulte más fácil nombrar el próximo paso.';

  @override
  String get energyBright04 =>
      'Hoy hay impulso para expresarte; comparte lo importante cuando sientas que es el momento.';

  @override
  String get energyBright05 =>
      'Una apertura en el ritmo de hoy puede aportar claridad sin exigirte prisa.';

  @override
  String get energyBright06 =>
      'La energía del día mira hacia fuera; observa qué estás listo para mostrar.';

  @override
  String get energyBright07 =>
      'Un poco de luz puede cambiar la perspectiva; los patrones de hoy te invitan a mirar adelante.';

  @override
  String get energyRadiant00 =>
      'La energía simbólica de hoy alcanza su brillo más pleno: abierta y expansiva.';

  @override
  String get energyRadiant01 =>
      'La energía simbólica de hoy se abre y te invita a ver más de un camino posible.';

  @override
  String get energyRadiant02 =>
      'Una corriente radiante recorre el día; deja crecer las posibilidades sin perder tu centro.';

  @override
  String get energyRadiant03 =>
      'El patrón cósmico se siente especialmente abierto; deja espacio para lo que te inspira.';

  @override
  String get energyRadiant04 =>
      'Un brillo más pleno colorea la energía de hoy y amplía tu visión de las posibilidades.';

  @override
  String get energyRadiant05 =>
      'Las señales de hoy tienen un tono expansivo; quizá sea más fácil imaginar lo que viene.';

  @override
  String get energyRadiant06 =>
      'Deja que la calidez del día amplíe tu mirada, sin olvidar que la elección final es tuya.';

  @override
  String get energyRadiant07 =>
      'El ritmo simbólico del cielo se siente generoso; recibe las posibilidades con buen juicio.';

  @override
  String get energyFocused00 =>
      'La energía simbólica de hoy se reúne en una dirección clara; predomina la señal de acción.';

  @override
  String get energyFocused01 =>
      'La señal de acción de hoy se vuelve más clara; observa un paso que puedas dar con intención.';

  @override
  String get energyFocused02 =>
      'La corriente simbólica se inclina hacia la acción, pero tú eliges el ritmo.';

  @override
  String get energyFocused03 =>
      'Hay una sensación de dirección hoy; atiende a lo que de verdad puedes influir.';

  @override
  String get energyFocused04 =>
      'Cuando compiten varias opciones, las señales de hoy te invitan a centrarte en un paso práctico.';

  @override
  String get energyFocused05 =>
      'Las señales de hoy se reúnen alrededor de una intención; préstale atención sin apresurarte.';

  @override
  String get energyFocused06 =>
      'La acción tiene hoy una atracción simbólica mayor; aclara tus razones antes de moverte.';

  @override
  String get energyFocused07 =>
      'Hoy importa la intención, no la intensidad; deja que la dirección elegida tome forma.';

  @override
  String get energyFlowing00 =>
      'La energía simbólica de hoy se mueve como la marea; predomina la señal de cambio.';

  @override
  String get energyFlowing01 =>
      'La señal de cambio se hace más visible hoy; deja un poco de flexibilidad en tus planes.';

  @override
  String get energyFlowing02 =>
      'Una corriente cósmica cambiante recorre el día; adaptarte quizá te muestre otro camino.';

  @override
  String get energyFlowing03 =>
      'La energía del cambio se nota más; mantente abierto a lo que te muestre otro ángulo.';

  @override
  String get energyFlowing04 =>
      'Las señales de hoy hablan de moverse entre posibilidades, no de un destino fijo.';

  @override
  String get energyFlowing05 =>
      'Cuando cambian las circunstancias, una respuesta flexible quizá te sirva más que un plan rígido.';

  @override
  String get energyFlowing06 =>
      'Un ritmo fluido recorre el día; observa qué puede evolucionar sin forzar una respuesta.';

  @override
  String get energyFlowing07 =>
      'La corriente simbólica se inclina hacia la transición; puedes seguirla a tu propio ritmo.';

  @override
  String get defaultUserName => 'Explorador';

  @override
  String get searchCountries => 'Buscar países';

  @override
  String get greetingMorning => 'Buenos días,';

  @override
  String get greetingAfternoon => 'Buenas tardes,';

  @override
  String get greetingEvening => 'Buenas noches,';

  @override
  String get colorRoleLead => 'Principal';

  @override
  String get colorRoleSupporting => 'Complementario';

  @override
  String colorRoleSemantics(String role, String name) {
    return 'Color $role: $name';
  }

  @override
  String colorRoleUnavailableSemantics(String role) {
    return 'El color $role aún no está disponible';
  }

  @override
  String readingAreaSemantics(String category) {
    return 'Área de lectura: $category';
  }

  @override
  String get energyInsightNewTooltip =>
      'Nueva reflexión sobre la energía de hoy';

  @override
  String get energyInsightReadTooltip =>
      'Leer la reflexión sobre la energía de hoy';

  @override
  String get energyInsightHideTooltip =>
      'Ocultar el significado de la energía de hoy';

  @override
  String get energyInsightCoachMark =>
      'Aquí encontrarás una nueva reflexión sobre tu energía cada día.';

  @override
  String get ritualLocked => 'Tu momento ha quedado fijado.';

  @override
  String get periodPassedShort => 'PASADO';

  @override
  String get errorNetworkHeadline => 'Se interrumpió la conexión.';

  @override
  String get errorNetworkDetail =>
      'Comprueba tu conexión y vuelve a intentarlo.';

  @override
  String get errorServerHeadline =>
      'No se pudo completar la lectura en este momento.';

  @override
  String get errorServerDetail =>
      'El servicio respondió, pero no pudo terminar. Vuelve a intentarlo en un momento.';

  @override
  String get errorRejectedHeadline =>
      'Debes revisar algunos datos de tu perfil.';

  @override
  String get errorRejectedDetail =>
      'Revisa tus datos de nacimiento y comienza una nueva lectura.';

  @override
  String get errorInvalidHeadline =>
      'Esta versión de la app no pudo interpretar el resultado.';

  @override
  String get errorInvalidDetail =>
      'Actualizar la app podría restablecer las lecturas.';

  @override
  String get errorConfigurationHeadline =>
      'Esta versión no tiene configurado el servicio de lecturas.';

  @override
  String get errorConfigurationDetail =>
      'Versión de desarrollo: no se configuró el servicio de cálculo.';

  @override
  String get errorNothingRecorded =>
      'No se guardó ninguna lectura de este intento.';

  @override
  String get insufficientHeading => 'NO HAY DATOS SUFICIENTES';

  @override
  String get insufficientBody =>
      'Tu perfil aún no contiene suficientes datos para sugerir una dirección esta vez. Añadir la hora y el país de nacimiento aporta más contexto a los ciclos.';

  @override
  String get periodElapsedHeading => 'ESE PERIODO YA PASÓ';

  @override
  String get periodElapsedBody =>
      'Ese periodo ya terminó donde te encuentras, así que no queda una franja horaria por analizar. Elige un periodo posterior o consulta el momento actual. La lectura de hoy no se traslada a mañana.';

  @override
  String colorsToKeepNear(String first, String second) {
    return 'Colores para tener cerca: $first y $second';
  }

  @override
  String colorToKeepNear(String name) {
    return 'Color para tener cerca: $name';
  }

  @override
  String get shareTooltip => 'Compartir esta lectura';

  @override
  String get shareUnavailable => 'No se puede compartir en este momento.';

  @override
  String get shareDisclaimer =>
      'Una perspectiva simbólica para reflexionar cada día; no es una predicción ni una probabilidad.';

  @override
  String get backToHistory => 'Volver al historial';

  @override
  String get saveFailedRetry => 'No se guardó · Reintentar';

  @override
  String get savingToHistory => 'Guardando en el historial…';

  @override
  String get responsibleUseLink => 'Uso responsable y política de seguridad';

  @override
  String get historyToday => 'HOY';

  @override
  String get historyCouldNotOpen =>
      'No se pudo abrir tu historial de lecturas.';

  @override
  String get historyNotEnoughData => 'DATOS INSUFICIENTES';

  @override
  String get historyPeriodPassed => 'PERIODO PASADO';

  @override
  String get zodiacAries => 'Aries';

  @override
  String get zodiacTaurus => 'Tauro';

  @override
  String get zodiacGemini => 'Géminis';

  @override
  String get zodiacCancer => 'Cáncer';

  @override
  String get zodiacLeo => 'Leo';

  @override
  String get zodiacVirgo => 'Virgo';

  @override
  String get zodiacLibra => 'Libra';

  @override
  String get zodiacScorpio => 'Escorpio';

  @override
  String get zodiacSagittarius => 'Sagitario';

  @override
  String get zodiacCapricorn => 'Capricornio';

  @override
  String get zodiacAquarius => 'Acuario';

  @override
  String get zodiacPisces => 'Piscis';

  @override
  String zodiacAvatarSemantics(String sign) {
    return 'Avatar del signo zodiacal $sign';
  }

  @override
  String get profileTitle => 'Perfil';

  @override
  String get openProfile => 'Abrir tu perfil';

  @override
  String get saveAction => 'Guardar';

  @override
  String get cancelAction => 'Cancelar';

  @override
  String get profileSaved => 'Perfil actualizado.';

  @override
  String profileBirthTimeLocked(String wait) {
    return 'Podrás cambiar tu hora de nacimiento dentro de $wait.';
  }

  @override
  String profileBirthCountryLocked(String wait) {
    return 'Podrás cambiar tu país de nacimiento dentro de $wait.';
  }

  @override
  String profileWaitHoursMinutes(String hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String profileWaitMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String get profileConfirmTitle => '¿Guardar estos cambios?';

  @override
  String get profileConfirmBirthTime =>
      'Después, tu hora de nacimiento quedará fija durante 2 horas.';

  @override
  String get profileConfirmBirthCountry =>
      'Después, tu país de nacimiento quedará fijo durante 1 hora.';

  @override
  String get profileBirthTimeUnknownValue => 'Desconocida';

  @override
  String get profileReadingsUnchanged =>
      'Las lecturas que ya guardaste no cambian.';

  @override
  String profileBirthDateLocked(String wait) {
    return 'Podrás cambiar tu fecha de nacimiento dentro de $wait.';
  }

  @override
  String get profileConfirmBirthDate =>
      'Después, tu fecha de nacimiento quedará fija durante 4 horas.';
}
