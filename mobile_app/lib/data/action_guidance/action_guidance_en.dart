/// English copy for Action Guidance.
///
/// Contains base reflections per decision mode plus context lenses for
/// career, love, finances (money), study, friends, and other.
///
/// Adheres strictly to responsible use:
/// - Never tells the reader to buy, sell, quit, marry, or divorce.
/// - Free from forbidden words: 'invest', 'money', 'salary', 'loan', 'profit',
///   'buy', 'sell', 'pay', 'relationship', 'partner', 'break up', 'walk away',
///   'leave them', 'quit', 'resign', 'marry', 'divorce'.
/// - Avoids overclaims like 'most aligned', 'more aligned', 'best moment',
///   'reads as the most'.
const Map<String, (String, String, String)> actionGuidanceEn =
    <String, (String, String, String)>{
  // ---------------------------------------------------------------------------
  // Base entries (General / Universal)
  // ---------------------------------------------------------------------------
  'balanced': (
    'The signals did not lean either way today.',
    'Write down what you already believe, before you look for more signs.',
    'Asking again in another mode until an answer looks like the one you wanted.',
  ),
  'yes_no:first': (
    'Today the signals lean toward openness rather than resistance.',
    'Notice where you were already leaning, and what that tells you.',
    'Treating a symbolic lean as permission to skip your own reasoning.',
  ),
  'yes_no:second': (
    'Today the signals lean toward resistance rather than openness.',
    'Name the hesitation you already feel, plainly, before arguing with it.',
    'Reading resistance as a verdict instead of a reason to look again.',
  ),
  'act_wait:first': (
    'Timing counted alongside everything else, the reading leans toward acting.',
    'Ask what you could begin now that would still be yours tomorrow.',
    'Confusing a well-timed moment with a finished decision.',
  ),
  'act_wait:second': (
    'Timing counted alongside everything else, the reading leans toward waiting.',
    'Let the question sit, and see whether it changes shape by evening.',
    'Mistaking patience for avoidance, or hurry for courage.',
  ),
  'advance_retreat:first': (
    'Recent momentum counted with the rest, the reading leans toward advancing.',
    'Notice what has actually shifted since the start of the week.',
    'Assuming momentum will keep itself going.',
  ),
  'advance_retreat:second': (
    'Recent momentum counted with the rest, the reading leans toward drawing back.',
    'Ask what would really be lost by holding your position a little longer.',
    'Reading a quiet day as a setback.',
  ),
  'stay_go:first': (
    'Staying power counted with the rest, the reading leans toward holding your place.',
    'Consider what the ground you are standing on is actually giving you.',
    'Confusing stillness with being stuck.',
  ),
  'stay_go:second': (
    'Staying power counted with the rest, the reading leans toward moving.',
    'Ask what you would take with you, and what you would set down.',
    'Treating restlessness as a plan.',
  ),
  'keep_let_go:first': (
    'The signals lean toward holding rather than releasing.',
    'Look at what you are holding, and whether you chose it or inherited it.',
    'Holding on from habit and calling it commitment.',
  ),
  'keep_let_go:second': (
    'The signals lean toward releasing rather than holding.',
    'Ask what would have room to grow if your attention were freed.',
    'Reading a symbolic lean as a reason to decide something for someone else.',
  ),
  'commit_withdraw:first': (
    'The week ahead counted with the rest, the reading leans toward committing.',
    'Think in weeks rather than hours, and see if the question survives that.',
    'Mistaking a steady week for a guarantee.',
  ),
  'commit_withdraw:second': (
    'The week ahead counted with the rest, the reading leans toward stepping back out.',
    'Ask what would have to be true for this to feel steadier.',
    'Reading an unsettled week as a permanent state.',
  ),
  'left_right:first': (
    'The polarity counted with the rest, the reading leans inward and receptive.',
    'Give the quieter, less obvious reading of your question some room.',
    'Using a symbolic polarity for anything physical — traffic, routes or safety.',
  ),
  'left_right:second': (
    'The polarity counted with the rest, the reading leans outward and expressive.',
    'Try saying the thing you have been circling, at least to yourself.',
    'Using a symbolic polarity for anything physical — traffic, routes or safety.',
  ),

  // ---------------------------------------------------------------------------
  // Career (Work & Initiatives)
  // ---------------------------------------------------------------------------
  'career:balanced': (
    'In your work today, the signals remain in careful equilibrium.',
    'Assemble your facts and current standing before seeking further signs.',
    'Prompting again repeatedly to find an answer that flatters your hopes.',
  ),
  'career:yes_no:first': (
    'In your work, the signals lean toward welcoming fresh opportunities.',
    'Ask whether this step genuinely serves your long-term professional aims.',
    'Confusing temporary excitement with a well-prepared plan of action.',
  ),
  'career:yes_no:second': (
    'In your work, the signals lean toward caution and weighing present hurdles.',
    'Examine any unresolved doubts in the project before proceeding further.',
    'Treating a temporary obstacle as an impasse instead of a cue to refine.',
  ),
  'career:act_wait:first': (
    'Timing counted alongside everything else in your work, the reading leans toward acting.',
    'Begin tangible components today that you can steadily build upon tomorrow.',
    'Confusing an opportune moment with a project that is already completed.',
  ),
  'career:act_wait:second': (
    'Timing counted alongside everything else in your work, the reading leans toward waiting.',
    'Allow extra time to gather data and verify details before concluding.',
    'Hurrying the pace before your professional groundwork is truly solid.',
  ),
  'career:advance_retreat:first': (
    'Recent professional momentum counted with the rest, the reading leans toward advancing.',
    'Harness your current progress to expand scope or introduce new proposals.',
    'Assuming favorable momentum will sustain itself without sustained effort.',
  ),
  'career:advance_retreat:second': (
    'Recent professional momentum counted with the rest, the reading leans toward holding back.',
    'Hold your current ground to audit processes and avoid overextending effort.',
    'Interpreting a pause for strategic recalibration as a career setback.',
  ),
  'career:stay_go:first': (
    'Staying power counted with the rest in your work, the reading leans toward holding your place.',
    'Reflect on the solid foundation and experience your present role affords.',
    'Confusing professional stability with being stalled in place.',
  ),
  'career:stay_go:second': (
    'Staying power counted with the rest in your work, the reading leans toward shifting direction.',
    'Clarify what capabilities you intend to carry forward and what to leave behind.',
    'Mistaking a restless mood for a complete vocational strategy.',
  ),
  'career:keep_let_go:first': (
    'In your work, the signals lean toward preserving what you have built.',
    'Revisit the core values you stand for and stay grounded in them.',
    'Clinging to outmoded workflows simply out of hesitation to adapt.',
  ),
  'career:keep_let_go:second': (
    'In your work, the signals lean toward unburdening your workload.',
    'Release low-impact obligations to focus on your essential priorities.',
    'Dropping shared duties unilaterally without proper communication.',
  ),
  'career:commit_withdraw:first': (
    'The week ahead counted with the rest in your work, the reading leans toward steady commitment.',
    'View the venture across weeks and quarters to test its true endurance.',
    'Mistaking a smooth stretch of days for an enduring guarantee.',
  ),
  'career:commit_withdraw:second': (
    'The week ahead counted with the rest in your work, the reading leans toward stepping back to regroup.',
    'Identify what conditions are needed for the initiative to regain stability.',
    'Viewing a demanding week as a sign of permanent failure.',
  ),
  'career:left_right:first': (
    'In your work, the reading leans inward toward listening and gathering insight.',
    'Make space for constructive critiques and observant study before deciding.',
    'Using a symbolic polarity for anything physical — traffic, routes or safety.',
  ),
  'career:left_right:second': (
    'In your work, the reading leans outward toward articulating and presenting ideas.',
    'Voice your perspective clearly with colleagues and relevant stakeholders.',
    'Using a symbolic polarity for anything physical — traffic, routes or safety.',
  ),

  // ---------------------------------------------------------------------------
  // Love (Personal Connection & Bonds)
  // ---------------------------------------------------------------------------
  'love:balanced': (
    'In matters of personal connection today, the signals rest in stillness.',
    'Reflect honestly on your feelings before seeking outside indicators.',
    'Seeking repeated signs to quiet a passing moment of vulnerability.',
  ),
  'love:yes_no:first': (
    'In personal connections, the signals lean toward openness and receptive warmth.',
    'Express your genuine feelings rather than maintaining guarded boundaries.',
    'Expecting others to intuit your emotions without clear, honest dialogue.',
  ),
  'love:yes_no:second': (
    'In personal connections, the signals lean toward prudence and holding healthy space.',
    'Listen to your inner hesitation and give yourself room to process gently.',
    'Treating reserve as finality rather than an invitation to deeper understanding.',
  ),
  'love:act_wait:first': (
    'Timing counted alongside everything else in personal bonds, the reading leans toward reaching out.',
    'Offer thoughtful gestures of care and open a channel for genuine connection.',
    'Pressing for an immediate response before the other person is ready.',
  ),
  'love:act_wait:second': (
    'Timing counted alongside everything else in personal bonds, the reading leans toward patience.',
    'Allow shared time and emotional space for feelings to settle organically.',
    'Confusing distant silence with sincere, patient understanding.',
  ),
  'love:advance_retreat:first': (
    'Recent closeness counted with the rest, the reading leans toward deepening connection.',
    'Honor the genuine moments of shared trust that have recently unfolded.',
    'Assuming all subtle complexities have effortlessly resolved themselves.',
  ),
  'love:advance_retreat:second': (
    'Recent closeness counted with the rest, the reading leans toward slowing the pace.',
    'Allow a quiet interval so both of you can clarify your personal feelings.',
    'Interpreting a quiet day as emotional distance or an enduring setback.',
  ),
  'love:stay_go:first': (
    'Staying power counted with the rest, the reading leans toward cherishing current ties.',
    'Look closely at the care and shared history that have sustained you both.',
    'Confusing quiet familiarity with lack of emotional growth.',
  ),
  'love:stay_go:second': (
    'Staying power counted with the rest, the reading leans toward refreshing shared routines.',
    'Introduce fresh habits and novel shared experiences to invite new energy.',
    'Allowing momentary boredom to dictate sudden emotional reactions.',
  ),
  'love:keep_let_go:first': (
    'In personal connections, the signals lean toward nurturing what is meaningful.',
    'Notice whether your attachment arises from deep care or simple habit.',
    'Straining to maintain surface harmony while avoiding honest topics.',
  ),
  'love:keep_let_go:second': (
    'In personal connections, the signals lean toward releasing heavy expectations.',
    'Ease the desire to manage or overthink how the other person responds.',
    'Using symbolic guidance to decide feelings on behalf of someone else.',
  ),
  'love:commit_withdraw:first': (
    'The week ahead counted with the rest, the reading leans toward steadfast closeness.',
    'Think in terms of steady presence across seasons rather than fleeting moods.',
    'Treating a gentle period as a reason to stop tending to shared bonds.',
  ),
  'love:commit_withdraw:second': (
    'The week ahead counted with the rest, the reading leans toward taking personal breath.',
    'Dedicate time to inner renewal so you bring your grounded self to others.',
    'Viewing a period of mutual recalibration as an irremediable divide.',
  ),
  'love:left_right:first': (
    'In personal connections, the reading leans inward toward deep, attentive listening.',
    'Listen with mindful focus to what is communicated beneath spoken words.',
    'Using symbolic polarity for physical navigation, traffic, or safety.',
  ),
  'love:left_right:second': (
    'In personal connections, the reading leans outward toward sincere self-expression.',
    'Find the courage to articulate your heartfelt feelings and gentle desires.',
    'Using symbolic polarity for physical navigation, traffic, or safety.',
  ),

  // ---------------------------------------------------------------------------
  // Finances (Resources & Material Balance)
  // ---------------------------------------------------------------------------
  'money:balanced': (
    'In financial matters today, the signals maintain a steady balance.',
    'Take note of existing reserves and adhere to your established allocations.',
    'Using symbolic indicators to justify a hasty or emotional expenditure.',
  ),
  'money:yes_no:first': (
    'In financial matters, the signals lean toward clarity and positive outlook.',
    'Ensure this choice is grounded in genuine necessity and long-term design.',
    'Entering into material obligations before all associated costs are transparent.',
  ),
  'money:yes_no:second': (
    'In financial matters, the signals lean toward caution and conserving reserves.',
    'Audit your contingency buffers and focus on protecting existing resources.',
    'Treating prudence as scarcity rather than a sound defensive posture.',
  ),
  'money:act_wait:first': (
    'Timing counted alongside everything else in financial matters, the reading leans toward acting.',
    'Execute well-researched resource allocations that were planned in advance.',
    'Expanding expenditure beyond initial parameters simply because conditions feel easy.',
  ),
  'money:act_wait:second': (
    'Timing counted alongside everything else in financial matters, the reading leans toward waiting.',
    'Maintain a calm posture and take several days to weigh major commitments.',
    'Rushing to commit resources out of fear of missing a fleeting window.',
  ),
  'money:advance_retreat:first': (
    'Recent resource momentum counted with the rest, the reading leans toward measured growth.',
    'Leverage current stability to improve the discipline of your allocations.',
    'Assuming positive material conditions will persist without watchful upkeep.',
  ),
  'money:advance_retreat:second': (
    'Recent resource momentum counted with the rest, the reading leans toward retrenching.',
    'Trim incidental outflows that do not serve meaningful long-range value.',
    'Viewing disciplined budgeting as an unwelcome restriction.',
  ),
  'money:stay_go:first': (
    'Staying power counted with the rest in financial matters, the reading leans toward holding structure.',
    'Acknowledge the resilience and security your current approach provides.',
    'Confusing financial security with an absence of forward opportunity.',
  ),
  'money:stay_go:second': (
    'Staying power counted with the rest in financial matters, the reading leans toward restructuring.',
    'Review which outlays should be curtailed to reinforce critical priorities.',
    'Enacting drastic financial shifts based on short-term restlessness.',
  ),
  'money:keep_let_go:first': (
    'In financial matters, the signals lean toward safeguarding built-up reserves.',
    'Appraise the practical utility of what you are holding in reserve.',
    'Maintaining recurring subscriptions solely out of inattention to records.',
  ),
  'money:keep_let_go:second': (
    'In financial matters, the signals lean toward eliminating unproductive drains.',
    'Consider how much lighter your budget feels when wasteful leakage stops.',
    'Indiscriminately cutting fundamental needs that support vitality and health.',
  ),
  'money:commit_withdraw:first': (
    'The week ahead counted with the rest in financial matters, the reading leans toward steady pacing.',
    'Evaluate material decisions within a quarterly or multi-month horizon.',
    'Treating a week of moderate spending as license to abandon controls.',
  ),
  'money:commit_withdraw:second': (
    'The week ahead counted with the rest in financial matters, the reading leans toward pausing commitments.',
    'Clarify what requirements must be met before undertaking fresh outflows.',
    'Interpreting an unexpected expense as an overwhelming disaster.',
  ),
  'money:left_right:first': (
    'In financial matters, the reading leans toward meticulous review and analysis.',
    'Cross-check figures and concrete statements before formalizing decisions.',
    'Using symbolic readings to speculate with essential resources.',
  ),
  'money:left_right:second': (
    'In financial matters, the reading leans toward decisive and orderly settlement.',
    'Address pending fiscal obligations with prompt and systematic clarity.',
    'Using symbolic readings to speculate with essential resources.',
  ),

  // ---------------------------------------------------------------------------
  // Study (Learning & Personal Mastery)
  // ---------------------------------------------------------------------------
  'study:balanced': (
    'In learning and development today, the signals encourage calm consolidation.',
    'Review foundational concepts thoroughly before introducing advanced material.',
    'Attempting to cram excess topics when your mind seeks time to integrate.',
  ),
  'study:yes_no:first': (
    'In learning and development, the signals lean toward absorbing fresh knowledge.',
    'Select the specific capability you wish to refine and devote undivided focus to it.',
    'Initiating numerous topics concurrently without the persistence to finish.',
  ),
  'study:yes_no:second': (
    'In learning and development, the signals lean toward reinforcing foundational basics.',
    'Dedicate study sessions to clarifying core principles before advancing.',
    'Disheartening yourself because thorough mastery takes time and patience.',
  ),
  'study:act_wait:first': (
    'Timing counted alongside everything else in your studies, the reading leans toward starting.',
    'Engage in focused daily practice to cement a resilient routine.',
    'Drafting an overly elaborate curriculum without executing daily work.',
  ),
  'study:act_wait:second': (
    'Timing counted alongside everything else in your studies, the reading leans toward contemplative study.',
    'Grant your intellect time to internalize ideas rather than skimming quickly.',
    'Equating rapid consumption with genuine, deep comprehension.',
  ),
  'study:advance_retreat:first': (
    'Recent learning momentum counted with the rest, the reading leans toward tackling higher rigor.',
    'Challenge your thinking with demanding problems that require deeper synthesis.',
    'Bypassing elemental drills before their principles are fully second nature.',
  ),
  'study:advance_retreat:second': (
    'Recent learning momentum counted with the rest, the reading leans toward simplifying and cataloging.',
    'Synthesize lecture notes and conceptual maps to bolster long-term recall.',
    'Treating a deliberate slowdown as falling behind your peers.',
  ),
  'study:stay_go:first': (
    'In learning, the signals lean toward deepening mastery within your current domain.',
    'Explore the full depth of your existing discipline before looking elsewhere.',
    'Drifting restlessly across subjects because early stages feel routine.',
  ),
  'study:stay_go:second': (
    'In learning, the signals lean toward broadening into complementary disciplines.',
    'Seek out cross-functional perspectives that enrich your analytical toolkit.',
    'Confusing temporary fascination with a long-term academic pathway.',
  ),
  'study:keep_let_go:first': (
    'In learning, the reading leans toward honoring proven study habits.',
    'Uphold the study timetable and routines that have delivered reliable gains.',
    'Holding on to inefficient learning methods out of mere familiarity.',
  ),
  'study:keep_let_go:second': (
    'In learning, the reading leans toward clearing away redundant reference materials.',
    'Prune your reading pile to concentrate on truly authoritative sources.',
    'Hoarding articles and books that you realistically never intend to study.',
  ),
  'study:commit_withdraw:first': (
    'Looking across the coming week, the reading leans toward dedication to your coursework.',
    'Block out non-negotiable study hours across the week as a key priority.',
    'Committing to prolonged programs on brief inspiration without testing your schedule.',
  ),
  'study:commit_withdraw:second': (
    'Looking across the coming week, the reading leans toward deliberate mental recovery.',
    'Allow yourself scheduled downtime to restore cognitive focus.',
    'Equating a much-needed study break with a loss of scholarly ambition.',
  ),
  'study:left_right:first': (
    'In learning, the reading leans inward toward deep reading and reflective analysis.',
    'Listen attentively to instructions and analyze texts with thorough concentration.',
    'Relying on intuitive symbols in place of rigorous factual study.',
  ),
  'study:left_right:second': (
    'In learning, the reading leans outward toward articulating ideas and teaching others.',
    'Explain newly learned concepts aloud to test the clarity of your grasp.',
    'Relying on intuitive symbols in place of rigorous factual study.',
  ),

  // ---------------------------------------------------------------------------
  // Friends (Friendship & Social Circles)
  // ---------------------------------------------------------------------------
  'friends:balanced': (
    'In friendship and social circles today, the signals rest in easy harmony.',
    'Savor your own solitude before stepping out into group gatherings.',
    'Striving for social validation when you would genuinely prefer quiet.',
  ),
  'friends:yes_no:first': (
    'In friendship, the signals lean toward authentic closeness and warmth.',
    'Dedicate care and presence to friendships that bring uplifting, honest energy.',
    'Attempting to accommodate everyone at the expense of your own boundaries.',
  ),
  'friends:yes_no:second': (
    'In friendship, the signals lean toward maintaining clear personal boundaries.',
    'Acknowledge interactions that leave you depleted and politely step back.',
    'Harboring guilt when unable to fulfill every social invitation.',
  ),
  'friends:act_wait:first': (
    'Timing counted alongside everything else, the reading leans toward reaching out to friends.',
    'Send a warm note to an old friend you have been meaning to check in on.',
    'Expecting immediate replies when friends have their own pressing schedules.',
  ),
  'friends:act_wait:second': (
    'Timing counted alongside everything else, the reading leans toward letting gatherings occur naturally.',
    'Allow social plans to develop unhurriedly without forcing attendance.',
    'Assuming negative motives when a message is answered later than usual.',
  ),
  'friends:advance_retreat:first': (
    'Recent social momentum counted with the rest, the reading leans toward welcoming new acquaintances.',
    'Participate in shared interest groups that reflect your authentic values.',
    'Extending total confidence to new acquaintances before character is shown.',
  ),
  'friends:advance_retreat:second': (
    'Recent social momentum counted with the rest, the reading leans toward a close, trusted circle.',
    'Prioritize quality time with a handful of companions who truly know you.',
    'Isolating yourself completely over a minor misunderstanding in a group.',
  ),
  'friends:stay_go:first': (
    'In friendships, the reading leans toward honoring enduring, long-standing circles.',
    'Appreciate companions who have stood alongside you across varying seasons.',
    'Tolerating draining social circles solely because of nostalgic history.',
  ),
  'friends:stay_go:second': (
    'In friendships, the reading leans toward seeking companions with shared passions.',
    'Broaden your horizons by conversing with people of kindred curiosity.',
    'Viewing natural social shifts as personal betrayal.',
  ),
  'friends:keep_let_go:first': (
    'In friendships, the reading leans toward upholding trust and kept promises.',
    'Show up steadfastly for friends whenever they ask for a listening ear.',
    'Excusing hurtful social behavior under the banner of unquestioning loyalty.',
  ),
  'friends:keep_let_go:second': (
    'In friendships, the reading leans toward releasing minor social grievances.',
    'Extend grace toward honest slips and resolve misunderstandings gently.',
    'Nurturing silent resentment instead of addressing matters transparently.',
  ),
  'friends:commit_withdraw:first': (
    'The week ahead counted with the rest, the reading leans toward active involvement with friends.',
    'Coordinate a shared weekend endeavor or collaborative community effort.',
    'Promising assistance across multiple events beyond your real energy levels.',
  ),
  'friends:commit_withdraw:second': (
    'The week ahead counted with the rest, the reading leans toward claiming restorative solitude.',
    'Recharge your social energy in the peaceful comfort of your own space.',
    'Vanishing from communications without a courteous heads-up to friends.',
  ),
  'friends:left_right:first': (
    'In social interactions, the reading leans toward compassionate, focused listening.',
    'Listen attentively to your friend\'s story without interjecting hasty advice.',
    'Using intuitive symbols to pass judgment on others\' sincerity.',
  ),
  'friends:left_right:second': (
    'In social interactions, the reading leans toward candid and constructive sharing.',
    'Communicate your perspective gently in the spirit of mutual growth.',
    'Using intuitive symbols to pass judgment on others\' sincerity.',
  ),

  // ---------------------------------------------------------------------------
  // Other / Situational (Specific Contexts)
  // ---------------------------------------------------------------------------
  'other:balanced': (
    'In this specific matter today, the signals remain in thoughtful neutrality.',
    'View the situation dispassionately without imposing prior expectations.',
    'Impatience for an immediate outcome while dynamics are still unfolding.',
  ),
  'other:yes_no:first': (
    'In this matter, the signals lean toward adaptable openness and receptivity.',
    'Approach the dilemma from an unfamiliar angle you previously overlooked.',
    'Mechanically applying an old template to a completely novel context.',
  ),
  'other:yes_no:second': (
    'In this matter, the signals lean toward prudent vigilance and steady ground.',
    'Examine all facets and anticipate downstream effects before choosing.',
    'Deciding in haste merely to relieve temporary uncertainty.',
  ),
  'other:act_wait:first': (
    'Timing counted alongside everything else, the reading leans toward resolving matters now.',
    'Clear small outstanding details before they compound into larger friction.',
    'Acting on impulse without a sensible fallback plan.',
  ),
  'other:act_wait:second': (
    'Timing counted alongside everything else, the reading leans toward patient observation.',
    'Allow unfolding events to clarify true intentions before stepping in.',
    'Intervening anxiously and disrupting the natural course of things.',
  ),
};
