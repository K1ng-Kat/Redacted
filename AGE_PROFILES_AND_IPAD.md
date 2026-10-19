# REDACTED — age-sensitive mystery design and iPad 6 compatibility

## Research basis
These profiles are **design heuristics, not a psychological or reading-level assessment**. Children of the same age differ substantially in vocabulary, reading speed, reasoning and prior knowledge. Players choose a **reading/gameplay profile**, not a verified birth date. REDACTED stores only the selected profile in local settings and does not send it to a server.

1. NAEYC Developmentally Appropriate Practice recommends strengths-based, play-based approaches and explicit consideration of individual differences rather than assigning ability solely by age:
   https://www.naeyc.org/resources/position-statements/dap/definition/
2. US IES/What Works Clearinghouse *Improving Reading Comprehension in Kindergarten Through 3rd Grade* emphasizes comprehension strategies, story structure and guided questioning:
   https://ies.ed.gov/ncee/wwc/PracticeGuide/14
3. US IES *Foundational Skills to Support Reading for Understanding in Kindergarten Through 3rd Grade* highlights age-variable language comprehension and vocabulary:
   https://ies.ed.gov/ncee/wwc/PracticeGuide/21/Published
4. US IES *Providing Reading Interventions for Students in Grades 4–9* recommends explicit comprehension-building, asking questions, monitoring understanding, and gradual access to challenging texts:
   https://ies.ed.gov/ncee/wwc/PracticeGuide/29
5. Apple HIG iPadOS: support 9.7-inch 768×1024 pt iPads, dynamic window size, touch/keyboard ergonomics, text sizing:
   https://developer.apple.com/design/human-interface-guidelines/layout
6. Apple age bands and content ratings are independent of the in-game preference:
   https://developer.apple.com/app-store/categories/
   https://developer.apple.com/kids/
7. FTC COPPA guidance: this game's local gameplay preference is **not** an age-verification or consent gate, and should not be treated as such:
   https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions

## Implemented profiles

| Profile | Brief and question language | Gameplay changes | Assistance |
|---|---|---|---|
| 6–8 Junior | Short direct question + simplified mystery vocabulary | 2 options for choices and object-search; evidence pairs show 3 items; standard 3-digit locks and logged signals | Story and instruction text-to-speech; timeline first-event scaffold; first letter for word scramble |
| 9–12 Explorer | Story clues, cause/effect questions | 3 choice answers; full 4-point timelines; original lock and radio rules | Optional read-aloud and story-focused hints |
| 13–15 Investigator | Compare recorded evidence with testimony | 4 choices; new timeline permutation; reverse the three-digit lock code; add 10 to radio frequency, wrap after 100 | Deduction-focused questions and correct mechanical instructions |
| 16+ Expert | Evaluate indirect evidence and contradictions | 4 choices; distinct timeline permutation; move last code digit to front; tune the frequency complement to 100 | Leaner inference-focused hints |

Every authored case across ten districts uses one of ten puzzle mechanics, and every mechanic has a defined variant in AgeAdjustedMission. The 100 authored case scenarios and resolutions are preserved.

**Accuracy safety checks:** Underlying correct answer indices are not changed when answers are hidden; the correct option always remains visible. Pair puzzles retain both correct clues. Converted keypad answers have three digits; transformed radio answers stay in 0–100 MHz and on the 5 MHz step grid. Timelines maintain a one-to-one answer mapping.

**Progress:** The same on-device save is shared by all profiles, so family members sharing an iPad should know that coins, unlocked levels and scores are shared. Age profiles are not parental controls or separate accounts. Clearing a level under an easier setting retains the score if a harder setting is selected later; future designs can add separate saves, but they are NOT implemented here.

## OS support decisions

- iPad 6th generation (2018) receives iPadOS 17 security updates. Apple's iPadOS 18 compatibility list starts at iPad 7th generation. Sources:
  https://support.apple.com/en-ph/100100
  https://support.apple.com/en-gb/104986
- The single universal Xcode target has a common **minimum deployment target of 17.0** for iOS + iPadOS. Both iPhone and iPad are explicitly supported by the target's device family.
- To honor the product's iPhone requirement, `RedactedApp` shows an explanatory message on iPhone running iOS 17; iPadOS 17 can play the game.
- Apple App Store **cannot enforce separate iPhone 18 / iPad 17 minimums from a single universal deployment target**. An iPhone on iOS 17 might still see/download the game but will see the iPhone update message. This distinction must not be hidden from testers or App Review.
- Playtest on a physical iPad 6th generation running iPadOS 17 and an iPhone on iOS 18 or later. Compile testing must be performed in Xcode; code and data inspection alone do not prove device performance.
- To submit in the Kids category, separately review Apple's Kids Category, parental-gate, privacy, and content guidelines. A local age preference does not automatically make an app compliant.

## Startup motion

The loading artwork now interpolates both the percentage label and filled progress width rather than stepping directly between 4%, 48%, 82% and 100%. The root uses prepared local catalog/save and music checkpoints, with a short animation window before transitioning to the lobby. Respect Reduce Motion; avoid unnecessary network loads or indefinite loading sequences.
